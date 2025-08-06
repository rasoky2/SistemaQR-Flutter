import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Colors, Card, showDialog, Checkbox, FilledButton;
import 'package:inventario_qr/models/articulo.model.dart';
import 'package:inventario_qr/providers/inventario.provider.dart';
import 'package:inventario_qr/repositories/excel.repository.dart';
import 'package:inventario_qr/widgets/restriccion_dialog.dart';
import 'package:open_file/open_file.dart';
import 'package:provider/provider.dart';

class IngresarDatosScreen extends StatefulWidget {
  const IngresarDatosScreen({super.key});

  @override
  State<IngresarDatosScreen> createState() => _IngresarDatosScreenState();
}

class _IngresarDatosScreenState extends State<IngresarDatosScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _demandaController = TextEditingController();
  final _costoPedidoController = TextEditingController();
  final _costoMantenimientoController = TextEditingController();
  final _costoFaltanteController = TextEditingController();
  final _costoUnitarioController = TextEditingController();
  final _espacioUnidadController = TextEditingController();
  final _desviacionDiariaController = TextEditingController();
  final _puntoReordenController = TextEditingController();
  final _tamanoLoteController = TextEditingController();

  @override
  void dispose() {
    _nombreController.dispose();
    _demandaController.dispose();
    _costoPedidoController.dispose();
    _costoMantenimientoController.dispose();
    _costoFaltanteController.dispose();
    _costoUnitarioController.dispose();
    _espacioUnidadController.dispose();
    _desviacionDiariaController.dispose();
    _puntoReordenController.dispose();
    _tamanoLoteController.dispose();
    super.dispose();
  }

  void _limpiarFormulario() {
    _formKey.currentState?.reset();
    _nombreController.clear();
    _demandaController.clear();
    _costoPedidoController.clear();
    _costoMantenimientoController.clear();
    _costoFaltanteController.clear();
    _costoUnitarioController.clear();
    _espacioUnidadController.clear();
    _desviacionDiariaController.clear();
    _puntoReordenController.clear();
    _tamanoLoteController.clear();
  }

  void _agregarArticulo() {
    if (_formKey.currentState?.validate() ?? false) {
      debugPrint('📝 Iniciando agregar artículo manual...');
      
      // Validación adicional para el tamaño de lote
      final tamanoLote = double.tryParse(_tamanoLoteController.text);
      if (tamanoLote == null || tamanoLote <= 0) {
        debugPrint('❌ Tamaño de lote inválido: ${_tamanoLoteController.text}');
        // Mostrar mensaje de error usando InfoBar
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return ContentDialog(
              title: const Text('Error'),
              content: const Text('El tamaño de lote debe ser mayor a 0'),
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

      // Crear el artículo
      final articulo = Articulo(
        nombre: _nombreController.text.trim(),
        demandaAnual: double.parse(_demandaController.text),
        costoPedido: double.parse(_costoPedidoController.text),
        costoMantenimiento: double.parse(_costoMantenimientoController.text),
        costoFaltante: double.parse(_costoFaltanteController.text),
        costoUnitario: double.parse(_costoUnitarioController.text),
        espacioUnidad: double.parse(_espacioUnidadController.text),
        desviacionDiaria: double.parse(_desviacionDiariaController.text),
        puntoReorden: double.parse(_puntoReordenController.text),
        tamanoLote: tamanoLote,
      );

      debugPrint('📦 Artículo creado: ${articulo.nombre}');
      debugPrint('   - Demanda anual: ${articulo.demandaAnual}');
      debugPrint('   - Costo pedido: ${articulo.costoPedido}');
      debugPrint('   - Costo mantenimiento: ${articulo.costoMantenimiento}');
      debugPrint('   - Costo faltante: ${articulo.costoFaltante}');
      debugPrint('   - Costo unitario: ${articulo.costoUnitario}');
      debugPrint('   - Espacio unidad: ${articulo.espacioUnidad}');
      debugPrint('   - Desviación diaria: ${articulo.desviacionDiaria}');
      debugPrint('   - Punto reorden: ${articulo.puntoReorden}');
      debugPrint('   - Tamaño lote: ${articulo.tamanoLote}');

      // Agregar el artículo al provider
      final provider = context.read<InventarioProvider>()
      ..agregarArticulo(articulo);
      
      debugPrint('✅ Artículo agregado al provider. Total de artículos: ${provider.articulos.length}');
      
      _limpiarFormulario();
      
      // Mostrar mensaje de éxito usando InfoBar
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return ContentDialog(
            title: const Text('Éxito'),
            content: const Text('Artículo agregado correctamente'),
            actions: [
              Button(
                onPressed: () => Navigator.pop(context),
                child: const Text('Aceptar'),
              ),
            ],
          );
        },
      );
    } else {
      debugPrint('❌ Validación del formulario falló');
    }
  }

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
            const Text('Ingresar Datos'),
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
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFormCard(),
                const SizedBox(height: 24),
                _buildArticulosList(provider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFormCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(FluentIcons.add, color: Colors.blue),
                const SizedBox(width: 12),
                const Text(
                  'Nuevo Artículo',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _nombreController,
                          label: 'Nombre del Artículo',
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'El nombre es requerido';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTextField(
                          controller: _demandaController,
                          label: 'Demanda Anual (unidades)',
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'La demanda es requerida';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Debe ser un número válido';
                            }
                            if (double.parse(value) <= 0) {
                              return 'Debe ser mayor a 0';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _costoPedidoController,
                          label: 'Costo por Pedido (soles)',
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'El costo es requerido';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Debe ser un número válido';
                            }
                            if (double.parse(value) <= 0) {
                              return 'Debe ser mayor a 0';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTextField(
                          controller: _costoMantenimientoController,
                          label: 'Costo Mantenimiento (soles/unidad)',
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'El costo es requerido';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Debe ser un número válido';
                            }
                            if (double.parse(value) <= 0) {
                              return 'Debe ser mayor a 0';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _costoFaltanteController,
                          label: 'Costo por Faltante (soles/unidad)',
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'El costo es requerido';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Debe ser un número válido';
                            }
                            if (double.parse(value) <= 0) {
                              return 'Debe ser mayor a 0';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTextField(
                          controller: _costoUnitarioController,
                          label: 'Costo Unitario (soles)',
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'El costo es requerido';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Debe ser un número válido';
                            }
                            if (double.parse(value) <= 0) {
                              return 'Debe ser mayor a 0';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _espacioUnidadController,
                          label: 'Espacio por Unidad (m²)',
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'El espacio es requerido';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Debe ser un número válido';
                            }
                            if (double.parse(value) <= 0) {
                              return 'Debe ser mayor a 0';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTextField(
                          controller: _desviacionDiariaController,
                          label: 'Desviación Estándar Diaria',
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'La desviación es requerida';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Debe ser un número válido';
                            }
                            if (double.parse(value) < 0) {
                              return 'Debe ser mayor o igual a 0';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _puntoReordenController,
                          label: 'Punto de Reorden (unidades)',
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'El punto de reorden es requerido';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Debe ser un número válido';
                            }
                            if (double.parse(value) < 0) {
                              return 'Debe ser mayor o igual a 0';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTextField(
                          controller: _tamanoLoteController,
                          label: 'Tamaño de Lote (unidades)',
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'El tamaño de lote es requerido';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Debe ser un número válido';
                            }
                            if (double.parse(value) <= 0) {
                              return 'Debe ser mayor a 0';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: Button(
                          onPressed: _agregarArticulo,
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(FluentIcons.add),
                              SizedBox(width: 8),
                              Text('Agregar Artículo'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Button(
                          onPressed: _limpiarFormulario,
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(FluentIcons.clear),
                              SizedBox(width: 8),
                              Text('Limpiar Formulario'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Button(
                          onPressed: () => _mostrarDialogoImportarExcel(context),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(FluentIcons.excel_document),
                              SizedBox(width: 8),
                              Text('Importar desde Excel'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Button(
                          onPressed: () => _generarPlantillaExcel(context),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(FluentIcons.download),
                              SizedBox(width: 8),
                              Text('Generar Plantilla Excel'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
  }) {
    return TextFormBox(
      controller: controller,
      placeholder: 'Ingrese $label',
      validator: validator,
    );
  }

  Widget _buildArticulosList(InventarioProvider provider) {
    if (provider.articulos.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Center(
            child: Column(
              children: [
                Icon(FluentIcons.package, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No hay artículos agregados',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Agrega artículos usando el formulario de arriba',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
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
            Row(
              children: [
                Icon(FluentIcons.package, color: Colors.blue),
                const SizedBox(width: 12),
                Text(
                  'Artículos Agregados (${provider.articulos.length})',
                  style: const TextStyle(
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
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(FluentIcons.info, color: Colors.blue, size: 16),
                    const SizedBox(width: 8),
                    const Text(
                      'Restricción: Máximo 150 m² en total',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
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

  Future<void> _generarPlantillaExcel(BuildContext context) async {
    try {
      debugPrint('📋 Iniciando generación de plantilla Excel...');
      
      // Generar la plantilla usando el repositorio
      final filePath = await ExcelRepository.generarPlantilla();
      
      debugPrint('✅ Plantilla generada exitosamente en: $filePath');
      
      // Mostrar diálogo de confirmación
      if (context.mounted) {
        final bool? abrirArchivo = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return ContentDialog(
              title: const Text('Plantilla Generada'),
              content: const Text(
                'La plantilla Excel se ha generado correctamente con todos los campos necesarios. '
                '¿Deseas abrir el archivo para ver la estructura?',
              ),
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
          debugPrint('📂 Abriendo plantilla Excel...');
          final result = await OpenFile.open(filePath);
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
      debugPrint('❌ Error al generar plantilla: $e');
      
      // Mostrar mensaje de error
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return ContentDialog(
              title: const Text('Error'),
              content: Text('Error al generar la plantilla Excel: $e'),
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

  Future<void> _mostrarDialogoImportarExcel(BuildContext context) async {
    final provider = context.read<InventarioProvider>();
    
    try {
      debugPrint('🔍 Iniciando proceso de importación Excel...');
      
      // Primero seleccionar el archivo
      await provider.seleccionarArchivo();
      debugPrint('📄 Archivo seleccionado correctamente');
      
      // Leer las columnas disponibles en el archivo Excel
      final columnasDisponibles = await provider.leerColumnasExcel();
      debugPrint('📋 Columnas disponibles: $columnasDisponibles');
      
      // Limpiar columnas de importación y agregar las disponibles
      provider.limpiarColumnasImportar();
      for (final columna in columnasDisponibles) {
        provider.agregarColumnaImportar(columna);
      }
      debugPrint('📋 Columnas configuradas para importación');

      if (context.mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return StatefulBuilder(
              builder: (context, setState) {
                return ContentDialog(
                  title: const Text('Seleccionar Columnas para Importar'),
                  content: SizedBox(
                    width: 400,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Seleccione las columnas que desea importar del archivo Excel:',
                          style: TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 16),
                        ...columnasDisponibles.map((columna) => Checkbox(
                          checked: provider.columnasImportar.contains(columna),
                          onChanged: (bool? value) {
                            debugPrint('🔘 Checkbox cambiado para columna: $columna, valor: $value');
                            if (value == true) {
                              provider.agregarColumnaImportar(columna);
                            } else {
                              provider.eliminarColumnaImportar(columna);
                            }
                            setState(() {}); // Reconstruir el diálogo
                          },
                          content: Text(columna),
                        )),
                      ],
                    ),
                  ),
                  actions: [
                    Button(
                      onPressed: () {
                        debugPrint('📥 Botón Importar presionado');
                        Navigator.pop(context);
                        provider.importarArticulos().then((_) {
                          // Mostrar diálogo de advertencia si hay campos faltantes
                          if (provider.error != null && provider.error!.contains('campos faltantes')) {
                            if (context.mounted) {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return ContentDialog(
                                    title: const Text('⚠️ Campos Faltantes'),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Se detectaron artículos con campos faltantes o inválidos:',
                                          style: TextStyle(fontSize: 14),
                                        ),
                                        const SizedBox(height: 16),
                                        ...provider.articulos.where((articulo) {
                                          return articulo.demandaAnual <= 0 ||
                                                 articulo.costoPedido <= 0 ||
                                                 articulo.costoMantenimiento <= 0 ||
                                                 articulo.costoFaltante <= 0 ||
                                                 articulo.costoUnitario <= 0 ||
                                                 articulo.espacioUnidad <= 0 ||
                                                 articulo.desviacionDiaria < 0 ||
                                                 articulo.puntoReorden < 0 ||
                                                 articulo.tamanoLote <= 0;
                                        }).map((articulo) {
                                          final problemas = <String>[];
                                          if (articulo.demandaAnual <= 0) {
                                            problemas.add('Demanda anual');
                                          }
                                          if (articulo.costoPedido <= 0) {
                                            problemas.add('Costo por pedido');
                                          }
                                          if (articulo.costoMantenimiento <= 0) {
                                            problemas.add('Costo mantenimiento');
                                          }
                                          if (articulo.costoFaltante <= 0) {
                                            problemas.add('Costo por faltante');
                                          }
                                          if (articulo.costoUnitario <= 0) {
                                            problemas.add('Costo unitario');
                                          }
                                          if (articulo.espacioUnidad <= 0) {
                                            problemas.add('Espacio por unidad');
                                          }
                                          if (articulo.desviacionDiaria < 0) {
                                            problemas.add('Desviación estándar diaria');
                                          }
                                          if (articulo.puntoReorden < 0) {
                                            problemas.add('Punto de reorden');
                                          }
                                          if (articulo.tamanoLote <= 0) {
                                            problemas.add('Tamaño de lote');
                                          }
                                          
                                          return Padding(
                                            padding: const EdgeInsets.only(bottom: 8),
                                            child: Text(
                                              '• ${articulo.nombre}: ${problemas.join(', ')}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.red,
                                              ),
                                            ),
                                          );
                                        }),
                                        const SizedBox(height: 16),
                                        const Text(
                                          'Por favor, edite los artículos en la tabla para completar los datos faltantes.',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ],
                                    ),
                                    actions: [
                                      Button(
                                        onPressed: () {
                                          Navigator.pop(context);
                                        },
                                        child: const Text('Entendido'),
                                      ),
                                    ],
                                  );
                                },
                              );
                            }
                          }
                        });
                      },
                      child: const Text('Importar'),
                    ),
                    Button(
                      onPressed: () {
                        debugPrint('❌ Botón Cancelar presionado');
                        Navigator.pop(context);
                      },
                      child: const Text('Cancelar'),
                    ),
                  ],
                );
              },
            );
          },
        );
      }
    } catch (e) {
      debugPrint('❌ Error en proceso de importación: $e');
      // Mostrar error si no se puede leer el archivo
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return ContentDialog(
              title: const Text('Error'),
              content: Text('Error al leer el archivo Excel: $e'),
              actions: [
                Button(
                  onPressed: () {
                    Navigator.pop(context);
                  },
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
    properties..add(StringProperty('displayValue', displayValue))
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
    final borderColor = _isEditing ? Colors.blue : Colors.grey.withOpacity(0.3);
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