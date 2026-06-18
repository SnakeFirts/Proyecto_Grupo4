import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/lead.dart';

/// Servicio que se comunica con ERPNext vía API REST.
///
/// Flujo: cuando un Lead pasa a "Completado", se crea (o busca) un
/// Cliente en ERPNext y luego se genera una Cotización con el
/// producto SRV001 usando las notas del Lead como detalle.
class ErpNextService {
  // ─── Credenciales y dirección del servidor ─────────────────────────────────
  // En un proyecto real estas irían en un archivo .env o en Flutter Secure Storage.
  // Para esta demo las dejamos aquí porque es un proyecto universitario.
  static const String _baseUrl = 'https://demo.erp.nextoncloud.net';
  static const String _apiKey = '2f7249dab33e6d1';
  static const String _apiSecret = '35eb97f9bdfb07e';

  // ─── Helpers de autenticación ──────────────────────────────────────────────
  // ERPNext usa Basic Auth con API Key + API Secret.
  Map<String, String> get _headers => {
        'Authorization':
            'Basic ${base64Encode(utf8.encode('$_apiKey:$_apiSecret'))}',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  /// Construye la URL base para un recurso dado (ej. "Customer", "Quotation").
  Uri _uri(String doctype, {String? name, Map<String, String>? filters}) {
    if (name != null) {
      // GET/PUT de un documento específico: /api/resource/Doctype/name
      return Uri.parse(
          '$_baseUrl/api/resource/$doctype/${Uri.encodeComponent(name)}');
    }
    if (filters != null) {
      // GET con filtros: /api/resource/Doctype?filters=[["field","=","value"]]
      final filterStr = jsonEncode(
          filters.entries.map((e) => [e.key, '=', e.value]).toList());
      return Uri.parse(
          '$_baseUrl/api/resource/$doctype?filters=${Uri.encodeComponent(filterStr)}');
    }
    // POST para crear nuevo documento
    return Uri.parse('$_baseUrl/api/resource/$doctype');
  }

  // ─── PASO 1: Buscar o crear el Cliente ─────────────────────────────────────

  /// Busca un cliente en ERPNext por nombre exacto.
  /// Si existe, devuelve su nombre tal cual está en el sistema.
  /// Si no existe, lo crea y devuelve el nombre nuevo.
  Future<String> buscarOCrearCliente(Lead lead) async {
    // Primero intentamos buscar por nombre exacto
    final nombre = lead.nameprospecto.trim();

    try {
      final buscarResp = await http.get(
        _uri('Customer', filters: {'customer_name': nombre}),
        headers: _headers,
      );

      if (buscarResp.statusCode == 200) {
        final data = jsonDecode(buscarResp.body);
        final resultados = data['data'] as List<dynamic>;

        // Si encontramos coincidencia exacta, usamos ese cliente
        if (resultados.isNotEmpty) {
          final existente = resultados.first['name'] as String;
          return existente;
        }
      }
    } catch (e) {
      // Si falla la búsqueda, intentamos crear directamente
    }

    // No existe — lo creamos con la información del Lead
    return await _crearCliente(lead);
  }

  /// Crea un nuevo Cliente en ERPNext usando los datos del Lead.
  Future<String> _crearCliente(Lead lead) async {
    final clienteData = {
      'customer_name': lead.nameprospecto.trim(),
      'customer_type': 'Company',
      'customer_group': 'Individual',
      'territory': 'Todos los territorios',
      'language': 'es',
      'email_id': lead.correo.isNotEmpty ? lead.correo : null,
      'mobile_no': lead.telefono.isNotEmpty ? lead.telefono : null,
    };

    // Limpiamos los valores nulos para no enviar campos vacíos
    clienteData.removeWhere((_, v) => v == null);

    final resp = await http.post(
      _uri('Customer'),
      headers: _headers,
      body: jsonEncode(clienteData),
    );

    if (resp.statusCode == 200 || resp.statusCode == 201) {
      final data = jsonDecode(resp.body);
      return data['data']['name'] as String;
    }

    // Si falla porque ya existe (carrera entre búsqueda y creación),
    // intentamos buscarlo de nuevo
    if (resp.statusCode == 409 || resp.statusCode == 400) {
      return await buscarOCrearCliente(lead);
    }

    throw Exception(
        'No se pudo crear el Cliente en ERPNext (${resp.statusCode}): ${resp.body}');
  }

  // ─── PASO 2: Crear la Cotización ──────────────────────────────────────────

  /// Crea una Cotización en ERPNext asociada al cliente.
  ///
  /// - [clienteName]: nombre del cliente en ERPNext ( resultado de buscarOCrearCliente )
  /// - [lead]: el Lead original, de donde sacamos las notas y datos
  /// - [monto]: monto opcional para el servicio. Si es 0 o null, se deja precio abierto.
  Future<String> crearCotizacion({
    required String clienteName,
    required Lead lead,
    double? monto,
  }) async {
    // La fecha de hoy y validez de 15 días
    final hoy = DateTime.now();
    final validez = hoy.add(const Duration(days: 15));

    final cotizacionData = {
      'quotation_to': 'Customer',
      'party_name': clienteName,
      'order_type': 'Sales',
      'company': 'MANCO',
      'transaction_date': _formatDate(hoy),
      'valid_till': _formatDate(validez),
      'currency': 'HNL',
      'selling_price_list': 'Venta estándar',
      'taxes_and_charges': '15%',
      'disable_rounded_total': 1,
      // Las notas del Lead van aquí como observaciones de la cotización
      'terms': lead.detalle.isNotEmpty
          ? _limpiarHtml(lead.detalle)
          : 'Cotización generada desde RapiLead',
      // Referencia al Lead de origen para trazabilidad
      'remarks': 'Generado desde RapiLead - Lead: ${lead.nameprospecto}',
      // Ítem: SRV001 - Servicios Generales
      // La descripción del ítem es el detalle/notas del Lead.
      // Esto le da contexto al cliente sobre qué incluye la cotización.
      'items': [
        {
          'item_code': 'SRV001',
          'item_name': 'Servicios Generales',
          'description': lead.detalle.isNotEmpty
              ? _limpiarHtml(lead.detalle)
              : 'Servicios generales - generada desde RapiLead',
          'qty': 1,
          'rate': monto ?? 0,
          'amount': monto ?? 0,
        }
      ],
    };

    final resp = await http.post(
      _uri('Quotation'),
      headers: _headers,
      body: jsonEncode(cotizacionData),
    );

    if (resp.statusCode == 200 || resp.statusCode == 201) {
      final data = jsonDecode(resp.body);
      return data['data']['name'] as String;
    }

    throw Exception(
        'No se pudo crear la Cotización en ERPNext (${resp.statusCode}): ${resp.body}');
  }

  // ─── MÉTODO PRINCIPAL: sincronizar un Lead completado ──────────────────────

  /// Punto de entrada principal. Se llama cuando un Lead pasa a "Completado".
  ///
  /// Devuelve un mapa con el resultado para que la UI pueda mostrar
  /// un mensaje al usuario con el nombre de la cotización creada.
  Future<Map<String, String>> sincronizarLeadCompletado(Lead lead) async {
    // Paso 1: buscar o crear el cliente en ERPNext
    final clienteName = await buscarOCrearCliente(lead);

    // Paso 2: crear la cotización con el producto SRV001
    final cotizacionName = await crearCotizacion(
      clienteName: clienteName,
      lead: lead,
    );

    return {
      'cliente': clienteName,
      'cotizacion': cotizacionName,
    };
  }

  // ─── Utilidades ────────────────────────────────────────────────────────────

  /// Formatea una fecha como "YYYY-MM-DD" que es lo que ERPNext espera.
  String _formatDate(DateTime fecha) {
    return '${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}';
  }

  /// Limpia etiquetas HTML básicas del texto para mandarlo como terms.
  String _limpiarHtml(String texto) {
    return texto
        .replaceAll(RegExp(r'<[^>]*>'), '') // quita etiquetas HTML
        .replaceAll('&nbsp;', ' ') // espacio HTML
        .replaceAll(RegExp(r'\n{3,}'), '\n\n') // máximo 2 saltos seguidos
        .trim();
  }
}
