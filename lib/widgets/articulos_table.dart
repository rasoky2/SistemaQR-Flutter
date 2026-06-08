import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:inventario_qr/models/articulo.model.dart';
import 'package:inventario_qr/providers/inventario.provider.dart';
import 'package:inventario_qr/utils/logger.dart';
import 'package:inventario_qr/utils/math_utils.dart';
import 'package:inventario_qr/utils/theme_colors.dart';
import 'package:inventario_qr/widgets/articulos_table.subwidgets.dart';
import 'package:pluto_grid/pluto_grid.dart';
import 'package:provider/provider.dart';
import 'package:unicons/unicons.dart';

/// Widget reutilizable para mostrar una tabla de artículos usando PlutoGrid
class ArticulosTable extends StatefulWidget {
  final List<Articulo> articulos;
  final bool showDeleteButton;
  final bool showEditButton;
  final Function(Articulo)? onEdit;
  final Function(List<Articulo>)? onDelete;
  final String? title;
  final double height;

  const ArticulosTable({
    super.key,
    required this.articulos,
    this.showDeleteButton = true,
    this.showEditButton = false,
    this.onEdit,
    this.onDelete,
    this.title,
    this.height = 400,
  });

  @override
  State<ArticulosTable> createState() => _ArticulosTableState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<Articulo>('articulos', articulos))
      ..add(DiagnosticsProperty<bool>('showDeleteButton', showDeleteButton))
      ..add(DiagnosticsProperty<bool>('showEditButton', showEditButton))
      ..add(ObjectFlagProperty<Function(Articulo p1)?>.has('onEdit', onEdit))
      ..add(ObjectFlagProperty<Function(List<Articulo> p1)?>.has(
          'onDelete', onDelete))
      ..add(StringProperty('title', title))
      ..add(DoubleProperty('height', height));
  }
}

class _ArticulosTableState extends State<ArticulosTable> {
  PlutoGridStateManager? stateManager;
  late List<PlutoColumn> columns;
  List<PlutoRow> rows = [];

  String _computeArticlesSignature() {
    final buffer = StringBuffer();
    for (final a in widget.articulos) {
      buffer
        ..write(a.nombre)
        ..write('|')
        ..write(a.demandaAnual)
        ..write('|')
        ..write(a.costoPedido)
        ..write('|')
        ..write(a.costoMantenimiento)
        ..write('|')
        ..write(a.costoFaltante)
        ..write('|')
        ..write(a.costoUnitario)
        ..write('|')
        ..write(a.espacioUnidad)
        ..write('|')
        ..write(a.desviacionDiaria)
        ..write('|')
        ..write(a.puntoReorden)
        ..write('|')
        ..write(a.tamanoLote)
        ..write(';');
    }
    return buffer.toString();
  }

  @override
  void initState() {
    super.initState();
    _initializePlutoGridColumns();
  }

