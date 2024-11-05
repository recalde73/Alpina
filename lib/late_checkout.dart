import 'package:flutter/material.dart';

class LateCheckout {
  bool lateCheckout; // true si el late checkout está habilitado, false en caso contrario
  double tarifaLateCheckout; // Tarifa adicional para el late checkout

  LateCheckout({
    this.lateCheckout = false,
    this.tarifaLateCheckout = 20.0, // Tarifa por defecto, se puede ajustar
  });

  // Método para habilitar o deshabilitar late checkout
  void setLateCheckout(bool value) {
    lateCheckout = value;
  }

  // Método para obtener el monto adicional del late checkout
  double calcularTarifaAdicional() {
    return lateCheckout ? tarifaLateCheckout : 0.0;
  }
}

// Widget para gestionar la selección del late checkout
class LateCheckoutSelector extends StatefulWidget {
  final Function(bool) onLateCheckoutChanged; // Callback para manejar el cambio en la selección
  final bool initialSelection;

  const LateCheckoutSelector({
    Key? key,
    required this.onLateCheckoutChanged,
    this.initialSelection = false,
  }) : super(key: key);

  @override
  _LateCheckoutSelectorState createState() => _LateCheckoutSelectorState();
}

class _LateCheckoutSelectorState extends State<LateCheckoutSelector> {
  bool lateCheckoutSelected = false;

  @override
  void initState() {
    super.initState();
    lateCheckoutSelected = widget.initialSelection;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '¿Desea salir después del mediodía?',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Row(
          children: [
            Radio<bool>(
              value: true,
              groupValue: lateCheckoutSelected,
              onChanged: (value) {
                setState(() {
                  lateCheckoutSelected = value!;
                  widget.onLateCheckoutChanged(lateCheckoutSelected);
                });
              },
            ),
            const Text('Sí'),
            Radio<bool>(
              value: false,
              groupValue: lateCheckoutSelected,
              onChanged: (value) {
                setState(() {
                  lateCheckoutSelected = value!;
                  widget.onLateCheckoutChanged(lateCheckoutSelected);
                });
              },
            ),
            const Text('No'),
          ],
        ),
      ],
    );
  }
}

