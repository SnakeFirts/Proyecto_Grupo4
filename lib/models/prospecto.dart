import 'package:cloud_firestore/cloud_firestore.dart';

class Prospecto {
  final String? id;
  String compania;
  String nombre;
  String direccion;
  String cargo;
  String correo;
  String telefono;
  String movil;
  DateTime? fechaCreacion;

  Prospecto({
    this.id,
    required this.compania,
    required this.nombre,
    required this.direccion,
    required this.cargo,
    required this.correo,
    required this.telefono,
    required this.movil,
    this.fechaCreacion,
  });

  String fullName() => nombre;

  Map<String, dynamic> toMap() {
    return {
      'compania': compania,
      'nombre': nombre,
      'direccion': direccion,
      'cargo': cargo,
      'correo': correo,
      'telefono': telefono,
      'movil': movil,
      'fechaCreacion': fechaCreacion != null
          ? Timestamp.fromDate(fechaCreacion!)
          : FieldValue.serverTimestamp(),
    };
  }

  factory Prospecto.fromMap(Map<String, dynamic> map, String docId) {
    return Prospecto(
      id: docId,
      compania: map['compania'] ?? '',
      nombre: map['nombre'] ?? '',
      direccion: map['direccion'] ?? '',
      cargo: map['cargo'] ?? '',
      correo: map['correo'] ?? '',
      telefono: map['telefono'] ?? '',
      movil: map['movil'] ?? '',
      fechaCreacion: (map['fechaCreacion'] as Timestamp?)?.toDate(),
    );
  }

  factory Prospecto.fromDoc(DocumentSnapshot doc) {
    return Prospecto.fromMap(
      doc.data() as Map<String, dynamic>,
      doc.id,
    );
  }

  Prospecto copyWith({
    String? id,
    String? compania,
    String? nombre,
    String? direccion,
    String? cargo,
    String? correo,
    String? telefono,
    String? movil,
    DateTime? fechaCreacion,
  }) {
    return Prospecto(
      id: id ?? this.id,
      compania: compania ?? this.compania,
      nombre: nombre ?? this.nombre,
      direccion: direccion ?? this.direccion,
      cargo: cargo ?? this.cargo,
      correo: correo ?? this.correo,
      telefono: telefono ?? this.telefono,
      movil: movil ?? this.movil,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
    );
  }
}
