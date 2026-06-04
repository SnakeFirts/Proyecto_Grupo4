import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/bitacora_model.dart';
import '../services/location_service.dart';

class BitacoraController extends ChangeNotifier {
  final comentarioController = TextEditingController();
  final LocationService _locationService = LocationService();
  
  String tipoSeleccionado = 'Llamada';
  bool cargandoGps = false;
  bool gpsCargado = false;
  Position? posicion;

  Future<void> seleccionarTipo(String tipo) async {
    tipoSeleccionado = tipo;
    gpsCargado = false;
    cargandoGps = false;
    posicion = null;
    notifyListeners();
    if (tipo == 'Visita') {
      await obtenerUbicacion();
    }
  }

  Future<void> obtenerUbicacion() async {
    cargandoGps = true;
    notifyListeners();
    try {
      final Position? nuevaPosicion = await _locationService.obtenerUbicacion();
      if (nuevaPosicion != null) {
        posicion = nuevaPosicion;
        gpsCargado = true;
      }
    } catch (e) {
      gpsCargado = false;
    }
    cargandoGps = false;
    notifyListeners();
  }

  String getHint() {
    switch (tipoSeleccionado) {
      case 'Llamada':
        return 'Detalla el resultado de la llamada...';
      case 'Correo':
        return 'Describe el correo enviado...';
      case 'Visita':
        return '¿Cuál fue el objetivo y resultado de la visita presencial?';
      default:
        return '';
    }
  }

  BitacoraModel generarBitacora() {
    return BitacoraModel(
      tipoInteraccion: tipoSeleccionado,
      comentario: comentarioController.text,
      latitud: posicion?.latitude,
      longitud: posicion?.longitude,
      fecha: DateTime.now(),
    );
  }
}