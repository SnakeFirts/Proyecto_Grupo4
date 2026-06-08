import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../controllers/bitacora_controller.dart';
import '../models/lead.dart';
import '../services/firestore_service.dart';
import 'widgets/gps_card.dart';
import 'widgets/interaction_chip.dart';

// ─── Colores ──────────────────────────────────────────────────────────────────
class _C {
  static const blue = Color(0xFF3B82F6);
  static const bgPage = Color(0xFFF0F4FF);
  static const bgCard = Color(0xFFFFFFFF);
  static const textDark = Color(0xFF0F172A);
  static const textGrey = Color(0xFF94A3B8);
  static const textMedium = Color(0xFF475569);
  static const divider = Color(0xFFE2E8F0);
  static const green = Color(0xFF22C55E);
  static const red = Color(0xFFEF4444);
  static const amber = Color(0xFFF59E0B);
  static const purple = Color(0xFF8B5CF6);
}

/// Pantalla principal de Bitácora para un Lead concreto.
/// Muestra el historial y permite añadir/editar/eliminar entradas.
class BitacoraScreen extends StatelessWidget {
  final Lead lead;
  final FirestoreService svc;

  const BitacoraScreen({
    super.key,
    required this.lead,
    required this.svc,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BitacoraController(),
      child: _BitacoraView(lead: lead, svc: svc),
    );
  }
}

class _BitacoraView extends StatelessWidget {
  final Lead lead;
  final FirestoreService svc;

  const _BitacoraView({required this.lead, required this.svc});

  @override
  Widget build(BuildContext context) {
    return Consumer<BitacoraController>(
      builder: (context, controller, _) {
        return Scaffold(
          backgroundColor: _C.bgPage,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Row(children: [
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          border: Border.all(color: _C.divider),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded,
                            size: 18, color: _C.textDark),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        const Text('Bitácora',
                            style:
                                TextStyle(fontSize: 12, color: _C.textGrey)),
                        Text(
                          lead.nameprospecto,
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: _C.textDark),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ]),
                    ),
                  ]),
                ),

                // ── Info del lead ────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: _C.bgCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _C.divider),
                    ),
                    child: Row(children: [
                      if (lead.infoprospecto.isNotEmpty) ...[
                        const Icon(Icons.business_outlined,
                            size: 14, color: _C.textGrey),
                        const SizedBox(width: 6),
                        Text(lead.infoprospecto,
                            style: const TextStyle(
                                fontSize: 12, color: _C.textMedium)),
                        const SizedBox(width: 12),
                      ],
                      if (lead.telefono.isNotEmpty) ...[
                        const Icon(Icons.phone_outlined,
                            size: 14, color: _C.textGrey),
                        const SizedBox(width: 4),
                        Text(lead.telefono,
                            style: const TextStyle(
                                fontSize: 12, color: _C.textMedium)),
                      ],
                    ]),
                  ),
                ),
                const SizedBox(height: 12),
                const Divider(color: _C.divider, height: 1),

                // ── Historial de entradas ────────────────────────────────────
                Expanded(
                  child: lead.id == null
                      ? const Center(
                          child: Text('Lead sin ID — guarda primero el lead.',
                              style: TextStyle(color: _C.textGrey)))
                      : StreamBuilder<List<Map<String, dynamic>>>(
                          stream: svc.streamBitacoras(lead.id!),
                          builder: (ctx, snap) {
                            if (snap.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                  child: CircularProgressIndicator(
                                      color: _C.blue));
                            }
                            final entradas = snap.data ?? [];
                            if (entradas.isEmpty) {
                              return _emptyHistorial();
                            }
                            return ListView.separated(
                              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                              itemCount: entradas.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (ctx, i) =>
                                  _EntradaCard(
                                entrada: entradas[i],
                                leadId: lead.id!,
                                svc: svc,
                              ),
                            );
                          },
                        ),
                ),

                // ── Formulario nueva entrada ─────────────────────────────────
                _NuevaEntradaPanel(
                    controller: controller, lead: lead, svc: svc),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _emptyHistorial() => Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.menu_book_outlined, size: 48, color: _C.textGrey),
          const SizedBox(height: 12),
          const Text('Sin entradas aún',
              style: TextStyle(
                  color: _C.textDark, fontWeight: FontWeight.w600, fontSize: 15)),
          const SizedBox(height: 4),
          const Text('Registra la primera interacción abajo.',
              style: TextStyle(color: _C.textGrey, fontSize: 13)),
        ]),
      );
}

