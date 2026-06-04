class Lead {
  String nameprospecto;
  String infoprospecto;
  String fecha;
  String detalle;
  String estado;

  Lead({
    required this.nameprospecto,
    required this.infoprospecto,
    required this.fecha,
    required this.detalle,
    required this.estado,
  });

  String fullName() {
    return infoprospecto;
  }
}
