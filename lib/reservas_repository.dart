import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ReservasRepository {
  final CollectionReference _reservasCollection = FirebaseFirestore.instance.collection('reservas');

  Future<List<Map<String, dynamic>>> getReservas() async {
    try {
      QuerySnapshot snapshot = await _reservasCollection.get();
      return snapshot.docs.map((doc) {
        var data = doc.data() as Map<String, dynamic>;
        return {
          'habitacion': data['habitacion'] ?? '',
          'nombre': data['nombre'] ?? '',
          'cantidad': data['cantidad'] ?? 0,
          'telefono': data['telefono'] ?? '',
          'adultos': data['adultos'] ?? 0,
          'ninos': data['ninos'] ?? 0,
          'checkIn': data['checkIn'] ?? '',
          'checkOut': data['checkOut'] ?? '',
          'observaciones': data['observaciones'] ?? '',
          'montoTotal': data['montoTotal'] ?? 0.0,
          'montoSenado': data['montoSenado'] ?? 0.0,
          'saldo': data['saldo'] ?? 0.0,
          'lateCheckout': data['lateCheckout'] ?? false,
          'id': doc.id, // Incluye el ID del documento para futuras operaciones
        };
      }).toList();
    } catch (e) {
      print("Error al obtener reservas: $e");
      return [];
    }
  }

  Future<void> addReserva(Map<String, dynamic> reserva) async {
    try {
      await _reservasCollection.add(reserva);
      print("Reserva añadida exitosamente en la base de datos.");
    } catch (e) {
      print("Error al agregar la reserva en la base de datos: $e");
      rethrow;
    }
  }

  Future<void> updateReserva(String id, Map<String, dynamic> reserva) async {
    try {
      await _reservasCollection.doc(id).update(reserva);
    } catch (e) {
      print("Error al actualizar reserva: $e");
    }
  }

  Future<void> deleteReserva(String id) async {
    try {
      await _reservasCollection.doc(id).delete();
    } catch (e) {
      print("Error al eliminar reserva: $e");
    }
  }

  // Mover el método dentro de la clase
  Future<bool> isHabitacionDisponible(String habitacionId, DateTime checkIn, DateTime checkOut) async {
    try {
      QuerySnapshot snapshot = await _reservasCollection
          .where('habitacion', isEqualTo: habitacionId) // Cambiado a 'habitacion'
          .get();

      for (var doc in snapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        DateTime existingCheckIn = DateFormat('dd/MM/yyyy').parse(data['checkIn']);
        DateTime existingCheckOut = DateFormat('dd/MM/yyyy').parse(data['checkOut']);

        bool isOverlap = checkIn.isBefore(existingCheckOut) && checkOut.isAfter(existingCheckIn);
        if (isOverlap) {
          return false; // Hay conflicto de fechas
        }
      }
      return true; // No hay conflicto
    } catch (e) {
      print("Error al verificar disponibilidad: $e");
      return false;
    }
  }
}




// Ejemplo de uso en otro archivo
// final reservasRepository = ReservasRepository();
// reservasRepository.addReserva({ 'nombre': 'Juan Pérez', 'habitacion': '101', ... });