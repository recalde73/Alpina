import 'package:flutter/material.dart';

Widget buildDismissibleReserva({
  required BuildContext context,
  required int index,
  required Map<String, dynamic> reserva,
  required VoidCallback onDismissed,
  required VoidCallback onCardTap,
}) {
  return Dismissible(
    key: UniqueKey(),
    direction: DismissDirection.endToStart,
    confirmDismiss: (direction) async {
      return await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Confirmar eliminación"),
            content: const Text("¿Estás seguro de que deseas eliminar esta reserva?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text("Cancelar"),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text("Eliminar"),
              ),
            ],
          );
        },
      );
    },
    onDismissed: (_) => onDismissed(),
    background: Container(
      color: Colors.red,
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Icon(Icons.delete, color: Colors.white), // Agrega el ícono de basurero
          SizedBox(width: 8),
          Text("Eliminar", style: TextStyle(color: Colors.white)),
        ],
      ),
    ),
    child: Card(
      color: Colors.green[100],
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: ListTile(
        title: Text('${reserva['habitacion']} - ${reserva['nombre']}'),
        subtitle: Text('Teléfono: ${reserva['telefono']}\nAdultos: ${reserva['adultos']}, Niños: ${reserva['ninos']}\nCheck-in: ${reserva['checkIn']}\nCheck-out: ${reserva['checkOut']}\nObservaciones: ${reserva['observaciones']}'),
        onTap: onCardTap,
      ),
    ),
  );
}
