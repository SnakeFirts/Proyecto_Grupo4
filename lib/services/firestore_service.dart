import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/prospecto.dart';
import '../models/lead.dart';

/// Servicio único de acceso a Firestore.
/// Úsalo con Provider o instancia directa — es stateless.
class FirestoreService {
  final _db = FirebaseFirestore.instance;

  // ─── Colecciones ──────────────────────────────────────────────────────────
  CollectionReference<Map<String, dynamic>> get _prospectos =>
      _db.collection('prospectos');

  CollectionReference<Map<String, dynamic>> get _leads =>
      _db.collection('leads');

  CollectionReference<Map<String, dynamic>> _bitacoras(String leadId) =>
      _db.collection('leads').doc(leadId).collection('bitacoras');

  // ─── PROSPECTOS ───────────────────────────────────────────────────────────

  // Apunte: Ahora pedimos isAdmin y currentUid para saber a quién le estamos trayendo los datos
  Stream<List<Prospecto>> streamProspectos(bool isAdmin, String currentUid) {
    // Apunte: Quitamos el orderBy de Firebase para no obligar a crear un Índice Compuesto
    Query<Map<String, dynamic>> query = _prospectos;

    // Apunte: Si es vendedor, filtramos para que la base de datos solo le regrese sus propios clientes
    if (!isAdmin) {
      query = query.where('userId', isEqualTo: currentUid);
    }

    return query.snapshots().map((snap) {
      final lista = snap.docs.map(Prospecto.fromDoc).toList();

      // Apunte: Ordenamos los datos aquí en el teléfono (del más reciente al más antiguo)
      lista.sort((a, b) {
        final fechaA = a.fechaCreacion ?? DateTime(2000);
        final fechaB = b.fechaCreacion ?? DateTime(2000);
        return fechaB.compareTo(fechaA);
      });

      return lista;
    });
  }

  Future<void> actualizarEstadoLead(String id, String nuevoEstado) async {
    await _leads.doc(id).update({'estado': nuevoEstado});
  }

  /// Crear prospecto — devuelve el ID generado
  Future<String> crearProspecto(Prospecto p, String currentUid) async {
    final data = p.toMap();
    // Apunte: Forzamos la inyección del ID del creador justo antes de mandarlo a la nube, así evitamos que se pierda el dato
    data['userId'] = currentUid;

    final ref = await _prospectos.add(data);
    return ref.id;
  }

  /// Actualizar prospecto existente
  Future<void> actualizarProspecto(Prospecto p) async {
    if (p.id == null) throw Exception('Prospecto sin ID');
    final data = p.toMap();
    data.remove('userId'); //
    await _prospectos.doc(p.id).update(data);
  }

  /// Eliminar prospecto
  Future<void> eliminarProspecto(String id) async {
    await _prospectos.doc(id).delete();
  }

  // ─── LEADS ────────────────────────────────────────────────────────────────

  // Apunte: Misma lógica de permisos para las oportunidades (Leads)
  Stream<List<Lead>> streamLeads(bool isAdmin, String currentUid) {
    // Apunte: Misma solución, quitamos el orderBy de la consulta
    Query<Map<String, dynamic>> query = _leads;

    // Apunte: Ocultamos lo que no es del vendedor actual
    if (!isAdmin) {
      query = query.where('userId', isEqualTo: currentUid);
    }

    return query.snapshots().map((snap) {
      final lista = snap.docs.map(Lead.fromDoc).toList();

      // Apunte: Ordenamiento local para Leads
      lista.sort((a, b) {
        final fechaA = a.fechaCreacion ?? DateTime(2000);
        final fechaB = b.fechaCreacion ?? DateTime(2000);
        return fechaB.compareTo(fechaA);
      });

      return lista;
    });
  }

  /// Crear lead — devuelve el ID generado
  Future<String> crearLead(Lead l, String currentUid) async {
    final data = l.toMap();
    // Apunte: Marcamos la propiedad de la oportunidad
    data['userId'] = currentUid;

    final ref = await _leads.add(data);
    return ref.id;
  }

  /// Actualizar lead existente
  Future<void> actualizarLead(Lead l) async {
    if (l.id == null) throw Exception('Lead sin ID');
    final data = l.toMap();
    data.remove('userId');
    await _leads.doc(l.id).update(data);
  }

