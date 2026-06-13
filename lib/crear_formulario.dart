import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'models/lead.dart';
import 'models/prospecto.dart';
import 'models/estado_opciones.dart';
import 'services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CrearPersonaForm extends StatefulWidget {
  final bool isProspecto;
  final Function(Prospecto)? handleOnCreateProspecto;
  final Function(Lead)? handleOnCreateLead;
  final Prospecto? prospectoInicial;
  final Lead? leadInicial;

  const CrearPersonaForm({
    super.key,
    required this.isProspecto,
    this.handleOnCreateProspecto,
    this.handleOnCreateLead,
    this.prospectoInicial,
    this.leadInicial,
  });

  @override
  State<CrearPersonaForm> createState() => _CrearPersonaFormState();
}

class _CrearPersonaFormState extends State<CrearPersonaForm> {
  final _formKey = GlobalKey<FormState>();

  final _companiaNameProspectoController = TextEditingController();
  final _nombreInfoProspectoController = TextEditingController();
  final _direccionController = TextEditingController();
  final _cargoDetalleController = TextEditingController();
  final _correoEstadoController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _movilController = TextEditingController();

  DateTime? _fechaSeleccionada;

  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  String? _activeField;

  @override
  void initState() {
    super.initState();
    if (widget.isProspecto && widget.prospectoInicial != null) {
      final p = widget.prospectoInicial!;
      _companiaNameProspectoController.text = p.compania;
      _nombreInfoProspectoController.text = p.nombre;
      _direccionController.text = p.direccion;
      _cargoDetalleController.text = p.cargo;
      _correoEstadoController.text = p.correo;
      _telefonoController.text = p.telefono;
      _movilController.text = p.movil;
    } else if (!widget.isProspecto && widget.leadInicial != null) {
      final l = widget.leadInicial!;
      _companiaNameProspectoController.text = l.nameprospecto;
      _nombreInfoProspectoController.text = l.infoprospecto;
      _cargoDetalleController.text = l.detalle;
      _correoEstadoController.text = l.estado;
      _fechaSeleccionada = l.fecha;
    } else if (!widget.isProspecto) {
      _correoEstadoController.text = 'Abierto';
    }
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    final enabled = await _speechToText.initialize();
    setState(() => _speechEnabled = enabled);
  }

  Future<void> _toggleListening(
      String fieldId, TextEditingController controller) async {
    if (_activeField == fieldId && _speechToText.isListening) {
      await _speechToText.stop();
      setState(() => _activeField = null);
    } else {
      if (_speechToText.isListening) await _speechToText.stop();
      await _speechToText.listen(
        onResult: (result) {
          setState(() => controller.text = result.recognizedWords);
        },
        localeId: 'es_HN',
      );
      setState(() => _activeField = fieldId);
    }
  }

  bool _isListening(String fieldId) =>
      _activeField == fieldId && _speechToText.isListening;

  Widget _micButton(String fieldId, TextEditingController controller) {
    if (!_speechEnabled) return const SizedBox.shrink();
    final listening = _isListening(fieldId);
    return IconButton(
      icon: Icon(
        listening ? Icons.mic : Icons.mic_none,
        color: listening ? Colors.red : Colors.blue,
      ),
      tooltip: listening ? 'Detener' : 'Dictar',
      onPressed: () => _toggleListening(fieldId, controller),
    );
  }

  @override
  void dispose() {
    _companiaNameProspectoController.dispose();
    _nombreInfoProspectoController.dispose();
    _direccionController.dispose();
    _cargoDetalleController.dispose();
    _correoEstadoController.dispose();
    _telefonoController.dispose();
    _movilController.dispose();
    _speechToText.stop();
    super.dispose();
  }

