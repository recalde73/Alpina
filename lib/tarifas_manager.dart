import 'package:flutter/material.dart';

class TarifasManager {
  // Tarifa base por tipo de habitación
  final Map<String, double> tarifasPorTipoHabitacion = {
    'Individual': 50.0,
    'Doble': 75.0,
    'Triple': 100.0,
    'Cuádruple': 120.0,
  };

  // Tarifa adicional por persona
  final double tarifaPorAdulto = 20.0;
  final double tarifaPorNino = 10.0;

  // Tarifa por late checkout
  final double tarifaLateCheckout = 20.0;

  // Calcular el monto total de la reserva
  double calcularMontoTotal({
    required String tipoHabitacion,
    required int cantidadAdultos,
    required int cantidadNinos,
    required DateTime checkIn,
    required DateTime checkOut,
    required bool lateCheckout,
  }) {
    // Obtener tarifa base por el tipo de habitación
    double tarifaBase = tarifasPorTipoHabitacion[tipoHabitacion] ?? 0.0;

    // Calcular duración de la estadía
    int cantidadDias = checkOut.difference(checkIn).inDays;
    if (cantidadDias <= 0) {
      cantidadDias = 1; // Mínimo 1 día de estadía
    }

    // Calcular el costo por la cantidad de personas
    double costoPorPersonas = (cantidadAdultos * tarifaPorAdulto) + (cantidadNinos * tarifaPorNino);

    // Calcular el costo base de la estadía (tarifa base por cantidad de días)
    double costoBase = tarifaBase * cantidadDias;

    // Calcular el costo total
    double costoTotal = costoBase + costoPorPersonas;

    // Agregar tarifa de late checkout si aplica
    if (lateCheckout) {
      costoTotal += tarifaLateCheckout;
    }

    return costoTotal;
  }
}

// Widget para mostrar el cálculo del monto total y el saldo
class TarifaCalculator extends StatefulWidget {
  final String tipoHabitacion;
  final int cantidadAdultos;
  final int cantidadNinos;
  final DateTime checkIn;
  final DateTime checkOut;
  final bool lateCheckout;
  final Function(double) onMontoCalculado;

  const TarifaCalculator({
    Key? key,
    required this.tipoHabitacion,
    required this.cantidadAdultos,
    required this.cantidadNinos,
    required this.checkIn,
    required this.checkOut,
    required this.lateCheckout,
    required this.onMontoCalculado,
  }) : super(key: key);

  @override
  _TarifaCalculatorState createState() => _TarifaCalculatorState();
}

class _TarifaCalculatorState extends State<TarifaCalculator> {
  late double montoTotal;
  late double montoSenado;
  late double saldo;

  final TextEditingController montoSenadoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _calcularMontoTotal();
  }

  void _calcularMontoTotal() {
    TarifasManager tarifasManager = TarifasManager();
    setState(() {
      montoTotal = tarifasManager.calcularMontoTotal(
        tipoHabitacion: widget.tipoHabitacion,
        cantidadAdultos: widget.cantidadAdultos,
        cantidadNinos: widget.cantidadNinos,
        checkIn: widget.checkIn,
        checkOut: widget.checkOut,
        lateCheckout: widget.lateCheckout,
      );
      montoSenado = 0.0; // Por defecto, el monto señado es 0
      saldo = montoTotal; // Saldo inicial igual al monto total
      widget.onMontoCalculado(montoTotal);
    });
  }

  void _actualizarSaldo() {
    setState(() {
      double senado = double.tryParse(montoSenadoController.text) ?? 0.0;
      montoSenado = senado;
      saldo = montoTotal - montoSenado;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        Text(
          'Monto Total: \$${montoTotal.toStringAsFixed(2)}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: montoSenadoController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Monto Señado',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            _actualizarSaldo();
          },
        ),
        const SizedBox(height: 10),
        Text(
          'Saldo: \$${saldo.toStringAsFixed(2)}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
