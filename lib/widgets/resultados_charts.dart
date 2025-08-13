// ignore: directives_ordering
import 'dart:io' show File if (dart.library.html) '';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:inventario_qr/models/resultado.model.dart';
import 'package:inventario_qr/utils/theme_colors.dart';
import 'package:inventario_qr/utils/web_download_stub.dart'
    if (dart.library.html) 'package:inventario_qr/utils/web_download_html.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

enum ChartDisplayType {
  combinedLine,           // Línea combinada normalizada (Costo, Espacio, Z)
  barCosts,               // Barras: costos por artículo
  stackedCostBreakdown,   // Barras apiladas: costoPedidos, costoMantenimiento, costoServicio
  barSpaceUsed,           // Barras horizontales: espacio usado por artículo
  barBackorders,          // Barras: Backorders esperados por artículo
  zScoreDistribution,     // Barras: Z-Score por artículo
}

class ChartData {
  ChartData(this.nombre, this.valor);
  final String nombre;
  final double valor;
}

class ResultadosCharts extends StatefulWidget {
  const ResultadosCharts({super.key, required this.resultado, this.initialType = ChartDisplayType.combinedLine});

  final ResultadoSistema resultado;
  final ChartDisplayType initialType;

  @override
  State<ResultadosCharts> createState() => _ResultadosChartsState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties..add(DiagnosticsProperty<ResultadoSistema>('resultado', resultado))
    ..add(EnumProperty<ChartDisplayType>('initialType', initialType));
  }
}

