import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'reservas_filter.dart';
import 'reservas_disponibilidad.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [
        Locale('es', 'ES'), // Configuración en español
      ],
      home: ReservasScreen(),
    );
  }
}

class ReservasScreen extends StatefulWidget {
  const ReservasScreen({super.key});

  @override
  _ReservasScreenState createState() => _ReservasScreenState();
}

class _ReservasScreenState extends State<ReservasScreen> {
  List<Map<String, dynamic>> reservas = [
    {
      'habitacion': 'Habitación: 101',
      'nombre': 'Juan Pérez',
      'cantidad': 2,
      'telefono': '123456789',
      'adultos': 2,
      'ninos': 0,
      'checkIn': '30/10/2024',
      'checkOut': '02/11/2024',
      'observaciones': 'Preferencia por vista al jardín.'
    },
    {
      'habitacion': 'Habitación: 102',
      'nombre': 'Ana Gómez',
      'cantidad': 1,
      'telefono': '987654321',
      'adultos': 1,
      'ninos': 1,
      'checkIn': '30/10/2024',
      'checkOut': '01/11/2024',
      'observaciones': 'Solicita desayuno temprano.'
    },
  ];

  void _mostrarDisponibilidad() async {
  DateTime? fechaSeleccionada = await showDatePicker(
    context: context,
    initialDate: DateTime.now(),
    firstDate: DateTime.now(),
    lastDate: DateTime(2101),
    locale: const Locale('es', 'ES'), // Localización en español
  );

  if (fechaSeleccionada != null) {
    ReservasDisponibilidad disponibilidad = ReservasDisponibilidad(reservas: reservas);
    disponibilidad.mostrarHabitacionesDisponibles(context, fechaSeleccionada);
  }
}