  Future<void> _procesarGuardado() async {
    final service = FirestoreService();
    final esEdicion = widget.isProspecto
        ? widget.prospectoInicial?.id != null
        : widget.leadInicial?.id != null;
    final uid =
        FirebaseAuth.instance.currentUser?.uid ?? ''; // ← Lo leemos aquí

    try {
      if (widget.isProspecto) {
        final prospecto = (widget.prospectoInicial ??
                Prospecto(
                  compania: '',
                  nombre: '',
                  direccion: '',
                  cargo: '',
                  correo: '',
                  telefono: '',
                  movil: '',
                ))
            .copyWith(
          compania: _companiaNameProspectoController.text,
          nombre: _nombreInfoProspectoController.text,
          direccion: _direccionController.text,
          cargo: _cargoDetalleController.text,
          correo: _correoEstadoController.text,
          telefono: _telefonoController.text,
          movil: _movilController.text,
        );

        if (esEdicion) {
          await service.actualizarProspecto(prospecto);
          widget.handleOnCreateProspecto?.call(prospecto);
        } else {
          final id = await service.crearProspecto(prospecto, uid);
          widget.handleOnCreateProspecto?.call(prospecto.copyWith(id: id));
        }
      } else {
        final lead = (widget.leadInicial ??
                Lead(
                  nameprospecto: '',
                  infoprospecto: '',
                  detalle: '',
                  estado: 'Abierto',
                ))
            .copyWith(
          nameprospecto: _companiaNameProspectoController.text,
          infoprospecto: _nombreInfoProspectoController.text,
          fecha: _fechaSeleccionada,
          detalle: _cargoDetalleController.text,
          estado: _correoEstadoController.text,
        );

        if (esEdicion) {
          await service.actualizarLead(lead);
          widget.handleOnCreateLead?.call(lead);
        } else {
          final id = await service.crearLead(lead, uid);
          widget.handleOnCreateLead?.call(lead.copyWith(id: id));
        }
      }

      final modelo = widget.isProspecto ? 'Prospecto' : 'Lead';
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: Colors.blue,
        content: Text(esEdicion ? '$modelo actualizado' : '$modelo creado'),
      ));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: Colors.red,
        content: Text('Error al guardar: $e'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isP = widget.isProspecto;
    final esEdicion = isP
        ? widget.prospectoInicial?.id != null
        : widget.leadInicial?.id != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isP
              ? (esEdicion ? 'Editar Prospecto' : 'Crear Prospecto')
              : (esEdicion ? 'Editar Lead' : 'Crear Lead'),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: _companiaNameProspectoController,
                  decoration: InputDecoration(
                    labelText: isP ? 'Compañía' : 'Nombre Compañía Prospecto',
                  ),
                  validator: (v) =>
                      v!.isEmpty ? 'Por favor complete este campo' : null,
                ),
                TextFormField(
                  controller: _nombreInfoProspectoController,
                  maxLines: !isP ? 3 : 1,
                  minLines: !isP ? 2 : 1,
                  keyboardType:
                      !isP ? TextInputType.multiline : TextInputType.text,
                  decoration: InputDecoration(
                    labelText: isP ? 'Nombre' : 'Información Prospecto',
                    alignLabelWithHint: true,
                    suffixIcon:
                        _micButton('info', _nombreInfoProspectoController),
                  ),
                  validator: (v) =>
                      v!.isEmpty ? 'Por favor complete este campo' : null,
                ),
                if (isP)
                  TextFormField(
                    controller: _direccionController,
                    maxLines: 3,
                    minLines: 2,
                    keyboardType: TextInputType.multiline,
                    decoration: InputDecoration(
                      labelText: 'Dirección',
                      alignLabelWithHint: true,
                      suffixIcon: _micButton('direccion', _direccionController),
                    ),
                    validator: (v) =>
                        v!.isEmpty ? 'Por favor complete este campo' : null,
                  )
                else
                  FormField<DateTime>(
                    initialValue: _fechaSeleccionada,
                    validator: (_) => _fechaSeleccionada == null
                        ? 'Por favor seleccione una fecha'
                        : null,
                    builder: (state) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            _fechaSeleccionada == null
                                ? 'Seleccionar Fecha'
                                : '${_fechaSeleccionada!.toLocal()}'
                                    .split(' ')[0],
                            style: TextStyle(
                              color: _fechaSeleccionada == null
                                  ? Colors.grey
                                  : null,
                            ),
                          ),
                          trailing: const Icon(Icons.calendar_today),
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _fechaSeleccionada ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                            );
                            if (picked != null) {
                              setState(() => _fechaSeleccionada = picked);
                              state.didChange(picked);
                            }
                          },
                        ),
                        if (state.errorText != null)
                          Padding(
                            padding: const EdgeInsets.only(left: 12, top: 4),
                            child: Text(
                              state.errorText!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                TextFormField(
                  controller: _cargoDetalleController,
                  maxLines: !isP ? 4 : 1,
                  minLines: !isP ? 2 : 1,
                  keyboardType:
                      !isP ? TextInputType.multiline : TextInputType.text,
                  decoration: InputDecoration(
                    labelText: isP ? 'Cargo' : 'Detalle',
                    alignLabelWithHint: true,
                    suffixIcon: _micButton('detalle', _cargoDetalleController),
                  ),
                  validator: (v) =>
                      v!.isEmpty ? 'Por favor complete este campo' : null,
                ),
                if (isP)
                  TextFormField(
                    controller: _correoEstadoController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Correo',
                      hintText: 'ejemplo@correo.com',
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return 'Por favor complete este campo';
                      }
                      final emailRegex =
                          RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                      if (!emailRegex.hasMatch(v)) {
                        return 'Por favor ingrese un correo válido';
                      }
                      return null;
                    },
                  )
                else
                  DropdownButtonFormField<String>(
                    initialValue: EstadoOpciones.lista
                            .contains(_correoEstadoController.text)
                        ? _correoEstadoController.text
                        : null,
                    decoration: const InputDecoration(labelText: 'Estado'),
                    items: EstadoOpciones.lista
                        .map((estado) => DropdownMenuItem(
                              value: estado,
                              child: Text(estado),
                            ))
                        .toList(),
                    onChanged: (nuevoEstado) {
                      if (nuevoEstado != null) {
                        _correoEstadoController.text = nuevoEstado;
                      }
                    },
                    validator: (v) => v == null || v.isEmpty
                        ? 'Por favor seleccione un estado'
                        : null,
                  ),
                if (isP) ...[
                  TextFormField(
                    controller: _telefonoController,
                    decoration: const InputDecoration(labelText: 'Teléfono'),
                    keyboardType: TextInputType.phone,
                    validator: (v) =>
                        v!.length < 8 ? 'Ingrese un teléfono válido' : null,
                  ),
                  TextFormField(
                    controller: _movilController,
                    decoration: const InputDecoration(labelText: 'Móvil'),
                    keyboardType: TextInputType.phone,
                    validator: (v) => v!.isEmpty ? 'Ingrese el móvil' : null,
                  ),
                ],
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 59, 130, 246),
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28.0),
                      ),
                    ),
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        await _procesarGuardado();
                      }
                    },
                    icon: Icon(
                      esEdicion
                          ? Icons.save_outlined
                          : Icons.check_circle_outline,
                      size: 24,
                    ),
                    label: Text(
                      esEdicion ? 'Guardar cambios' : 'Crear',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
