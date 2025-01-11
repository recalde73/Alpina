import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'reservas_repository.dart';
//import 'habitaciones_disponibilidad.dart'; 
import 'tarifas_manager.dart';
//import 'package:Alpina/habitaciones_disponibilidad.dart';
import 'habitaciones_repository.dart';


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

  // NUEVO: Repositorio de habitaciones
  final HabitacionesRepository _habitacionesRepository = HabitacionesRepository();

  final FocusNode _observacionesFocusNode = FocusNode();

  // Controladores de texto
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

  // NUEVO: Lista de habitaciones cargadas de Firestore
  List<Map<String, dynamic>> _habitaciones = [];
  // NUEVO: Habitación seleccionada (almacenaremos el Map completo o solo el 'id')
  Map<String, dynamic>? _selectedHabitacion;

  @override
  void initState() {
    super.initState();

    // Cargar habitaciones desde Firebase
    _loadHabitaciones();

    // Inicializa los controladores con los datos existentes o valores vacíos
    // NOTA: Eliminamos el habitacionController, porque usaremos el dropdown
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
  }

  Future<void> _loadHabitaciones() async {
    try {
      final lista = await _habitacionesRepository.getHabitaciones();
      setState(() {
        _habitaciones = lista;
      });

      // Si estamos editando una reserva existente, buscar la que coincida con la que tenía la reserva
      if (widget.reserva != null && widget.reserva!['habitacion'] != null) {
        final nombreHab = widget.reserva!['habitacion'];
        // Intentar buscar la habitación en la lista
        final matching = _habitaciones.firstWhere(
          (hab) => hab['nombre'] == nombreHab,
          orElse: () => {},
        );
        if (matching.isNotEmpty) {
          setState(() {
            _selectedHabitacion = matching;
          });
        }
      }

    } catch (e) {
      print('Error al cargar habitaciones: $e');
      // Manejar error en UI si lo deseas
    }
  }

  Future<void> selectDate(BuildContext context, TextEditingController controller) async {
    DateTime initialDate = DateTime.now();
    if (controller.text.isNotEmpty) {
      try {
        initialDate = DateFormat('dd/MM/yyyy').parse(controller.text);
      } catch (e) {}
    }

    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      locale: const Locale('es', 'ES'),
    );
    if (picked != null) {
      setState(() {
        controller.text = DateFormat('dd/MM/yyyy', 'es').format(picked);
      });
    }
  }

  void _saveForm() async {
    if (_formKey.currentState!.validate()) {
      // Validar que se seleccione alguna habitación
      if (_selectedHabitacion == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor, seleccione una habitación.')),
        );
        return;
      }

      // Obtener datos para verificación
      // Ahora en vez de leer de habitacionController, tomamos el nombre de _selectedHabitacion
      final habitacionId = _selectedHabitacion!['nombre']; 
      final checkInDate = DateFormat('dd/MM/yyyy').parse(checkInController.text);
      final checkOutDate = DateFormat('dd/MM/yyyy').parse(checkOutController.text);

      // Verificar disponibilidad
      bool disponible = await _reservasRepository.isHabitacionDisponible(
        habitacionId,
        checkInDate,
        checkOutDate,
      );

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
        return;
      }

      // Obtener valores de monto total y saldo
      double montoTotal = double.tryParse(montoTotalController.text) ?? 0.0;
      double montoSenado = double.tryParse(montoSenadoController.text) ?? 0.0;
      double saldo = montoTotal - montoSenado;

      // Construir el mapa de datos de la reserva
      Map<String, dynamic> reservaData = {
        'habitacion': habitacionId, // Nombre (o ID) de la habitación
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

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: Text(isEditing ? 'Editar Reserva' : 'Nueva Reserva'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // ****************
              // REEMPLAZAR TextFormField "habitacion" POR Dropdown
              // ****************
              const SizedBox(height: 5),
              DropdownButtonFormField<Map<String, dynamic>>(
                decoration: const InputDecoration(labelText: 'Seleccionar Habitación'),
                value: _selectedHabitacion, // puede ser null si no ha cargado o no hay coincidencia
                items: _habitaciones.map((hab) {
                  return DropdownMenuItem<Map<String, dynamic>>(
                    value: hab,
                    child: Text('${hab['nombre']} (cap: ${hab['capacidad']})'),
                  );
                }).toList(),
                onChanged: (habSeleccionada) {
                  setState(() {
                    _selectedHabitacion = habSeleccionada;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Por favor, seleccione una habitación';
                  }
                  return null;
                },
              ),

              // Resto de campos:
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
                  }
                  // Validar checkOut posterior a checkIn
                  if (checkInController.text.isNotEmpty) {
                    final inDate = DateFormat('dd/MM/yyyy').parse(checkInController.text);
                    final outDate = DateFormat('dd/MM/yyyy').parse(value);
                    if (outDate.isBefore(inDate)) {
                      return 'La fecha de check-out debe ser posterior a la de check-in.';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              // Late checkout: podrías usar un Switch, un Dropdown o un Checkbox
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
                focusNode: _observacionesFocusNode,
                decoration: const InputDecoration(
                  labelText: 'Observaciones',
                ),
                // Permite múltiples líneas pero limita la altura
                keyboardType: TextInputType.multiline,
                minLines: 1,        // Puedes ajustarlo a 2 o 3 según prefieras
                maxLines: 5,        // Hasta 5 líneas, por ejemplo
                // Al presionar la tecla “enter”, se mostrará el botón "Done" en algunos teclados
                textInputAction: TextInputAction.done,
                // Cuando el usuario presione “Done”, se quita el foco y el teclado se cierra
                onFieldSubmitted: (_) {
                  _observacionesFocusNode.unfocus();
                },
              ),

              // TarifaCalculator
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
    );
  }
}
