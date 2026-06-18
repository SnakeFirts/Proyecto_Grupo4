class BitacoraModel {
  final String tipoInteraccion;
  final String comentario;
  final double? latitud;
  final double? longitud;
  final double? kilometros; // Solo se registra en visitas
  final DateTime fecha;

  BitacoraModel({
    required this.tipoInteraccion,
    required this.comentario,
    this.latitud,
    this.longitud,
    this.kilometros,
    required this.fecha,
  });

  Map<String, dynamic> toMap() {
    return {
      'tipoInteraccion': tipoInteraccion,
      'comentario': comentario,
      'latitud': latitud,
      'longitud': longitud,
      'kilometros': kilometros,
      'fecha': fecha.toIso8601String(),
    };
  }
}