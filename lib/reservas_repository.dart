import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ReservasRepository {
  final CollectionReference _reservasCollection =
      FirebaseFirestore.instance.collection('reservas');

  /// Obtiene todas las reservas desde Firestore y las mapea a List<Map<String, dynamic>>.
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
          'id': doc.id, // ID del documento en Firestore
        };
      }).toList();
    } catch (e) {
      print("Error al obtener reservas: $e");
      return [];
    }
  }

  /// Agrega una reserva nueva en Firestore.
  Future<void> addReserva(Map<String, dynamic> reserva) async {
    try {
      await _reservasCollection.add(reserva);
      print("Reserva añadida exitosamente en la base de datos.");
    } catch (e) {
      print("Error al agregar la reserva en la base de datos: $e");
      rethrow;
    }
  }

  /// Actualiza la reserva con [id] en Firestore con los datos de [reserva].
  Future<void> updateReserva(String id, Map<String, dynamic> reserva) async {
    try {
      await _reservasCollection.doc(id).update(reserva);
    } catch (e) {
      print("Error al actualizar reserva: $e");
    }
  }

  /// Elimina la reserva con [id] en Firestore.
  Future<void> deleteReserva(String id) async {
    try {
      await _reservasCollection.doc(id).delete();
    } catch (e) {
      print("Error al eliminar reserva: $e");
    }
  }

  /// Verifica si la [habitacionId] está disponible en el rango [checkIn, checkOut].
  /// Retorna `true` si no hay superposición de reservas, caso contrario `false`.
  Future<bool> isHabitacionDisponible(
    String habitacionId,
    DateTime checkIn,
    DateTime checkOut,
  ) async {
    try {
      QuerySnapshot snapshot = await _reservasCollection
          .where('habitacion', isEqualTo: habitacionId)
          .get();

      for (var doc in snapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;

        DateTime existingCheckIn = DateFormat('dd/MM/yyyy').parse(data['checkIn']);
        DateTime existingCheckOut = DateFormat('dd/MM/yyyy').parse(data['checkOut']);

        bool isOverlap =
            checkIn.isBefore(existingCheckOut) && checkOut.isAfter(existingCheckIn);
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

  // ----------------------------------------------------------------------------
  // NUEVO MÉTODO: Agrupar reservas por día (checkIn), opcionalmente filtrando
  // por un rango de fechas (fechaDesde, fechaHasta).
  // Retorna un Map donde la llave es 'dd/MM/yyyy' y el valor es la CANTIDAD de reservas.
  // ----------------------------------------------------------------------------
  Future<Map<String, int>> getReservasAgrupadasPorDia({
    DateTime? fechaDesde,
    DateTime? fechaHasta,
  }) async {
    try {
      // 1. Traemos todas las reservas desde Firestore (con el método existente).
      final allReservas = await getReservas();

      // 2. Filtramos en el lado del cliente, comparando las fechas con checkIn.
      final reservasFiltradas = allReservas.where((res) {
        final checkInStr = res['checkIn'] as String;
        if (checkInStr.isEmpty) return false;

        final checkInDate = DateFormat('dd/MM/yyyy').parse(checkInStr);

        // fechaDesde y fechaHasta son opcionales, si vienen null, no se filtra.
        final afterDesde = (fechaDesde == null) || !checkInDate.isBefore(fechaDesde);
        final beforeHasta = (fechaHasta == null) || !checkInDate.isAfter(fechaHasta);

        return afterDesde && beforeHasta;
      }).toList();

      // 3. Agrupamos las reservas filtradas por día de checkIn.
      final Map<String, int> mapaAgrupado = {};
      for (var reserva in reservasFiltradas) {
        final checkInStr = reserva['checkIn'] as String;
        mapaAgrupado[checkInStr] = (mapaAgrupado[checkInStr] ?? 0) + 1;
      }

      return mapaAgrupado;
    } catch (e) {
      print('Error en getReservasAgrupadasPorDia: $e');
      return {};
    }
  }
}





// Ejemplo de uso en otro archivo
// final reservasRepository = ReservasRepository();
// reservasRepository.addReserva({ 'nombre': 'Juan Pérez', 'habitacion': '101', ... });