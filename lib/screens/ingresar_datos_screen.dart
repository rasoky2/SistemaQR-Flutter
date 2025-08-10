import 'package:flutter/material.dart';
import 'package:inventario_qr/models/articulo.model.dart';
import 'package:inventario_qr/providers/inventario.provider.dart';
import 'package:inventario_qr/repositories/excel.repository.dart';
import 'package:inventario_qr/utils/theme_colors.dart';
import 'package:inventario_qr/widgets/articulos_table.dart';
import 'package:inventario_qr/widgets/restriccion_dialog.dart';
import 'package:open_file/open_file.dart';
import 'package:provider/provider.dart';
import 'package:unicons/unicons.dart';

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
  void initState() {
    super.initState();
  }

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

  void _limpiarTodosLosDatos(BuildContext context) {
    final provider = context.read<InventarioProvider>();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Limpieza'),
          content: const Text(
            '¿Estás seguro de que deseas eliminar todos los artículos del inventario? '
            'Esta acción no se puede deshacer.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                provider.limpiarDatos();
                Navigator.pop(context);
                
                // Mostrar mensaje de confirmación
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Todos los datos han sido eliminados'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Eliminar Todo'),
            ),
          ],
        );
      },
    );
  }

  void _agregarArticulo() {
    if (_formKey.currentState?.validate() ?? false) {
      debugPrint('📝 Iniciando agregar artículo manual...');
      
      // Validación adicional para el tamaño de lote
      final tamanoLote = double.tryParse(_tamanoLoteController.text);
      if (tamanoLote == null || tamanoLote <= 0) {
        debugPrint('❌ Tamaño de lote inválido: ${_tamanoLoteController.text}');
        // Mostrar mensaje de error usando AlertDialog
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Error'),
              content: const Text('El tamaño de lote debe ser mayor a 0'),
              actions: [
                TextButton(
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
      
      // Mostrar mensaje de éxito usando AlertDialog
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Éxito'),
            content: const Text('Artículo agregado correctamente'),
            actions: [
              TextButton(
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ingresar Datos'),
        leading: IconButton(
          icon: const Icon(UniconsLine.arrow_left),
              onPressed: () => Navigator.pop(context),
        ),
        actions: [
                      IconButton(
              onPressed: () => mostrarDialogoRestricciones(context),
              icon: const Icon(UniconsLine.setting),
              tooltip: 'Configurar Restricciones',
            ),
          ],
        ),
      body: Consumer<InventarioProvider>(
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
            const Row(
              children: [
                Icon(UniconsLine.plus, color: MDSJColors.primary),
                SizedBox(width: 12),
                Text(
                  'Nuevo Artículo',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: MDSJColors.textPrimary,
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
                        child: ElevatedButton.icon(
                          onPressed: _agregarArticulo,
                          icon: const Icon(UniconsLine.plus),
                          label: const Text('Agregar Artículo'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _limpiarFormulario,
                          icon: const Icon(UniconsLine.times),
                          label: const Text('Limpiar Formulario'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final provider = context.read<InventarioProvider>();
                            debugPrint('🔍 Iniciando proceso de importación Excel (directo por plantilla)...');
                            await provider.seleccionarArchivo();
                            await provider.importarArticulos();
                          },
                          icon: const Icon(UniconsLine.upload_alt),
                          label: const Text('Importar desde Excel'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _generarPlantillaExcel(context),
                          icon: const Icon(UniconsLine.download_alt),
                          label: const Text('Generar Plantilla Excel'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _limpiarTodosLosDatos(context),
                          icon: const Icon(UniconsLine.trash),
                          label: const Text('Limpiar Todos los Datos'),
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
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: 'Ingrese $label',
      ),
      validator: validator,
    );
  }

  Widget _buildArticulosList(InventarioProvider provider) {
    return ArticulosTable(
      articulos: provider.articulos,
      title: 'Artículos Agregados',
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
            return AlertDialog(
              title: const Text('Plantilla Generada'),
              content: const Text(
                'La plantilla Excel se ha generado correctamente con todos los campos necesarios. '
                '¿Deseas abrir el archivo para ver la estructura?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('No'),
                ),
                TextButton(
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
            return AlertDialog(
              title: const Text('Error'),
              content: Text('Error al generar la plantilla Excel: $e'),
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
    }
  }

  // Dialogo de importación eliminado; importación directa con plantilla
} 