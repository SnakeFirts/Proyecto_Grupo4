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
  final _direccionFechaController = TextEditingController(); 
  final _cargoDetalleController = TextEditingController(); 
  final _correoEstadoController = TextEditingController(); 
  final _telefonoController = TextEditingController();
  final _movilController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _companiaNameProspectoController.dispose();
    _nombreInfoProspectoController.dispose();
    _direccionFechaController.dispose();
    _cargoDetalleController.dispose();
    _correoEstadoController.dispose();
    _telefonoController.dispose();
    _movilController.dispose();
    super.dispose();
  }

  void _procesarGuardado() {
    if (widget.isProspecto) {
      if (widget.handleOnCreateProspecto != null) {
        widget.handleOnCreateProspecto!(
          Prospecto(
            compania: _companiaNameProspectoController.text,
            nombre: _nombreInfoProspectoController.text,
            direccion: _direccionFechaController.text,
            cargo: _cargoDetalleController.text,
            correo: _correoEstadoController.text,
            telefono: _telefonoController.text,
            movil: _movilController.text,
          ),
        );
      }
    } else {
      if (widget.handleOnCreateLead != null) {
        widget.handleOnCreateLead!(
          Lead(
            nameprospecto: _companiaNameProspectoController.text,
            infoprospecto: _nombreInfoProspectoController.text,
            fecha: _direccionFechaController.text,
            detalle: _cargoDetalleController.text,
            estado: _correoEstadoController.text,
          ),
        );
      }
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
  }

  @override
  Widget build(BuildContext context) {
    bool isP = widget.isProspecto;

    return Scaffold(
      appBar: AppBar(
          title: Text(isP ? 'Crear Prospecto' : 'Crear Lead')),
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
                      labelText:
                          isP ? 'Compañía' : 'Nombre Compañía Prospecto'),
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

                TextFormField(
                  controller: _direccionFechaController,
                  maxLines: isP ? 3 : 1,
                  minLines: isP ? 2 : 1,
                  keyboardType:
                      isP ? TextInputType.multiline : TextInputType.text,
                  decoration: InputDecoration(
                    labelText: isP ? 'Dirección' : 'Fecha',
                    alignLabelWithHint: true,
                  ),
                  validator: (v) =>
                      v!.isEmpty ? 'Por favor complete este campo' : null,
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
                        items: EstadoOpciones.lista.map((estado) => DropdownMenuItem(
                                  value: estado,
                                  child: Text(estado),
                                )).toList(),
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
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        _procesarGuardado();
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
