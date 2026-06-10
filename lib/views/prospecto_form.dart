import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../models/prospecto.dart';
import '../services/firestore_service.dart';

// ─── Colores (mismos que dashboard) ──────────────────────────────────────────
class _C {
  static const blue = Color(0xFF3B82F6);
  static const bgPage = Color(0xFFF0F4FF);
  static const bgCard = Color(0xFFFFFFFF);
  static const textDark = Color(0xFF0F172A);
  static const textMedium = Color(0xFF475569);
  static const textGrey = Color(0xFF94A3B8);
  static const divider = Color(0xFFE2E8F0);
  static const red = Color(0xFFEF4444);
  static const label = Color(0xFF94A3B8);
}

class ProspectoForm extends StatefulWidget {
  final Prospecto? prospecto;
  final FirestoreService firestoreService;

  const ProspectoForm({
    super.key,
    this.prospecto,
    required this.firestoreService,
  });

  @override
  State<ProspectoForm> createState() => _ProspectoFormState();
}

class _ProspectoFormState extends State<ProspectoForm> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _companiaCtrl;
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _direccionCtrl;
  late final TextEditingController _cargoCtrl;
  late final TextEditingController _correoCtrl;
  late final TextEditingController _telefonoCtrl;
  late final TextEditingController _movilCtrl;

  bool _loading = false;
  bool get _editando => widget.prospecto != null;

  // ── Speech-to-text ──────────────────────────────────────────────────────────
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  String? _activeField;

  @override
  void initState() {
    super.initState();
    final p = widget.prospecto;
    _companiaCtrl = TextEditingController(text: p?.compania ?? '');
    _nombreCtrl = TextEditingController(text: p?.nombre ?? '');
    _direccionCtrl = TextEditingController(text: p?.direccion ?? '');
    _cargoCtrl = TextEditingController(text: p?.cargo ?? '');
    _correoCtrl = TextEditingController(text: p?.correo ?? '');
    _telefonoCtrl = TextEditingController(text: p?.telefono ?? '');
    _movilCtrl = TextEditingController(text: p?.movil ?? '');

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
        localeId: 'es_HN',
      );
      setState(() => _activeField = fieldId);
    }
  }

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
    _companiaCtrl.dispose();
    _nombreCtrl.dispose();
    _direccionCtrl.dispose();
    _cargoCtrl.dispose();
    _correoCtrl.dispose();
    _telefonoCtrl.dispose();
    _movilCtrl.dispose();
    _speechToText.stop();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _loading = true);

    try {
      final p = Prospecto(
        id: widget.prospecto?.id,
        compania: _companiaCtrl.text.trim(),
        nombre: _nombreCtrl.text.trim(),
        direccion: _direccionCtrl.text.trim(),
        cargo: _cargoCtrl.text.trim(),
        correo: _correoCtrl.text.trim().toLowerCase(),
        telefono: _telefonoCtrl.text.trim(),
        movil: _movilCtrl.text.trim(),
        fechaCreacion: widget.prospecto?.fechaCreacion ?? DateTime.now(),
      );

      if (_editando) {
        await widget.firestoreService.actualizarProspecto(p);
      } else {
        await widget.firestoreService.crearProspecto(p);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: _C.blue,
            content: Text(
              _editando
                  ? 'Prospecto actualizado exitosamente'
                  : 'Prospecto creado exitosamente',
            ),
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
                    _editando ? 'Editar' : 'Nuevo',
                    style: const TextStyle(fontSize: 12, color: _C.textGrey),
                  ),
                  const Text(
                    'Prospecto',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: _C.textDark),
                  ),
                ]),
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
                        ctrl: _companiaCtrl,
                        fieldId: 'compania',
                        label: 'Empresa / Compañía',
                        icon: Icons.business_outlined,
                        hint: 'Ej. Distribuidora Norte S.A.',
                        textCapitalization: TextCapitalization.words,
                        required: true,
                      ),
                      _field(
                        ctrl: _nombreCtrl,
                        fieldId: 'nombre',
                        label: 'Nombre del contacto',
                        icon: Icons.person_outline_rounded,
                        hint: 'Ej. María García',
                        textCapitalization: TextCapitalization.words,
                        required: true,
                      ),
                      _field(
                        ctrl: _cargoCtrl,
                        fieldId: 'cargo',
                        label: 'Cargo',
                        icon: Icons.work_outline_rounded,
                        hint: 'Ej. Gerente de Compras',
                        textCapitalization: TextCapitalization.words,
                      ),
                      _field(
                        ctrl: _correoCtrl,
                        fieldId: 'correo',
                        label: 'Correo electrónico',
                        icon: Icons.mail_outline_rounded,
                        hint: 'contacto@empresa.com',
                        keyboardType: TextInputType.emailAddress,
                        showMic: false,
                        required: true,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Ingresa un correo';
                          }
                          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$')
                              .hasMatch(v.trim())) {
                            return 'Formato inválido';
                          }
                          return null;
                        },
                      ),
                      _field(
                        ctrl: _telefonoCtrl,
                        fieldId: 'telefono',
                        label: 'Teléfono',
                        icon: Icons.phone_outlined,
                        hint: '+504 2222-3333',
                        keyboardType: TextInputType.phone,
                        showMic: false,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'[\d\s\+\-\(\)]'))
                        ],
                        required: true,
                        validator: (v) {
                          final digits = v?.replaceAll(RegExp(r'\D'), '') ?? '';
                          return digits.length < 7
                              ? 'Teléfono muy corto'
                              : null;
                        },
                      ),
                      _field(
                        ctrl: _movilCtrl,
                        fieldId: 'movil',
                        label: 'Móvil / WhatsApp',
                        icon: Icons.smartphone_outlined,
                        hint: '+504 9999-0000',
                        keyboardType: TextInputType.phone,
                        showMic: false,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'[\d\s\+\-\(\)]'))
                        ],
                      ),
                      _fieldMultiline(
                        ctrl: _direccionCtrl,
                        fieldId: 'direccion',
                        label: 'Dirección',
                        icon: Icons.location_on_outlined,
                        hint: 'Colonia, ciudad, referencia...',
                      ),
                      const SizedBox(height: 24),

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
                                      _editando
                                          ? Icons.save_outlined
                                          : Icons.check_circle_outline,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _editando
                                          ? 'Guardar cambios'
                                          : 'Crear prospecto',
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

  // ─── Helpers de campo ──────────────────────────────────────────────────────

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

  Widget _fieldMultiline({
    required TextEditingController ctrl,
    required String fieldId,
    required String label,
    required IconData icon,
    String? hint,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _label(label),
        TextFormField(
          controller: ctrl,
          maxLines: 3,
          minLines: 2,
          keyboardType: TextInputType.multiline,
          textCapitalization: TextCapitalization.sentences,
          decoration: _deco(
            icon: icon,
            hint: hint,
            suffix: _micIcon(fieldId, ctrl),
          ),
        ),
      ]),
    );
  }

  Widget _label(String text, {bool required = false}) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
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
