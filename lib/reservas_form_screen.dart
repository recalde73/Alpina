// reservas_form_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'tarifas_manager.dart';
import 'reservas_repository.dart';
import 'tarifas_manager.dart';

class ReservasFormScreen extends StatefulWidget {
  final Map<String, dynamic>? reserva;
  final Function(Map<String, dynamic>) onSave;

  const ReservasFormScreen({
    Key? key,
    this.reserva,
    required this.onSave,
  }) : super(key: key);

  @override
  _ReservasFormScreenState createState() => _ReservasFormScreenState();
}

class _ReservasFormScreenState extends State<ReservasFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ReservasRepository _reservasRepository = ReservasRepository();

  // Controladores de texto
  late TextEditingController habitacionController;
  late TextEditingController nombreController;
  late TextEditingController telefonoController;
  late TextEditingController cantidadController;
  late TextEditingController adultosController;
  late TextEditingController ninosController;
  late TextEditingController checkInController;
  late TextEditingController checkOutController;
  late TextEditingController observacionesController;
  TextEditingController montoTotalController = TextEditingController();
  TextEditingController montoSenadoController = TextEditingController();

  bool lateCheckout = false;
  double montoTotal = 0.0;
  double saldo = 0.0;

  @override
  void initState() {
    super.initState();
    // Inicializa los controladores con los datos existentes o valores vacíos
    habitacionController = TextEditingController(text: widget.reserva?['habitacion'] ?? '');
    nombreController = TextEditingController(text: widget.reserva?['nombre'] ?? '');
    telefonoController = TextEditingController(text: widget.reserva?['telefono'] ?? '');
    cantidadController = TextEditingController(text: widget.reserva?['cantidad']?.toString() ?? '');
    adultosController = TextEditingController(text: widget.reserva?['adultos']?.toString() ?? '');
    ninosController = TextEditingController(text: widget.reserva?['ninos']?.toString() ?? '');
    checkInController = TextEditingController(text: widget.reserva?['checkIn'] ?? '');
    checkOutController = TextEditingController(text: widget.reserva?['checkOut'] ?? '');
    observacionesController = TextEditingController(text: widget.reserva?['observaciones'] ?? '');
    montoSenadoController.text = widget.reserva?['montoSenado']?.toString() ?? '0.0';
    montoTotalController.text = widget.reserva?['montoTotal']?.toString() ?? '0.0';

    lateCheckout = widget.reserva?['lateCheckout'] ?? false;

    // Añadir listeners para actualizar la interfaz cuando cambien los valores
    adultosController.addListener(() => setState(() {}));
    ninosController.addListener(() => setState(() {}));
    checkInController.addListener(() => setState(() {}));
    checkOutController.addListener(() => setState(() {}));
    montoSenadoController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    // Libera los controladores cuando ya no son necesarios
    habitacionController.dispose();
    nombreController.dispose();
    telefonoController.dispose();
    cantidadController.dispose();
    adultosController.dispose();
    ninosController.dispose();
    checkInController.dispose();
    checkOutController.dispose();
    observacionesController.dispose();
    montoSenadoController.dispose();
    montoTotalController.dispose();
    super.dispose();
  }

  Future<void> selectDate(BuildContext context, TextEditingController controller) async {
    DateTime initialDate = DateTime.now();
    if (controller.text.isNotEmpty) {
      try {
        initialDate = DateFormat('dd/MM/yyyy').parse(controller.text);
      } catch (e) {
        // Manejar error de parseo si es necesario
      }
    }

    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      locale: const Locale('es', 'ES'), // Calendario en español
    );
    if (picked != null) {
      setState(() {
        controller.text = DateFormat('dd/MM/yyyy', 'es').format(picked);
      });
    }
  }

  void _saveForm() async {
    if (_formKey.currentState!.validate()) {
      // Obtener datos para verificación
      String habitacionId = habitacionController.text;
      DateTime checkInDate = DateFormat('dd/MM/yyyy').parse(checkInController.text);
      DateTime checkOutDate = DateFormat('dd/MM/yyyy').parse(checkOutController.text);

      // Verificar disponibilidad
      bool disponible = await _reservasRepository.isHabitacionDisponible(habitacionId, checkInDate, checkOutDate);

      if (!disponible) {
        // Mostrar mensaje de error y salir
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Cabaña no disponible'),
              content: const Text('La cabaña seleccionada no está disponible para las fechas elegidas.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Aceptar'),
                ),
              ],
            );
          },
        );
        return; // Salir del método sin guardar
      }

      // Obtener valores de monto total y saldo
      double montoTotal = double.tryParse(montoTotalController.text) ?? 0.0;
      double montoSenado = double.tryParse(montoSenadoController.text) ?? 0.0;
      double saldo = montoTotal - montoSenado;

      // Construir el mapa de datos de la reserva
      Map<String, dynamic> reservaData = {
        'habitacion': habitacionController.text,
        'nombre': nombreController.text,
        'telefono': telefonoController.text,
        'cantidad': int.tryParse(cantidadController.text) ?? 1,
        'adultos': int.tryParse(adultosController.text) ?? 0,
        'ninos': int.tryParse(ninosController.text) ?? 0,
        'checkIn': checkInController.text,
        'checkOut': checkOutController.text,
        'observaciones': observacionesController.text,
        'lateCheckout': lateCheckout,
        'montoTotal': montoTotal,
        'montoSenado': montoSenado,
        'saldo': saldo,
      };

      widget.onSave(reservaData);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isEditing = widget.reserva != null;

    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Colors.green,
            ),
        inputDecorationTheme: const InputDecorationTheme(
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.green),
          ),
          labelStyle: TextStyle(color: Colors.green),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green, // Fondo del botón
            foregroundColor: Colors.white, // Color del texto del botón
          ),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: MaterialStateColor.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return Colors.green; // Color cuando el switch está activado
            }
            return Colors.grey; // Color cuando el switch está desactivado
          }),
          trackColor: MaterialStateColor.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return Colors.greenAccent; // Color cuando el switch está activado
            }
            return Colors.grey.shade400; // Color cuando el switch está desactivado
          }),
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.green, // Color de fondo del AppBar
          title: Text(isEditing ? 'Editar Reserva' : 'Nueva Reserva'),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Campos del formulario
                TextFormField(
                  controller: habitacionController,
                  decoration: const InputDecoration(labelText: 'Habitación'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, ingrese la habitación';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: nombreController,
                  decoration: const InputDecoration(labelText: 'Nombre del Cliente'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, ingrese el nombre del cliente';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: telefonoController,
                  decoration: const InputDecoration(labelText: 'Teléfono'),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, ingrese el teléfono';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: cantidadController,
                  decoration: const InputDecoration(labelText: 'Cantidad de Huéspedes'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, ingrese la cantidad de huéspedes';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: adultosController,
                  decoration: const InputDecoration(labelText: 'Cantidad de Adultos'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, ingrese la cantidad de adultos';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: ninosController,
                  decoration: const InputDecoration(labelText: 'Cantidad de Niños'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, ingrese la cantidad de niños';
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
                      return 'Por favor, seleccione la fecha de check-in';
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
                      return 'Por favor, seleccione la fecha de check-out';
                    } else if (checkInController.text.isNotEmpty &&
                        DateFormat('dd/MM/yyyy').parse(value).isBefore(
                            DateFormat('dd/MM/yyyy').parse(checkInController.text))) {
                      return 'La fecha de check-out debe ser posterior a la de check-in.';
                    }
                    return null;
                  },
                ),
                DropdownButtonFormField<String>(
                  value: lateCheckout ? 'Sí' : 'No',
                  decoration: const InputDecoration(labelText: '¿Quiere salir después del mediodía?'),
                  items: ['Sí', 'No'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      lateCheckout = newValue == 'Sí';
                    });
                  },
                ),
                TextFormField(
                  controller: observacionesController,
                  decoration: const InputDecoration(labelText: 'Observaciones'),
                  keyboardType: TextInputType.multiline,
                  maxLines: null,
                ),
                const SizedBox(height: 20),
                // Integración del TarifaCalculator
                TarifaCalculator(
                  cantidadAdultos: int.tryParse(adultosController.text) ?? 0,
                  cantidadNinos: int.tryParse(ninosController.text) ?? 0,
                  checkIn: checkInController.text.isNotEmpty
                      ? DateFormat('dd/MM/yyyy').parse(checkInController.text)
                      : DateTime.now(),
                  checkOut: checkOutController.text.isNotEmpty
                      ? DateFormat('dd/MM/yyyy').parse(checkOutController.text)
                      : DateTime.now(),
                  lateCheckout: lateCheckout,
                  montoTotalController: montoTotalController,
                  montoSenadoController: montoSenadoController,
                  onMontoCalculado: (double nuevoMontoTotal, double nuevoSaldo) {
                    setState(() {
                      montoTotal = nuevoMontoTotal;
                      saldo = nuevoSaldo;
                    });
                  },
                ),

                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _saveForm,
                  child: const Text('Guardar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
