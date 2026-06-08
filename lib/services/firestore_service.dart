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
  Stream<List<Prospecto>> streamProspectos() {
    return _prospectos
        .orderBy('fechaCreacion', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(Prospecto.fromDoc).toList());
  }

  /// Crear prospecto — devuelve el ID generado
  Future<String> crearProspecto(Prospecto p) async {
    final ref = await _prospectos.add(p.toMap());
    return ref.id;
  }

  /// Actualizar prospecto existente
  Future<void> actualizarProspecto(Prospecto p) async {
    if (p.id == null) throw Exception('Prospecto sin ID');
    await _prospectos.doc(p.id).update(p.toMap());
  }

  /// Eliminar prospecto
  Future<void> eliminarProspecto(String id) async {
    await _prospectos.doc(id).delete();
  }

  // ─── LEADS ────────────────────────────────────────────────────────────────
  Stream<List<Lead>> streamLeads() {
    return _leads
        .orderBy('fechaCreacion', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(Lead.fromDoc).toList());
  }

  /// Crear lead — devuelve el ID generado
  Future<String> crearLead(Lead l) async {
    final ref = await _leads.add(l.toMap());
    return ref.id;
  }

  /// Actualizar lead existente
  Future<void> actualizarLead(Lead l) async {
    if (l.id == null) throw Exception('Lead sin ID');
    await _leads.doc(l.id).update(l.toMap());
  }

  /// Eliminar lead
  Future<void> eliminarLead(String id) async {
    await _leads.doc(id).delete();
  }

  /// Convertir prospecto en lead (crea lead y puede marcar prospecto)
  Future<String> convertirProspectoALead(Prospecto p) async {
    final lead = Lead.desdeProspecto(p);
    return await crearLead(lead);
  }

  // ─── BITÁCORAS ────────────────────────────────────────────────────────────
  Stream<List<Map<String, dynamic>>> streamBitacoras(String leadId) {
    return _bitacoras(leadId)
        .orderBy('fecha', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => {'id': d.id, ...d.data()})
            .toList());
  }

  /// Guardar entrada de bitácora
  Future<void> guardarBitacora({
    required String leadId,
    required String tipoInteraccion,
    required String comentario,
    double? latitud,
    double? longitud,
  }) async {
    await _bitacoras(leadId).add({
      'tipoInteraccion': tipoInteraccion,
      'comentario': comentario,
      'latitud': latitud,
      'longitud': longitud,
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
}
