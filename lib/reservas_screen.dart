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
  bool mostrarTodasLasReservas = false;

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
        _filterReservas();
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
        final checkOut = reserva['checkOut'] ?? '';

        bool matchesQuery = nombre.contains(query) || habitacion.contains(query);
        
        if (mostrarTodasLasReservas) {
          return matchesQuery;
        } else {
          if (checkOut.isNotEmpty) {
            DateTime checkOutDate = DateFormat('dd/MM/yyyy').parse(checkOut);
            DateTime fiveDaysAgo = DateTime.now().subtract(const Duration(days: 5));
            return matchesQuery && checkOutDate.isAfter(fiveDaysAgo);
          }
          return false;
        }
      }).toList();

      // Ordenar las reservas por fecha de check-in de la más antigua a la más reciente
      filteredReservas.sort((a, b) {
        DateTime fechaA = DateFormat('dd/MM/yyyy').parse(a['checkIn'] ?? '');
        DateTime fechaB = DateFormat('dd/MM/yyyy').parse(b['checkIn'] ?? '');
        return fechaA.compareTo(fechaB);
      });
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
    return DefaultTabController(
      length: 2, // Número de pestañas
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Alpina Green',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            textAlign: TextAlign.center,
          ),
          backgroundColor: Colors.green, // Color de la barra de "Alpina Green"
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(48.0),
            child: Material(
              color: Color(0xFF81C784), // Color más claro para distinguir las pestañas
              child: TabBar(
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.black,
                tabs: [
                  Tab(text: "Reservas"),
                  Tab(text: "Reporte de Ganancias"),
                ],
              ),
            ),
          ),
        ),
        body: TabBarView(
          children: [
            _buildReservasTab(),
            _buildReporteTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildReservasTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Text(
          _errorMessage!,
          style: const TextStyle(fontSize: 18, color: Colors.red),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (filteredReservas.isEmpty) {
      return const Center(
        child: Text(
          'No hay reservas disponibles.',
          style: TextStyle(fontSize: 18),
        ),
      );
    }

    // Agrupar reservas por fecha de check-in
    Map<String, List<Map<String, dynamic>>> reservasPorFecha = {};
    for (var reserva in filteredReservas) {
      String? fecha = reserva['checkIn'];

      if (fecha != null && fecha.isNotEmpty) {
        try {
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
      child: Column(
        children: [
          ReservasFilter(
            controller: filterController,
            onFilterChanged: (query) => _filterReservas(),
            mostrarTodas: mostrarTodasLasReservas,
            onMostrarTodasChanged: (value) {
              setState(() {
                mostrarTodasLasReservas = value;
                _filterReservas();
              });
            },
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
    );
  }

  Widget _buildReporteTab() {
    return const Center(
      child: Text(
        'Aquí se mostrará el reporte de ganancias.',
        style: TextStyle(fontSize: 18),
      ),
    );
  }
}


