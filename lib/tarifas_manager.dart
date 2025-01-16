import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TarifasManager {
  // Tarifas por cantidad de adultos
  final Map<int, double> tarifasPorAdultos = {
    1: 160000.0,
    2: 250000.0,
    3: 340000.0,
    4: 430000.0,
  };

  // Tarifa por niño
  final double tarifaPorNino = 50000.0;

  // Tarifa por late checkout
  final double tarifaLateCheckout = 20000.0;

  // Calcular el monto total
  double calcularMontoTotal({
    required int cantidadAdultos,
    required int cantidadNinos,
    required DateTime checkIn,
    required DateTime checkOut,
    required bool lateCheckout,
  }) {
    int cantidadDias = checkOut.difference(checkIn).inDays;
    if (cantidadDias <= 0) {
      cantidadDias = 1; // Mínimo un día
    }

    // Obtener tarifa base según la cantidad de adultos
    double tarifaBase = tarifasPorAdultos[cantidadAdultos] ?? 0.0;

    // Calcular costo por niños
    double costoNinos = cantidadNinos * tarifaPorNino * cantidadDias;

    // Calcular costo total
    double costoTotal = (tarifaBase * cantidadDias) + costoNinos;

    // Agregar costo por late checkout si aplica
    if (lateCheckout) {
      costoTotal += tarifaLateCheckout;
    }

    return costoTotal;
  }
}

// Widget para mostrar el cálculo del monto total y el saldo
class TarifaCalculator extends StatefulWidget {
  final int cantidadAdultos;
  final int cantidadNinos;
  final DateTime checkIn;
  final DateTime checkOut;
  final bool lateCheckout;
  final TextEditingController montoTotalController;
  final TextEditingController montoSenadoController;
  final Function(double montoTotal, double saldo) onMontoCalculado;

  const TarifaCalculator({
    super.key,
    required this.cantidadAdultos,
    required this.cantidadNinos,
    required this.checkIn,
    required this.checkOut,
    required this.lateCheckout,
    required this.montoTotalController,
    required this.montoSenadoController,
    required this.onMontoCalculado,
  });

  @override
  _TarifaCalculatorState createState() => _TarifaCalculatorState();
}

class _TarifaCalculatorState extends State<TarifaCalculator> {
  bool montoTotalEditable = false;
  double saldo = 0.0;
  final FocusNode _montoTotalFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Diferir la llamada a _calcularMontos()
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calcularMontos();
    });
    widget.montoSenadoController.addListener(_calcularSaldo);
    widget.montoTotalController.addListener(_calcularSaldo);
  }

  void _calcularMontos() {
    TarifasManager tarifasManager = TarifasManager();

    double calculatedMontoTotal = tarifasManager.calcularMontoTotal(
      cantidadAdultos: widget.cantidadAdultos,
      cantidadNinos: widget.cantidadNinos,
      checkIn: widget.checkIn,
      checkOut: widget.checkOut,
      lateCheckout: widget.lateCheckout,
    );

    if (!montoTotalEditable) {
      widget.montoTotalController.text = calculatedMontoTotal.toStringAsFixed(0);
    }

    _calcularSaldo();
  }

  void _calcularSaldo() {
    double montoTotal = double.tryParse(widget.montoTotalController.text) ?? 0.0;
    double montoSenado = double.tryParse(widget.montoSenadoController.text) ?? 0.0;
    saldo = montoTotal - montoSenado;

    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onMontoCalculado(montoTotal, saldo);
      });
    }
  }

  @override
  void didUpdateWidget(TarifaCalculator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cantidadAdultos != widget.cantidadAdultos ||
        oldWidget.cantidadNinos != widget.cantidadNinos ||
        oldWidget.checkIn != widget.checkIn ||
        oldWidget.checkOut != widget.checkOut ||
        oldWidget.lateCheckout != widget.lateCheckout) {
      _calcularMontos();
    }
  }

  @override
  void dispose() {
    _montoTotalFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Campo para 'Monto Total' con ícono de lápiz
        TextFormField(
          controller: widget.montoTotalController,
          focusNode: _montoTotalFocusNode,
          decoration: InputDecoration(
            labelText: 'Monto Total',
            suffixIcon: IconButton(
              icon: Icon(
                montoTotalEditable ? Icons.check : Icons.edit,
                color: Colors.green,
              ),
              onPressed: () {
                setState(() {
                  montoTotalEditable = !montoTotalEditable;
                  if (montoTotalEditable) {
                    FocusScope.of(context).requestFocus(_montoTotalFocusNode);
                  } else {
                    _calcularSaldo();
                    FocusScope.of(context).unfocus();
                  }
                });
              },
            ),
          ),
          keyboardType: TextInputType.number,
          enabled: true, // Siempre habilitado
          readOnly: !montoTotalEditable, // Controla si es editable
          onChanged: (value) {
            _calcularSaldo();
          },
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: widget.montoSenadoController,
          decoration: const InputDecoration(labelText: 'Monto Señado'),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor, ingrese el monto señado';
            } else if (double.tryParse(value) == null) {
              return 'Ingrese un número válido';
            }
            return null;
          },
          onChanged: (value) {
            _calcularSaldo();
          },
        ),
        const SizedBox(height: 10),
        Text(
          'Saldo: \$${saldo.toStringAsFixed(0)}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

