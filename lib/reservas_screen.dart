import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ReservasScreen extends StatefulWidget {
  const ReservasScreen({Key? key}) : super(key: key);

  @override
  _ReservasScreenState createState() => _ReservasScreenState();
}

class _ReservasScreenState extends State<ReservasScreen> {
  List<Map<String, dynamic>> reservas = [
    {
      'habitacion': 'Habitación 101',
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
      'habitacion': 'Habitación 102',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reservas Alpina'),
      ),
      body: ListView.builder(
        itemCount: reservas.length,
        itemBuilder: (context, index) {
          final reserva = reservas[index];
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
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddReservaDialog,
        child: const Icon(Icons.add),
        backgroundColor: Colors.green,
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

    Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
      DateTime? picked = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime(2101),
      );
      if (picked != null) {
        setState(() {
          controller.text = DateFormat('dd/MM/yyyy').format(picked);
        });
      }
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Detalles de la Reserva'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: habitacionController,
                  decoration: const InputDecoration(labelText: 'Habitación'),
                ),
                TextField(
                  controller: nombreController,
                  decoration: const InputDecoration(labelText: 'Nombre del cliente'),
                ),
                TextField(
                  controller: telefonoController,
                  decoration: const InputDecoration(labelText: 'Número de Teléfono'),
                  keyboardType: TextInputType.phone,
                ),
                TextField(
                  controller: cantidadController,
                  decoration: const InputDecoration(labelText: 'Cantidad de huéspedes'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: adultosController,
                  decoration: const InputDecoration(labelText: 'Cantidad de Adultos'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: ninosController,
                  decoration: const InputDecoration(labelText: 'Cantidad de Niños'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: checkInController,
                  readOnly: true,
                  decoration: const InputDecoration(labelText: 'Check-in'),
                  onTap: () => _selectDate(context, checkInController),
                ),
                TextField(
                  controller: checkOutController,
                  readOnly: true,
                  decoration: const InputDecoration(labelText: 'Check-out'),
                  onTap: () => _selectDate(context, checkOutController),
                ),
                TextField(
                  controller: observacionesController,
                  decoration: const InputDecoration(labelText: 'Observaciones'),
                  keyboardType: TextInputType.multiline,
                  maxLines: null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
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
                });
                Navigator.pop(context);
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  void _showAddReservaDialog() {
    TextEditingController habitacionController = TextEditingController(text: "Habitación ");
    TextEditingController nombreController = TextEditingController();
    TextEditingController telefonoController = TextEditingController();
    TextEditingController cantidadController = TextEditingController();
    TextEditingController adultosController = TextEditingController();
    TextEditingController ninosController = TextEditingController();
    TextEditingController checkInController = TextEditingController();
    TextEditingController checkOutController = TextEditingController();
    TextEditingController observacionesController = TextEditingController();

    Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
      DateTime? picked = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime(2101),
      );
      if (picked != null) {
        setState(() {
          controller.text = DateFormat('dd/MM/yyyy').format(picked);
        });
      }
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Agregar Nueva Reserva'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: habitacionController,
                  decoration: const InputDecoration(labelText: 'Habitación'),
                  onChanged: (value) {
                    if (!value.startsWith("Habitación ")) {
                      habitacionController.text = "Habitación ";
                      habitacionController.selection = TextSelection.fromPosition(
                        TextPosition(offset: habitacionController.text.length),
                      );
                    }
                  },
                ),
                TextField(
                  controller: nombreController,
                  decoration: const InputDecoration(labelText: 'Nombre del cliente'),
                ),
                TextField(
                  controller: telefonoController,
                  decoration: const InputDecoration(labelText: 'Número de Teléfono'),
                  keyboardType: TextInputType.phone,
                ),
                TextField(
                  controller: cantidadController,
                  decoration: const InputDecoration(labelText: 'Cantidad de huéspedes'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: adultosController,
                  decoration: const InputDecoration(labelText: 'Cantidad de Adultos'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: ninosController,
                  decoration: const InputDecoration(labelText: 'Cantidad de Niños'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: checkInController,
                  readOnly: true,
                  decoration: const InputDecoration(labelText: 'Check-in'),
                  onTap: () => _selectDate(context, checkInController),
                ),
                TextField(
                  controller: checkOutController,
                  readOnly: true,
                  decoration: const InputDecoration(labelText: 'Check-out'),
                  onTap: () => _selectDate(context, checkOutController),
                ),
                TextField(
                  controller: observacionesController,
                  decoration: const InputDecoration(labelText: 'Observaciones'),
                  keyboardType: TextInputType.multiline,
                  maxLines: null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
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
                });
                Navigator.pop(context);
              },
              child: const Text('Agregar'),
            ),
          ],
        );
      },
    );
  }
}
