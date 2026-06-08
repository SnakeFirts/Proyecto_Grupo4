import 'package:cloud_firestore/cloud_firestore.dart';

class Lead {
  final String? id;
  String nameprospecto;
  String? prospectoId;
  String infoprospecto;
  DateTime? fecha;
  String detalle;
  String estado;
  String telefono;
  String correo;
  DateTime? fechaCreacion;

  Lead({
    this.id,
    required this.nameprospecto,
    this.prospectoId,
    required this.infoprospecto,
    this.fecha,
    required this.detalle,
    required this.estado,
    this.telefono = '',
    this.correo = '',
    this.fechaCreacion,
  });

  // Para mostrar la fecha formateada en UI
  String get fechaFormateada {
    if (fecha == null) return '—';
    return '${fecha!.day.toString().padLeft(2, '0')}/'
        '${fecha!.month.toString().padLeft(2, '0')}/'
        '${fecha!.year}';
  }

  String fullName() => nameprospecto;

  Map<String, dynamic> toMap() {
    return {
      'nameprospecto': nameprospecto,
      'prospectoId': prospectoId,
      'infoprospecto': infoprospecto,
      'fecha': fecha != null ? Timestamp.fromDate(fecha!) : null,
      'detalle': detalle,
      'estado': estado,
      'telefono': telefono,
      'correo': correo,
      'fechaCreacion': fechaCreacion != null
          ? Timestamp.fromDate(fechaCreacion!)
          : FieldValue.serverTimestamp(),
    };
  }

  factory Lead.fromMap(Map<String, dynamic> map, String docId) {
    return Lead(
      id: docId,
      nameprospecto: map['nameprospecto'] ?? '',
      prospectoId: map['prospectoId'],
      infoprospecto: map['infoprospecto'] ?? '',
      fecha: (map['fecha'] as Timestamp?)?.toDate(),
      detalle: map['detalle'] ?? '',
      estado: map['estado'] ?? 'Abierto',
      telefono: map['telefono'] ?? '',
      correo: map['correo'] ?? '',
      fechaCreacion: (map['fechaCreacion'] as Timestamp?)?.toDate(),
    );
  }

  factory Lead.fromDoc(DocumentSnapshot doc) {
    return Lead.fromMap(
      doc.data() as Map<String, dynamic>,
      doc.id,
    );
  }

  Lead copyWith({
    String? id,
    String? nameprospecto,
    String? prospectoId,
    String? infoprospecto,
    DateTime? fecha,
    String? detalle,
    String? estado,
    String? telefono,
    String? correo,
    DateTime? fechaCreacion,
  }) {
    return Lead(
      id: id ?? this.id,
      nameprospecto: nameprospecto ?? this.nameprospecto,
      prospectoId: prospectoId ?? this.prospectoId,
      infoprospecto: infoprospecto ?? this.infoprospecto,
      fecha: fecha ?? this.fecha,
      detalle: detalle ?? this.detalle,
      estado: estado ?? this.estado,
      telefono: telefono ?? this.telefono,
      correo: correo ?? this.correo,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
    );
  }

  /// Crea un Lead desde un Prospecto (conversión)
  factory Lead.desdeProspecto(dynamic p) {
    return Lead(
      prospectoId: p.id,
      nameprospecto: p.nombre,
      infoprospecto: p.compania,
      detalle: '',
      estado: 'Abierto',
      telefono: p.telefono,
      correo: p.correo,
    );
  }
}
