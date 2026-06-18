import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../models/lead.dart';
import '../models/prospecto.dart';
import '../models/estado_opciones.dart';
import '../services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/local_notification_service.dart';
import '../services/erpnext_service.dart';

// ─── Colores ──────────────────────────────────────────────────────────────────
class _C {
  static const blue = Color(0xFF3B82F6);
  static const bgPage = Color(0xFFF0F4FF);
  static const bgCard = Color(0xFFFFFFFF);
  static const textDark = Color(0xFF0F172A);
  static const textGrey = Color(0xFF94A3B8);
  static const divider = Color(0xFFE2E8F0);
  static const red = Color(0xFFEF4444);
  static const green = Color(0xFF22C55E);
  static const amber = Color(0xFFF59E0B);
  static const label = Color(0xFF94A3B8);
}

Color _estadoColor(String e) {
  switch (e.toLowerCase()) {
    case 'completado':
      return _C.green;
    case 'abierto':
      return _C.amber;
    case 'perdido':
      return _C.red;
    default:
      return _C.textGrey;
  }
}

class LeadForm extends StatefulWidget {
  final Lead? lead;
  final Prospecto? prospectoOrigen;
  final FirestoreService firestoreService;

  const LeadForm({
    super.key,
    this.lead,
    this.prospectoOrigen,
    required this.firestoreService,
  });

  @override
  State<LeadForm> createState() => _LeadFormState();
}

