import 'package:flutter/material.dart';

class Habitacion {
  final String numero;
  final String tipo;
  List<DateTimeRange> reservas;

  Habitacion({required this.numero, required this.tipo, this.reservas = const []});

  bool estaDisponible(DateTime checkIn, DateTime checkOut) {
    for (final reserva in reservas) {
      if (checkIn.isBefore(reserva.end) && checkOut.isAfter(reserva.start)) {
        return false; // Hay solapamiento
      }
    }
    return true;
  }
}

class HabitacionesRepository {
  final List<Habitacion> habitaciones = [
    Habitacion(numero: '101', tipo: 'Individual'),
    Habitacion(numero: '102', tipo: 'Doble'),
    Habitacion(numero: '103', tipo: 'Doble'),
    Habitacion(numero: '104', tipo: 'Doble'),
    Habitacion(numero: '105', tipo: 'Doble'),
    // Añadir más habitaciones
  ];

  List<Habitacion> obtenerHabitacionesDisponibles(DateTime checkIn, DateTime checkOut) {
    return habitaciones.where((habitacion) => habitacion.estaDisponible(checkIn, checkOut)).toList();
  }

  void reservarHabitacion(String numero, DateTime checkIn, DateTime checkOut) {
    final habitacion = habitaciones.firstWhere((h) => h.numero == numero);
    habitacion.reservas.add(DateTimeRange(start: checkIn, end: checkOut));
  }

  void liberarHabitacion(String numero) {
    final habitacion = habitaciones.firstWhere((h) => h.numero == numero);
    habitacion.reservas.clear();
  }
}

final HabitacionesRepository habitacionesRepository = HabitacionesRepository();

void mostrarHabitacionesDisponibles(BuildContext context, DateTime checkIn, DateTime checkOut) {
  final habitacionesDisponibles = habitacionesRepository.obtenerHabitacionesDisponibles(checkIn, checkOut);

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Habitaciones Disponibles'),
        content: SizedBox(
          height: 200.0,
          width: 300.0,
          child: ListView.builder(
            itemCount: habitacionesDisponibles.length,
            itemBuilder: (context, index) {
              final habitacion = habitacionesDisponibles[index];
              return ListTile(
                title: Text('Habitación ${habitacion.numero} - ${habitacion.tipo}'),
                trailing: habitacion.estaDisponible(checkIn, checkOut)
                    ? const Text('Disponible', style: TextStyle(color: Colors.green))
                    : const Text('Reservada', style: TextStyle(color: Colors.red)),
                onTap: habitacion.estaDisponible(checkIn, checkOut)
                    ? () {
                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: const Text('Confirmar Reserva'),
                              content: Text('¿Desea reservar la habitación ${habitacion.numero}?'),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: const Text('Cancelar'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    habitacionesRepository.reservarHabitacion(habitacion.numero, checkIn, checkOut);
                                    Navigator.of(context).pop(); // Cierra el cuadro de confirmación
                                    Navigator.of(context).pop(); // Cierra el cuadro de disponibilidad
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Habitación ${habitacion.numero} reservada exitosamente.')),
                                    );
                                  },
                                  child: const Text('Confirmar'),
                                ),
                              ],
                            );
                          },
                        );
                      }
                    : null,
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cerrar'),
          ),
        ],
      );
    },
  );
}
