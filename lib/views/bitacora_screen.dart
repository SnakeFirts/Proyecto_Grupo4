import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/bitacora_controller.dart';
import 'widgets/gps_card.dart';
import 'widgets/interaction_chip.dart';

class BitacoraScreen extends StatelessWidget {
  final String nombreLead;

  const BitacoraScreen({
    super.key,
    required this.nombreLead,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BitacoraController(),
      child: Consumer<BitacoraController>(
        builder: (context, controller, child) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Bitácora'),
            ),
            body: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Lead: $nombreLead',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Tipo de Interacción',
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      InteractionChip(
                        titulo: 'Llamada',
                        icono: Icons.call,
                        seleccionado:
                            controller.tipoSeleccionado == 'Llamada',
                        onTap: () {
                          controller.seleccionarTipo('Llamada',);
                        },
                      ),
                      InteractionChip(
                        titulo: 'Correo',
                        icono: Icons.email,
                        seleccionado:
                            controller.tipoSeleccionado == 'Correo',
                        onTap: () {
                          controller.seleccionarTipo('Correo',);
                        },
                      ),
                      InteractionChip(
                        titulo: 'Visita',
                        icono: Icons.directions_car_filled,
                        seleccionado:
                            controller.tipoSeleccionado == 'Visita',
                        onTap: () {
                          controller.seleccionarTipo('Visita',);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: controller.comentarioController, maxLines: 5,
                    decoration: InputDecoration(
                      hintText: controller.getHint(),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (controller.tipoSeleccionado ==
                      'Visita')
                    GpsCard(
                      cargando:
                          controller.cargandoGps,
                      gpsCargado:
                          controller.gpsCargado,
                      posicion:
                          controller.posicion,
                    ),

                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Bitácora registrada',
                            ),
                          ),
                        );
                        Navigator.pop(context);
                      },
                      child: Text(
                        controller.tipoSeleccionado == 'Visita'
                            ? 'Confirmar Check-In'
                            : 'Registrar',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}