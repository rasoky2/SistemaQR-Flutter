import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:inventario_qr/models/articulo.model.dart';
import 'package:inventario_qr/providers/inventario.provider.dart';
import 'package:inventario_qr/repositories/excel.repository.dart';
import 'package:inventario_qr/screens/tutorial_screen.dart';
import 'package:inventario_qr/utils/logger.dart';
import 'package:inventario_qr/widgets/articulos_table.dart';
import 'package:inventario_qr/widgets/restriccion_dialog.dart';
import 'package:inventario_qr/widgets/restriccion_fab.dart';
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
  
  // Focus nodes para navegación rápida con Enter/Tab
  final _nombreFocus = FocusNode();
  final _demandaFocus = FocusNode();
  final _costoPedidoFocus = FocusNode();
  final _costoMantenimientoFocus = FocusNode();
  final _costoFaltanteFocus = FocusNode();
  final _costoUnitarioFocus = FocusNode();
  final _espacioUnidadFocus = FocusNode();
  final _desviacionDiariaFocus = FocusNode();
  final _puntoReordenFocus = FocusNode();
  final _tamanoLoteFocus = FocusNode();
  
  double? _parseNum(String? input) {
    if (input == null) {
      return null;
    }
    String s = input.trim();
    if (s.isEmpty) {
      return null;
    }
    // Si no hay punto y sí hay coma, usar coma como decimal
    if (!s.contains('.') && s.contains(',')) {
      s = s.replaceAll(',', '.');
    }
    // Quitar separadores de miles comunes
    s = s.replaceAll('\u00A0', '').replaceAll(' ', '');
    return double.tryParse(s);
  }
  


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
    _nombreFocus.dispose();
    _demandaFocus.dispose();
    _costoPedidoFocus.dispose();
    _costoMantenimientoFocus.dispose();
    _costoFaltanteFocus.dispose();
    _costoUnitarioFocus.dispose();
    _espacioUnidadFocus.dispose();
    _desviacionDiariaFocus.dispose();
    _puntoReordenFocus.dispose();
    _tamanoLoteFocus.dispose();
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
      logDebug('📝 Iniciando agregar artículo manual...');
      
      // Validación adicional para el tamaño de lote
      final tamanoLote = _parseNum(_tamanoLoteController.text);
      if (tamanoLote == null || tamanoLote <= 0) {
        logDebug('❌ Tamaño de lote inválido: ${_tamanoLoteController.text}');
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
        demandaAnual: _parseNum(_demandaController.text) ?? 0,
        costoPedido: _parseNum(_costoPedidoController.text) ?? 0,
        costoMantenimiento: _parseNum(_costoMantenimientoController.text) ?? 0,
        costoFaltante: _parseNum(_costoFaltanteController.text) ?? 0,
        costoUnitario: _parseNum(_costoUnitarioController.text) ?? 0,
        espacioUnidad: _parseNum(_espacioUnidadController.text) ?? 0,
        desviacionDiaria: _parseNum(_desviacionDiariaController.text) ?? 0,
        puntoReorden: _parseNum(_puntoReordenController.text) ?? 0,
        tamanoLote: tamanoLote,
      );

      logDebug('📦 Artículo creado: ${articulo.nombre}');
      logDebug('   - Demanda anual: ${articulo.demandaAnual}');
      logDebug('   - Costo pedido: ${articulo.costoPedido}');
      logDebug('   - Costo mantenimiento: ${articulo.costoMantenimiento}');
      logDebug('   - Costo faltante: ${articulo.costoFaltante}');
      logDebug('   - Costo unitario: ${articulo.costoUnitario}');
      logDebug('   - Espacio unidad: ${articulo.espacioUnidad}');
      logDebug('   - Desviación diaria: ${articulo.desviacionDiaria}');
      logDebug('   - Punto reorden: ${articulo.puntoReorden}');
      logDebug('   - Tamaño lote: ${articulo.tamanoLote}');

      // Agregar el artículo al provider
      final provider = context.read<InventarioProvider>()
      ..agregarArticulo(articulo);
      
      logDebug('✅ Artículo agregado al provider. Total de artículos: ${provider.articulos.length}');
      
      _limpiarFormulario();
      
      // Feedback ligero sin bloquear (mejor UX)
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Artículo agregado correctamente'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      logDebug('❌ Validación del formulario falló');
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
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TutorialScreen()),
            ),
            icon: const Icon(UniconsLine.question_circle),
            tooltip: 'Ayuda',
          ),
          IconButton(
            onPressed: () => mostrarDialogoRestricciones(context),
            icon: const Icon(UniconsLine.setting),
            tooltip: 'Configurar Restricciones',
          ),
        ],
        ),
      body: CallbackShortcuts(
        bindings: <ShortcutActivator, VoidCallback>{
          const SingleActivator(LogicalKeyboardKey.enter, control: true): _agregarArticulo,
        },
        child: Consumer<InventarioProvider>(
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
      ),
      floatingActionButton: const RestriccionFab(),
    );
  }

  Widget _buildFormCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
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
                          focusNode: _nombreFocus,
                          nextFocusNode: _demandaFocus,
                          textInputAction: TextInputAction.next,
                          autofocus: true,
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
                        child: _buildNumberField(
                          controller: _demandaController,
                          label: 'Demanda Anual (unidades)',
                          focusNode: _demandaFocus,
                          nextFocusNode: _costoPedidoFocus,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'La demanda es requerida';
                            }
                            final v = _parseNum(value);
                            if (v == null) {
                              return 'Debe ser un número válido';
                            }
                            if (v <= 0) {
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
                        child: _buildNumberField(
                          controller: _costoPedidoController,
                          label: 'Costo por Pedido (soles)',
                          focusNode: _costoPedidoFocus,
                          nextFocusNode: _costoMantenimientoFocus,
                          step: 0.1,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'El costo es requerido';
                            }
                            final v = _parseNum(value);
                            if (v == null) {
                              return 'Debe ser un número válido';
                            }
                            if (v <= 0) {
                              return 'Debe ser mayor a 0';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildNumberField(
                          controller: _costoMantenimientoController,
                          label: 'Costo Mantenimiento (soles/unidad)',
                          focusNode: _costoMantenimientoFocus,
                          nextFocusNode: _costoFaltanteFocus,
                          step: 0.1,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'El costo es requerido';
                            }
                            final v = _parseNum(value);
                            if (v == null) {
                              return 'Debe ser un número válido';
                            }
                            if (v <= 0) {
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
                        child: _buildNumberField(
                          controller: _costoFaltanteController,
                          label: 'Costo por Faltante (soles/unidad)',
                          focusNode: _costoFaltanteFocus,
                          nextFocusNode: _costoUnitarioFocus,
                          step: 0.1,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'El costo es requerido';
                            }
                            final v = _parseNum(value);
                            if (v == null) {
                              return 'Debe ser un número válido';
                            }
                            if (v <= 0) {
                              return 'Debe ser mayor a 0';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildNumberField(
                          controller: _costoUnitarioController,
                          label: 'Costo Unitario (soles)',
                          focusNode: _costoUnitarioFocus,
                          nextFocusNode: _espacioUnidadFocus,
                          step: 0.1,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'El costo es requerido';
                            }
                            final v = _parseNum(value);
                            if (v == null) {
                              return 'Debe ser un número válido';
                            }
                            if (v <= 0) {
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
                        child: _buildNumberField(
                          controller: _espacioUnidadController,
                          label: 'Espacio por Unidad (m²)',
                          focusNode: _espacioUnidadFocus,
                          nextFocusNode: _desviacionDiariaFocus,
                          step: 0.1,
                          showStepper: true,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'El espacio es requerido';
                            }
                            final v = _parseNum(value);
                            if (v == null) {
                              return 'Debe ser un número válido';
                            }
                            if (v <= 0) {
                              return 'Debe ser mayor a 0';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildNumberField(
                          controller: _desviacionDiariaController,
                          label: 'Desviación Estándar Diaria',
                          focusNode: _desviacionDiariaFocus,
                          nextFocusNode: _puntoReordenFocus,
                          step: 0.1,
                          showStepper: true,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'La desviación es requerida';
                            }
                            final v = _parseNum(value);
                            if (v == null) {
                              return 'Debe ser un número válido';
                            }
                            if (v < 0) {
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
                        child: _buildNumberField(
                          controller: _puntoReordenController,
                          label: 'Punto de Reorden (unidades)',
                          focusNode: _puntoReordenFocus,
                          nextFocusNode: _tamanoLoteFocus,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'El punto de reorden es requerido';
                            }
                            final v = _parseNum(value);
                            if (v == null) {
                              return 'Debe ser un número válido';
                            }
                            if (v < 0) {
                              return 'Debe ser mayor o igual a 0';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildNumberField(
                          controller: _tamanoLoteController,
                          label: 'Tamaño de Lote (unidades)',
                          focusNode: _tamanoLoteFocus,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _agregarArticulo(),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'El tamaño de lote es requerido';
                            }
                            final v = _parseNum(value);
                            if (v == null) {
                              return 'Debe ser un número válido';
                            }
                            if (v <= 0) {
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
    FocusNode? focusNode,
    FocusNode? nextFocusNode,
    TextInputAction? textInputAction,
    bool autofocus = false,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      decoration: InputDecoration(
        labelText: label,
        hintText: 'Ingrese $label',
      ),
      autofocus: autofocus,
      textInputAction: textInputAction ?? TextInputAction.next,
      onFieldSubmitted: (_) {
        if (nextFocusNode != null) {
          FocusScope.of(context).requestFocus(nextFocusNode);
        }
      },
      validator: validator,
    );
  }

  Widget _buildNumberField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
    FocusNode? focusNode,
    FocusNode? nextFocusNode,
    TextInputAction? textInputAction,
    void Function(String)? onSubmitted,
    double step = 1,
    bool allowDecimal = true,
    bool showStepper = false,
  }) {
    final formatters = <TextInputFormatter>[
      FilteringTextInputFormatter.allow(RegExp(allowDecimal ? r'[0-9.,]' : r'[0-9]')),
    ];
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: formatters,
      decoration: InputDecoration(
        labelText: label,
        hintText: 'Ingrese $label',
        suffixIcon: showStepper
            ? SizedBox(
                width: 96,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      tooltip: 'Decrementar',
                      icon: const Icon(UniconsLine.minus_circle),
                      onPressed: () {
                        double val = _parseNum(controller.text) ?? 0;
                        val = (val - step);
                        if (val < 0) {
                          val = 0;
                        }
                        controller.text = allowDecimal
                            ? val.toStringAsFixed(2)
                            : val.toStringAsFixed(0);
                      },
                    ),
                    IconButton(
                      tooltip: 'Incrementar',
                      icon: const Icon(UniconsLine.plus_circle),
                      onPressed: () {
                        double val = _parseNum(controller.text) ?? 0;
                        val = (val + step);
                        controller.text = allowDecimal
                            ? val.toStringAsFixed(2)
                            : val.toStringAsFixed(0);
                      },
                    ),
                  ],
                ),
              )
            : null,
      ),
      textInputAction: textInputAction ?? TextInputAction.next,
      onFieldSubmitted: (value) {
        if (onSubmitted != null) {
          onSubmitted(value);
        }
        if (nextFocusNode != null) {
          FocusScope.of(context).requestFocus(nextFocusNode);
        }
      },
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
      
      // En Web no se puede abrir el archivo con OpenFile, solo informar
      if (kIsWeb) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Descarga de plantilla iniciada en el navegador.'),
            ),
          );
        }
        return;
      }

      // Mostrar diálogo de confirmación (solo no-Web)
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