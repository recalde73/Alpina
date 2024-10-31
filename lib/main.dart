import 'package:flutter/material.dart';
import 'reservas_screen.dart';

void main() {
  runApp(const AlpinaApp());
}

class AlpinaApp extends StatelessWidget {
  const AlpinaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestión de Reservas',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: const ReservasScreen(),
    );
  }
}