  /// Eliminar lead
  Future<void> eliminarLead(String id) async {
    await _leads.doc(id).delete();
  }

  /// Convertir prospecto en lead (crea lead y puede marcar prospecto)
  Future<String> convertirProspectoALead(Prospecto p, String currentUid) async {
    final lead = Lead.desdeProspecto(p);
    // Apunte: Pasamos el UID para que el nuevo lead también se asigne correctamente al vendedor
    return await crearLead(lead, currentUid);
  }

  // ─── BITÁCORAS ────────────────────────────────────────────────────────────
  Stream<List<Map<String, dynamic>>> streamBitacoras(String leadId) {
    // Apunte: Aquí sí podemos dejar el orderBy porque las bitácoras no las filtramos con un where (solo pedimos las del documento actual)
    return _bitacoras(leadId)
        .orderBy('fecha', descending: true)
        .snapshots()
        .map(
            (snap) => snap.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  /// Guardar entrada de bitácora
  Future<void> guardarBitacora({
    required String leadId,
    required String tipoInteraccion,
    required String comentario,
    double? latitud,
    double? longitud,
    double? kilometros,
  }) async {
    await _bitacoras(leadId).add({
      'tipoInteraccion': tipoInteraccion,
      'comentario': comentario,
      'latitud': latitud,
      'longitud': longitud,
      'kilometros': kilometros,
      'fecha': FieldValue.serverTimestamp(),
    });
  }

  /// Editar entrada de bitácora existente
  Future<void> editarBitacora({
    required String leadId,
    required String bitacoraId,
    required String tipoInteraccion,
    required String comentario,
  }) async {
    await _bitacoras(leadId).doc(bitacoraId).update({
      'tipoInteraccion': tipoInteraccion,
      'comentario': comentario,
      'editadoEn': FieldValue.serverTimestamp(),
    });
  }

  /// Eliminar entrada de bitácora
  Future<void> eliminarBitacora({
    required String leadId,
    required String bitacoraId,
  }) async {
    await _bitacoras(leadId).doc(bitacoraId).delete();
  }

  // ─── KILÓMETROS POR USUARIO ────────────────────────────────────────────
  /// Obtiene el total de kilómetros recorridos por cada vendedor.
  /// Retorna un Map<userId, totalKm>.
  Future<Map<String, double>> obtenerKilometrosPorUsuario() async {
    final Map<String, double> kmPorUsuario = {};
    final Map<String, String> leadToUser = {}; // leadId → userId

    // 1. Obtener todos los leads para mapear leadId → userId
    final leadsSnap = await _leads.get();
    for (final doc in leadsSnap.docs) {
      final data = doc.data();
      final userId = data['userId'] as String?;
      if (userId != null && userId.isNotEmpty) {
        leadToUser[doc.id] = userId;
      }
    }

    if (leadToUser.isEmpty) return kmPorUsuario;

    // 2. Usar collectionGroup para traer todas las bitácoras de golpe
    try {
      final bitacorasSnap = await _db.collectionGroup('bitacoras').get();
      for (final doc in bitacorasSnap.docs) {
        final data = doc.data();
        final kilometros = (data['kilometros'] as num?)?.toDouble();
        if (kilometros != null && kilometros > 0) {
          // Obtener el leadId del padre
          final leadId = doc.reference.parent.parent?.id;
          if (leadId != null) {
            final userId = leadToUser[leadId];
            if (userId != null) {
              kmPorUsuario[userId] = (kmPorUsuario[userId] ?? 0) + kilometros;
            }
          }
        }
      }
    } catch (_) {
      // Si collectionGroup falla (índice no creado), buscar lead por lead
      for (final leadId in leadToUser.keys) {
        final bitacorasSnap = await _bitacoras(leadId).get();
        for (final doc in bitacorasSnap.docs) {
          final data = doc.data();
          final kilometros = (data['kilometros'] as num?)?.toDouble();
          if (kilometros != null && kilometros > 0) {
            final userId = leadToUser[leadId]!;
            kmPorUsuario[userId] = (kmPorUsuario[userId] ?? 0) + kilometros;
          }
        }
      }
    }

    return kmPorUsuario;
  }
}
