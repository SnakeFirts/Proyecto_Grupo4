import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:speech_to_text/speech_to_text.dart'; // Importamos la librería
import '../models/bitacora_model.dart';
import '../services/location_service.dart';

class BitacoraController extends ChangeNotifier {
  final comentarioController = TextEditingController();
  final LocationService _locationService = LocationService();
  final SpeechToText _speechToText = SpeechToText(); // Instancia del plugin
  
  String tipoSeleccionado = 'Llamada';
  bool cargandoGps = false;
  bool gpsCargado = false;
  Position? posicion;

  // Nuevas variables para controlar el micrófono
  bool isListening = false;
  bool speechEnabled = false;

  BitacoraController() {
    _initSpeech(); // Inicializamos al instanciar el controlador
  }

  // Configura el plugin de voz
  Future<void> _initSpeech() async {
    speechEnabled = await _speechToText.initialize();
    notifyListeners();
  }

  // Comienza a escuchar
  Future<void> startListening() async {
    if (!speechEnabled) return; // Si no hay permisos, no hace nada
    
    await _speechToText.listen(
      onResult: (result) {
        // Escribe lo que escucha en el cuadro de texto
        comentarioController.text = result.recognizedWords;
        notifyListeners();
      },
      localeId: 'es_HN', // Opcional: ajustado al español de Honduras o el que prefieras
    );
    isListening = true;
    notifyListeners();
  }

  // Detiene la escucha
  Future<void> stopListening() async {
    await _speechToText.stop();
    isListening = false;
    notifyListeners();
  }

  Future<void> seleccionarTipo(String tipo) async {
    tipoSeleccionado = tipo;
    gpsCargado = false;
    cargandoGps = false;
    posicion = null;
    
    // Si cambiamos de tipo y el micrófono estaba activo, lo apagamos
    if (isListening) {
      await stopListening();
    }
    
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