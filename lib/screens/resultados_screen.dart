import 'package:file_picker/file_picker.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' hide Colors, Card, showDialog;
import 'package:inventario_qr/models/resultado.model.dart';
import 'package:inventario_qr/providers/inventario.provider.dart';
import 'package:inventario_qr/repositories/inventario.repository.dart';
import 'package:inventario_qr/utils/math_utils.dart';
import 'package:open_file/open_file.dart';
import 'package:provider/provider.dart';

class ResultadosScreen extends StatefulWidget {
  const ResultadosScreen({super.key});

  @override
  State<ResultadosScreen> createState() => _ResultadosScreenState();
}

class _ResultadosScreenState extends State<ResultadosScreen> {
  bool _isStatisticsExpanded = false;
  bool _isExtremesExpanded = false;
  bool _isChartsExpanded = false;

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      header: PageHeader(
        title: Row(
          children: [
            Button(
              onPressed: () => Navigator.pop(context),
              child: const Icon(FluentIcons.back, size: 20),
            ),
            const SizedBox(width: 8),
            const Text('Resultados del Modelo QR'),
            const Spacer(),
            Consumer<InventarioProvider>(
              builder: (context, provider, child) {
                if (provider.resultado == null) {
                  return const SizedBox.shrink();
                }
                return Button(
                  onPressed: () => _exportarResultadosExcel(context),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(FluentIcons.excel_document, size: 16),
                      SizedBox(width: 4),
                      Text('Exportar Excel'),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
      content: Consumer<InventarioProvider>(
        builder: (context, provider, child) {
          debugPrint('📊 ResultadosScreen: Consumer reconstruyendo');
          debugPrint('📊 ResultadosScreen: Resultado disponible: ${provider.resultado != null}');
          debugPrint('📊 ResultadosScreen: Artículos disponibles: ${provider.articulos.length}');
          
          if (provider.resultado == null) {
            debugPrint('📊 ResultadosScreen: No hay resultados disponibles');
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(FluentIcons.calculator, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No hay resultados disponibles',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Ejecuta los cálculos desde la pantalla principal',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          debugPrint('📊 ResultadosScreen: Mostrando resultados');
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSystemSummary(provider),
                const SizedBox(height: 24),
                _buildResultsTable(provider),
                const SizedBox(height: 24),
                _buildDetailedResults(provider),
                const SizedBox(height: 24),
                _buildChartsSection(provider),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSystemSummary(InventarioProvider provider) {
    final resultado = provider.resultado!;
    final estadisticas = InventarioRepository.calcularEstadisticas(resultado);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(FluentIcons.info, color: Colors.blue),
                const SizedBox(width: 12),
                const Text(
                  'Resumen del Sistema',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Primera fila - Métricas principales
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    'Costo Total',
                    MathUtils.formatearMoneda(resultado.costoTotalSistema),
                    FluentIcons.money,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItemWithConstraint(
                    'Espacio Usado',
                    MathUtils.formatearUnidades(resultado.espacioTotalUsado, 'm²'),
                    FluentIcons.database,
                    Colors.blue,
                    (resultado.espacioTotalUsado / provider.espacioMaximo) * 100,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItemWithConstraint(
                    'Presupuesto',
                    MathUtils.formatearMoneda(resultado.presupuestoTotal),
                    FluentIcons.calculator,
                    Colors.orange,
                    (resultado.presupuestoTotal / provider.presupuestoMaximo) * 100,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItemWithConstraint(
                    'Número de Pedidos',
                    resultado.numeroTotalPedidos.toString(),
                    FluentIcons.package,
                    Colors.purple,
                    (resultado.numeroTotalPedidos / provider.numeroMaximoPedidos) * 100,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Segunda fila - Métricas adicionales
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    'Total Artículos',
                    resultado.resultados.length.toString(),
                    FluentIcons.list,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    'Costo Promedio/Artículo',
                    MathUtils.formatearMoneda(resultado.costoTotalSistema / resultado.resultados.length),
                    FluentIcons.calculator,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    'Espacio Promedio/Artículo',
                    MathUtils.formatearUnidades(resultado.espacioTotalUsado / resultado.resultados.length, 'm²'),
                    FluentIcons.database,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    'Pedidos Promedio/Artículo',
                    (resultado.numeroTotalPedidos / resultado.resultados.length).toStringAsFixed(1),
                    FluentIcons.package,
                    Colors.purple,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Tercera fila - Análisis de extremos (desplegable)
            _buildExpandableExtremes(resultado, estadisticas),
            
            const SizedBox(height: 24),
            Container(
              height: 1,
              color: Colors.grey.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            _buildExpandableStatistics(estadisticas),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 32, color: color),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryItemWithConstraint(String title, String value, IconData icon, Color color, double constraintPercentage) {
    Color progressColor;
    
    if (constraintPercentage <= 70) {
      progressColor = Colors.green;
    } else if (constraintPercentage <= 90) {
      progressColor = Colors.orange;
    } else {
      progressColor = Colors.red;
    }

    return Column(
      children: [
        Icon(icon, size: 32, color: color),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        // Barra de progreso compacta con espacio independiente
        Container(
          width: double.infinity,
          height: 4,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: constraintPercentage / 100,
            child: Container(
              decoration: BoxDecoration(
                color: progressColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${constraintPercentage.toStringAsFixed(0)}%',
          style: TextStyle(
            fontSize: 10,
            color: progressColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildSummaryItemWithDetails(String title, String detail, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 32, color: color),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          detail,
          style: TextStyle(
            fontSize: 10,
            color: Colors.blue,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildExpandableExtremes(ResultadoSistema resultado, Map<String, dynamic> estadisticas) {
    return Column(
      children: [
        Button(
          onPressed: () => setState(() => _isExtremesExpanded = !_isExtremesExpanded),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  _isExtremesExpanded ? FluentIcons.chevron_down : FluentIcons.chevron_right,
                  color: Colors.blue,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Icon(FluentIcons.chart, color: Colors.blue, size: 16),
                const SizedBox(width: 8),
                const Text(
                  'Análisis de Extremos',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const Spacer(),
                Text(
                  _isExtremesExpanded ? 'Ocultar' : 'Mostrar',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_isExtremesExpanded) ...[
          const SizedBox(height: 16),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            child: Row(
              children: [
                Expanded(
                  child: _buildSummaryItemWithDetails(
                    'Artículo Más Costoso',
                    estadisticas['articuloMasCostoso'] as String,
                    MathUtils.formatearMoneda(resultado.resultados.reduce((a, b) => a.costoTotal > b.costoTotal ? a : b).costoTotal),
                    FluentIcons.warning,
                    Colors.red,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItemWithDetails(
                    'Artículo Menos Costoso',
                    estadisticas['articuloMenosCostoso'] as String,
                    MathUtils.formatearMoneda(resultado.resultados.reduce((a, b) => a.costoTotal < b.costoTotal ? a : b).costoTotal),
                    FluentIcons.check_mark,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItemWithDetails(
                    'Mayor Espacio',
                    estadisticas['articuloMasEspacio'] as String,
                    MathUtils.formatearUnidades(resultado.resultados.reduce((a, b) => a.espacioUsado > b.espacioUsado ? a : b).espacioUsado, 'm²'),
                    FluentIcons.database,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItemWithDetails(
                    'Menor Espacio',
                    estadisticas['articuloMenosEspacio'] as String,
                    MathUtils.formatearUnidades(resultado.resultados.reduce((a, b) => a.espacioUsado < b.espacioUsado ? a : b).espacioUsado, 'm²'),
                    FluentIcons.database,
                    Colors.blue,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildResultsTable(InventarioProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(FluentIcons.table, color: Colors.blue),
                const SizedBox(width: 12),
                const Text(
                  'Resultados por Artículo',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Artículo')),
                  DataColumn(label: Text('Q')),
                  DataColumn(label: Text('R')),
                  DataColumn(label: Text('Z-Score')),
                  DataColumn(label: Text('Backorders')),
                  DataColumn(label: Text('Costo Total')),
                  DataColumn(label: Text('Espacio')),
                ],
                rows: provider.resultado!.resultados.map((resultado) {
                  return DataRow(
                    cells: [
                      DataCell(Text(resultado.nombre)),
                      DataCell(Text(resultado.tamanoLote.toStringAsFixed(0))),
                      DataCell(Text(resultado.puntoReorden.toStringAsFixed(0))),
                      DataCell(Text(resultado.zScore.toStringAsFixed(2))),
                      DataCell(Text(resultado.backordersEsperados.toStringAsFixed(2))),
                      DataCell(Text(MathUtils.formatearMoneda(resultado.costoTotal))),
                      DataCell(Text(MathUtils.formatearUnidades(resultado.espacioUsado, 'm²'))),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedResults(InventarioProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(FluentIcons.document, color: Colors.blue),
                const SizedBox(width: 12),
                const Text(
                  'Detalles por Artículo',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: [
                  const DataColumn(label: Text('Parámetro')),
                  ...provider.resultado!.resultados.map((resultado) {
                    return DataColumn(
                      label: Text(resultado.nombre),
                    );
                  }),
                ],
                rows: <DataRow>[
                  _buildParameterRow('Tamaño de Lote (Q)', provider.resultado!.resultados.map((r) => r.tamanoLote.toStringAsFixed(0)).toList()),
                  _buildParameterRow('Punto de Reorden (R)', provider.resultado!.resultados.map((r) => r.puntoReorden.toStringAsFixed(0)).toList()),
                  _buildParameterRow('Z-Score', provider.resultado!.resultados.map((r) => r.zScore.toStringAsFixed(2)).toList()),
                  _buildParameterRow('Backorders Esperados', provider.resultado!.resultados.map((r) => r.backordersEsperados.toStringAsFixed(2)).toList()),
                  _buildParameterRow('Costo de Pedidos', provider.resultado!.resultados.map((r) => MathUtils.formatearMoneda(r.costoPedidos)).toList()),
                  _buildParameterRow('Costo de Mantenimiento', provider.resultado!.resultados.map((r) => MathUtils.formatearMoneda(r.costoMantenimiento)).toList()),
                  _buildParameterRow('Costo de Servicio', provider.resultado!.resultados.map((r) => MathUtils.formatearMoneda(r.costoServicio)).toList()),
                  _buildParameterRow('Costo Total', provider.resultado!.resultados.map((r) => MathUtils.formatearMoneda(r.costoTotal)).toList()),
                  _buildParameterRow('Espacio Usado', provider.resultado!.resultados.map((r) => MathUtils.formatearUnidades(r.espacioUsado, 'm²')).toList()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  DataRow _buildParameterRow(String parameter, List<String> values) {
    return DataRow(
      cells: [
        DataCell(
          Text(
            parameter,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
        ),
        ...values.map((value) => DataCell(Text(value))),
      ],
    );
  }

  Widget _buildExpandableStatistics(Map<String, dynamic> estadisticas) {
    return Column(
      children: [
        Button(
          onPressed: () => setState(() => _isStatisticsExpanded = !_isStatisticsExpanded),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  _isStatisticsExpanded ? FluentIcons.chevron_down : FluentIcons.chevron_right,
                  color: Colors.blue,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Icon(FluentIcons.chart, color: Colors.blue, size: 16),
                const SizedBox(width: 8),
                const Text(
                  'Estadísticas Promedio',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const Spacer(),
                Text(
                  _isStatisticsExpanded ? 'Ocultar' : 'Mostrar',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_isStatisticsExpanded) ...[
          const SizedBox(height: 16),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            child: Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    'Costo Promedio',
                    MathUtils.formatearMoneda(estadisticas['costoPromedio']),
                    FluentIcons.money,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    'Espacio Promedio',
                    MathUtils.formatearUnidades(estadisticas['espacioPromedio'], 'm²'),
                    FluentIcons.database,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    'Z-Score Promedio',
                    estadisticas['zScorePromedio'].toStringAsFixed(2),
                    FluentIcons.calculator,
                    Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    'Mediana Costo',
                    MathUtils.formatearMoneda(estadisticas['medianaCosto']),
                    FluentIcons.chart,
                    Colors.purple,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildChartsSection(InventarioProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(FluentIcons.chart, color: Colors.blue),
                const SizedBox(width: 12),
                const Text(
                  'Visualización de Datos',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildExpandableCharts(provider),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandableCharts(InventarioProvider provider) {
    return Column(
      children: [
        Button(
          onPressed: () => setState(() => _isChartsExpanded = !_isChartsExpanded),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  _isChartsExpanded ? FluentIcons.chevron_down : FluentIcons.chevron_right,
                  color: Colors.blue,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Icon(FluentIcons.chart, color: Colors.blue, size: 16),
                const SizedBox(width: 8),
                const Text(
                  'Gráficas y Análisis',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const Spacer(),
                Text(
                  _isChartsExpanded ? 'Ocultar' : 'Mostrar',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_isChartsExpanded) ...[
          const SizedBox(height: 16),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            child: Column(
              children: [
                // Gráfica de costos por artículo
                _buildCostChart(provider),
                const SizedBox(height: 24),
                // Gráfica de espacio por artículo
                _buildSpaceChart(provider),
                const SizedBox(height: 24),
                // Gráfica de Z-Score por artículo
                _buildZScoreChart(provider),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCostChart(InventarioProvider provider) {
    final resultados = provider.resultado!.resultados;
    final barGroups = resultados.asMap().entries.map((entry) {
      final index = entry.key;
      final resultado = entry.value;
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: resultado.costoTotal,
            color: Colors.blue,
            width: 20,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
        ],
      );
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Costos por Artículo',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: resultados.map((r) => r.costoTotal).reduce((a, b) => a > b ? a : b) * 1.2,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final resultado = resultados[group.x];
                    return BarTooltipItem(
                      '${resultado.nombre}\n${MathUtils.formatearMoneda(rod.toY)}',
                      const TextStyle(color: Colors.white),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                rightTitles: const AxisTitles(),
                topTitles: const AxisTitles(),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() >= 0 && value.toInt() < resultados.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            resultados[value.toInt()].nombre,
                            style: const TextStyle(fontSize: 10),
                            textAlign: TextAlign.center,
                          ),
                        );
                      }
                      return const Text('');
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 60,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        MathUtils.formatearMoneda(value),
                        style: const TextStyle(fontSize: 10),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              barGroups: barGroups,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSpaceChart(InventarioProvider provider) {
    final resultados = provider.resultado!.resultados;
    final barGroups = resultados.asMap().entries.map((entry) {
      final index = entry.key;
      final resultado = entry.value;
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: resultado.espacioUsado,
            color: Colors.green,
            width: 20,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
        ],
      );
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Espacio por Artículo',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: resultados.map((r) => r.espacioUsado).reduce((a, b) => a > b ? a : b) * 1.2,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final resultado = resultados[group.x];
                    return BarTooltipItem(
                      '${resultado.nombre}\n${MathUtils.formatearUnidades(rod.toY, 'm²')}',
                      const TextStyle(color: Colors.white),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                rightTitles: const AxisTitles(),
                topTitles: const AxisTitles(),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() >= 0 && value.toInt() < resultados.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            resultados[value.toInt()].nombre,
                            style: const TextStyle(fontSize: 10),
                            textAlign: TextAlign.center,
                          ),
                        );
                      }
                      return const Text('');
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 60,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        MathUtils.formatearUnidades(value, 'm²'),
                        style: const TextStyle(fontSize: 10),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              barGroups: barGroups,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildZScoreChart(InventarioProvider provider) {
    final resultados = provider.resultado!.resultados;
    final barGroups = resultados.asMap().entries.map((entry) {
      final index = entry.key;
      final resultado = entry.value;
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: resultado.zScore,
            color: resultado.zScore > 0 ? Colors.orange : Colors.red,
            width: 20,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
        ],
      );
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Z-Score por Artículo',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: resultados.map((r) => r.zScore).reduce((a, b) => a > b ? a : b) * 1.2,
              minY: resultados.map((r) => r.zScore).reduce((a, b) => a < b ? a : b) * 1.2,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final resultado = resultados[group.x];
                    return BarTooltipItem(
                      '${resultado.nombre}\nZ-Score: ${rod.toY.toStringAsFixed(2)}',
                      const TextStyle(color: Colors.white),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                rightTitles: const AxisTitles(),
                topTitles: const AxisTitles(),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() >= 0 && value.toInt() < resultados.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            resultados[value.toInt()].nombre,
                            style: const TextStyle(fontSize: 10),
                            textAlign: TextAlign.center,
                          ),
                        );
                      }
                      return const Text('');
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 60,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toStringAsFixed(1),
                        style: const TextStyle(fontSize: 10),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              barGroups: barGroups,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _exportarResultadosExcel(BuildContext context) async {
    final provider = context.read<InventarioProvider>();
    
    if (provider.resultado == null) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return ContentDialog(
            title: const Text('Error'),
            content: const Text('No hay resultados disponibles para exportar'),
            actions: [
              Button(
                onPressed: () => Navigator.pop(context),
                child: const Text('Aceptar'),
              ),
            ],
          );
        },
      );
      return;
    }

    try {
      debugPrint('📤 Iniciando exportación de resultados a Excel...');
      
      // Preguntar dónde guardar el archivo
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Guardar archivo Excel',
        fileName: 'resultados_inventario_qr.xlsx',
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      if (outputFile == null) {
        debugPrint('❌ Usuario canceló la selección de ubicación');
        return;
      }

      debugPrint('📁 Ubicación seleccionada: $outputFile');
      
      // Llamar al método de exportación del provider
      await provider.exportarResultadosExcel(outputFile);
      
      debugPrint('✅ Resultados exportados exitosamente');
      
      // Preguntar si desea abrir el archivo
      if (context.mounted) {
        final bool? abrirArchivo = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return ContentDialog(
              title: const Text('Exportación Completada'),
              content: const Text('Los resultados se han exportado correctamente. ¿Deseas abrir el archivo Excel?'),
              actions: [
                Button(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('No'),
                ),
                Button(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Sí, abrir'),
                ),
              ],
            );
          },
        );

        if (abrirArchivo == true) {
          debugPrint('📂 Abriendo archivo Excel...');
          final result = await OpenFile.open(outputFile);
          if (result.type != ResultType.done) {
            debugPrint('❌ Error al abrir archivo: ${result.message}');
            if (context.mounted) {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return ContentDialog(
                    title: const Text('Error'),
                    content: Text('No se pudo abrir el archivo: ${result.message}'),
                    actions: [
                      Button(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Aceptar'),
                      ),
                    ],
                  );
                },
              );
            }
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Error al exportar resultados: $e');
      
      // Mostrar mensaje de error
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return ContentDialog(
              title: const Text('Error'),
              content: Text('Error al exportar resultados: $e'),
              actions: [
                Button(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Aceptar'),
                ),
              ],
            );
          },
        );
      }
    }
  }
} 