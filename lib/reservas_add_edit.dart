import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ReservasAddEdit {
  final GlobalKey<FormState> formKey;
  final TextEditingController habitacionController;
  final TextEditingController nombreController;
  final TextEditingController telefonoController;
  final TextEditingController cantidadController;
  final TextEditingController adultosController;
  final TextEditingController ninosController;
  final TextEditingController checkInController;
  final TextEditingController checkOutController;
  final TextEditingController observacionesController;
  final Function(Map<String, dynamic>) onSave;

  ReservasAddEdit({
    required this.formKey,
    required this.habitacionController,
    required this.nombreController,
    required this.telefonoController,
    required this.cantidadController,
    required this.adultosController,
    required this.ninosController,
    required this.checkInController,
    required this.checkOutController,
    required this.observacionesController,
    required this.onSave,
  });

  Future<void> selectDate(BuildContext context, TextEditingController controller) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      locale: const Locale('es', 'ES'), // Calendario en español
    );
    if (picked != null) {
      controller.text = DateFormat('dd/MM/yyyy', 'es').format(picked);
    }
  }

  void showAddEditDialog(BuildContext context, {bool isEditing = false}) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEditing ? 'Editar Reserva' : 'Agregar Nueva Reserva'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: habitacionController,
                    decoration: const InputDecoration(labelText: 'Habitación:'),
                    validator: (value) {
                      if (value == null || value.isEmpty || !value.startsWith("Habitación: ")) {
                        return 'Por favor, ingrese el número de habitación.';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: nombreController,
                    decoration: const InputDecoration(labelText: 'Nombre del cliente'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, ingrese el nombre del cliente.';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: telefonoController,
                    decoration: const InputDecoration(labelText: 'Número de Teléfono'),
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, ingrese el número de teléfono.';
                      } else if (!RegExp(r'^\d+$').hasMatch(value)) {
                        return 'El número de teléfono debe contener solo números.';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: cantidadController,
                    decoration: const InputDecoration(labelText: 'Cantidad de huéspedes'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty || int.tryParse(value) == null || int.parse(value) <= 0) {
                        return 'Ingrese una cantidad válida de huéspedes.';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: adultosController,
                    decoration: const InputDecoration(labelText: 'Cantidad de Adultos'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty || int.tryParse(value) == null || int.parse(value) < 0) {
                        return 'Ingrese una cantidad válida de adultos.';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: ninosController,
                    decoration: const InputDecoration(labelText: 'Cantidad de Niños'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty || int.tryParse(value) == null || int.parse(value) < 0) {
                        return 'Ingrese una cantidad válida de niños.';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: checkInController,
                    readOnly: true,
                    decoration: const InputDecoration(labelText: 'Check-in'),
                    onTap: () => selectDate(context, checkInController),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, seleccione la fecha de check-in.';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: checkOutController,
                    readOnly: true,
                    decoration: const InputDecoration(labelText: 'Check-out'),
                    onTap: () => selectDate(context, checkOutController),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, seleccione la fecha de check-out.';
                      } else if (checkInController.text.isNotEmpty && DateFormat('dd/MM/yyyy').parse(value).isBefore(DateFormat('dd/MM/yyyy').parse(checkInController.text))) {
                        return 'La fecha de check-out debe ser posterior a la de check-in.';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: observacionesController,
                    decoration: const InputDecoration(labelText: 'Observaciones'),
                    keyboardType: TextInputType.multiline,
                    maxLines: null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  onSave({
                    'habitacion': habitacionController.text,
                    'nombre': nombreController.text,
                    'cantidad': int.tryParse(cantidadController.text) ?? 1,
                    'telefono': telefonoController.text,
                    'adultos': int.tryParse(adultosController.text) ?? 0,
                    'ninos': int.tryParse(ninosController.text) ?? 0,
                    'checkIn': checkInController.text,
                    'checkOut': checkOutController.text,
                    'observaciones': observacionesController.text,
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }
}