  List<Map<String, dynamic>> filteredReservas = [];
  TextEditingController filterController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    filteredReservas = reservas; // Mostrar todas las reservas inicialmente
    filterController.addListener(_filterReservas);
  }

  void _filterReservas() {
    setState(() {
      String query = filterController.text.toLowerCase();
      filteredReservas = reservas.where((reserva) {
        final nombre = reserva['nombre'].toLowerCase();
        final habitacion = reserva['habitacion'].toLowerCase();
        return nombre.contains(query) || habitacion.contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    Map<String, List<Map<String, dynamic>>> reservasPorFecha = {};
    for (var reserva in filteredReservas) {
      String fecha = reserva['checkIn'];
      if (reservasPorFecha[fecha] == null) {
        reservasPorFecha[fecha] = [];
      }
      reservasPorFecha[fecha]!.add(reserva);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reservas Alpina'),
      ),
      body: Column(
        children: [
          ReservasFilter(
            controller: filterController,
            onFilterChanged: (query) => _filterReservas(),
          ),
          Expanded(
            child: ListView(
              children: reservasPorFecha.entries.map((entry) {
                String fecha = entry.key;
                List<Map<String, dynamic>> reservasDelDia = entry.value;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        DateFormat('dd MMMM yyyy', 'es').format(DateFormat('dd/MM/yyyy').parse(fecha)),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                    ),
                    ...reservasDelDia.map((reserva) {
                      int index = reservas.indexOf(reserva);
                      return Dismissible(
                        key: UniqueKey(),
                        direction: DismissDirection.endToStart,
                        confirmDismiss: (direction) async {
                          return await showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text("Confirmar eliminación"),
                                content: const Text("¿Estás seguro de que deseas eliminar esta reserva?"),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(false),
                                    child: const Text("Cancelar"),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(true),
                                    child: const Text("Eliminar"),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        onDismissed: (direction) {
                          setState(() {
                            reservas.removeAt(index);
                            _filterReservas(); // Actualizar el filtro
                          });
                        },
                        background: Container(color: Colors.red),
                        child: _buildReservaCard(
                          context,
                          index,
                          reserva['habitacion'],
                          reserva['nombre'],
                          reserva['cantidad'],
                          reserva['telefono'],
                          reserva['adultos'],
                          reserva['ninos'],
                          reserva['checkIn'],
                          reserva['checkOut'],
                          reserva['observaciones'],
                        ),
                      );
                    }),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
      floatingActionButton: Stack(
        children: [
          // Botón para agregar una nueva reserva
          Positioned(
            bottom: 16.0,
            right: 16.0,
            child: FloatingActionButton(
              onPressed: _showAddReservaDialog,
              backgroundColor: Colors.green,
              tooltip: 'Agregar reserva',
              child: const Icon(Icons.add),
            ),
          ),
          // Botón para ver disponibilidad
          Positioned(
            bottom: 80.0, // Ajuste para mostrarlo encima del botón de agregar
            right: 16.0,
            child: FloatingActionButton(
              onPressed: _mostrarDisponibilidad,
              backgroundColor: Colors.green[700],
              tooltip: 'Ver disponibilidad',
              child: const Icon(Icons.calendar_today),
            ),
          ),
        ],
      ),

    );
  }

  Widget _buildReservaCard(BuildContext context, int index, String habitacion, String nombre, int cantidad, String telefono, int adultos, int ninos, String checkIn, String checkOut, String observaciones) {
    return Card(
      color: Colors.green[100],
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: ListTile(
        title: Text('$habitacion - $nombre'),
        subtitle: Text('Teléfono: $telefono\nAdultos: $adultos, Niños: $ninos\nCheck-in: $checkIn\nCheck-out: $checkOut\nObservaciones: $observaciones'),
        onTap: () {
          _showReservaDetails(context, index, habitacion, nombre, cantidad, telefono, adultos, ninos, checkIn, checkOut, observaciones);
        },
      ),
    );
  }

  void _showReservaDetails(BuildContext context, int index, String habitacion, String nombre, int cantidad, String telefono, int adultos, int ninos, String checkIn, String checkOut, String observaciones) {
    TextEditingController habitacionController = TextEditingController(text: habitacion);
    TextEditingController nombreController = TextEditingController(text: nombre);
    TextEditingController telefonoController = TextEditingController(text: telefono);
    TextEditingController cantidadController = TextEditingController(text: cantidad.toString());
    TextEditingController adultosController = TextEditingController(text: adultos.toString());
    TextEditingController ninosController = TextEditingController(text: ninos.toString());
    TextEditingController checkInController = TextEditingController(text: checkIn);
    TextEditingController checkOutController = TextEditingController(text: checkOut);
    TextEditingController observacionesController = TextEditingController(text: observaciones);

    Future<void> selectDate(BuildContext context, TextEditingController controller) async {
      DateTime? picked = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
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

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Detalles de la Reserva'),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
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
                if (_formKey.currentState!.validate()) {
                  setState(() {
                    reservas[index] = {
                      'habitacion': habitacionController.text,
                      'nombre': nombreController.text,
                      'cantidad': int.tryParse(cantidadController.text) ?? 1,
                      'telefono': telefonoController.text,
                      'adultos': int.tryParse(adultosController.text) ?? 0,
                      'ninos': int.tryParse(ninosController.text) ?? 0,
                      'checkIn': checkInController.text,
                      'checkOut': checkOutController.text,
                      'observaciones': observacionesController.text,
                    };
                    _filterReservas();
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

  void _showAddReservaDialog() {
    TextEditingController habitacionController = TextEditingController(text: "Habitación: ");
    TextEditingController nombreController = TextEditingController();
    TextEditingController telefonoController = TextEditingController();
    TextEditingController cantidadController = TextEditingController();
    TextEditingController adultosController = TextEditingController();
    TextEditingController ninosController = TextEditingController();
    TextEditingController checkInController = TextEditingController();
    TextEditingController checkOutController = TextEditingController();
    TextEditingController observacionesController = TextEditingController();

    Future<void> selectDate(BuildContext context, TextEditingController controller) async {
      DateTime? picked = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
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

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Agregar Nueva Reserva'),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
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
                if (_formKey.currentState!.validate()) {
                  setState(() {
                    reservas.add({
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
                    _filterReservas();
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Agregar'),
            ),
          ],
        );
      },
    );
  }
}
