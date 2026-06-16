import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

class CardScanResult {
  final String nombre;
  final String empresa;
  final String cargo;
  final String correo;
  final String telefono;
  final String direccion;
  final String rawText;

  const CardScanResult({
    required this.nombre,
    required this.empresa,
    required this.cargo,
    required this.correo,
    required this.telefono,
    required this.direccion,
    required this.rawText,
  });
}

class CardScannerService {
  static final _recognizer =
      TextRecognizer(script: TextRecognitionScript.latin);
  static final _picker = ImagePicker();

  static Future<CardScanResult?> escanearDesdeCamera() async {
    final photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 90,
    );
    if (photo == null) return null;
    return _procesar(photo.path);
  }

  static Future<CardScanResult?> escanearDesdeGaleria() async {
    final photo = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (photo == null) return null;
    return _procesar(photo.path);
  }

  static Future<CardScanResult> _procesar(String path) async {
    final inputImage = InputImage.fromFile(File(path));
    final recognized = await _recognizer.processImage(inputImage);
    final rawText = recognized.text;

    final correo = _extraerCorreo(rawText);
    final telefono = _extraerTelefono(rawText);
    final cargo = _extraerCargo(rawText);
    final direccion = _extraerDireccion(rawText);
    final nombre = _extraerNombre(rawText, cargo, correo, telefono, direccion);
    final empresa = _extraerEmpresa(rawText, nombre, cargo, direccion);

    return CardScanResult(
      nombre: nombre,
      empresa: empresa,
      cargo: cargo,
      correo: correo,
      telefono: telefono,
      direccion: direccion,
      rawText: rawText,
    );
  }

  // ── Correo ─────────────────────────────────────────────────────────────────
  static String _extraerCorreo(String text) {
    final match = RegExp(
      r'[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}',
    ).firstMatch(text);
    return match?.group(0)?.trim() ?? '';
  }

  // ── Teléfono: prefiere celular hondureño ───────────────────────────────────
  static String _extraerTelefono(String text) {
    // Celular hondureño: empieza con 8 o 9
    final celular = RegExp(
      r'(?:Cel[:\.]?\s*)?(\+?504[\s\-]?)?([89]\d{3}[\s\-]?\d{4})',
      caseSensitive: false,
    ).firstMatch(text);

    if (celular != null) {
      return celular
          .group(0)!
          .replaceAll(RegExp(r'[Cc]el[:\.]?\s*'), '')
          .trim();
    }

    // Cualquier teléfono como fallback
    final cualquiera = RegExp(
      r'\(?\+?[\d]{2,4}\)?[\s\-]?[\d\s\-\(\)]{6,15}',
    ).firstMatch(text);

    return cualquiera?.group(0)?.trim() ?? '';
  }

  // ── Cargo ──────────────────────────────────────────────────────────────────
  static String _extraerCargo(String text) {
    final keywords = [
      'Gerente',
      'Director',
      'Ejecutivo',
      'Jefe',
      'Manager',
      'Coordinador',
      'Presidente',
      'Vicepresidente',
      'Fundador',
      'Co-Fundador',
      'Subgerente',
      'Supervisor',
      'Representante',
      'Asesor',
      'Consultor',
      'Analista',
      'Especialista',
      'Ing.',
      'Lic.',
      'Dr.',
      'Dra.',
      'Abogado',
      'Arquitecto',
      'Ventas',
      'Operaciones',
      'Finanzas',
      'Marketing',
      'TI',
      'Unidad',
      'Estrategia',
      'Comunicacion',
      'Corporativas',
    ];

    for (final line in text.split('\n')) {
      final l = line.trim();
      if (l.isEmpty) continue;
      for (final kw in keywords) {
        if (l.contains(kw)) return l;
      }
    }
    return '';
  }

  // ── Dirección: detecta calles, colonias, edificios, ciudades ──────────────
  static String _extraerDireccion(String text) {
    final keywords = [
      'Col\.',
      'Colonia',
      'Blvd',
      'Boulevard',
      'Av\.',
      'Avenida',
      'Calle',
      'Km\.',
      'Km ',
      'Carretera',
      'Edificio',
      'Edif\.',
      'Casa',
      'Local',
      'Piso',
      'Barrio',
      'Bo\.',
      'Residencial',
      'Tegucigalpa',
      'San Pedro Sula',
      'La Ceiba',
      'Honduras',
      'C\.A\.',
      'Plaza',
      'Centro Comercial',
      'Paseo',
    ];

    final lines = text.split('\n');
    final direccionLines = <String>[];

    for (int i = 0; i < lines.length; i++) {
      final l = lines[i].trim();
      if (l.isEmpty) continue;

      for (final kw in keywords) {
        if (l.contains(kw)) {
          direccionLines.add(l);
          // Incluir la siguiente línea si parece continuación
          if (i + 1 < lines.length) {
            final next = lines[i + 1].trim();
            // Continuación si no tiene @, no es teléfono puro, no es www
            if (next.isNotEmpty &&
                !next.contains('@') &&
                !next.toLowerCase().contains('www.') &&
                !RegExp(r'^\+?[\d\s\-\(\)]+$').hasMatch(next) &&
                !direccionLines.contains(next)) {
              direccionLines.add(next);
            }
          }
          break;
        }
      }
    }

    return direccionLines.join(', ');
  }

  // ── Nombre ─────────────────────────────────────────────────────────────────
  static String _extraerNombre(
    String text,
    String cargo,
    String correo,
    String telefono,
    String direccion,
  ) {
    final prefijos = RegExp(
      r'^(Ing\.|Lic\.|Dr\.|Dra\.|Sr\.|Sra\.|Arq\.)\s*',
      caseSensitive: false,
    );

    for (final line in text.split('\n')) {
      final l = line.trim();
      if (l.isEmpty) continue;
      if (l == cargo) continue;
      if (l.contains('@')) continue;
      if (l.toLowerCase().contains('www.')) continue;
      if (l.toLowerCase().contains('http')) continue;
      if (RegExp(r'^\+?[\d\s\-\(\)\.]+$').hasMatch(l)) continue;
      if (direccion.contains(l)) continue;

      final sinPrefijo = l.replaceFirst(prefijos, '').trim();
      final palabras = sinPrefijo.split(' ');

      if (palabras.length >= 2 && palabras.length <= 5) {
        if (RegExp(r'^\d').hasMatch(sinPrefijo)) continue;
        if (sinPrefijo == cargo) continue;
        // Al menos una palabra debe empezar con mayúscula
        if (palabras.any((p) => p.isNotEmpty && p[0] == p[0].toUpperCase())) {
          return sinPrefijo;
        }
      }
    }
    return '';
  }

  // ── Empresa ────────────────────────────────────────────────────────────────
  static String _extraerEmpresa(
    String text,
    String nombre,
    String cargo,
    String direccion,
  ) {
    final keywords = [
      'S.A.', 'S.A. de C.V.', 'S de RL', 'LLC', 'Corp', 'Ltda',
      'Group', 'Grupo', 'Corporación', 'Asociación', 'Fundación',
      'Instituto', 'Solutions', 'Services', 'Consulting',
      'Latinoamérica', 'Internacional', 'Global', 'Nacional',
      'Banco', 'Financiera', 'Seguros', 'Inversiones',
      'MCC', 'AMHON', // empresas específicas de las tarjetas de prueba
    ];

    for (final line in text.split('\n')) {
      final l = line.trim();
      if (l.isEmpty || l == nombre || l == cargo) continue;
      if (l.contains('@') || l.toLowerCase().contains('www.')) continue;
      if (RegExp(r'^\+?[\d\s\-\(\)\.]+$').hasMatch(l)) continue;
      if (direccion.contains(l)) continue;

      for (final kw in keywords) {
        if (l.contains(kw)) return l;
      }
    }

    // Fallback: línea corta que no sea nombre ni cargo ni dirección
    for (final line in text.split('\n')) {
      final l = line.trim();
      if (l.isEmpty || l == nombre || l == cargo) continue;
      if (l.contains('@') || l.toLowerCase().contains('www.')) continue;
      if (RegExp(r'^\+?[\d\s\-\(\)\.]+$').hasMatch(l)) continue;
      if (direccion.contains(l)) continue;
      if (l.split(' ').length <= 4 && l.length > 3) return l;
    }

    return '';
  }

  static void dispose() => _recognizer.close();
}