class _LeadFormState extends State<LeadForm> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nombreCtrl;
  late final TextEditingController _infoCtrl;
  late final TextEditingController _telefonoCtrl;
  late final TextEditingController _correoCtrl;
  late final TextEditingController _detalleCtrl;

  DateTime? _fechaSeleccionada;
  String _estadoSeleccionado = 'Abierto';
  bool _loading = false;

  // Servicio de integración con ERPNext (cuando un lead se completa, pasa a cotización)
  final _erpnextService = ErpNextService();

  // ── Speech-to-text ──────────────────────────────────────────────────────────
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  String? _activeField;

  bool get _editando => widget.lead != null;
  bool get _desdeProspecto => widget.prospectoOrigen != null;

  @override
  void initState() {
    super.initState();
    final l = widget.lead;
    final p = widget.prospectoOrigen;

    _nombreCtrl =
        TextEditingController(text: l?.nameprospecto ?? p?.nombre ?? '');
    _infoCtrl =
        TextEditingController(text: l?.infoprospecto ?? p?.compania ?? '');
    _telefonoCtrl =
        TextEditingController(text: l?.telefono ?? p?.telefono ?? '');
    _correoCtrl = TextEditingController(text: l?.correo ?? p?.correo ?? '');
    _detalleCtrl = TextEditingController(text: l?.detalle ?? '');

    _fechaSeleccionada = l?.fecha;
    _estadoSeleccionado = l?.estado ?? 'Abierto';

    _initSpeech();
  }

  Future<void> _initSpeech() async {
    final enabled = await _speechToText.initialize();
    if (mounted) setState(() => _speechEnabled = enabled);
  }

  Future<void> _toggleListening(
      String fieldId, TextEditingController ctrl) async {
    if (_activeField == fieldId && _speechToText.isListening) {
      await _speechToText.stop();
      setState(() => _activeField = null);
    } else {
      if (_speechToText.isListening) await _speechToText.stop();
      await _speechToText.listen(
        onResult: (result) =>
            setState(() => ctrl.text = result.recognizedWords),
        listenOptions: SpeechListenOptions(localeId: 'es_HN'),
      );
      setState(() => _activeField = fieldId);
    }
  }

  /// Icono de micrófono en el estilo de _C (usado como suffixIcon).
  Widget _micIcon(String fieldId, TextEditingController ctrl) {
    if (!_speechEnabled) return const SizedBox.shrink();
    final active = _activeField == fieldId && _speechToText.isListening;
    return GestureDetector(
      onTap: () => _toggleListening(fieldId, ctrl),
      child: Padding(
        padding: const EdgeInsets.only(right: 12),
        child: Icon(
          active ? Icons.mic_rounded : Icons.mic_none_rounded,
          color: active ? _C.red : _C.label,
          size: 20,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _infoCtrl.dispose();
    _telefonoCtrl.dispose();
    _correoCtrl.dispose();
    _detalleCtrl.dispose();
    _speechToText.stop();
    super.dispose();
  }

  Future<void> _seleccionarFecha() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _fechaSeleccionada = picked);
  }

  // ── Enviar cotización a ERPNext manualmente (botón avión) ──────────────
  // Se activa cuando el usuario toca el ícono de avión en el header.
  // Valida que el lead esté guardado y tiene detalle, y muestra
  // un diálogo de confirmación antes de enviar.
  Future<void> _enviarCotizacionERPNext() async {
    // Construimos el lead con los datos actuales del formulario
    final leadData = Lead(
      id: widget.lead?.id,
      nameprospecto: _nombreCtrl.text.trim(),
      prospectoId: widget.lead?.prospectoId ?? widget.prospectoOrigen?.id,
      infoprospecto: _infoCtrl.text.trim(),
      fecha: _fechaSeleccionada,
      detalle: _detalleCtrl.text.trim(),
      estado: _estadoSeleccionado,
      telefono: _telefonoCtrl.text.trim(),
      correo: _correoCtrl.text.trim().toLowerCase(),
      fechaCreacion: widget.lead?.fechaCreacion ?? DateTime.now(),
    );

    if (leadData.detalle.isEmpty && leadData.nameprospecto.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Primero ingresa el nombre y las notas del lead'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Mostramos el diálogo de confirmación
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.send_rounded, color: Color(0xFF22C55E), size: 22),
            SizedBox(width: 8),
            Text('Enviar a ERPNext'),
          ],
        ),
        content: Text(
          '¿Desea crear la cotización para "${leadData.nameprospecto}" en ERPNext ahora?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Después', style: TextStyle(color: Colors.grey)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: _C.green),
            child: const Text('Crear ahora'),
          ),
        ],
      ),
    );

    if (confirmar != true) return; // El usuario eligió "Después"

    // Enviamos a ERPNext
    setState(() => _loading = true);
    try {
      final resultado =
          await _erpnextService.sincronizarLeadCompletado(leadData);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: _C.green,
            content: Text(
                '✅ Cotización ${resultado["cotizacion"]} creada en ERPNext'),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.orange,
            content: Text(
              '⚠️ Error: ${e.toString().length > 80 ? '${e.toString().substring(0, 80)}...' : e.toString()}',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Guardar lead ──────────────────────────────────────────────────────────
  Future<void> _guardar() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _loading = true);

    try {
      final leadData = Lead(
        id: widget.lead?.id,
        nameprospecto: _nombreCtrl.text.trim(),
        prospectoId: widget.lead?.prospectoId ?? widget.prospectoOrigen?.id,
        infoprospecto: _infoCtrl.text.trim(),
        fecha: _fechaSeleccionada,
        detalle: _detalleCtrl.text.trim(),
        estado: _estadoSeleccionado,
        telefono: _telefonoCtrl.text.trim(),
        correo: _correoCtrl.text.trim().toLowerCase(),
        fechaCreacion: widget.lead?.fechaCreacion ?? DateTime.now(),
      );

      if (_editando) {
        await widget.firestoreService.actualizarLead(leadData);
      } else {
        final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
        await widget.firestoreService.crearLead(leadData, uid);
      }

      if (_fechaSeleccionada != null) {
        await LocalNotificationService.show(
          title: '📅 Seguimiento pendiente',
          body: 'Hoy tienes seguimiento con ${_nombreCtrl.text.trim()}',
          scheduled: true,
          scheduledDate: _fechaSeleccionada!,
        );
      }

      // ── Sincronización con ERPNext ────────────────────────────────────────
      // Cuando el lead pasa a "Completado", preguntamos si desea crear
      // la cotización en ERPNext ahora o después.
      String? erpNextMsg;
      if (_estadoSeleccionado == 'Completado') {
        final confirmar = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.send_rounded, color: Color(0xFF22C55E), size: 22),
                SizedBox(width: 8),
                Text('Crear cotización'),
              ],
            ),
            content: Text(
              '¿Desea crear la cotización en ERPNext para "${leadData.nameprospecto}" ahora?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child:
                    const Text('Después', style: TextStyle(color: Colors.grey)),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: FilledButton.styleFrom(backgroundColor: _C.green),
                child: const Text('Crear ahora'),
              ),
            ],
          ),
        );

        if (confirmar == true) {
          try {
            final resultado =
                await _erpnextService.sincronizarLeadCompletado(leadData);
            erpNextMsg =
                'ERPNext: cotización ${resultado["cotizacion"]} creada';
          } catch (e) {
            erpNextMsg =
                '⚠️ ERPNext no disponible: ${e.toString().length > 80 ? '${e.toString().substring(0, 80)}...' : e.toString()}';
          }
        } else {
          erpNextMsg =
              'Cotización pendiente — puedes enviarla después con el botón ✈️';
        }
      }

      if (mounted) {
        // Mostramos el resultado (con o sin ERPNext)
        final msgBase = _editando
            ? 'Lead actualizado exitosamente'
            : 'Lead creado exitosamente';
        final msgFinal =
            erpNextMsg != null ? '$msgBase | $erpNextMsg' : msgBase;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: _C.blue,
            content: Text(msgFinal),
            duration: const Duration(seconds: 4),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: _C.red,
            content: Text('Error: ${e.toString()}'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bgPage,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────────
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
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
                    _desdeProspecto
                        ? 'Convertir a'
                        : (_editando ? 'Editar' : 'Nuevo'),
                    style: const TextStyle(fontSize: 12, color: _C.textGrey),
                  ),
                  const Text(
                    'Lead',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: _C.textDark),
                  ),
                ]),
                const Spacer(),
                // ── Botón de avión: enviar cotización a ERPNext manualmente ──
                // Solo aparece cuando estamos editando un lead existente.
                if (_editando)
                  InkWell(
                    onTap: _enviarCotizacionERPNext,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _C.green.withValues(alpha: 0.1),
                        border:
                            Border.all(color: _C.green.withValues(alpha: 0.3)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.send_rounded,
                          size: 18, color: _C.green),
                    ),
                  ),
                if (_desdeProspecto) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _C.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(children: [
                      Icon(Icons.swap_horiz_rounded, color: _C.blue, size: 14),
                      SizedBox(width: 4),
                      Text('Desde prospecto',
                          style: TextStyle(
                              color: _C.blue,
                              fontSize: 11,
                              fontWeight: FontWeight.w700)),
                    ]),
                  ),
                ],
              ]),
            ),
            const SizedBox(height: 8),
            const Divider(color: _C.divider, height: 16),

            // ── Formulario ───────────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _field(
                        ctrl: _nombreCtrl,
                        fieldId: 'nombre',
                        label: 'Nombre del contacto',
                        icon: Icons.person_outline_rounded,
                        hint: 'Ej. Carlos López',
                        textCapitalization: TextCapitalization.words,
                        required: true,
                      ),
                      _field(
                        ctrl: _infoCtrl,
                        fieldId: 'info',
                        label: 'Empresa / Información',
                        icon: Icons.business_outlined,
                        hint: 'Ej. Ferretería Central S.A.',
                        textCapitalization: TextCapitalization.words,
                        required: true,
                      ),
                      _field(
                        ctrl: _telefonoCtrl,
                        fieldId: 'telefono',
                        label: 'Teléfono',
                        icon: Icons.phone_outlined,
                        hint: '+504 9999-0000',
                        keyboardType: TextInputType.phone,
                        showMic: false, // no tiene sentido dictar un teléfono
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'[\d\s\+\-\(\)]'))
                        ],
                      ),
                      _field(
                        ctrl: _correoCtrl,
                        fieldId: 'correo',
                        label: 'Correo electrónico',
                        icon: Icons.mail_outline_rounded,
                        hint: 'contacto@empresa.com',
                        keyboardType: TextInputType.emailAddress,
                        showMic: false, // no tiene sentido dictar un correo
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return null;
                          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$')
                              .hasMatch(v.trim())) {
                            return 'Formato inválido';
                          }
                          return null;
                        },
                      ),

                      // ── Fecha con DatePicker ─────────────────────────────
                      _label('Fecha de seguimiento'),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: _seleccionarFecha,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 15),
                          decoration: BoxDecoration(
                            color: _C.bgCard,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: _C.divider, width: 1.5),
                          ),
                          child: Row(children: [
                            const Icon(Icons.calendar_today_outlined,
                                color: _C.label, size: 20),
                            const SizedBox(width: 12),
                            Text(
                              _fechaSeleccionada != null
                                  ? DateFormat('dd/MM/yyyy')
                                      .format(_fechaSeleccionada!)
                                  : 'Seleccionar fecha',
                              style: TextStyle(
                                fontSize: 14,
                                color: _fechaSeleccionada != null
                                    ? _C.textDark
                                    : _C.textGrey,
                              ),
                            ),
                            const Spacer(),
                            if (_fechaSeleccionada != null)
                              GestureDetector(
                                onTap: () =>
                                    setState(() => _fechaSeleccionada = null),
                                child: const Icon(Icons.close_rounded,
                                    color: _C.textGrey, size: 18),
                              ),
                          ]),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Estado ───────────────────────────────────────────
                      _label('Estado del lead', required: true),
                      const SizedBox(height: 6),
                      Row(
                        children: EstadoOpciones.lista.map((estado) {
                          final sel = estado == _estadoSeleccionado;
                          final color = _estadoColor(estado);
                          return Expanded(
                            child: GestureDetector(
                              onTap: () =>
                                  setState(() => _estadoSeleccionado = estado),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                margin: const EdgeInsets.only(right: 8),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: sel
                                      ? color.withValues(alpha: 0.12)
                                      : _C.bgCard,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: sel ? color : _C.divider,
                                    width: sel ? 2 : 1.5,
                                  ),
                                ),
                                child: Column(children: [
                                  Icon(
                                    estado == 'Abierto'
                                        ? Icons.radio_button_unchecked_rounded
                                        : estado == 'Completado'
                                            ? Icons.check_circle_outline_rounded
                                            : Icons.cancel_outlined,
                                    color: sel ? color : _C.textGrey,
                                    size: 20,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    estado,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: sel
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: sel ? color : _C.textGrey,
                                    ),
                                  ),
                                ]),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),

                      // ── Detalle / notas ──────────────────────────────────
                      _label('Detalle / Notas'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _detalleCtrl,
                        maxLines: 4,
                        minLines: 3,
                        keyboardType: TextInputType.multiline,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: _deco(
                          icon: Icons.notes_rounded,
                          hint:
                              'Describe la oportunidad, necesidades del cliente...',
                          suffix: _micIcon('detalle', _detalleCtrl),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // ── Botón guardar ─────────────────────────────────────
                      SizedBox(
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _guardar,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _C.blue,
                            disabledBackgroundColor:
                                _C.blue.withValues(alpha: 0.5),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                          ),
                          child: _loading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2.5),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      _editando || _desdeProspecto
                                          ? Icons.save_outlined
                                          : Icons.check_circle_outline,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _desdeProspecto
                                          ? 'Convertir a Lead'
                                          : (_editando
                                              ? 'Guardar cambios'
                                              : 'Crear lead'),
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────
  Widget _field({
    required TextEditingController ctrl,
    required String fieldId,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    List<TextInputFormatter>? inputFormatters,
    bool required = false,
    bool showMic = true,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _label(label, required: required),
        TextFormField(
          controller: ctrl,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          inputFormatters: inputFormatters,
          textInputAction: TextInputAction.next,
          decoration: _deco(
            icon: icon,
            hint: hint,
            suffix: showMic ? _micIcon(fieldId, ctrl) : null,
          ),
          validator: validator ??
              (required
                  ? (v) =>
                      (v == null || v.trim().isEmpty) ? 'Campo requerido' : null
                  : null),
        ),
      ]),
    );
  }

  Widget _label(String text, {bool required = false}) => Padding(
        padding: const EdgeInsets.only(bottom: 0),
        child: Row(children: [
          Text(
            text.toUpperCase(),
            style: const TextStyle(
              color: _C.label,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          if (required)
            const Text(' *',
                style: TextStyle(
                    color: _C.red, fontSize: 11, fontWeight: FontWeight.w700)),
        ]),
      );

  InputDecoration _deco({
    required IconData icon,
    String? hint,
    Widget? suffix,
  }) =>
      InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: _C.textGrey, fontSize: 14),
        prefixIcon: Icon(icon, color: _C.label, size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: _C.bgCard,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _C.divider, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _C.blue, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _C.red, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _C.red, width: 1.8),
        ),
        errorStyle: const TextStyle(color: _C.red, fontSize: 12),
      );
}
