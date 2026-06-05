class Lead {
  String nameprospecto;
  String infoprospecto;
  String fecha;
  String detalle;
  String estado;
  String telefono;
  String correo;

  Lead({
    required this.nameprospecto,
    required this.infoprospecto,
    required this.fecha,
    required this.detalle,
    required this.estado,
    this.telefono = '',
    this.correo = '',
  });

  String fullName() => infoprospecto;
}