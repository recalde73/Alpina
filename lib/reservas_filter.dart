import 'package:flutter/material.dart';

class ReservasFilter extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onFilterChanged;

  const ReservasFilter({super.key, required this.controller, required this.onFilterChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: TextField(
        controller: controller,
        decoration: const InputDecoration(
          labelText: 'Buscar por nombre o habitación',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.search),
        ),
        onChanged: onFilterChanged,
      ),
    );
  }
}