class _ResultadosChartsState extends State<ResultadosCharts> {
  late ChartDisplayType _type;
  final GlobalKey _chartKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
  }

  String _truncar(String nombre, {int max = 15}) {
    if (nombre.length <= max) {
      return nombre;
    }
    return '${nombre.substring(0, max - 3)}...';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(EnumProperty<ChartDisplayType>('initialType', widget.initialType))
      ..add(DiagnosticsProperty<ResultadoSistema>('resultado', widget.resultado));
  }

  @override
  Widget build(BuildContext context) {
    final resultados = widget.resultado.resultados;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.analytics, color: MDSJColors.primary),
            const SizedBox(width: 12),
            const Text(
              'Visualización de Datos',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: MDSJColors.textPrimary),
            ),
            const Spacer(),
            Tooltip(
              message: 'Exportar gráfico como PNG',
              child: IconButton(
                icon: const Icon(Icons.download),
                onPressed: _exportChartAsImage,
              ),
            ),
            DropdownButtonHideUnderline(
              child: DropdownButton<ChartDisplayType>(
                value: _type,
                items: const [
                  DropdownMenuItem(
                    value: ChartDisplayType.combinedLine,
                    child: Text('Línea combinada (normalizada)'),
                  ),
                  DropdownMenuItem(
                    value: ChartDisplayType.barCosts,
                    child: Text('Barras: Costos por artículo'),
                  ),
                  DropdownMenuItem(
                    value: ChartDisplayType.stackedCostBreakdown,
                    child: Text('Barras apiladas: Detalle de costos'),
                  ),
                  DropdownMenuItem(
                    value: ChartDisplayType.barSpaceUsed,
                    child: Text('Barras: Espacio usado (m²)'),
                  ),
                  DropdownMenuItem(
                    value: ChartDisplayType.barBackorders,
                    child: Text('Barras: Backorders esperados'),
                  ),
                  DropdownMenuItem(
                    value: ChartDisplayType.zScoreDistribution,
                    child: Text('Barras: Distribución Z-Score'),
                  ),
                ],
                onChanged: (v) => setState(() => _type = v ?? _type),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        RepaintBoundary(
          key: _chartKey,
          child: switch (_type) {
            ChartDisplayType.combinedLine => _buildCombined(resultados),
            ChartDisplayType.barCosts => _buildBars(resultados),
            ChartDisplayType.stackedCostBreakdown => _buildStackedCosts(resultados),
            ChartDisplayType.barSpaceUsed => _buildSpaceBars(resultados),
            ChartDisplayType.barBackorders => _buildBackordersBars(resultados),
            ChartDisplayType.zScoreDistribution => _buildZScoreBars(resultados),
          },
        ),
      ],
    );
  }

  Widget _buildCombined(List<ResultadoArticulo> resultados) {
    double maxCosto = 0;
    double maxEspacio = 0;
    double maxZScore = 0;
    for (final r in resultados) {
      if (r.costoTotal > maxCosto) {
        maxCosto = r.costoTotal;
      }
      if (r.espacioUsado > maxEspacio) {
        maxEspacio = r.espacioUsado;
      }
      if (r.zScore > maxZScore) {
        maxZScore = r.zScore;
      }
    }

    final costos = resultados.map((r) => ChartData(_truncar(r.nombre), (r.costoTotal / maxCosto) * 100)).toList();
    final espacios = resultados.map((r) => ChartData(_truncar(r.nombre), (r.espacioUsado / maxEspacio) * 100)).toList();
    final zscores = resultados.map((r) => ChartData(_truncar(r.nombre), (r.zScore / maxZScore) * 100)).toList();

    return SizedBox(
      height: 320,
      child: SfCartesianChart(
        primaryXAxis: const CategoryAxis(labelStyle: TextStyle(fontSize: 10), labelRotation: 45),
        primaryYAxis: const NumericAxis(labelStyle: TextStyle(fontSize: 10), minimum: 0, maximum: 100, interval: 20),
        legend: const Legend(isVisible: true, position: LegendPosition.bottom),
        tooltipBehavior: TooltipBehavior(enable: true, format: 'point.x\npoint.y%', header: 'series.name'),
        series: <CartesianSeries<dynamic, dynamic>>[
          LineSeries<ChartData, String>(
            dataSource: costos,
            xValueMapper: (d, _) => d.nombre,
            yValueMapper: (d, _) => d.valor,
            name: 'Costo Total (%)',
            color: MDSJColors.primary,
            width: 3,
            markerSettings: const MarkerSettings(isVisible: true, width: 6, height: 6),
          ),
          LineSeries<ChartData, String>(
            dataSource: espacios,
            xValueMapper: (d, _) => d.nombre,
            yValueMapper: (d, _) => d.valor,
            name: 'Espacio Usado (%)',
            color: MDSJColors.success,
            width: 3,
            markerSettings: const MarkerSettings(isVisible: true, width: 6, height: 6),
          ),
          LineSeries<ChartData, String>(
            dataSource: zscores,
            xValueMapper: (d, _) => d.nombre,
            yValueMapper: (d, _) => d.valor,
            name: 'Z-Score (%)',
            color: MDSJColors.warning,
            width: 3,
            markerSettings: const MarkerSettings(isVisible: true, width: 6, height: 6),
          ),
        ],
      ),
    );
  }

  Widget _buildBars(List<ResultadoArticulo> resultados) {
    final data = resultados.map((r) => ChartData(_truncar(r.nombre), r.costoTotal)).toList();
    return SizedBox(
      height: 320,
      child: SfCartesianChart(
        primaryXAxis: const CategoryAxis(labelStyle: TextStyle(fontSize: 10), labelRotation: 45),
        primaryYAxis: const NumericAxis(labelStyle: TextStyle(fontSize: 10)),
        // legend false by default
        tooltipBehavior: TooltipBehavior(enable: true, format: 'point.x\nS/ point.y'),
        series: <CartesianSeries<dynamic, dynamic>>[
          ColumnSeries<ChartData, String>(
            dataSource: data,
            xValueMapper: (d, _) => d.nombre,
            yValueMapper: (d, _) => d.valor,
            color: MDSJColors.primary.withValues(alpha: 0.9),
          ),
        ],
      ),
    );
  }

  Widget _buildStackedCosts(List<ResultadoArticulo> resultados) {
    final nombres = resultados.map((r) => _truncar(r.nombre)).toList();
    final pedidos = resultados.map((r) => r.costoPedidos).toList();
    final mantenimiento = resultados.map((r) => r.costoMantenimiento).toList();
    final servicio = resultados.map((r) => r.costoServicio).toList();

    return SizedBox(
      height: 340,
      child: SfCartesianChart(
        primaryXAxis: const CategoryAxis(labelStyle: TextStyle(fontSize: 10), labelRotation: 45),
        primaryYAxis: const NumericAxis(labelStyle: TextStyle(fontSize: 10)),
        legend: const Legend(isVisible: true, position: LegendPosition.bottom),
        tooltipBehavior: TooltipBehavior(enable: true, format: 'point.x\nS/ point.y', header: 'series.name'),
        series: <CartesianSeries<dynamic, dynamic>>[
          StackedColumnSeries<double, String>(
            dataSource: pedidos,
            xValueMapper: (v, i) => nombres[i],
            yValueMapper: (v, _) => v,
            name: 'Pedidos',
            color: const Color(0xFF1E88E5),
          ),
          StackedColumnSeries<double, String>(
            dataSource: mantenimiento,
            xValueMapper: (v, i) => nombres[i],
            yValueMapper: (v, _) => v,
            name: 'Mantenimiento',
            color: const Color(0xFF43A047),
          ),
          StackedColumnSeries<double, String>(
            dataSource: servicio,
            xValueMapper: (v, i) => nombres[i],
            yValueMapper: (v, _) => v,
            name: 'Servicio',
            color: const Color(0xFFFB8C00),
          ),
        ],
      ),
    );
  }

  Widget _buildSpaceBars(List<ResultadoArticulo> resultados) {
    final data = resultados.map((r) => ChartData(_truncar(r.nombre), r.espacioUsado)).toList();
    return SizedBox(
      height: 340,
      child: SfCartesianChart(
        isTransposed: true,
        primaryXAxis: const CategoryAxis(labelStyle: TextStyle(fontSize: 10)),
        primaryYAxis: const NumericAxis(labelStyle: TextStyle(fontSize: 10)),
        tooltipBehavior: TooltipBehavior(enable: true, format: 'point.x\npoint.y m²'),
        series: <CartesianSeries<dynamic, dynamic>>[
          BarSeries<ChartData, String>(
            dataSource: data,
            xValueMapper: (d, _) => d.nombre,
            yValueMapper: (d, _) => d.valor,
            color: MDSJColors.info,
          ),
        ],
      ),
    );
  }

  // (Eliminado: gráfico de dispersión Q vs Costo por decisión de UX)

  Widget _buildBackordersBars(List<ResultadoArticulo> resultados) {
    final data = resultados.map((r) => ChartData(_truncar(r.nombre), r.backordersEsperados)).toList();
    return SizedBox(
      height: 320,
      child: SfCartesianChart(
        primaryXAxis: const CategoryAxis(labelStyle: TextStyle(fontSize: 10), labelRotation: 45),
        primaryYAxis: const NumericAxis(labelStyle: TextStyle(fontSize: 10)),
        tooltipBehavior: TooltipBehavior(enable: true, format: 'point.x\npoint.y'),
        series: <CartesianSeries<dynamic, dynamic>>[
          ColumnSeries<ChartData, String>(
            dataSource: data,
            xValueMapper: (d, _) => d.nombre,
            yValueMapper: (d, _) => d.valor,
            color: const Color(0xFF8E24AA),
          ),
        ],
      ),
    );
  }

  Widget _buildZScoreBars(List<ResultadoArticulo> resultados) {
    final data = resultados.map((r) => ChartData(_truncar(r.nombre), r.zScore)).toList();
    return SizedBox(
      height: 320,
      child: SfCartesianChart(
        primaryXAxis: const CategoryAxis(labelStyle: TextStyle(fontSize: 10), labelRotation: 45),
        primaryYAxis: const NumericAxis(labelStyle: TextStyle(fontSize: 10)),
        tooltipBehavior: TooltipBehavior(enable: true, format: 'point.x\nZ: point.y'),
        series: <CartesianSeries<dynamic, dynamic>>[
          ColumnSeries<ChartData, String>(
            dataSource: data,
            xValueMapper: (d, _) => d.nombre,
            yValueMapper: (d, _) => d.valor,
            color: const Color(0xFFFFA000),
          ),
        ],
      ),
    );
  }

  Future<void> _exportChartAsImage() async {
    try {
      final boundary = _chartKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        return;
      }
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        return;
      }
      final Uint8List bytes = byteData.buffer.asUint8List();
      final fileName = 'grafico_${DateTime.now().millisecondsSinceEpoch}.png';
      if (kIsWeb) {
        await downloadBytesWeb(bytes, fileName, mimeType: 'image/png');
        // no usar context después del await
        return;
      } else {
        final dir = await getApplicationDocumentsDirectory();
        final path = '${dir.path}/$fileName';
        final file = File(path);
        await file.writeAsBytes(bytes);
        // Intentar abrir
        await OpenFile.open(path);
      }
    } catch (e) {
      // Silenciar errores en UI para evitar usar context tras awaits.
    }
  }
}


