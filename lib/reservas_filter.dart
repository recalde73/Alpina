import 'package:flutter/material.dart';

class ReservasFilter extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onFilterChanged;

  ReservasFilter({required this.controller, required this.onFilterChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: 'Buscar por nombre o habitación',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.search),
        ),
        onChanged: onFilterChanged,
      ),
    );
  }
}