// ─── Card de entrada del historial ────────────────────────────────────────────
class _EntradaCard extends StatelessWidget {
  final Map<String, dynamic> entrada;
  final String leadId;
  final FirestoreService svc;

  const _EntradaCard({
    required this.entrada,
    required this.leadId,
    required this.svc,
  });

  IconData _iconTipo(String tipo) {
    switch (tipo) {
      case 'Llamada':
        return Icons.call_outlined;
      case 'Correo':
        return Icons.mail_outline_rounded;
      case 'Visita':
        return Icons.location_on_outlined;
      default:
        return Icons.notes_rounded;
    }
  }

  Color _colorTipo(String tipo) {
    switch (tipo) {
      case 'Llamada':
        return _C.green;
      case 'Correo':
        return _C.blue;
      case 'Visita':
        return _C.purple;
      default:
        return _C.textGrey;
    }
  }

  String _formatFecha(dynamic ts) {
    if (ts == null) return '—';
    try {
      final dt = (ts as Timestamp).toDate();
      return DateFormat('dd/MM/yyyy HH:mm').format(dt);
    } catch (_) {
      return '—';
    }
  }

  @override
  Widget build(BuildContext context) {
    final tipo = entrada['tipoInteraccion'] ?? 'Nota';
    final comentario = entrada['comentario'] ?? '';
    final fecha = _formatFecha(entrada['fecha']);
    final editada = entrada['editadoEn'] != null;
    final color = _colorTipo(tipo);
    final icon = _iconTipo(tipo);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _C.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.divider),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(tipo,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: color)),
              Row(children: [
                Text(fecha,
                    style:
                        const TextStyle(fontSize: 11, color: _C.textGrey)),
                if (editada) ...[
                  const SizedBox(width: 6),
                  const Text('(editado)',
                      style: TextStyle(
                          fontSize: 10,
                          color: _C.textGrey,
                          fontStyle: FontStyle.italic)),
                ],
              ]),
            ]),
          ),
          // Menú editar / eliminar
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded,
                color: _C.textGrey, size: 18),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(children: [
                  Icon(Icons.edit_outlined, size: 18, color: _C.blue),
                  SizedBox(width: 8),
                  Text('Editar'),
                ]),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(children: [
                  Icon(Icons.delete_outline_rounded,
                      size: 18, color: _C.red),
                  SizedBox(width: 8),
                  Text('Eliminar', style: TextStyle(color: _C.red)),
                ]),
              ),
            ],
            onSelected: (val) async {
              if (val == 'edit') {
                _mostrarEditorEntrada(context, entrada, leadId, svc);
              } else {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    title: const Text('Eliminar entrada'),
                    content: const Text(
                        '¿Eliminar esta entrada? No se puede deshacer.'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancelar')),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _C.red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Eliminar'),
                      ),
                    ],
                  ),
                );
                if (ok == true) {
                  await svc.eliminarBitacora(
                      leadId: leadId, bitacoraId: entrada['id']);
                }
              }
            },
          ),
        ]),
        if (comentario.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(comentario,
              style: const TextStyle(
                  fontSize: 13,
                  color: _C.textMedium,
                  height: 1.4)),
        ],
        if (entrada['latitud'] != null) ...[
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.location_on_outlined,
                size: 13, color: _C.textGrey),
            const SizedBox(width: 4),
            Text(
              'Lat: ${(entrada['latitud'] as num).toStringAsFixed(4)} | '
              'Lon: ${(entrada['longitud'] as num).toStringAsFixed(4)}',
              style: const TextStyle(fontSize: 11, color: _C.textGrey),
            ),
          ]),
        ],
      ]),
    );
  }
}

