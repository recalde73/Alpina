import 'package:cloud_firestore/cloud_firestore.dart';

class HabitacionesRepository {
  final CollectionReference _habitacionesRef =
      FirebaseFirestore.instance.collection('habitaciones');

  Future<List<Map<String, dynamic>>> getHabitaciones() async {
    try {
      QuerySnapshot snapshot = await _habitacionesRef.get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'nombre': data['nombre'] ?? '',
          'capacidad': data['capacidad'] ?? 0,
          // Agrega más campos si los necesitas
        };
      }).toList();
    } catch (e) {
      print('Error al obtener habitaciones: $e');
      return [];
    }
  }
}
