import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:inventario_qr/models/resultado.model.dart';
import 'package:inventario_qr/providers/inventario.provider.dart';
import 'package:inventario_qr/repositories/inventario.repository.dart';
import 'package:inventario_qr/utils/logger.dart';
import 'package:inventario_qr/utils/math_utils.dart';
import 'package:inventario_qr/utils/theme_colors.dart';
import 'package:inventario_qr/widgets/articulos_table.dart';
// charts moved into ResultadosCharts widget
import 'package:inventario_qr/widgets/resultados_charts.dart';
import 'package:open_file/open_file.dart';
import 'package:provider/provider.dart';
import 'package:unicons/unicons.dart';



class ResultadosScreen extends StatefulWidget {
  const ResultadosScreen({super.key});

  @override
  State<ResultadosScreen> createState() => _ResultadosScreenState();
}

class _ResultadosScreenState extends State<ResultadosScreen> {
  bool _isStatisticsExpanded = false;
  bool _isExtremesExpanded = false;
  // charts state moved into ResultadosCharts widget

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultados del Modelo QR'),
        leading: IconButton(
          icon: const Icon(UniconsLine.arrow_left),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Consumer<InventarioProvider>(
            builder: (context, provider, child) {
              if (provider.resultado == null) {
                return const SizedBox.shrink();
              }
              return IconButton(
                onPressed: () => _exportarResultadosExcel(context),
                icon: const Icon(UniconsLine.file_export),
                tooltip: 'Exportar Excel',
              );
            },
          ),
        ],
      ),
      body: Consumer<InventarioProvider>(
        builder: (context, provider, child) {
          logDebug('📊 ResultadosScreen: Consumer reconstruyendo');
          logDebug('📊 ResultadosScreen: Resultado disponible: ${provider.resultado != null}');
          logDebug('📊 ResultadosScreen: Artículos disponibles: ${provider.articulos.length}');
          
          if (provider.resultado == null) {
            logDebug('📊 ResultadosScreen: No hay resultados disponibles');
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(UniconsLine.calculator, size: 64, color: Colors.grey),
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

          logDebug('📊 ResultadosScreen: Mostrando resultados');
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSystemSummary(provider),
                const SizedBox(height: 24),
                _buildResultsTable(provider),
                const SizedBox(height: 24),
                _buildArticulosTable(provider),
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
    final estadisticas = provider.estadisticas.isNotEmpty
        ? provider.estadisticas
        : InventarioRepository.calcularEstadisticas(resultado);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(UniconsLine.info_circle, color: MDSJColors.primary),
                SizedBox(width: 12),
                Text(
                  'Resumen del Sistema',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: MDSJColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Primera fila - Métricas principales
            Row(
              children: [
                Expanded(
                  child:                   _buildSummaryItem(
                    'Costo Total',
                    MathUtils.formatearMoneda(resultado.costoTotalSistema),
                    UniconsLine.money_bill,
                    MDSJColors.success,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItemWithComparison(
                    'Espacio Usado',
                    MathUtils.formatearUnidades(resultado.espacioTotalUsado, 'm²'),
                    UniconsLine.store,
                    MDSJColors.info,
                    (resultado.espacioTotalUsado / provider.espacioMaximo) * 100,
                    MathUtils.formatearUnidades(provider.espacioMaximo, 'm²'),
                  ),
                ),
                Expanded(
                  child: _buildSummaryItemWithComparison(
                    'Presupuesto',
                    MathUtils.formatearMoneda(resultado.presupuestoTotal),
                    UniconsLine.calculator,
                    MDSJColors.warning,
                    (resultado.presupuestoTotal / provider.presupuestoMaximo) * 100,
                    MathUtils.formatearMoneda(provider.presupuestoMaximo),
                  ),
                ),
                Expanded(
                  child: _buildSummaryItemWithComparison(
                    'Número de Pedidos',
                    resultado.numeroTotalPedidos.toString(),
                    UniconsLine.box,
                    MDSJColors.secondary,
                    (resultado.numeroTotalPedidos / provider.numeroMaximoPedidos) * 100,
                    provider.numeroMaximoPedidos.toString(),
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
                    UniconsLine.list_ul,
                    MDSJColors.info,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    'Costo Promedio/Artículo',
                    MathUtils.formatearMoneda(resultado.costoTotalSistema / resultado.resultados.length),
                    UniconsLine.calculator,
                    MDSJColors.success,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    'Espacio Promedio/Artículo',
                    MathUtils.formatearUnidades(resultado.espacioTotalUsado / resultado.resultados.length, 'm²'),
                    UniconsLine.store,
                    MDSJColors.info,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    'Pedidos Promedio/Artículo',
                    (resultado.numeroTotalPedidos / resultado.resultados.length).toStringAsFixed(1),
                    UniconsLine.box,
                    MDSJColors.secondary,
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
            color: MDSJColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: MDSJColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryItemWithComparison(String title, String value, IconData icon, Color color, double constraintPercentage, String maxValue) {
    Color comparisonColor;
    String comparisonText;
    String comparisonDetail;
    
    if (constraintPercentage <= 70) {
      comparisonColor = MDSJColors.success;
      comparisonText = 'Excelente';
      comparisonDetail = '${constraintPercentage.toStringAsFixed(0)}% del máximo';
    } else if (constraintPercentage <= 90) {
      comparisonColor = MDSJColors.warning;
      comparisonText = 'Atención';
      comparisonDetail = '${constraintPercentage.toStringAsFixed(0)}% del máximo';
    } else {
      comparisonColor = MDSJColors.error;
      comparisonText = 'Crítico';
      comparisonDetail = '${constraintPercentage.toStringAsFixed(0)}% del máximo';
    }

    return Column(
      children: [
        Icon(icon, size: 32, color: color),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            color: MDSJColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: MDSJColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: comparisonColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: comparisonColor.withValues(alpha: 0.6)),
          ),
          child: Column(
            children: [
              Text(
                comparisonText,
                style: TextStyle(
                  fontSize: 11,
                  color: comparisonColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                comparisonDetail,
                style: TextStyle(
                  fontSize: 9,
                  color: comparisonColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Máximo: $maxValue',
          style: const TextStyle(
            fontSize: 10,
            color: MDSJColors.textPrimary,
            fontWeight: FontWeight.w600,
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
            color: MDSJColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          detail,
          style: const TextStyle(
            fontSize: 10,
            color: MDSJColors.info,
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
            color: MDSJColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildExpandableExtremes(ResultadoSistema resultado, Map<String, dynamic> estadisticas) {
    return Column(
      children: [
        InkWell(
          onTap: () => setState(() => _isExtremesExpanded = !_isExtremesExpanded),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  _isExtremesExpanded ? UniconsLine.angle_up : UniconsLine.angle_down,
                  color: MDSJColors.primary,
                  size: 16,
                ),
                const SizedBox(width: 8),
                const Icon(UniconsLine.chart, color: MDSJColors.primary, size: 16),
                const SizedBox(width: 8),
                const Text(
                  'Análisis de Extremos',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: MDSJColors.textPrimary,
                  ),
                ),
                const Spacer(),
                Text(
                  _isExtremesExpanded ? 'Ocultar' : 'Mostrar',
                  style: const TextStyle(
                    fontSize: 12,
                    color: MDSJColors.primary,
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
                    // mostramos el valor formateado usando el nombre y buscando una vez
                    MathUtils.formatearMoneda(
                      (resultado.resultados.firstWhere(
                        (r) => r.nombre == (estadisticas['articuloMasCostoso'] as String),
                        orElse: () => resultado.resultados.first,
                      ).costoTotal),
                    ),
                    UniconsLine.exclamation_triangle,
                    MDSJColors.error,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItemWithDetails(
                    'Artículo Menos Costoso',
                    estadisticas['articuloMenosCostoso'] as String,
                    MathUtils.formatearMoneda(
                      (resultado.resultados.firstWhere(
                        (r) => r.nombre == (estadisticas['articuloMenosCostoso'] as String),
                        orElse: () => resultado.resultados.first,
                      ).costoTotal),
                    ),
                    UniconsLine.check_circle,
                    MDSJColors.success,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItemWithDetails(
                    'Mayor Espacio',
                    estadisticas['articuloMasEspacio'] as String,
                    MathUtils.formatearUnidades(
                      (resultado.resultados.firstWhere(
                        (r) => r.nombre == (estadisticas['articuloMasEspacio'] as String),
                        orElse: () => resultado.resultados.first,
                      ).espacioUsado),
                      'm²',
                    ),
                    UniconsLine.store,
                    MDSJColors.info,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItemWithDetails(
                    'Menor Espacio',
                    estadisticas['articuloMenosEspacio'] as String,
                    MathUtils.formatearUnidades(
                      (resultado.resultados.firstWhere(
                        (r) => r.nombre == (estadisticas['articuloMenosEspacio'] as String),
                        orElse: () => resultado.resultados.first,
                      ).espacioUsado),
                      'm²',
                    ),
                    UniconsLine.store,
                    MDSJColors.info,
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
            const Row(
              children: [
                Icon(UniconsLine.table, color: MDSJColors.primary),
                SizedBox(width: 12),
                Text(
                  'Resultados por Artículo',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: MDSJColors.textPrimary,
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

  Widget _buildArticulosTable(InventarioProvider provider) {
    return ArticulosTable(
      articulos: provider.articulos,
      title: 'Artículos del Sistema',
      height: 300,
      showDeleteButton: false, // Solo lectura en resultados
    );
  }



  Widget _buildExpandableStatistics(Map<String, dynamic> estadisticas) {
    return Column(
      children: [
        InkWell(
          onTap: () => setState(() => _isStatisticsExpanded = !_isStatisticsExpanded),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  _isStatisticsExpanded ? UniconsLine.angle_up : UniconsLine.angle_down,
                  color: MDSJColors.primary,
                  size: 16,
                ),
                const SizedBox(width: 8),
                const Icon(UniconsLine.chart, color: MDSJColors.primary, size: 16),
                const SizedBox(width: 8),
                const Text(
                  'Estadísticas Promedio',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: MDSJColors.textPrimary,
                  ),
                ),
                const Spacer(),
                Text(
                  _isStatisticsExpanded ? 'Ocultar' : 'Mostrar',
                  style: const TextStyle(
                    fontSize: 12,
                    color: MDSJColors.primary,
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
                    MathUtils.formatearMoneda(estadisticas['costoPromedio'] as double),
                    UniconsLine.money_bill,
                    MDSJColors.success,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    'Espacio Promedio',
                    MathUtils.formatearUnidades(estadisticas['espacioPromedio'] as double, 'm²'),
                    UniconsLine.store,
                    MDSJColors.info,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    'Z-Score Promedio',
                    (estadisticas['zScorePromedio'] as double).toStringAsFixed(2),
                    UniconsLine.calculator,
                    MDSJColors.warning,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    'Mediana Costo',
                    MathUtils.formatearMoneda(estadisticas['medianaCosto'] as double),
                    UniconsLine.chart,
                    MDSJColors.secondary,
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
        child: ResultadosCharts(resultado: provider.resultado!),
      ),
    );
  }

  // Charts moved to ResultadosCharts widget



  // Combined chart and chart data moved to ResultadosCharts





  Future<void> _exportarResultadosExcel(BuildContext context) async {
    final provider = context.read<InventarioProvider>();
    
    if (provider.resultado == null) {
      _mostrarDialogoError(context, 'No hay resultados disponibles para exportar');
      return;
    }

    try {
      debugPrint('📤 Iniciando exportación de resultados a Excel...');
      
      // Usar el método del ExcelRepository que maneja automáticamente web/móvil
      final filePath = await provider.exportarResultadosExcel();
      
      debugPrint('✅ Resultados exportados exitosamente en: $filePath');
      
      // Mostrar mensaje de éxito
      if (context.mounted) {
        _mostrarDialogoExito(context, filePath);
      }
      
    } catch (e) {
      debugPrint('❌ Error al exportar resultados: $e');
      
      if (context.mounted) {
        _mostrarDialogoError(context, 'Error al exportar resultados: $e');
      }
    }
  }

  void _mostrarDialogoError(BuildContext context, String mensaje) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(UniconsLine.exclamation_triangle, color: MDSJColors.error),
              SizedBox(width: 8),
              Text('Error'),
            ],
          ),
          content: Text(mensaje),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Aceptar'),
            ),
          ],
        );
      },
    );
  }

  void _mostrarDialogoExito(BuildContext context, String filePath) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(UniconsLine.check_circle, color: MDSJColors.success),
              SizedBox(width: 8),
              Text('Exportación Completada'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Los resultados se han exportado correctamente.'),
              const SizedBox(height: 8),
              if (kIsWeb)
                const Text(
                  'En web, el archivo se descargará automáticamente.',
                  style: TextStyle(
                    fontSize: 12,
                    color: MDSJColors.textSecondary,
                  ),
                )
              else
                Text(
                  'Ubicación: $filePath',
                  style: const TextStyle(
                    fontSize: 12,
                    color: MDSJColors.textSecondary,
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Aceptar'),
            ),
            if (!kIsWeb && filePath.isNotEmpty)
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  final result = await OpenFile.open(filePath);
                  if (result.type != ResultType.done && context.mounted) {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Error'),
                          content: Text('No se pudo abrir el archivo: ${result.message}'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Aceptar'),
                            ),
                          ],
                        );
                      },
                    );
                  }
                },
                child: const Text('Abrir archivo'),
              ),
          ],
        );
      },
    );
  }
} 