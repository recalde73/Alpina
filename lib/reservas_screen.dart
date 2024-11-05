import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'reservas_disponibilidad.dart';
import 'reservas_add_edit.dart';
import 'reservas_repository.dart';
import 'package:url_launcher/url_launcher.dart';
import 'habitaciones_disponibilidad.dart';
import 'late_checkout.dart';
import 'tarifas_manager.dart';

class ReservasScreen extends StatefulWidget {
  const ReservasScreen({super.key});

  @override
  _ReservasScreenState createState() => _ReservasScreenState();
}

class _ReservasScreenState extends State<ReservasScreen> {
  final ReservasRepository _reservasRepository = ReservasRepository();
  final HabitacionesRepository habitacionesRepository = HabitacionesRepository();
  List<Map<String, dynamic>> reservas = [];
  List<Map<String, dynamic>> filteredReservas = [];
  List<Map<String, dynamic>> reservasPasadas = [];
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

        if (checkOut.isNotEmpty) {
          DateTime checkOutDate = DateFormat('dd/MM/yyyy').parse(checkOut);
          DateTime now = DateTime.now();
          if (checkOutDate.isBefore(now)) {
            reservasPasadas.add(reserva);
            return false;
          }
        }
        return matchesQuery;
      }).toList();

      // Ordenar las reservas por fecha de check-in de la más antigua a la más reciente
      filteredReservas.sort((a, b) {
        DateTime fechaA = DateFormat('dd/MM/yyyy').parse(a['checkIn'] ?? '');
        DateTime fechaB = DateFormat('dd/MM/yyyy').parse(b['checkIn'] ?? '');
        return fechaA.compareTo(fechaB);
      });

      // Ordenar las reservas pasadas por fecha de check-in de la más antigua a la más reciente
      reservasPasadas.sort((a, b) {
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
      lateCheckout: false, // Nueva adición
      montoTotal: 0.0, // Agregado
      montoSenado: 0.0,
      saldo: 0.0,
      onSave: (newReserva) async {
        newReserva['telefono'] = _formatPhoneNumber(newReserva['telefono']);

        // Crear instancia de TarifasManager
        TarifasManager tarifasManager = TarifasManager();

        // Calcular monto total usando calcularMontoTotal
        double montoTotal = tarifasManager.calcularMontoTotal(
          tipoHabitacion: 'Individual', // Puedes reemplazar esto por la habitación seleccionada por el usuario
          cantidadAdultos: int.parse(newReserva['adultos'] ?? '0'),
          cantidadNinos: int.parse(newReserva['ninos'] ?? '0'),
          checkIn: DateFormat('dd/MM/yyyy').parse(newReserva['checkIn']),
          checkOut: DateFormat('dd/MM/yyyy').parse(newReserva['checkOut']),
          lateCheckout: newReserva['lateCheckout'] == true,
        );

        newReserva['montoTotal'] = montoTotal;

        // Calcular saldo
        double montoSenado = double.tryParse(newReserva['montoSenado']) ?? 0.0;
        newReserva['saldo'] = montoTotal - montoSenado;

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
      telefonoController: TextEditingController(text: _formatPhoneNumber(reserva['telefono'] ?? '')),
      cantidadController: TextEditingController(text: reserva['cantidad']?.toString() ?? ''),
      adultosController: TextEditingController(text: reserva['adultos']?.toString() ?? ''),
      ninosController: TextEditingController(text: reserva['ninos']?.toString() ?? ''),
      checkInController: TextEditingController(text: reserva['checkIn'] ?? ''),
      checkOutController: TextEditingController(text: reserva['checkOut'] ?? ''),
      observacionesController: TextEditingController(text: reserva['observaciones'] ?? ''),
      lateCheckout: reserva['lateCheckout'] ?? false, // Nueva adición
      montoTotal: reserva['montoTotal'] ?? 0.0, // Agregado anteriormente
      montoSenado: reserva['montoSenado'] ?? 0.0, // Agregado ahora
      saldo: reserva['saldo'] ?? 0.0,
      onSave: (updatedReserva) async {
        updatedReserva['telefono'] = _formatPhoneNumber(updatedReserva['telefono']);

        // Crear instancia de TarifasManager
        TarifasManager tarifasManager = TarifasManager();

        // Calcular monto total usando calcularMontoTotal
        double montoTotal = tarifasManager.calcularMontoTotal(
          tipoHabitacion: 'Individual', // Puedes reemplazar esto por la habitación seleccionada por el usuario
          cantidadAdultos: int.parse(updatedReserva['adultos'] ?? '0'),
          cantidadNinos: int.parse(updatedReserva['ninos'] ?? '0'),
          checkIn: DateFormat('dd/MM/yyyy').parse(updatedReserva['checkIn']),
          checkOut: DateFormat('dd/MM/yyyy').parse(updatedReserva['checkOut']),
          lateCheckout: updatedReserva['lateCheckout'] == true,
        );

        updatedReserva['montoTotal'] = montoTotal;

        // Calcular saldo
        double montoSenado = double.tryParse(updatedReserva['montoSenado']) ?? 0.0;
        updatedReserva['saldo'] = montoTotal - montoSenado;

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

  Future<void> _callPhoneNumber(String phoneNumber) async {
    final Uri url = Uri(scheme: 'tel', path: _formatPhoneNumber(phoneNumber));
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'No se pudo abrir $url';
    }
  }

  String _formatPhoneNumber(String phoneNumber) {
    if (phoneNumber.startsWith('0')) {
      return '+595' + phoneNumber.substring(1);
    }
    return phoneNumber;
  }

  int _calcularDias(String checkIn, String checkOut) {
    DateTime checkInDate = DateFormat('dd/MM/yyyy').parse(checkIn);
    DateTime checkOutDate = DateFormat('dd/MM/yyyy').parse(checkOut);
    return checkOutDate.difference(checkInDate).inDays;
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3, // Número de pestañas
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
                  Tab(text: "Reservas 📝"),
                  Tab(text: "Historial 📜"),
                  Tab(text: "Reporte 📊"),
                ],
              ),
            ),
          ),
        ),
        body: TabBarView(
          children: [
            _buildReservasTab(),
            _buildReservasPasadasTab(),
            _buildReporteTab(),
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
            // Botón de búsqueda
            Positioned(
              bottom: 144.0, // Ajuste para mostrarlo encima del botón de ver disponibilidad
              right: 16.0,
              child: FloatingActionButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text('Buscar Reservas'),
                        content: TextField(
                          controller: filterController,
                          decoration: const InputDecoration(
                            hintText: 'Ingrese nombre o habitación',
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              _filterReservas();
                            },
                            child: const Text('Buscar'),
                          ),
                          TextButton(
                            onPressed: () {
                              filterController.clear();
                              Navigator.of(context).pop();
                              _filterReservas();
                            },
                            child: const Text('Restaurar'),
                          ),
                        ],
                      );
                    },
                  );
                },
                backgroundColor: Colors.green[400],
                tooltip: 'Buscar',
                child: const Icon(Icons.search),
              ),
            ),
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
                        key: Key(reserva['id'].toString()),
                        direction: DismissDirection.startToEnd,
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
                        onDismissed: (direction) async {
                          try {
                            await _reservasRepository.deleteReserva(reserva['id']);
                            setState(() {
                              reservas.removeAt(index);
                              _filterReservas();
                            });
                          } catch (e) {
                            setState(() {
                              _errorMessage = "Error al eliminar la reserva: $e";
                            });
                          }
                        },
                        background: Container(
                          color: Colors.red,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          alignment: AlignmentDirectional.centerStart,
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        child: Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          child: ListTile(
                            title: Text('Habitación: ${reserva['habitacion']} - ${reserva['nombre']}'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Teléfono: ${_formatPhoneNumber(reserva['telefono'])}'),
                                Text('Adultos: ${reserva['adultos']}, Niños: ${reserva['ninos']}'),
                                Text('Check-in: ${reserva['checkIn']}'),
                                Text('Check-out: ${reserva['checkOut']}'),
                                Text('Observaciones: ${reserva['observaciones']}'),
                                Text('Monto Total: ${reserva['montoTotal'] ?? "No especificado"}'),
                                Text('Monto Señado: ${reserva['montoSenado'] ?? "No especificado"}'),
                                Text('Saldo: ${reserva['saldo'] ?? "No especificado"}'),
                                Text('Late Checkout: ${reserva['lateCheckout'] ?? "No"}'),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.phone, color: Colors.green),
                              onPressed: () => _callPhoneNumber(reserva['telefono']),
                            ),
                            onTap: () {
                              _showEditReservaDialog(index, reserva);
                            },
                          ),
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
    );
  }

  Widget _buildReservasPasadasTab() {
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

    if (reservasPasadas.isEmpty) {
      return const Center(
        child: Text(
          'No hay reservas pasadas disponibles.',
          style: TextStyle(fontSize: 18),
        ),
      );
    }

    // Agrupar reservas pasadas por fecha de check-in
    Map<String, List<Map<String, dynamic>>> reservasPorFecha = {};
    for (var reserva in reservasPasadas) {
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
                        key: Key(reserva['id'].toString()),
                        direction: DismissDirection.startToEnd,
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
                        onDismissed: (direction) async {
                          try {
                            await _reservasRepository.deleteReserva(reserva['id']);
                            setState(() {
                              reservas.removeAt(index);
                              _filterReservas();
                            });
                          } catch (e) {
                            setState(() {
                              _errorMessage = "Error al eliminar la reserva: $e";
                            });
                          }
                        },
                        background: Container(
                          color: Colors.red,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          alignment: AlignmentDirectional.centerStart,
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        child: Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          child: ListTile(
                            title: Text('Habitación: ${reserva['habitacion']} - ${reserva['nombre']}'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Teléfono: ${_formatPhoneNumber(reserva['telefono'])}'),
                                Text('Adultos: ${reserva['adultos']}, Niños: ${reserva['ninos']}'),
                                Text('Check-in: ${reserva['checkIn']}'),
                                Text('Check-out: ${reserva['checkOut']}'),
                                Text('Observaciones: ${reserva['observaciones']}'),
                                Text('Monto Total: ${reserva['montoTotal'] ?? "No especificado"}'),
                                Text('Monto Señado: ${reserva['montoSenado'] ?? "No especificado"}'),
                                Text('Saldo: ${reserva['saldo'] ?? "No especificado"}'),
                                Text('Late Checkout: ${reserva['lateCheckout'] ?? "No"}'),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.phone, color: Colors.green),
                              onPressed: () => _callPhoneNumber(reserva['telefono']),
                            ),
                            onTap: () {
                              _showEditReservaDialog(index, reserva);
                            },
                          ),
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
    );
  }

  Widget _buildReporteTab() {
    return const Center(
      child: Text(
        'Aca se veran muchos millones :)',
        style: TextStyle(fontSize: 18),
      ),
    );
  }
}
