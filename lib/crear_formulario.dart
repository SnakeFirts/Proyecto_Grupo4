import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'models/lead.dart';
import 'models/prospecto.dart';
import 'models/estado_opciones.dart';

class CrearPersonaForm extends StatefulWidget {
  final bool isProspecto;

  final Function(Prospecto)? handleOnCreateProspecto;
  final Function(Lead)? handleOnCreateLead;

  const CrearPersonaForm({
    super.key,
    required this.isProspecto,
    this.handleOnCreateProspecto,
    this.handleOnCreateLead,
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

  @override
  void dispose() {
    _companiaNameProspectoController.dispose();
    _nombreInfoProspectoController.dispose();
    _direccionController.dispose();
    _cargoDetalleController.dispose();
    _correoEstadoController.dispose();
    _telefonoController.dispose();
    _movilController.dispose();
    super.dispose();
  }

  Future<void> _procesarGuardado() async {
    final db = FirebaseFirestore.instance;

    try {
      if (widget.isProspecto) {
        final prospecto = Prospecto(
          compania: _companiaNameProspectoController.text,
          nombre: _nombreInfoProspectoController.text,
          direccion: _direccionController.text,
          cargo: _cargoDetalleController.text,
          correo: _correoEstadoController.text,
          telefono: _telefonoController.text,
          movil: _movilController.text,
        );

        final docRef = await db.collection('prospectos').add(prospecto.toMap());
        widget.handleOnCreateProspecto?.call(prospecto.copyWith(id: docRef.id));
      } else {
        final lead = Lead(
          nameprospecto: _companiaNameProspectoController.text,
          infoprospecto: _nombreInfoProspectoController.text,
          fecha: _fechaSeleccionada,
          detalle: _cargoDetalleController.text,
          estado: _correoEstadoController.text,
        );

        final docRef = await db.collection('leads').add(lead.toMap());
        widget.handleOnCreateLead?.call(lead.copyWith(id: docRef.id));
      }

      String modelo = widget.isProspecto ? 'Prospecto' : 'Lead';
      String nombreCreado = widget.isProspecto
          ? _nombreInfoProspectoController.text
          : _companiaNameProspectoController.text;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.blue,
          content: Text('Se creó con éxito el $modelo: $nombreCreado'),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text('Error al guardar: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isP = widget.isProspecto;

    return Scaffold(
      appBar: AppBar(title: Text(isP ? 'Crear Prospecto' : 'Crear Lead')),
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
                    decoration: const InputDecoration(
                      labelText: 'Dirección',
                      alignLabelWithHint: true,
                    ),
                    validator: (v) =>
                        v!.isEmpty ? 'Por favor complete este campo' : null,
                  )
                else
                  FormField<DateTime>(
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
                              initialDate: DateTime.now(),
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
                  ),
                  validator: (v) =>
                      v!.isEmpty ? 'Por favor complete este campo' : null,
                ),
                isP
                    ? TextFormField(
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
                    : DropdownButtonFormField<String>(
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
                    icon: const Icon(Icons.check_circle_outline, size: 24),
                    label: const Text(
                      'Crear',
                      style: TextStyle(
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