  void _initializePlutoGridColumns() {
    final provider = context.read<InventarioProvider>();
    
    // Formato dinámico para Punto de Reorden según la configuración del provider
    final int decR = provider.tipoRedondeoPuntoReorden == 'unidades' ? 0 : provider.decimalesPuntoReorden;
    final String formatR = decR == 0 ? '#,##0' : '#,##0.${'0' * decR}';

    // Formato dinámico para Tamaño de Lote según la configuración del provider
    final int decQ = provider.tipoRedondeoTamanoLote == 'unidades' ? 0 : provider.decimalesTamanoLote;
    final String formatQ = decQ == 0 ? '#,##0' : '#,##0.${'0' * decQ}';

    columns = [
      // Columna oculta para mantener el índice real del provider
      PlutoColumn(
        title: '_idx',
        field: '_idx',
        type: PlutoColumnType.number(),
        hide: true,
        readOnly: true,
      ),
      PlutoColumn(
        title: 'Nombre',
        field: 'nombre',
        type: PlutoColumnType.text(),
        width: 150,
        enableRowChecked: widget.showDeleteButton,
        enableAutoEditing: true,
      ),
      _buildNumericColumn(
        title: 'Demanda Anual',
        field: 'demandaAnual',
        width: 120,
      ),
      _buildNumericColumn(
        title: 'Costo Pedido (S/)',
        field: 'costoPedido',
        width: 130,
        textAlign: PlutoColumnTextAlign.center,
      ),
      _buildNumericColumn(
        title: 'Costo Mantenimiento (S/)',
        field: 'costoMantenimiento',
        width: 170,
        textAlign: PlutoColumnTextAlign.center,
      ),
      _buildNumericColumn(
        title: 'Costo Faltante (S/)',
        field: 'costoFaltante',
        width: 150,
        textAlign: PlutoColumnTextAlign.center,
      ),
      _buildNumericColumn(
        title: 'Costo Unitario (S/)',
        field: 'costoUnitario',
        width: 150,
        textAlign: PlutoColumnTextAlign.center,
      ),
      _buildNumericColumn(
        title: 'Espacio Unidad (m²)',
        field: 'espacioUnidad',
        width: 150,
      ),
      _buildNumericColumn(
        title: 'Desviación Diaria',
        field: 'desviacionDiaria',
        width: 140,
      ),
      PlutoColumn(
        title: 'Punto Reorden',
        field: 'puntoReorden',
        type: PlutoColumnType.number(
          format: formatR,
          applyFormatOnInit: false,
        ),
        width: 130,
        enableDropToResize: false,
        enableAutoEditing: true,
        renderer: _buildCalculatedColumnRenderer('puntoReorden'),
      ),
      PlutoColumn(
        title: 'Tamaño Lote',
        field: 'tamanoLote',
        type: PlutoColumnType.number(
          format: formatQ,
          applyFormatOnInit: false,
        ),
        width: 130,
        enableDropToResize: false,
        enableAutoEditing: true,
        renderer: _buildCalculatedColumnRenderer('tamanoLote'),
      ),
    ];
  }

  PlutoColumn _buildNumericColumn({
    required String title,
    required String field,
    required double width,
    PlutoColumnTextAlign textAlign = PlutoColumnTextAlign.left,
  }) {
    return PlutoColumn(
      title: title,
      field: field,
      type: PlutoColumnType.number(
        format: '#,##0.00',
        applyFormatOnInit: false,
      ),
      width: width,
      textAlign: textAlign,
      enableDropToResize: false,
      enableAutoEditing: true,
      renderer: _buildNumeroRenderer(),
    );
  }

