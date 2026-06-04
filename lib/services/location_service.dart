import 'package:geolocator/geolocator.dart';

class LocationService {
  Future<Position?> obtenerUbicacion() async {
    bool servicioHabilitado = await Geolocator.isLocationServiceEnabled();
    LocationPermission permiso = await Geolocator.checkPermission();

    if (!servicioHabilitado) {
      return null;
    }
    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
    }
    if (permiso == LocationPermission.denied || permiso == LocationPermission.deniedForever) {
      return null;
    }
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }
}