/// Bottom sheet para editar una entrada existente
void _mostrarEditorEntrada(
  BuildContext context,
  Map<String, dynamic> entrada,
  String leadId,
  FirestoreService svc,
) {
  final ctrl = TextEditingController(text: entrada['comentario'] ?? '');
  String tipo = entrada['tipoInteraccion'] ?? 'Llamada';
  bool loading = false;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFFFFFFFF),
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) {
      return StatefulBuilder(builder: (ctx, setS) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Editar entrada',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A))),
              const SizedBox(height: 16),
              Row(children: [
                for (final t in ['Llamada', 'Correo', 'Visita'])
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setS(() => tipo = t),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: tipo == t
                              ? const Color(0xFF3B82F6).withValues(alpha: 0.1)
                              : const Color(0xFFFFFFFF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: tipo == t
                                ? const Color(0xFF3B82F6)
                                : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Text(t,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: tipo == t
                                  ? const Color(0xFF3B82F6)
                                  : const Color(0xFF94A3B8),
                            )),
                      ),
                    ),
                  ),
              ]),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl,
                maxLines: 4,
                minLines: 3,
                decoration: InputDecoration(
                  hintText: 'Comentario...',
                  hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                  filled: true,
                  fillColor: const Color(0xFFF0F4FF),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: loading
                      ? null
                      : () async {
                          setS(() => loading = true);
                          await svc.editarBitacora(
                            leadId: leadId,
                            bitacoraId: entrada['id'],
                            tipoInteraccion: tipo,
                            comentario: ctrl.text.trim(),
                          );
                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text('Guardar cambios',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        );
      });
    },
  );
}

// ─── Panel inferior: nueva entrada ───────────────────────────────────────────
class _NuevaEntradaPanel extends StatelessWidget {
  final BitacoraController controller;
  final Lead lead;
  final FirestoreService svc;

  const _NuevaEntradaPanel({
    required this.controller,
    required this.lead,
    required this.svc,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _C.bgCard,
        border: Border(top: BorderSide(color: _C.divider)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Tipo de interacción ────────────────────────────────────────────
          Row(children: [
            InteractionChip(
              titulo: 'Llamada',
              icono: Icons.call,
              seleccionado: controller.tipoSeleccionado == 'Llamada',
              onTap: () => controller.seleccionarTipo('Llamada'),
            ),
            InteractionChip(
              titulo: 'Correo',
              icono: Icons.email,
              seleccionado: controller.tipoSeleccionado == 'Correo',
              onTap: () => controller.seleccionarTipo('Correo'),
            ),
            InteractionChip(
              titulo: 'Visita',
              icono: Icons.directions_car_filled,
              seleccionado: controller.tipoSeleccionado == 'Visita',
              onTap: () => controller.seleccionarTipo('Visita'),
            ),
          ]),
          const SizedBox(height: 12),

          // ── GPS si es Visita ──────────────────────────────────────────────
          if (controller.tipoSeleccionado == 'Visita') ...[
            GpsCard(
              cargando: controller.cargandoGps,
              gpsCargado: controller.gpsCargado,
              posicion: controller.posicion,
            ),
            const SizedBox(height: 12),
          ],

          // ── Comentario ────────────────────────────────────────────────────
          TextField(
            controller: controller.comentarioController,
            maxLines: 3,
            minLines: 2,
            decoration: InputDecoration(
              hintText: controller.getHint(),
              hintStyle: const TextStyle(color: _C.textGrey, fontSize: 13),
              filled: true,
              fillColor: _C.bgPage,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Botón registrar ───────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: lead.id == null
                  ? null
                  : () async {
                      final comentario =
                          controller.comentarioController.text.trim();
                      if (comentario.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Escribe un comentario')),
                        );
                        return;
                      }

                      await svc.guardarBitacora(
                        leadId: lead.id!,
                        tipoInteraccion: controller.tipoSeleccionado,
                        comentario: comentario,
                        latitud: controller.posicion?.latitude,
                        longitud: controller.posicion?.longitude,
                      );

                      controller.comentarioController.clear();
                      controller.seleccionarTipo('Llamada');

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            backgroundColor: _C.green,
                            content: Text('Entrada registrada'),
                          ),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: _C.blue,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                controller.tipoSeleccionado == 'Visita'
                    ? 'Confirmar Check-In'
                    : 'Registrar entrada',
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
