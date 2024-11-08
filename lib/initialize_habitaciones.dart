
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

Future<void> initializeHabitaciones() async {
  // Inicializar Firebase si no lo has hecho
  await Firebase.initializeApp();

  CollectionReference habitacionesCollection = FirebaseFirestore.instance.collection('habitaciones');

  List<Map<String, dynamic>> habitaciones = [
    {'nombre': 'Cabaña 1', 'capacidad': 4},
    {'nombre': 'Cabaña 2', 'capacidad': 4},
    {'nombre': 'Cabaña 3', 'capacidad': 4},
    {'nombre': 'Cabaña 4', 'capacidad': 4},
    {'nombre': 'Cabaña 5', 'capacidad': 4},
    {'nombre': 'Cabaña 6', 'capacidad': 4},
  ];

  for (var habitacion in habitaciones) {
    await habitacionesCollection.add(habitacion);
  }

  print('Habitaciones inicializadas correctamente.');
}
