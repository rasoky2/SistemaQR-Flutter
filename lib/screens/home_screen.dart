import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Colors, Card, showDialog;
import 'package:inventario_qr/models/articulo.model.dart';
import 'package:inventario_qr/providers/inventario.provider.dart';
import 'package:inventario_qr/widgets/restriccion_dialog.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      header: PageHeader(
        title: Row(
          children: [
            const Text('Sistema QR de Inventario'),
            const Spacer(),
            Button(
              onPressed: () => mostrarDialogoRestricciones(context),
              child: const Icon(FluentIcons.settings, size: 20),
            ),
          ],
        ),
      ),
      content: Consumer<InventarioProvider>(
        builder: (context, provider, child) {
          debugPrint('🏠 HomeScreen: Consumer reconstruyendo - Artículos: ${provider.articulos.length}');
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSystemSummary(provider),
                const SizedBox(height: 32),
                _buildNavigationCards(context, provider),
                const SizedBox(height: 32),
                _buildArticulosTable(provider, context),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSystemSummary(InventarioProvider provider) {
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
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    'Artículos',
                    '${provider.articulos.length}',
                    FluentIcons.package,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    'Costo Total',
                    provider.resultado != null 
                        ? 'S/ ${provider.resultado!.costoTotalSistema.toStringAsFixed(2)}'
                        : 'N/A',
                    FluentIcons.money,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    'Espacio Usado',
                    provider.resultado != null 
                        ? '${provider.resultado!.espacioTotalUsado.toStringAsFixed(1)} m²'
                        : 'N/A',
                    FluentIcons.database,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 32, color: Colors.blue),
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

  Widget _buildNavigationCards(BuildContext context, InventarioProvider provider) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.8,
      children: [
        _buildNavigationCard(
          context,
          'Ingresar Datos',
          'Agregar artículos manualmente',
          FluentIcons.add,
          Colors.teal,
          () => Navigator.pushNamed(context, '/ingresar-datos'),
        ),
        _buildNavigationCard(
          context,
          'Datos de Ejemplo',
          'Cargar datos de prueba',
          FluentIcons.lightning_bolt,
          Colors.green,
          () => provider.cargarDatosEjemplo(),
        ),
        _buildNavigationCard(
          context,
          'Ver Resultados',
          'Mostrar cálculos detallados',
          FluentIcons.calculator,
          Colors.orange,
          () => Navigator.pushNamed(context, '/resultados'),
          enabled: provider.resultado != null,
        ),
        _buildNavigationCard(
          context,
          'Limpiar Datos',
          'Eliminar todos los artículos',
          FluentIcons.delete,
          Colors.red,
          () => provider.limpiarDatos(),
          enabled: provider.articulos.isNotEmpty,
        ),
      ],
    );
  }

  Widget _buildNavigationCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback? onPressed, {
    bool enabled = true,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Tamaño de fuente responsivo basado en el ancho de la pantalla
    final titleFontSize = screenWidth > 1200 ? 14.0 : 
                         screenWidth > 800 ? 12.0 : 10.0;
    final subtitleFontSize = screenWidth > 1200 ? 10.0 : 
                           screenWidth > 800 ? 8.0 : 6.0;
    final iconSize = screenWidth > 1200 ? 24.0 : 
                    screenWidth > 800 ? 20.0 : 16.0;
    
    return Card(
      child: Button(
        onPressed: enabled ? onPressed : null,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: iconSize,
                color: enabled ? color : Colors.grey,
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.bold,
                  color: enabled ? Colors.black : Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: subtitleFontSize,
                  color: enabled ? Colors.grey : Colors.grey,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildArticulosTable(InventarioProvider provider, BuildContext context) {
    debugPrint('🏠 HomeScreen: Construyendo tabla de artículos');
    debugPrint('🏠 HomeScreen: Total de artículos en provider: ${provider.articulos.length}');
    debugPrint('🏠 HomeScreen: Nombres de artículos: ${provider.articulos.map((a) => a.nombre).toList()}');
    
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
                Text(
                  'Artículos en Inventario (${provider.articulos.length})',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (provider.articulos.isEmpty)
              const Center(
                child: Column(
                  children: [
                    Icon(FluentIcons.package, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No hay artículos en el inventario',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Agrega artículos usando los botones de arriba',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: [
                    const DataColumn(label: Text('Parámetro')),
                    ...provider.articulos.asMap().entries.map((entry) {
                      final index = entry.key;
                      final articulo = entry.value;
                      return DataColumn(
                        label: Row(
                          children: [
                            Text(articulo.nombre),
                            const SizedBox(width: 8),
                            Button(
                              onPressed: () => provider.eliminarArticulo(index),
                              child: const Icon(FluentIcons.delete, size: 12),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                  rows: <DataRow>[
                    _buildEditableParameterRow('Demanda anual (Dᵢ)', provider, (index, value) {
                      final articulo = provider.articulos[index];
                      final newArticulo = Articulo(
                        nombre: articulo.nombre,
                        demandaAnual: value,
                        costoPedido: articulo.costoPedido,
                        costoMantenimiento: articulo.costoMantenimiento,
                        costoFaltante: articulo.costoFaltante,
                        costoUnitario: articulo.costoUnitario,
                        espacioUnidad: articulo.espacioUnidad,
                        desviacionDiaria: articulo.desviacionDiaria,
                        puntoReorden: articulo.puntoReorden,
                        tamanoLote: articulo.tamanoLote,
                      );
                      provider.actualizarArticulo(index, newArticulo);
                    }),
                    _buildEditableParameterRow('Costo por pedido (Kᵢ)', provider, (index, value) {
                      final articulo = provider.articulos[index];
                      final newArticulo = Articulo(
                        nombre: articulo.nombre,
                        demandaAnual: articulo.demandaAnual,
                        costoPedido: value,
                        costoMantenimiento: articulo.costoMantenimiento,
                        costoFaltante: articulo.costoFaltante,
                        costoUnitario: articulo.costoUnitario,
                        espacioUnidad: articulo.espacioUnidad,
                        desviacionDiaria: articulo.desviacionDiaria,
                        puntoReorden: articulo.puntoReorden,
                        tamanoLote: articulo.tamanoLote,
                      );
                      provider.actualizarArticulo(index, newArticulo);
                    }),
                    _buildEditableParameterRow('Costo mant. anual (hᵢ)', provider, (index, value) {
                      final articulo = provider.articulos[index];
                      final newArticulo = Articulo(
                        nombre: articulo.nombre,
                        demandaAnual: articulo.demandaAnual,
                        costoPedido: articulo.costoPedido,
                        costoMantenimiento: value,
                        costoFaltante: articulo.costoFaltante,
                        costoUnitario: articulo.costoUnitario,
                        espacioUnidad: articulo.espacioUnidad,
                        desviacionDiaria: articulo.desviacionDiaria,
                        puntoReorden: articulo.puntoReorden,
                        tamanoLote: articulo.tamanoLote,
                      );
                      provider.actualizarArticulo(index, newArticulo);
                    }),
                    _buildEditableParameterRow('Costo por faltante (pᵢ)', provider, (index, value) {
                      final articulo = provider.articulos[index];
                      final newArticulo = Articulo(
                        nombre: articulo.nombre,
                        demandaAnual: articulo.demandaAnual,
                        costoPedido: articulo.costoPedido,
                        costoMantenimiento: articulo.costoMantenimiento,
                        costoFaltante: value,
                        costoUnitario: articulo.costoUnitario,
                        espacioUnidad: articulo.espacioUnidad,
                        desviacionDiaria: articulo.desviacionDiaria,
                        puntoReorden: articulo.puntoReorden,
                        tamanoLote: articulo.tamanoLote,
                      );
                      provider.actualizarArticulo(index, newArticulo);
                    }),
                    _buildEditableParameterRow('Costo unitario (cᵢ)', provider, (index, value) {
                      final articulo = provider.articulos[index];
                      final newArticulo = Articulo(
                        nombre: articulo.nombre,
                        demandaAnual: articulo.demandaAnual,
                        costoPedido: articulo.costoPedido,
                        costoMantenimiento: articulo.costoMantenimiento,
                        costoFaltante: articulo.costoFaltante,
                        costoUnitario: value,
                        espacioUnidad: articulo.espacioUnidad,
                        desviacionDiaria: articulo.desviacionDiaria,
                        puntoReorden: articulo.puntoReorden,
                        tamanoLote: articulo.tamanoLote,
                      );
                      provider.actualizarArticulo(index, newArticulo);
                    }),
                    _buildEditableParameterRow('Espacio por unidad (sᵢ)', provider, (index, value) {
                      final articulo = provider.articulos[index];
                      final newArticulo = Articulo(
                        nombre: articulo.nombre,
                        demandaAnual: articulo.demandaAnual,
                        costoPedido: articulo.costoPedido,
                        costoMantenimiento: articulo.costoMantenimiento,
                        costoFaltante: articulo.costoFaltante,
                        costoUnitario: articulo.costoUnitario,
                        espacioUnidad: value,
                        desviacionDiaria: articulo.desviacionDiaria,
                        puntoReorden: articulo.puntoReorden,
                        tamanoLote: articulo.tamanoLote,
                      );
                      provider.actualizarArticulo(index, newArticulo);
                    }),
                    _buildEditableParameterRow('Desv. estándar diaria (σ)', provider, (index, value) {
                      final articulo = provider.articulos[index];
                      final newArticulo = Articulo(
                        nombre: articulo.nombre,
                        demandaAnual: articulo.demandaAnual,
                        costoPedido: articulo.costoPedido,
                        costoMantenimiento: articulo.costoMantenimiento,
                        costoFaltante: articulo.costoFaltante,
                        costoUnitario: articulo.costoUnitario,
                        espacioUnidad: articulo.espacioUnidad,
                        desviacionDiaria: value,
                        puntoReorden: articulo.puntoReorden,
                        tamanoLote: articulo.tamanoLote,
                      );
                      provider.actualizarArticulo(index, newArticulo);
                    }),
                    _buildEditableParameterRow('Punto de reorden (Rᵢ)', provider, (index, value) {
                      final articulo = provider.articulos[index];
                      final newArticulo = Articulo(
                        nombre: articulo.nombre,
                        demandaAnual: articulo.demandaAnual,
                        costoPedido: articulo.costoPedido,
                        costoMantenimiento: articulo.costoMantenimiento,
                        costoFaltante: articulo.costoFaltante,
                        costoUnitario: articulo.costoUnitario,
                        espacioUnidad: articulo.espacioUnidad,
                        desviacionDiaria: articulo.desviacionDiaria,
                        puntoReorden: value,
                        tamanoLote: articulo.tamanoLote,
                      );
                      provider.actualizarArticulo(index, newArticulo);
                    }),
                    _buildEditableParameterRow('Tamaño de lote (Qᵢ)', provider, (index, value) {
                      final articulo = provider.articulos[index];
                      final newArticulo = Articulo(
                        nombre: articulo.nombre,
                        demandaAnual: articulo.demandaAnual,
                        costoPedido: articulo.costoPedido,
                        costoMantenimiento: articulo.costoMantenimiento,
                        costoFaltante: articulo.costoFaltante,
                        costoUnitario: articulo.costoUnitario,
                        espacioUnidad: articulo.espacioUnidad,
                        desviacionDiaria: articulo.desviacionDiaria,
                        puntoReorden: articulo.puntoReorden,
                        tamanoLote: value,
                      );
                      provider.actualizarArticulo(index, newArticulo);
                    }),
                  ],
                ),
              ),
            if (provider.articulos.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F8FF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFFB3D9FF),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(FluentIcons.info, color: Colors.blue, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Restricción: Máximo ${provider.espacioMaximo.toStringAsFixed(1)} m² en total',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Button(
                          onPressed: () => mostrarDialogoRestricciones(context),
                          child: const Icon(FluentIcons.edit, size: 14),
                        ),
                      ],
                    ),
                    if (provider.resultado != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            provider.resultado!.espacioTotalUsado <= provider.espacioMaximo 
                                ? FluentIcons.check_mark 
                                : FluentIcons.error,
                            color: provider.resultado!.espacioTotalUsado <= provider.espacioMaximo 
                                ? Colors.green 
                                : Colors.red,
                            size: 14,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Espacio usado: ${provider.resultado!.espacioTotalUsado.toStringAsFixed(1)} m² / ${provider.espacioMaximo.toStringAsFixed(1)} m²',
                            style: TextStyle(
                              fontSize: 12,
                              color: provider.resultado!.espacioTotalUsado <= provider.espacioMaximo 
                                  ? Colors.green 
                                  : Colors.red,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  DataRow _buildEditableParameterRow(String parameter, InventarioProvider provider, Function(int, double) onValueChanged) {
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
        ...provider.articulos.asMap().entries.map((entry) {
          final index = entry.key;
          final articulo = entry.value;
          
          // Determinar el valor a mostrar según el parámetro
          double value;
          String displayValue;
          String suffix = '';
          
          switch (parameter) {
            case 'Demanda anual (Dᵢ)':
              value = articulo.demandaAnual;
              displayValue = value.toStringAsFixed(0);
              suffix = ' unidades';
              break;
            case 'Costo por pedido (Kᵢ)':
              value = articulo.costoPedido;
              displayValue = 'S/ ${value.toStringAsFixed(2)}';
              break;
            case 'Costo mant. anual (hᵢ)':
              value = articulo.costoMantenimiento;
              displayValue = 'S/ ${value.toStringAsFixed(2)}';
              suffix = '/unidad';
              break;
            case 'Costo por faltante (pᵢ)':
              value = articulo.costoFaltante;
              displayValue = 'S/ ${value.toStringAsFixed(2)}';
              suffix = '/unidad';
              break;
            case 'Costo unitario (cᵢ)':
              value = articulo.costoUnitario;
              displayValue = 'S/ ${value.toStringAsFixed(2)}';
              break;
            case 'Espacio por unidad (sᵢ)':
              value = articulo.espacioUnidad;
              displayValue = value.toStringAsFixed(1);
              suffix = ' m²';
              break;
            case 'Desv. estándar diaria (σ)':
              value = articulo.desviacionDiaria;
              displayValue = value.toStringAsFixed(1);
              suffix = ' unidades/día';
              break;
            case 'Punto de reorden (Rᵢ)':
              value = articulo.puntoReorden;
              displayValue = value.toStringAsFixed(0);
              suffix = ' unidades';
              break;
            case 'Tamaño de lote (Qᵢ)':
              value = articulo.tamanoLote;
              displayValue = value.toStringAsFixed(0);
              suffix = ' unidades';
              break;
            default:
              value = 0.0;
              displayValue = '0';
          }
          
          return DataCell(
            _EditableCell(
              displayValue: displayValue + suffix,
              currentValue: value,
              onValueChanged: (newValue) => onValueChanged(index, newValue),
              parameter: parameter,
            ),
          );
        }),
      ],
    );
  }


}

class _EditableCell extends StatefulWidget {
  final String displayValue;
  final double currentValue;
  final Function(double) onValueChanged;
  final String parameter;

  const _EditableCell({
    required this.displayValue,
    required this.currentValue,
    required this.onValueChanged,
    required this.parameter,
  });

  @override
  State<_EditableCell> createState() => _EditableCellState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('displayValue', displayValue))
      ..add(DoubleProperty('currentValue', currentValue))
      ..add(ObjectFlagProperty<Function(double p1)>.has('onValueChanged', onValueChanged))
      ..add(StringProperty('parameter', parameter));
  }
}

class _EditableCellState extends State<_EditableCell> {
  bool _isEditing = false;
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _getNumericValue().toString());
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && _isEditing) {
        _finishEditing();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  double _getNumericValue() {
    // Extrae el valor numérico del displayValue
    final value = double.tryParse(widget.displayValue.replaceAll(RegExp(r'[^0-9.,-]'), '').replaceAll(',', '.'));
    return value ?? widget.currentValue;
  }

  void _startEditing() {
    setState(() => _isEditing = true);
    _focusNode.requestFocus();
    // Selecciona todo el texto al entrar en edición
    _controller.selection = TextSelection(baseOffset: 0, extentOffset: _controller.text.length);
  }

  void _finishEditing() {
    final value = double.tryParse(_controller.text.replaceAll(',', '.'));
    if (value != null) {
      widget.onValueChanged(value);
    }
    setState(() => _isEditing = false);
  }

  @override
  Widget build(BuildContext context) {
    // Alternar fondo tipo Excel (puedes usar hashCode para alternar color)
    final isEven = widget.parameter.hashCode.isEven;
    final baseColor = isEven ? const Color(0xFFF8FAFC) : const Color(0xFFFFFFFF);
    final borderColor = _isEditing ? Colors.blue : Colors.grey.withValues(alpha: 0.3);
    final borderWidth = _isEditing ? 2.0 : 1.0;

    return GestureDetector(
      onDoubleTap: _startEditing,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: baseColor,
          border: Border.all(color: borderColor, width: borderWidth),
          borderRadius: BorderRadius.circular(_isEditing ? 4 : 0),
        ),
        child: _isEditing
            ? TextField(
                controller: _controller,
                focusNode: _focusNode,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onSubmitted: (_) => _finishEditing(),
                onEditingComplete: _finishEditing,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                  border: InputBorder.none,
                ),
                onTap: () {
                  // Selecciona todo el texto al hacer tap en modo edición
                  _controller.selection = TextSelection(baseOffset: 0, extentOffset: _controller.text.length);
                },
              )
            : MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Text(
                  widget.displayValue,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: _isEditing ? Colors.blue : Colors.black,
                  ),
                ),
              ),
      ),
    );
  }
} 