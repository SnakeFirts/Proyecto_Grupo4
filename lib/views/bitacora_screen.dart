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
                        icono: Icons.phone,
                        seleccionado: controller.tipoSeleccionado == 'Llamada',
                        onTap: () => controller.seleccionarTipo('Llamada'), // <-- Cambio aquí
                      ),
                      const SizedBox(width: 12),
                      InteractionChip(
                        titulo: 'Correo',
                        icono: Icons.email,
                        seleccionado: controller.tipoSeleccionado == 'Correo',
                        onTap: () => controller.seleccionarTipo('Correo'), // <-- Cambio aquí
                      ),
                      const SizedBox(width: 12),
                      InteractionChip(
                        titulo: 'Visita',
                        icono: Icons.location_on,
                        seleccionado: controller.tipoSeleccionado == 'Visita',
                        onTap: () => controller.seleccionarTipo('Visita'), // <-- Cambio aquí
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // --- SECCIÓN MODIFICADA: TEXTFIELD + MICRÓFONO ---
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      TextField(
                        controller: controller.comentarioController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: controller.getHint(),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                      ),
                      
                      // Mostramos el botón de micrófono SÓLO si es Llamada
                      if (controller.tipoSeleccionado == 'Llamada') ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              controller.isListening ? 'Escuchando...' : 'Dictar nota',
                              style: TextStyle(
                                fontSize: 14,
                                color: controller.isListening ? Colors.red : Colors.grey,
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                controller.isListening ? Icons.mic : Icons.mic_none,
                                color: controller.isListening ? Colors.red : Colors.blue,
                              ),
                              onPressed: () {
                                if (controller.isListening) {
                                  controller.stopListening();
                                } else {
                                  controller.startListening();
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                  // --- FIN SECCIÓN MODIFICADA ---

                  const SizedBox(height: 24),
                  if (controller.tipoSeleccionado == 'Visita')
                    GpsCard(
                      cargando: controller.cargandoGps,
                      gpsCargado: controller.gpsCargado,
                      posicion: controller.posicion,
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