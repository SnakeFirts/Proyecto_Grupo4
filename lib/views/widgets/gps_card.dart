import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class GpsCard extends StatelessWidget {
  final bool cargando;
  final bool gpsCargado;
  final Position? posicion;

  const GpsCard({
    super.key,
    required this.cargando,
    required this.gpsCargado,
    required this.posicion,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xffF0FFF4),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xff86EFAC),
        ),
      ),
      child: cargando
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : gpsCargado
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: Colors.green,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'GPS Vinculado con Éxito',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Lat: ${posicion?.latitude.toStringAsFixed(4)} | '
                      'Lon: ${posicion?.longitude.toStringAsFixed(4)}',
                    ),
                  ],
                )
              : const Text(
                  'No se pudo obtener ubicación',
                ),
    );
  }
}