import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

// Asegúrate de ajustar la ruta real hacia tu ReservasRepository
import 'package:Alpina/reservas_repository.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({Key? key}) : super(key: key);

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  // Fechas para filtrar
  DateTime? _fechaDesde;
  DateTime? _fechaHasta;

  // Estado de carga y datos agrupados
  bool _isLoading = false;
  Map<String, int> _reservasPorDia = {};

  // Instancia del repositorio de reservas
  final ReservasRepository _reservasRepository = ReservasRepository();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reporte'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Filtros: fecha DESDE, fecha HASTA y botón "Filtrar"
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: _seleccionarFechaDesde,
                    child: Text(
                      _fechaDesde == null
                          ? 'DESDE'
                          : 'DESDE: ${DateFormat("dd/MM/yyyy").format(_fechaDesde!)}',
                    ),
                  ),
                ),
                Expanded(
                  child: TextButton(
                    onPressed: _seleccionarFechaHasta,
                    child: Text(
                      _fechaHasta == null
                          ? 'HASTA'
                          : 'HASTA: ${DateFormat("dd/MM/yyyy").format(_fechaHasta!)}',
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: _filtrarDatos,
                  child: const Text('Filtrar'),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Contenido principal: carga, mensaje o el gráfico
            _isLoading
                ? const CircularProgressIndicator()
                : _reservasPorDia.isEmpty
                    ? const Text('No hay datos para mostrar')
                    : Expanded(
                        child: _buildBarChart(),
                      ),
          ],
        ),
      ),
    );
  }

  /// Muestra un DatePicker para seleccionar la fecha DESDE
  Future<void> _seleccionarFechaDesde() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _fechaDesde = picked;
      });
    }
  }

  /// Muestra un DatePicker para seleccionar la fecha HASTA
  Future<void> _seleccionarFechaHasta() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _fechaHasta = picked;
      });
    }
  }

  /// Llama al repositorio, filtra por rango de fechas y agrupa resultados por día
  Future<void> _filtrarDatos() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Obtener todas las reservas
      final reservas = await _reservasRepository.getReservas();

      // Filtrar en el cliente según _fechaDesde y _fechaHasta
      final filtro = reservas.where((res) {
        // Se asume que res['checkIn'] es 'dd/MM/yyyy'
        final dateCheckIn = DateFormat('dd/MM/yyyy').parse(res['checkIn']);
        // Validar con _fechaDesde y _fechaHasta (si no son nulas)
        final desdeOk = _fechaDesde == null || !dateCheckIn.isBefore(_fechaDesde!);
        final hastaOk = _fechaHasta == null || !dateCheckIn.isAfter(_fechaHasta!);
        return desdeOk && hastaOk;
      }).toList();

      // Agrupar las reservas filtradas por día de checkIn
      final mapaReservas = await _reservasRepository.getReservasAgrupadasPorDia(
        fechaDesde: _fechaDesde,
        fechaHasta: _fechaHasta,
      );


      setState(() {
        _reservasPorDia = mapaReservas;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // Manejo de error: podría mostrar un diálogo, etc.
      debugPrint('Error al filtrar datos: $e');
    }
  }

  /// Construye el widget del BarChart con fl_chart, usando _reservasPorDia
  Widget _buildBarChart() {
    // Ordenar las fechas (keys) para mostrarlas de forma cronológica
    final sortedKeys = _reservasPorDia.keys.toList()
      ..sort((a, b) {
        final dateA = DateFormat('dd/MM/yyyy').parse(a);
        final dateB = DateFormat('dd/MM/yyyy').parse(b);
        return dateA.compareTo(dateB);
      });

    // Crear grupos de barras para cada fecha
    final List<BarChartGroupData> barGroups = [];
    for (int i = 0; i < sortedKeys.length; i++) {
      final fechaStr = sortedKeys[i];
      final valor = _reservasPorDia[fechaStr] ?? 0;

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: valor.toDouble(),
              color: Colors.green, // Color de la barra
              width: 16,           // Grosor de la barra
            ),
          ],
        ),
      );
    }

    // Determinar el valor máximo en Y para darle un poco de margen
    final maxY = barGroups
        .map((group) => group.barRods.first.toY)
        .fold<double>(0, (prev, curr) => curr > prev ? curr : prev);

    return BarChart(
      BarChartData(
        maxY: maxY + 1, // Se le suma 1 para que no quede pegado al borde
        barGroups: barGroups,
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          checkToShowHorizontalLine: (value) => value % 1 == 0, // líneas en cada entero
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.grey.shade300,
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),    // Sin títulos arriba
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),  // Sin títulos a la derecha
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1, // Paso entre valores del eje Y
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                // Muestra solo enteros
                if (value % 1 == 0) {
                  return Text(value.toInt().toString());
                }
                return const SizedBox();
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              // Muestra la fecha en el eje X
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= sortedKeys.length) {
                  return const SizedBox();
                }
                // Por ejemplo: "03/06"
                final label = sortedKeys[index].substring(0, 5);
                return Text(label, style: const TextStyle(fontSize: 10));
              },
            ),
          ),
        ),
      ),
    );
  }
}
