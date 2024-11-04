import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ReservasDisponibilidad {
  final List<Map<String, dynamic>> reservas;
  ReservasDisponibilidad({required this.reservas});

  List<String> obtenerHabitacionesDisponibles(DateTime fecha) {
    // Todas las habitaciones de alpina
    List<String> habitaciones = ['Habitación: 101', 'Habitación: 102', 'Habitación: 103', 'Habitación: 104', 'Habitación: 105', 'Habitación: 106'];
    List<String> ocupadas = [];

    String fechaFormateada = DateFormat('dd/MM/yyyy').format(fecha);

    // Filtrar habitaciones ocupadas en la fecha seleccionada
    for (var reserva in reservas) {
      if (reserva['checkIn'] == fechaFormateada || reserva['checkOut'] == fechaFormateada ||
          (DateFormat('dd/MM/yyyy').parse(reserva['checkIn']).isBefore(fecha) &&
           DateFormat('dd/MM/yyyy').parse(reserva['checkOut']).isAfter(fecha))) {
        ocupadas.add(reserva['habitacion']);
      }
    }

    // Devuelve la lista de habitaciones que no están ocupadas en esa fecha
    return habitaciones.where((habitacion) => !ocupadas.contains(habitacion)).toList();
  }

  void mostrarHabitacionesDisponibles(BuildContext context, DateTime fecha) {
    List<String> disponibles = obtenerHabitacionesDisponibles(fecha);
    String fechaFormateada = DateFormat('dd MMMM yyyy', 'es').format(fecha);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Habitaciones disponibles para $fechaFormateada'),
          content: disponibles.isEmpty
              ? const Text('No hay habitaciones disponibles en esta fecha.')
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: disponibles.map((hab) => Text(hab)).toList(),
                ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }
}
