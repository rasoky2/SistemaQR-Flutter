import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:inventario_qr/models/articulo.model.dart';
import 'package:inventario_qr/models/resultado.model.dart';
import 'package:inventario_qr/repositories/excel.repository.dart';
import 'package:inventario_qr/repositories/inventario.repository.dart';
import 'package:inventario_qr/utils/math_utils.dart';

/// Provider para manejar el estado del sistema de inventario
class InventarioProvider extends ChangeNotifier {
  List<Articulo> _articulos = [];
  ResultadoSistema? _resultado;
  bool _isLoading = false;
  String? _error;
  Map<String, bool> _restricciones = {};
  Map<String, dynamic> _estadisticas = {};

  // Configuración del sistema
  double _leadTimeDias = 36.5;
  double _espacioMaximo = 150.0;
  double _presupuestoMaximo = 10000.0;
  double _numeroMaximoPedidos = 100.0;

  // Columnas para importación
  final Set<String> _columnasImportar = {
    'Nombre',
    'Demanda Anual',
    'Costo por Pedido',
    'Costo Mantenimiento',
    'Costo por Faltante',
    'Costo Unitario',
    'Espacio por Unidad',
    'Desviación Estándar Diaria',
    'Punto de Reorden',
    'Tamaño de Lote',
  };

  // Archivo seleccionado para importación
  String? _archivoSeleccionado;

  // Getters
  List<Articulo> get articulos => _articulos;
  ResultadoSistema? get resultado => _resultado;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, bool> get restricciones => _restricciones;
  Map<String, dynamic> get estadisticas => _estadisticas;
  
  double get leadTimeDias => _leadTimeDias;
  double get espacioMaximo => _espacioMaximo;
  double get presupuestoMaximo => _presupuestoMaximo;
  double get numeroMaximoPedidos => _numeroMaximoPedidos;
  Set<String> get columnasImportar => _columnasImportar;

  /// Carga datos de ejemplo
  Future<void> cargarDatosEjemplo() async {
    _setLoading(true);
    try {
      _articulos = InventarioRepository.generarDatosEjemplo();
      await calcularResultados();
      _error = null;
    } catch (e) {
      _error = 'Error al cargar datos de ejemplo: $e';
    } finally {
      _setLoading(false);
    }
  }

