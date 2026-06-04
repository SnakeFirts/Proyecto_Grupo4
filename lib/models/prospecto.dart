class Prospecto {
  String compania;
  String nombre;
  String direccion;
  String cargo;
  String correo;
  String telefono;
  String movil;

  Prospecto({
    required this.compania,
    required this.nombre,
    required this.direccion,
    required this.cargo,
    required this.correo,
    required this.telefono,
    required this.movil,
  });

  String fullName() {
    return nombre;
  }
}
