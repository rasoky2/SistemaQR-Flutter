import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:inventario_qr/models/articulo.model.dart';
import 'package:inventario_qr/providers/inventario.provider.dart';
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
    properties..add(IterableProperty<Articulo>('articulos', articulos))
    ..add(DiagnosticsProperty<bool>('showDeleteButton', showDeleteButton))
    ..add(DiagnosticsProperty<bool>('showEditButton', showEditButton))
    ..add(ObjectFlagProperty<Function(Articulo p1)?>.has('onEdit', onEdit))
    ..add(ObjectFlagProperty<Function(List<Articulo> p1)?>.has('onDelete', onDelete))
    ..add(StringProperty('title', title))
    ..add(DoubleProperty('height', height));
  }
}

class _ArticulosTableState extends State<ArticulosTable> {
  late PlutoGridStateManager stateManager;
  late List<PlutoColumn> columns;
  List<PlutoRow> rows = [];

  @override
  void initState() {
    super.initState();
    _initializePlutoGridColumns();
    
    // Actualizar filas después del primer frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  // Formatear valor monetario en soles peruanos

  void _initializePlutoGridColumns() {
    columns = [
      PlutoColumn(
        title: 'Nombre',
        field: 'nombre',
        type: PlutoColumnType.text(),
        width: 150,
        enableRowChecked: widget.showDeleteButton,
      ),
      PlutoColumn(
        title: 'Demanda Anual',
        field: 'demandaAnual',
        type: PlutoColumnType.number(),
        width: 120,
        enableDropToResize: false,
      ),
      PlutoColumn(
        title: 'Costo Pedido (S/)',
        field: 'costoPedido',
        type: PlutoColumnType.number(),
        width: 130,
        textAlign: PlutoColumnTextAlign.center,
        enableDropToResize: false,
      ),
      PlutoColumn(
        title: 'Costo Mantenimiento (S/)',
        field: 'costoMantenimiento',
        type: PlutoColumnType.number(),
        width: 170,
        textAlign: PlutoColumnTextAlign.center,
        enableDropToResize: false,
      ),
      PlutoColumn(
        title: 'Costo Faltante (S/)',
        field: 'costoFaltante',
        type: PlutoColumnType.number(),
        width: 150,
        textAlign: PlutoColumnTextAlign.center,
        enableDropToResize: false,
      ),
      PlutoColumn(
        title: 'Costo Unitario (S/)',
        field: 'costoUnitario',
        type: PlutoColumnType.number(),
        width: 150,
        textAlign: PlutoColumnTextAlign.center,
        enableDropToResize: false,
      ),
      PlutoColumn(
        title: 'Espacio Unidad (m²)',
        field: 'espacioUnidad',
        type: PlutoColumnType.number(),
        width: 150,
        enableDropToResize: false,
      ),
      PlutoColumn(
        title: 'Desviación Diaria',
        field: 'desviacionDiaria',
        type: PlutoColumnType.number(),
        width: 140,
        enableDropToResize: false,
      ),
      PlutoColumn(
        title: 'Punto Reorden',
        field: 'puntoReorden',
        type: PlutoColumnType.number(),
        width: 130,
        enableDropToResize: false,
      ),
      PlutoColumn(
        title: 'Tamaño Lote',
        field: 'tamanoLote',
        type: PlutoColumnType.number(),
        width: 130,
        enableDropToResize: false,
      ),
    ];
  }

  // Convertir Articulo a PlutoRow
  PlutoRow _articuloToPlutoRow(Articulo articulo) {
    return PlutoRow(
      cells: {
        'nombre': PlutoCell(value: articulo.nombre),
        'demandaAnual': PlutoCell(value: articulo.demandaAnual),
        'costoPedido': PlutoCell(value: articulo.costoPedido),
        'costoMantenimiento': PlutoCell(value: articulo.costoMantenimiento),
        'costoFaltante': PlutoCell(value: articulo.costoFaltante),
        'costoUnitario': PlutoCell(value: articulo.costoUnitario),
        'espacioUnidad': PlutoCell(value: articulo.espacioUnidad),
        'desviacionDiaria': PlutoCell(value: articulo.desviacionDiaria),
        'puntoReorden': PlutoCell(value: articulo.puntoReorden),
        'tamanoLote': PlutoCell(value: articulo.tamanoLote),
      },
    );
  }
  // Extraer valor numérico de texto formateado

  // Convertir string a double con soporte para comas y puntos

  // Convertir string a double con soporte para comas y puntos

  // Manejar cambios en las celdas de PlutoGrid
  void _onCellChanged(PlutoGridOnChangedEvent event) {
    final rowIndex = event.row.key is int ? event.row.key as int : rows.indexOf(event.row);
    final field = event.column.field;
    
    debugPrint('📝 Celda cambiada: ${event.column.title} = ${event.value}');
    
    if (rowIndex >= 0 && rowIndex < widget.articulos.length) {
      
      switch (field) {
        case 'nombre':
          break;
        case 'demandaAnual':
          break;
        case 'costoPedido':
          break;
        case 'costoMantenimiento':
          break;
        case 'costoFaltante':
          break;
        case 'costoUnitario':
          break;
        case 'espacioUnidad':
          break;
        case 'desviacionDiaria':
          break;
        case 'puntoReorden':
          break;
        case 'tamanoLote':
          break;
        default:
          return;
      }
      
      // Notificar al provider si está disponible
    }
  }

  // Eliminar artículos seleccionados
  void _eliminarArticulosSeleccionados() {
    final selectedRows = stateManager.checkedRows;
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(UniconsLine.trash, color: Colors.red, size: 20),
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
                  color: Colors.red.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.2)),
                ),
                child: const Row(
                  children: [
                    Icon(UniconsLine.exclamation_triangle, color: Colors.red, size: 16),
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
                final indices = selectedRows.map((row) {
                  // Usar el índice de la fila en lugar de la clave
                  return rows.indexOf(row);
                }).toList()
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
                        const Icon(UniconsLine.check_circle, color: Colors.white),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text('${selectedRows.length} artículo${selectedRows.length != 1 ? 's' : ''} eliminado${selectedRows.length != 1 ? 's' : ''} correctamente'),
                        ),
                      ],
                    ),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
    rows = widget.articulos.map(_articuloToPlutoRow).toList();
    
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                        color: MDSJColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(UniconsLine.box, color: MDSJColors.primary),
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
                          backgroundColor: Colors.red.withOpacity(0.1),
                          foregroundColor: Colors.red,
                        ),
                      ),
                    ],
                  ],
                ),
                if (widget.articulos.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: MDSJColors.infoBackground,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: MDSJColors.infoBorder),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          UniconsLine.info_circle,
                          size: 16,
                          color: MDSJColors.primary,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Haz clic en cualquier celda para editar. Usa los checkboxes para seleccionar múltiples artículos.',
                            style: TextStyle(
                              fontSize: 13,
                              color: MDSJColors.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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
                child: PlutoGrid(
                  columns: columns,
                  rows: rows,
                  onLoaded: (PlutoGridOnLoadedEvent event) {
                    stateManager = event.stateManager;
                    stateManager.setShowColumnFilter(false);
                  },
                  onChanged: (PlutoGridOnChangedEvent event) {
                    debugPrint('📝 Celda cambiada: ${event.column.title} = ${event.value}');
                    _onCellChanged(event);
                  },
                  onRowChecked: (PlutoGridOnRowCheckedEvent event) {
                    debugPrint('✅ Fila seleccionada: ${event.isChecked}');
                  },
                  configuration: const PlutoGridConfiguration(
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
    properties..add(DiagnosticsProperty<PlutoGridStateManager>('stateManager', stateManager))
    ..add(IterableProperty<PlutoColumn>('columns', columns))
    ..add(IterableProperty<PlutoRow>('rows', rows));
  }
} 