  /// Lee las columnas del archivo Excel seleccionado
  Future<List<String>> leerColumnasExcel() async {
    try {
      debugPrint('🔍 Provider: Leyendo columnas del archivo...');
      final columnas = await ExcelRepository.leerColumnasExcel(_archivoSeleccionado);
      debugPrint('✅ Provider: Columnas leídas exitosamente: $columnas');
      return columnas;
    } catch (e) {
      debugPrint('❌ Provider: Error al leer columnas: $e');
      _error = 'Error al leer columnas: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Importa artículos desde Excel
  Future<void> importarArticulos() async {
    debugPrint('🚀 Provider: Iniciando importación de artículos...');
    _setLoading(true);
    try {
      if (_archivoSeleccionado == null) {
        throw Exception('No se ha seleccionado ningún archivo');
      }
      
      debugPrint('📋 Provider: Columnas seleccionadas: $_columnasImportar');
      debugPrint('📄 Provider: Archivo: $_archivoSeleccionado');
      
      // Leer todas las columnas disponibles para determinar la estructura
      final columnasDisponibles = await ExcelRepository.leerColumnasExcel(_archivoSeleccionado);
      
      // Si hay columnas disponibles, usar todas para la importación
      // (el repositorio se encargará de filtrar según la estructura detectada)
      final columnasParaImportar = columnasDisponibles.isNotEmpty ? 
          Set<String>.from(columnasDisponibles) : _columnasImportar;
      
      // Importar usando las columnas
      _articulos = await ExcelRepository.importarArticulosConColumnas(columnasParaImportar, _archivoSeleccionado!);
      debugPrint('✅ Provider: Artículos importados: ${_articulos.length}');
      debugPrint('📋 Provider: Lista de artículos después de importar: ${_articulos.map((a) => a.nombre).toList()}');
      
      // Verificar si hay artículos con campos faltantes
      final articulosConProblemas = <String>[];
      for (final articulo in _articulos) {
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
        
        if (problemas.isNotEmpty) {
          articulosConProblemas.add('${articulo.nombre}: ${problemas.join(', ')}');
        }
      }
      
      if (articulosConProblemas.isNotEmpty) {
        _error = 'Algunos artículos tienen campos faltantes o inválidos. Por favor, revise y complete los datos.';
        debugPrint('⚠️ Provider: Artículos con problemas: $articulosConProblemas');
      } else {
        _error = null;
      }
      
      await calcularResultados();
      debugPrint('🎉 Provider: Importación completada exitosamente');
      debugPrint('📊 Provider: Total de artículos en provider: ${_articulos.length}');
      notifyListeners(); // Asegurar que la UI se actualice
    } catch (e) {
      debugPrint('❌ Provider: Error al importar artículos: $e');
      _error = 'Error al importar artículos: $e';
    } finally {
      _setLoading(false);
    }
  }

  /// Selecciona un archivo para importación
  Future<void> seleccionarArchivo() async {
    try {
      debugPrint('📁 Provider: Abriendo FilePicker...');
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
      );

      if (result != null && result.files.isNotEmpty) {
        _archivoSeleccionado = result.files.first.path!;
        _error = null;
        debugPrint('✅ Provider: Archivo seleccionado: $_archivoSeleccionado');
      } else {
        throw Exception('No se seleccionó ningún archivo');
      }
    } catch (e) {
      debugPrint('❌ Provider: Error al seleccionar archivo: $e');
      _error = 'Error al seleccionar archivo: $e';
    }
    notifyListeners();
  }

  /// Exporta resultados a Excel
  Future<String?> exportarResultados() async {
    if (_resultado == null) {
      _error = 'No hay resultados para exportar';
      notifyListeners();
      return null;
    }

    try {
      final filePath = await ExcelRepository.exportarResultados(_resultado!);
      _error = null;
      return filePath;
    } catch (e) {
      _error = 'Error al exportar resultados: $e';
      notifyListeners();
      return null;
    }
  }

  /// Genera plantilla Excel
  Future<String?> generarPlantilla() async {
    try {
      final filePath = await ExcelRepository.generarPlantilla();
      _error = null;
      return filePath;
    } catch (e) {
      _error = 'Error al generar plantilla: $e';
      notifyListeners();
      return null;
    }
  }

  /// Calcula los resultados del modelo QR
  Future<void> calcularResultados() async {
    debugPrint('🧮 Provider: Iniciando cálculo de resultados...');
    debugPrint('🧮 Provider: Total de artículos: ${_articulos.length}');
    
    if (_articulos.isEmpty) {
      debugPrint('❌ Provider: No hay artículos para calcular');
      _error = 'No hay artículos para calcular';
      notifyListeners();
      return;
    }

    try {
      debugPrint('🧮 Provider: Llamando a InventarioRepository.evaluarModeloQR...');
      _resultado = InventarioRepository.evaluarModeloQR(
        _articulos,
        leadTimeDias: _leadTimeDias,
        espacioMaximo: _espacioMaximo,
        presupuestoMaximo: _presupuestoMaximo,
        numeroMaximoPedidos: _numeroMaximoPedidos,
      );
      debugPrint('✅ Provider: Resultados calculados exitosamente');

      // Validar restricciones
      debugPrint('🧮 Provider: Validando restricciones...');
      _restricciones = InventarioRepository.validarRestricciones(
        _resultado!,
        espacioMaximo: _espacioMaximo,
        presupuestoMaximo: _presupuestoMaximo,
        numeroMaximoPedidos: _numeroMaximoPedidos,
      );
      debugPrint('✅ Provider: Restricciones validadas');

      // Calcular estadísticas
      debugPrint('🧮 Provider: Calculando estadísticas...');
      _estadisticas = InventarioRepository.calcularEstadisticas(_resultado!);
      debugPrint('✅ Provider: Estadísticas calculadas');
      _error = null;
    } catch (e) {
      debugPrint('❌ Provider: Error al calcular resultados: $e');
      _error = 'Error al calcular resultados: $e';
    }
    debugPrint('🧮 Provider: Finalizando cálculo de resultados');
    notifyListeners();
  }

  /// Actualiza un artículo existente
  void actualizarArticulo(int index, Articulo articulo) {
    if (index >= 0 && index < _articulos.length) {
      _articulos[index] = articulo;
      calcularResultados();
    }
  }

  /// Actualiza la configuración del sistema
  void actualizarConfiguracion({
    double? leadTimeDias,
    double? espacioMaximo,
    double? presupuestoMaximo,
    double? numeroMaximoPedidos,
  }) {
    bool needsRecalculation = false;

    if (leadTimeDias != null && leadTimeDias != _leadTimeDias) {
      _leadTimeDias = leadTimeDias;
      needsRecalculation = true;
    }

    if (espacioMaximo != null && espacioMaximo != _espacioMaximo) {
      _espacioMaximo = espacioMaximo;
      needsRecalculation = true;
    }

    if (presupuestoMaximo != null && presupuestoMaximo != _presupuestoMaximo) {
      _presupuestoMaximo = presupuestoMaximo;
      needsRecalculation = true;
    }

    if (numeroMaximoPedidos != null && numeroMaximoPedidos != _numeroMaximoPedidos) {
      _numeroMaximoPedidos = numeroMaximoPedidos;
      needsRecalculation = true;
    }

    if (needsRecalculation && _articulos.isNotEmpty) {
      calcularResultados();
    } else {
      notifyListeners();
    }
  }

  /// Limpia todos los datos
  void limpiarDatos() {
    _articulos.clear();
    _resultado = null;
    _error = null;
    _restricciones.clear();
    _estadisticas.clear();
    notifyListeners();
  }

  /// Agrega una columna a la lista de importación
  void agregarColumnaImportar(String columna) {
    _columnasImportar.add(columna);
    notifyListeners();
  }

  /// Elimina una columna de la lista de importación
  void eliminarColumnaImportar(String columna) {
    _columnasImportar.remove(columna);
    notifyListeners();
  }

  /// Limpia todas las columnas de importación
  void limpiarColumnasImportar() {
    _columnasImportar.clear();
    notifyListeners();
  }

  /// Agrega un artículo a la lista
  void agregarArticulo(Articulo articulo) {
    debugPrint('📝 Provider: Agregando artículo: ${articulo.nombre}');
    debugPrint('📝 Provider: Total de artículos antes: ${_articulos.length}');
    
    _articulos.add(articulo);
    
    debugPrint('📝 Provider: Total de artículos después: ${_articulos.length}');
    debugPrint('📝 Provider: Lista de artículos: ${_articulos.map((a) => a.nombre).toList()}');
    
    calcularResultados();
  }

  /// Elimina un artículo de la lista por índice
  void eliminarArticulo(int index) {
    if (index >= 0 && index < _articulos.length) {
      _articulos.removeAt(index);
      calcularResultados();
    }
  }

  /// Obtiene el estado de las restricciones como texto
  String obtenerEstadoRestricciones() {
    if (_restricciones.isEmpty) {
      return 'No hay restricciones evaluadas';
    }

    final estados = <String>[];
    
    if (_restricciones['espacio'] == true) {
      estados.add('✅ Espacio: ${MathUtils.formatearUnidades(_resultado?.espacioTotalUsado ?? 0, 'm²')} ≤ ${MathUtils.formatearUnidades(_espacioMaximo, 'm²')}');
    } else {
      estados.add('❌ Espacio: ${MathUtils.formatearUnidades(_resultado?.espacioTotalUsado ?? 0, 'm²')} > ${MathUtils.formatearUnidades(_espacioMaximo, 'm²')}');
    }

    if (_restricciones['presupuesto'] == true) {
      estados.add('✅ Presupuesto: ${MathUtils.formatearMoneda(_resultado?.presupuestoTotal ?? 0)} ≤ ${MathUtils.formatearMoneda(_presupuestoMaximo)}');
    } else {
      estados.add('❌ Presupuesto: ${MathUtils.formatearMoneda(_resultado?.presupuestoTotal ?? 0)} > ${MathUtils.formatearMoneda(_presupuestoMaximo)}');
    }

    if (_restricciones['pedidos'] == true) {
      estados.add('✅ Pedidos: ${_resultado?.numeroTotalPedidos ?? 0} ≤ $_numeroMaximoPedidos');
    } else {
      estados.add('❌ Pedidos: ${_resultado?.numeroTotalPedidos ?? 0} > $_numeroMaximoPedidos');
    }

    return estados.join('\n');
  }

  /// Verifica si todas las restricciones se cumplen
  bool get todasRestriccionesCumplidas {
    return _restricciones.values.every((cumple) => cumple);
  }

  /// Obtiene el artículo con mayor costo
  ResultadoArticulo? get articuloMasCostoso {
    if (_resultado?.resultados.isEmpty ?? true) {
      return null;
    }
    return _resultado!.resultados.reduce((a, b) => a.costoTotal > b.costoTotal ? a : b);
  }

  /// Obtiene el artículo con menor costo
  ResultadoArticulo? get articuloMenosCostoso {
    if (_resultado?.resultados.isEmpty ?? true) {
      return null;
    }
    return _resultado!.resultados.reduce((a, b) => a.costoTotal < b.costoTotal ? a : b);
  }

  /// Obtiene el artículo que usa más espacio
  ResultadoArticulo? get articuloMasEspacio {
    if (_resultado?.resultados.isEmpty ?? true) {
      return null;
    }
    return _resultado!.resultados.reduce((a, b) => a.espacioUsado > b.espacioUsado ? a : b);
  }

  /// Obtiene el artículo que usa menos espacio
  ResultadoArticulo? get articuloMenosEspacio {
    if (_resultado?.resultados.isEmpty ?? true) {
      return null;
    }
    return _resultado!.resultados.reduce((a, b) => a.espacioUsado < b.espacioUsado ? a : b);
  }

  /// Establece el estado de carga
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Exporta los resultados a Excel
  Future<void> exportarResultadosExcel([String? outputPath]) async {
    if (_resultado == null) {
      throw Exception('No hay resultados disponibles para exportar');
    }

    debugPrint('📤 Provider: Iniciando exportación de resultados a Excel...');
    
    try {
      await ExcelRepository.exportarResultadosExcel(_resultado!, outputPath);
      debugPrint('✅ Provider: Resultados exportados exitosamente');
    } catch (e) {
      debugPrint('❌ Provider: Error al exportar resultados: $e');
      rethrow;
    }
  }
} 