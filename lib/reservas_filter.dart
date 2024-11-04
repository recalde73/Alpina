import 'package:flutter/material.dart';

class ReservasFilter extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onFilterChanged;
  final bool mostrarTodas;
  final Function(bool) onMostrarTodasChanged;

  const ReservasFilter({
    super.key,
    required this.controller,
    required this.onFilterChanged,
    required this.mostrarTodas,
    required this.onMostrarTodasChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        children: [
          TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Buscar por nombre o habitación',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: onFilterChanged,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Mostrar todas las reservas'),
              Switch(
                value: mostrarTodas,
                onChanged: (value) {
                  onMostrarTodasChanged(value);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

