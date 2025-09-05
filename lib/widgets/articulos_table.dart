import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:inventario_qr/models/articulo.model.dart';
import 'package:inventario_qr/providers/inventario.provider.dart';
import 'package:inventario_qr/utils/logger.dart';
import 'package:inventario_qr/utils/math_utils.dart';
import 'package:inventario_qr/utils/theme_colors.dart';
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

  // Formatear valor monetario en soles peruanos

  void _initializePlutoGridColumns() {
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
        // ✅ EDICIÓN AUTOMÁTICA AL CAMBIAR DE CELDA (SIN ENTER)
        enableAutoEditing: true,
      ),
      PlutoColumn(
        title: 'Demanda Anual',
        field: 'demandaAnual',
        type: PlutoColumnType.number(
          format: '#,##0.00',
          applyFormatOnInit: false, // ✅ EVITAR SELECCIÓN AUTOMÁTICA DE TEXTO
        ),
        width: 120,
        enableDropToResize: false,
        // ✅ EDICIÓN AUTOMÁTICA AL CAMBIAR DE CELDA (SIN ENTER)
        enableAutoEditing: true,
      ),
      PlutoColumn(
        title: 'Costo Pedido (S/)',
        field: 'costoPedido',
        type: PlutoColumnType.number(
          format: '#,##0.00',
          applyFormatOnInit: false, // ✅ EVITAR SELECCIÓN AUTOMÁTICA DE TEXTO
        ),
        width: 130,
        textAlign: PlutoColumnTextAlign.center,
        enableDropToResize: false,
        // ✅ EDICIÓN AUTOMÁTICA AL CAMBIAR DE CELDA (SIN ENTER)
        enableAutoEditing: true,
      ),
      PlutoColumn(
        title: 'Costo Mantenimiento (S/)',
        field: 'costoMantenimiento',
        type: PlutoColumnType.number(
          format: '#,##0.00',
          applyFormatOnInit: false, // ✅ EVITAR SELECCIÓN AUTOMÁTICA DE TEXTO
        ),
        width: 170,
        textAlign: PlutoColumnTextAlign.center,
        enableDropToResize: false,
        // ✅ EDICIÓN AUTOMÁTICA AL CAMBIAR DE CELDA (SIN ENTER)
        enableAutoEditing: true,
      ),
      PlutoColumn(
        title: 'Costo Faltante (S/)',
        field: 'costoFaltante',
        type: PlutoColumnType.number(
          format: '#,##0.00',
          applyFormatOnInit: false, // ✅ EVITAR SELECCIÓN AUTOMÁTICA DE TEXTO
        ),
        width: 150,
        textAlign: PlutoColumnTextAlign.center,
        enableDropToResize: false,
        // ✅ EDICIÓN AUTOMÁTICA AL CAMBIAR DE CELDA (SIN ENTER)
        enableAutoEditing: true,
      ),
      PlutoColumn(
        title: 'Costo Unitario (S/)',
        field: 'costoUnitario',
        type: PlutoColumnType.number(
          format: '#,##0.00',
          applyFormatOnInit: false, // ✅ EVITAR SELECCIÓN AUTOMÁTICA DE TEXTO
        ),
        width: 150,
        textAlign: PlutoColumnTextAlign.center,
        enableDropToResize: false,
        // ✅ EDICIÓN AUTOMÁTICA AL CAMBIAR DE CELDA (SIN ENTER)
        enableAutoEditing: true,
      ),
      PlutoColumn(
        title: 'Espacio Unidad (m²)',
        field: 'espacioUnidad',
        type: PlutoColumnType.number(
          format: '#,##0.00',
          applyFormatOnInit: false, // ✅ EVITAR SELECCIÓN AUTOMÁTICA DE TEXTO
        ),
        width: 150,
        enableDropToResize: false,
        // ✅ EDICIÓN AUTOMÁTICA AL CAMBIAR DE CELDA (SIN ENTER)
        enableAutoEditing: true,
      ),
      PlutoColumn(
        title: 'Desviación Diaria',
        field: 'desviacionDiaria',
        type: PlutoColumnType.number(
          format: '#,##0.00',
          applyFormatOnInit: false, // ✅ EVITAR SELECCIÓN AUTOMÁTICA DE TEXTO
        ),
        width: 140,
        enableDropToResize: false,
        // ✅ EDICIÓN AUTOMÁTICA AL CAMBIAR DE CELDA (SIN ENTER)
        enableAutoEditing: true,
      ),
      PlutoColumn(
        title: 'Punto Reorden',
        field: 'puntoReorden',
        type: PlutoColumnType.number(
          format: '#,##0', // ✅ Números enteros para punto de reorden
          applyFormatOnInit: false, // ✅ EVITAR SELECCIÓN AUTOMÁTICA DE TEXTO
        ),
        width: 130,
        enableDropToResize: false,
        // ✅ EDICIÓN AUTOMÁTICA AL CAMBIAR DE CELDA (SIN ENTER)
        enableAutoEditing: true,
        // ✅ RENDERER PERSONALIZADO PARA COLOREAR NÚMEROS CALCULADOS AUTOMÁTICAMENTE
        renderer: (rendererContext) {
          final idxCell = rendererContext.row.cells['_idx'];
          if (idxCell?.value is num) {
            final rowIndex = (idxCell!.value as num).toInt();
            if (rowIndex >= 0 && rowIndex < widget.articulos.length) {
              // Si la celda fue calculada automáticamente, colorear en azul
              final provider = context.read<InventarioProvider>();
              if (provider.esCeldaCalculadaAutomaticamente(
                  widget.articulos[rowIndex].nombre, 'puntoReorden')) {
                return Text(
                  rendererContext.cell.value.toString(),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF0069A7),
                  ),
                );
              }
            }
          }
          // Celda normal sin coloreado
          return Text(
            rendererContext.cell.value.toString(),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          );
        },
      ),
      PlutoColumn(
        title: 'Tamaño Lote',
        field: 'tamanoLote',
        type: PlutoColumnType.number(
          format: '#,##0', // ✅ Números enteros para tamaño de lote
          applyFormatOnInit: false, // ✅ EVITAR SELECCIÓN AUTOMÁTICA DE TEXTO
        ),
        width: 130,
        enableDropToResize: false,
        // ✅ EDICIÓN AUTOMÁTICA AL CAMBIAR DE CELDA (SIN ENTER)
        enableAutoEditing: true,
        // ✅ RENDERER PERSONALIZADO PARA COLOREAR NÚMEROS CALCULADOS AUTOMÁTICAMENTE
        renderer: (rendererContext) {
          final idxCell = rendererContext.row.cells['_idx'];
          if (idxCell?.value is num) {
            final rowIndex = (idxCell!.value as num).toInt();
            if (rowIndex >= 0 && rowIndex < widget.articulos.length) {
              // Si la celda fue calculada automáticamente, colorear en azul
              final provider = context.read<InventarioProvider>();
              if (provider.esCeldaCalculadaAutomaticamente(
                  widget.articulos[rowIndex].nombre, 'tamanoLote')) {
                return Text(
                  rendererContext.cell.value.toString(),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF0069A7),
                  ),
                );
              }
            }
          }
          // Celda normal sin coloreado
          return Text(
            rendererContext.cell.value.toString(),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          );
        },
      ),
    ];
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
        // ✅ USAR VALORES REDONDEADOS SEGÚN CONFIGURACIÓN DEL PROVIDER
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
    // Usar el índice real desde la columna oculta
    final idxCell = event.row.cells['_idx'];
    final rowIndex =
        (idxCell?.value is num) ? (idxCell!.value as num).toInt() : -1;
    final field = event.column.field;

    debugPrint('📝 Celda cambiada: ${event.column.title} = ${event.value}');

    if (rowIndex >= 0 && rowIndex < widget.articulos.length) {
      double? parseNum(v) {
        if (v == null) {
          return null;
        }
        String s = v.toString().trim();
        if (s.isEmpty) {
          return null;
        }
        // Normaliza miles y decimales para formatos con coma o punto
        // 1. elimina espacios y NBSP
        s = s.replaceAll('\u00A0', '').replaceAll(' ', '');
        // 2. si tiene ambos (coma y punto), asume que el último símbolo es decimal
        final hasComma = s.contains(',');
        final hasDot = s.contains('.');
        if (hasComma && hasDot) {
          final lastComma = s.lastIndexOf(',');
          final lastDot = s.lastIndexOf('.');
          if (lastComma > lastDot) {
            // coma decimal: quita puntos de miles y reemplaza coma por punto
            s = s.replaceAll('.', '').replaceAll(',', '.');
          } else {
            // punto decimal: quita comas de miles
            s = s.replaceAll(',', '');
          }
        } else if (hasComma && !hasDot) {
          // solo coma: tratar como decimal
          s = s.replaceAll('.', '').replaceAll(',', '.');
        } else {
          // solo punto o ninguno: quitar separadores de miles si los hubiera
          s = s.replaceAll(',', '');
        }
        return double.tryParse(s);
      }

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
        final parsed = parseNum(event.value);
        if (parsed == null) {
          // Valor inválido: no actualizar
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
            // ✅ REDONDEAR SEGÚN CONFIGURACIÓN DEL PROVIDER
            final valorRedondeado =
                _redondearSegunConfiguracion(parsed, 'puntoReorden');
            actualizado = original.copyWith(puntoReorden: valorRedondeado);
            break;
          case 'tamanoLote':
            // ✅ REDONDEAR SEGÚN CONFIGURACIÓN DEL PROVIDER
            final valorRedondeado =
                _redondearSegunConfiguracion(parsed, 'tamanoLote');
            actualizado = original.copyWith(tamanoLote: valorRedondeado);
            break;
          default:
            return;
        }
      }

      // ✅ REMOVER TRACKING DE CELDA CALCULADA AUTOMÁTICAMENTE SI EL USUARIO LA EDITA
      if (field == 'puntoReorden' || field == 'tamanoLote') {
        // ✅ PROGRAMAR REMOCIÓN DE TRACKING PARA EVITAR ERROR DE WIDGET TREE LOCKED
        SchedulerBinding.instance.addPostFrameCallback((_) {
          provider.removerTrackingCeldaCalculada(
              widget.articulos[rowIndex].nombre, field);
        });
      }

      // ✅ PROGRAMAR ACTUALIZACIÓN DEL PROVIDER PARA EVITAR ERROR DE WIDGET TREE LOCKED
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
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child:
                    const Icon(UniconsLine.trash, color: Colors.red, size: 20),
              ),
              const SizedBox(width: 12),
              const Text('Confirmar Eliminación'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '¿Estás seguro de que deseas eliminar ${selectedRows.length} artículo${selectedRows.length != 1 ? 's' : ''} seleccionado${selectedRows.length != 1 ? 's' : ''}?',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
                ),
                child: const Row(
                  children: [
                    Icon(UniconsLine.exclamation_triangle,
                        color: Colors.red, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Esta acción no se puede deshacer',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                // Eliminar en orden inverso para evitar problemas de índices
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

                Navigator.pop(context);
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
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Actualizar filas de PlutoGrid
    rows = [
      for (int i = 0; i < widget.articulos.length; i++)
        _articuloToPlutoRow(i, widget.articulos[i])
    ];

    if (widget.articulos.isEmpty) {
      return Card(
        elevation: 2,
        child: Container(
          padding: const EdgeInsets.all(32.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: MDSJColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    UniconsLine.box,
                    size: 48,
                    color: MDSJColors.primary,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'No hay artículos agregados',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: MDSJColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Agrega artículos usando el formulario de arriba',
                  style: TextStyle(
                    fontSize: 16,
                    color: MDSJColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: MDSJColors.infoBackground,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: MDSJColors.infoBorder),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        UniconsLine.info_circle,
                        size: 16,
                        color: MDSJColors.primary,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Los artículos aparecerán aquí',
                        style: TextStyle(
                          fontSize: 14,
                          color: MDSJColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
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
                // Se elimina el banner informativo redundante
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
                    return PlutoGrid(
                      key: ValueKey(_computeArticlesSignature()),
                      columns: columns,
                      rows: [
                        for (int i = 0; i < widget.articulos.length; i++)
                          _articuloToPlutoRow(i, widget.articulos[i])
                      ],
                      onLoaded: (PlutoGridOnLoadedEvent event) {
                        stateManager = event.stateManager;
                        stateManager!.setShowColumnFilter(false);
                      },
                      onChanged: (PlutoGridOnChangedEvent event) {
                        logDebug(
                            '📝 Celda cambiada: ${event.column.title} = ${event.value}');
                        _onCellChanged(event);
                      },
                      onRowChecked: (PlutoGridOnRowCheckedEvent event) {
                        logDebug('✅ Fila seleccionada: ${event.isChecked}');
                      },
                      configuration: const PlutoGridConfiguration(
                        // ✅ CONFIGURACIÓN DE NAVEGACIÓN EXCEL-STYLE
                        enableMoveDownAfterSelecting:
                            true, // Mover abajo después de seleccionar
                        enableMoveHorizontalInEditing:
                            true, // Permitir movimiento horizontal durante edición
                        tabKeyAction: PlutoGridTabKeyAction
                            .moveToNextOnEdge, // Tab continúa a siguiente fila en bordes

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
