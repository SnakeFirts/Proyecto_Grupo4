import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:speech_to_text/speech_to_text.dart'; // ← nuevo
import '../models/bitacora_model.dart';
import '../services/location_service.dart';

class BitacoraController extends ChangeNotifier {
  final comentarioController = TextEditingController();
  final LocationService _locationService = LocationService();
  final SpeechToText _speechToText = SpeechToText(); // ← nuevo

  String tipoSeleccionado = 'Llamada';
  bool cargandoGps = false;
  bool gpsCargado = false;
  Position? posicion;

  // ── Speech ──────────────────────────────────────────
  bool isListening = false;
  bool speechEnabled = false;

  BitacoraController() {
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    speechEnabled = await _speechToText.initialize();
    notifyListeners();
  }

  Future<void> startListening() async {
    if (!speechEnabled) return;
    await _speechToText.listen(
      onResult: (result) {
        comentarioController.text = result.recognizedWords;
        notifyListeners();
      },
      localeId: 'es_HN',
    );
    isListening = true;
    notifyListeners();
  }

  Future<void> stopListening() async {
    await _speechToText.stop();
    isListening = false;
    notifyListeners();
  }
  // ─────────────────────────────────────────────────────

  Future<void> seleccionarTipo(String tipo) async {
    tipoSeleccionado = tipo;
    gpsCargado = false;
    cargandoGps = false;
    posicion = null;
    if (isListening) await stopListening(); // ← detener mic al cambiar tipo
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
      debugPrint('ERROR GPS: $e');
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
