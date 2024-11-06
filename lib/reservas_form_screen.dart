// reservas_form_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
  _ReservasScreenState  createState() => _ReservasScreenState ();
}

class _ReservasScreenState  extends State<ReservasFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

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
  late TextEditingController montoSenadoController;

  bool lateCheckout = false;
  double montoTotal = 0.0;
  double montoSenado = 0.0;
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
    montoSenadoController = TextEditingController(text: widget.reserva?['montoSenado']?.toString() ?? '');

    lateCheckout = widget.reserva?['lateCheckout'] ?? false;
    montoTotal = widget.reserva?['montoTotal'] ?? 0.0;
    montoSenado = widget.reserva?['montoSenado'] ?? 0.0;
    saldo = widget.reserva?['saldo'] ?? 0.0;
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
    super.dispose();
  }

  Future<void> selectDate(BuildContext context, TextEditingController controller) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: controller.text.isNotEmpty
          ? DateFormat('dd/MM/yyyy').parse(controller.text)
          : DateTime.now(),
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

  void _calculateMontoTotal() {
    // Crear instancia de TarifasManager
    TarifasManager tarifasManager = TarifasManager();

    // Calcular monto total usando calcularMontoTotal
    double calculatedMontoTotal = tarifasManager.calcularMontoTotal(
      tipoHabitacion: 'Individual', // Puedes reemplazar esto por la habitación seleccionada por el usuario
      cantidadAdultos: int.tryParse(adultosController.text) ?? 0,
      cantidadNinos: int.tryParse(ninosController.text) ?? 0,
      checkIn: DateFormat('dd/MM/yyyy').parse(checkInController.text),
      checkOut: DateFormat('dd/MM/yyyy').parse(checkOutController.text),
      lateCheckout: lateCheckout,
    );

    setState(() {
      montoTotal = calculatedMontoTotal;
    });
  }

  void _saveForm() {
    if (_formKey.currentState!.validate()) {
      // Calcular monto total y saldo antes de guardar
      _calculateMontoTotal();

      montoSenado = double.tryParse(montoSenadoController.text) ?? 0.0;
      saldo = montoTotal - montoSenado;

      // Construye el mapa de datos de la reserva
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
                // Aquí agregas los TextFormField y otros widgets del formulario
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
                SwitchListTile(
                  title: const Text('Late Checkout'),
                  value: lateCheckout,
                  activeColor: Colors.green, // Color del switch cuando está activo
                  onChanged: (bool value) {
                    setState(() {
                      lateCheckout = value;
                    });
                  },
                ),
                TextFormField(
                  controller: observacionesController,
                  decoration: const InputDecoration(labelText: 'Observaciones'),
                  keyboardType: TextInputType.multiline,
                  maxLines: null,
                ),
                TextFormField(
                  controller: montoSenadoController,
                  decoration: const InputDecoration(labelText: 'Monto Señado'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, ingrese el monto señado';
                    } else if (double.tryParse(value) == null) {
                      return 'Ingrese un número válido';
                    }
                    return null;
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
