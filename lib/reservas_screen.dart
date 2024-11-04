import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'reservas_filter.dart';
import 'reservas_disponibilidad.dart';
import 'reservas_card.dart';
import 'reservas_add_edit.dart';
import 'reservas_repository.dart';

class ReservasScreen extends StatefulWidget {
  const ReservasScreen({super.key});

  @override
  _ReservasScreenState createState() => _ReservasScreenState();
}

class _ReservasScreenState extends State<ReservasScreen> {
  final ReservasRepository _reservasRepository = ReservasRepository();
  List<Map<String, dynamic>> reservas = [];
  List<Map<String, dynamic>> filteredReservas = [];
  TextEditingController filterController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadReservas();
    filterController.addListener(_filterReservas);
  }

  void _loadReservas() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      List<Map<String, dynamic>> loadedReservas = await _reservasRepository.getReservas();
      setState(() {
        reservas = loadedReservas;
        filteredReservas = reservas;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Error al cargar las reservas: $e";
      });
    }
  }

  void _filterReservas() {
    setState(() {
      String query = filterController.text.toLowerCase();
      filteredReservas = reservas.where((reserva) {
        final nombre = reserva['nombre']?.toLowerCase() ?? '';
        final habitacion = reserva['habitacion']?.toLowerCase() ?? '';
        return nombre.contains(query) || habitacion.contains(query);
      }).toList();
    });
  }

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

  void _showAddReservaDialog() {
    ReservasAddEdit reservasAddEdit = ReservasAddEdit(
      formKey: _formKey,
      habitacionController: TextEditingController(text: "Habitación: "),
      nombreController: TextEditingController(),
      telefonoController: TextEditingController(),
      cantidadController: TextEditingController(),
      adultosController: TextEditingController(),
      ninosController: TextEditingController(),
      checkInController: TextEditingController(),
      checkOutController: TextEditingController(),
      observacionesController: TextEditingController(),
      onSave: (newReserva) async {
        try {
          await _reservasRepository.addReserva(newReserva);
          _loadReservas();
        } catch (e) {
          setState(() {
            _errorMessage = "Error al agregar la reserva: $e";
          });
        }
      },
    );

    reservasAddEdit.showAddEditDialog(context, isEditing: false);
  }

  void _showEditReservaDialog(int index, Map<String, dynamic> reserva) {
    ReservasAddEdit reservasAddEdit = ReservasAddEdit(
      formKey: _formKey,
      habitacionController: TextEditingController(text: reserva['habitacion'] ?? ''),
      nombreController: TextEditingController(text: reserva['nombre'] ?? ''),
      telefonoController: TextEditingController(text: reserva['telefono'] ?? ''),
      cantidadController: TextEditingController(text: reserva['cantidad']?.toString() ?? ''),
      adultosController: TextEditingController(text: reserva['adultos']?.toString() ?? ''),
      ninosController: TextEditingController(text: reserva['ninos']?.toString() ?? ''),
      checkInController: TextEditingController(text: reserva['checkIn'] ?? ''),
      checkOutController: TextEditingController(text: reserva['checkOut'] ?? ''),
      observacionesController: TextEditingController(text: reserva['observaciones'] ?? ''),
      onSave: (updatedReserva) async {
        try {
          await _reservasRepository.updateReserva(reserva['id'], updatedReserva);
          _loadReservas();
        } catch (e) {
          setState(() {
            _errorMessage = "Error al actualizar la reserva: $e";
          });
        }
      },
    );

    reservasAddEdit.showAddEditDialog(context, isEditing: true);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Reservas Alpina'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Reservas Alpina'),
        ),
        body: Center(
          child: Text(
            _errorMessage!,
            style: const TextStyle(fontSize: 18, color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (filteredReservas.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Reservas Alpina'),
        ),
        body: const Center(
          child: Text(
            'No hay reservas disponibles.',
            style: TextStyle(fontSize: 18),
          ),
        ),
      );
    }

    Map<String, List<Map<String, dynamic>>> reservasPorFecha = {};
    for (var reserva in filteredReservas) {
      String? fecha = reserva['checkIn'];

      if (fecha != null && fecha.isNotEmpty) {
        try {
          DateTime parsedFecha = DateFormat('dd/MM/yyyy').parse(fecha);

          if (reservasPorFecha[fecha] == null) {
            reservasPorFecha[fecha] = [];
          }
          reservasPorFecha[fecha]!.add(reserva);
        } catch (e) {
          print("Error al parsear la fecha: $e");
        }
      }
    }

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus(); // Quita el foco de cualquier campo activo al hacer clic fuera
      },
      child: Scaffold(
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
                        return buildDismissibleReserva(
                          context: context,
                          index: index,
                          reserva: reserva,
                          onDismissed: () async {
                            try {
                              await _reservasRepository.deleteReserva(reserva['id']);
                              _loadReservas();
                            } catch (e) {
                              setState(() {
                                _errorMessage = "Error al eliminar la reserva: $e";
                              });
                            }
                          },
                          onCardTap: () {
                            _showEditReservaDialog(index, reserva);
                          },
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
      ),
    );
  }
}