  PlutoColumnRenderer _buildCalculatedColumnRenderer(String field) {
    return (PlutoColumnRendererContext rendererContext) {
      final idxCell = rendererContext.row.cells['_idx'];
      final provider = context.read<InventarioProvider>();
      final int decimales = field == 'puntoReorden'
          ? (provider.tipoRedondeoPuntoReorden == 'unidades' ? 0 : provider.decimalesPuntoReorden)
          : (provider.tipoRedondeoTamanoLote == 'unidades' ? 0 : provider.decimalesTamanoLote);

      if (idxCell?.value is num) {
        final rowIndex = (idxCell!.value as num).toInt();
        if (rowIndex >= 0 && rowIndex < widget.articulos.length) {
          if (provider.esCeldaCalculadaAutomaticamente(
              widget.articulos[rowIndex].nombre, field)) {
            final double? doubleVal =
                double.tryParse(rendererContext.cell.value.toString());
            return Text(
              doubleVal != null
                  ? MathUtils.formatearConDecimales(doubleVal, decimales)
                  : rendererContext.cell.value.toString(),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF0069A7),
              ),
            );
          }
        }
      }
      final double? doubleVal =
          double.tryParse(rendererContext.cell.value.toString());
      return Text(
        doubleVal != null
            ? MathUtils.formatearConDecimales(doubleVal, decimales)
            : rendererContext.cell.value.toString(),
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      );
    };
  }

  /// Renderer de números para aplicar formato dinámico de separadores en la UI de PlutoGrid
  PlutoColumnRenderer _buildNumeroRenderer() {
    return (PlutoColumnRendererContext rendererContext) {
      final value = rendererContext.cell.value;
      if (value is num) {
        return Text(
          MathUtils.formatearNumero(value.toDouble()),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        );
      }
      return Text(rendererContext.cell.value.toString());
    };
  }

  /// Redondea un valor según la configuración del provider
  double _redondearSegunConfiguracion(double valor, String tipo) {
    final provider = context.read<InventarioProvider>();

    if (tipo == 'puntoReorden') {
      if (provider.tipoRedondeoPuntoReorden == 'unidades') {
        return MathUtils.redondearInteligente(valor, tipo: 'unidades');
      } else {
        return MathUtils.redondearInteligente(valor,
            tipo: 'unidades_decimales',
            decimales: provider.decimalesPuntoReorden);
      }
    } else if (tipo == 'tamanoLote') {
      if (provider.tipoRedondeoTamanoLote == 'unidades') {
        return MathUtils.redondearInteligente(valor, tipo: 'unidades');
      } else {
        return MathUtils.redondearInteligente(valor,
            tipo: 'unidades_decimales',
            decimales: provider.decimalesTamanoLote);
      }
    }

    return valor;
  }

  // Convertir Articulo a PlutoRow
  PlutoRow _articuloToPlutoRow(int index, Articulo articulo) {
    return PlutoRow(
      cells: {
        '_idx': PlutoCell(value: index),
        'nombre': PlutoCell(value: articulo.nombre),
        'demandaAnual': PlutoCell(value: articulo.demandaAnual),
        'costoPedido': PlutoCell(value: articulo.costoPedido),
        'costoMantenimiento': PlutoCell(value: articulo.costoMantenimiento),
        'costoFaltante': PlutoCell(value: articulo.costoFaltante),
        'costoUnitario': PlutoCell(value: articulo.costoUnitario),
        'espacioUnidad': PlutoCell(value: articulo.espacioUnidad),
        'desviacionDiaria': PlutoCell(value: articulo.desviacionDiaria),
        'puntoReorden': PlutoCell(
            value: _redondearSegunConfiguracion(
                articulo.puntoReorden, 'puntoReorden')),
        'tamanoLote': PlutoCell(
            value: _redondearSegunConfiguracion(
                articulo.tamanoLote, 'tamanoLote')),
      },
    );
  }

  // Manejar cambios en las celdas de PlutoGrid
  void _onCellChanged(PlutoGridOnChangedEvent event) {
    final idxCell = event.row.cells['_idx'];
    final rowIndex =
        (idxCell?.value is num) ? (idxCell!.value as num).toInt() : -1;
    final field = event.column.field;

    debugPrint('Celda cambiada: ${event.column.title} = ${event.value}');

    if (rowIndex >= 0 && rowIndex < widget.articulos.length) {
      final provider = context.read<InventarioProvider>();
      final original = provider.articulos[rowIndex];
      Articulo actualizado = original;

      if (field == 'nombre') {
        final nuevoNombre = (event.value ?? '').toString().trim();
        if (nuevoNombre.isEmpty) {
          return;
        }
        actualizado = original.copyWith(nombre: nuevoNombre);
      } else {
        final parsed = MathUtils.parseDouble(event.value);
        if (parsed == null) {
          return;
        }
        switch (field) {
          case 'demandaAnual':
            actualizado = original.copyWith(demandaAnual: parsed);
            break;
          case 'costoPedido':
            actualizado = original.copyWith(costoPedido: parsed);
            break;
          case 'costoMantenimiento':
            actualizado = original.copyWith(costoMantenimiento: parsed);
            break;
          case 'costoFaltante':
            actualizado = original.copyWith(costoFaltante: parsed);
            break;
          case 'costoUnitario':
            actualizado = original.copyWith(costoUnitario: parsed);
            break;
          case 'espacioUnidad':
            actualizado = original.copyWith(espacioUnidad: parsed);
            break;
          case 'desviacionDiaria':
            actualizado = original.copyWith(desviacionDiaria: parsed);
            break;
          case 'puntoReorden':
            final valorRedondeado =
                _redondearSegunConfiguracion(parsed, 'puntoReorden');
            actualizado = original.copyWith(puntoReorden: valorRedondeado);
            break;
          case 'tamanoLote':
            final valorRedondeado =
                _redondearSegunConfiguracion(parsed, 'tamanoLote');
            actualizado = original.copyWith(tamanoLote: valorRedondeado);
            break;
          default:
            return;
        }
      }

      if (field == 'puntoReorden' || field == 'tamanoLote') {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          provider.removerTrackingCeldaCalculada(
              widget.articulos[rowIndex].nombre, field);
        });
      }

      SchedulerBinding.instance.addPostFrameCallback((_) {
        provider.actualizarArticulo(rowIndex, actualizado);
      });
    }
  }

  // Eliminar artículos seleccionados
  void _eliminarArticulosSeleccionados() {
    final selectedRows = stateManager?.checkedRows ?? <PlutoRow>[];
    if (selectedRows.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(UniconsLine.exclamation_triangle, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text('Selecciona al menos un artículo para eliminar'),
              ),
            ],
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ConfirmarEliminacionDialog(
          cantidadArticulos: selectedRows.length,
          onConfirmar: () {
            final indices = selectedRows
                .map((row) => row.cells['_idx']?.value)
                .whereType<num>()
                .map((n) => n.toInt())
                .toSet()
                .toList()
              ..sort((a, b) => b.compareTo(a));

            final provider = context.read<InventarioProvider>();
            for (final index in indices) {
              if (index >= 0 && index < provider.articulos.length) {
                provider.eliminarArticulo(index);
              }
            }

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(UniconsLine.check_circle,
                        color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                          '${selectedRows.length} artículo${selectedRows.length != 1 ? 's' : ''} eliminado${selectedRows.length != 1 ? 's' : ''} correctamente'),
                    ),
                  ],
                ),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                duration: const Duration(seconds: 3),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    rows = [
      for (int i = 0; i < widget.articulos.length; i++)
        _articuloToPlutoRow(i, widget.articulos[i])
    ];

    if (widget.articulos.isEmpty) {
      return const SinArticulosPlaceholder();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: MDSJColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(UniconsLine.box,
                          color: MDSJColors.primary),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title ?? 'Artículos en Inventario',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: MDSJColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${widget.articulos.length} artículo${widget.articulos.length != 1 ? 's' : ''} agregado${widget.articulos.length != 1 ? 's' : ''}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: MDSJColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (widget.showDeleteButton) ...[
                      IconButton(
                        onPressed: _eliminarArticulosSeleccionados,
                        icon: const Icon(UniconsLine.trash),
                        tooltip: 'Eliminar artículos seleccionados',
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.red.withValues(alpha: 0.1),
                          foregroundColor: Colors.red,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: widget.height,
              child: Theme(
                data: Theme.of(context).copyWith(
                  inputDecorationTheme: InputDecorationTheme(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: const BorderSide(color: Colors.transparent),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: const BorderSide(color: Colors.transparent),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: const BorderSide(color: Colors.transparent),
                    ),
                    filled: false,
                  ),
                ),
                child: Consumer<InventarioProvider>(
                  builder: (context, provider, _) {
                    _initializePlutoGridColumns();
                    
                    rows = [
                      for (int i = 0; i < widget.articulos.length; i++)
                        _articuloToPlutoRow(i, widget.articulos[i])
                    ];

                    final plutoGridKey = ValueKey(
                      '${_computeArticlesSignature()}'
                      '_${provider.formatoSeparadores}'
                      '_${provider.tipoRedondeoPuntoReorden}_${provider.decimalesPuntoReorden}'
                      '_${provider.tipoRedondeoTamanoLote}_${provider.decimalesTamanoLote}'
                    );

                    return PlutoGrid(
                      key: plutoGridKey,
                      columns: columns,
                      rows: rows,
                      onLoaded: (PlutoGridOnLoadedEvent event) {
                        stateManager = event.stateManager;
                        stateManager!.setShowColumnFilter(false);
                      },
                      onChanged: (PlutoGridOnChangedEvent event) {
                        logDebug(
                            'Celda cambiada: ${event.column.title} = ${event.value}');
                        _onCellChanged(event);
                      },
                      onRowChecked: (PlutoGridOnRowCheckedEvent event) {
                        logDebug('Fila seleccionada: ${event.isChecked}');
                      },
                      configuration: const PlutoGridConfiguration(
                        enableMoveDownAfterSelecting: true,
                        enableMoveHorizontalInEditing: true,
                        tabKeyAction: PlutoGridTabKeyAction.moveToNextOnEdge,
                        columnSize: PlutoGridColumnSizeConfig(
                          autoSizeMode: PlutoAutoSizeMode.scale,
                        ),
                        style: PlutoGridStyleConfig(
                          gridBorderColor: Color(0xFFE0E0E0),
                          rowHeight: 56,
                          columnTextStyle: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: MDSJColors.textPrimary,
                          ),
                          cellTextStyle: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: MDSJColors.textPrimary,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<PlutoGridStateManager?>(
          'stateManager', stateManager))
      ..add(IterableProperty<PlutoColumn>('columns', columns))
      ..add(IterableProperty<PlutoRow>('rows', rows));
  }
}
