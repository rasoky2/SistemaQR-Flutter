import 'dart:io';

import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:inventario_qr/models/articulo.model.dart';
import 'package:inventario_qr/models/resultado.model.dart';
import 'package:path_provider/path_provider.dart';

/// Repositorio para manejar la importación y exportación de archivos Excel
class ExcelRepository {
  /// Lee las columnas disponibles en un archivo Excel
  static Future<List<String>> leerColumnasExcel(String? filePath) async {
    try {
      debugPrint('🔍 Iniciando lectura de columnas Excel...');
      
      if (filePath == null) {
        debugPrint('📁 Abriendo FilePicker para seleccionar archivo...');
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['xlsx', 'xls'],
        );

        if (result == null || result.files.isEmpty) {
          debugPrint('❌ No se seleccionó ningún archivo');
          throw Exception('No se seleccionó ningún archivo');
        }
        filePath = result.files.first.path!;
        debugPrint('📄 Archivo seleccionado: $filePath');
      }

      final file = File(filePath);
      final bytes = await file.readAsBytes();
      debugPrint('📊 Archivo leído, tamaño: ${bytes.length} bytes');
      
      final excel = Excel.decodeBytes(bytes);
      final sheet = excel.tables[excel.tables.keys.first]!;
      debugPrint('📋 Hoja encontrada: ${excel.tables.keys.first}');

      // Buscar la fila de encabezados (primera fila no vacía)
      int headerRow = 0;
      for (int row = 0; row < sheet.maxRows; row++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row));
        if (cell.value != null && cell.value.toString().trim().isNotEmpty) {
          headerRow = row;
          debugPrint('📝 Fila de encabezados encontrada en fila: $headerRow');
          break;
        }
      }

      // Verificar si el archivo tiene estructura de parámetros en filas
      final primeraColumna = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: headerRow)).value?.toString().trim() ?? '';
      final esEstructuraParametros = primeraColumna.toLowerCase().contains('parámetro') || 
                                    primeraColumna.toLowerCase().contains('parametro');

      if (esEstructuraParametros) {
        debugPrint('📋 Detectada estructura de parámetros en filas');
        // Para estructura de parámetros, las columnas son los nombres de los artículos
        final columnas = <String>[];
        for (int col = 1; col < 20; col++) { // Máximo 20 columnas
          final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: headerRow));
          final header = cell.value?.toString().trim() ?? '';
          if (header.isNotEmpty) {
            columnas.add(header);
            debugPrint('📋 Columna encontrada: $header');
          }
        }
        debugPrint('✅ Total de columnas encontradas: ${columnas.length}');
        debugPrint('📋 Columnas: $columnas');
        return columnas;
      } else {
        debugPrint('📋 Detectada estructura estándar (artículos en filas)');
        // Para estructura estándar, las columnas son los parámetros
        final columnas = <String>[];
        for (int col = 0; col < 20; col++) { // Máximo 20 columnas
          final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: headerRow));
          final header = cell.value?.toString().trim() ?? '';
          if (header.isNotEmpty) {
            columnas.add(header);
            debugPrint('📋 Columna encontrada: $header');
          }
        }
        debugPrint('✅ Total de columnas encontradas: ${columnas.length}');
        debugPrint('📋 Columnas: $columnas');
        return columnas;
      }
    } catch (e) {
      debugPrint('❌ Error al leer columnas del archivo Excel: $e');
      throw Exception('Error al leer columnas del archivo Excel: $e');
    }
  }

  /// Importa artículos desde un archivo Excel usando columnas seleccionadas
  static Future<List<Articulo>> importarArticulosConColumnas(Set<String> columnasSeleccionadas, String filePath) async {
    try {
      debugPrint('🚀 Iniciando importación de artículos...');
      debugPrint('📋 Columnas seleccionadas: $columnasSeleccionadas');
      debugPrint('📄 Archivo: $filePath');
      
      final file = File(filePath);
      final bytes = await file.readAsBytes();
      debugPrint('📊 Archivo leído, tamaño: ${bytes.length} bytes');
      
      final excel = Excel.decodeBytes(bytes);
      final sheet = excel.tables[excel.tables.keys.first]!;
      debugPrint('📋 Hoja encontrada: ${excel.tables.keys.first}');

      // Buscar la fila de encabezados (primera fila no vacía)
      int headerRow = 0;
      for (int row = 0; row < sheet.maxRows; row++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row));
        if (cell.value != null && cell.value.toString().trim().isNotEmpty) {
          headerRow = row;
          debugPrint('📝 Fila de encabezados encontrada en fila: $headerRow');
          break;
        }
      }

      // Verificar si el archivo tiene estructura de parámetros en filas
      final primeraColumna = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: headerRow)).value?.toString().trim() ?? '';
      final esEstructuraParametros = primeraColumna.toLowerCase().contains('parámetro') || 
                                    primeraColumna.toLowerCase().contains('parametro');

      if (esEstructuraParametros) {
        debugPrint('📋 Detectada estructura de parámetros en filas');
        return _importarDesdeEstructuraParametros(sheet, headerRow, columnasSeleccionadas);
      } else {
        debugPrint('📋 Detectada estructura estándar (artículos en filas)');
        return _importarDesdeEstructuraEstandar(sheet, headerRow, columnasSeleccionadas);
      }
    } catch (e) {
      debugPrint('❌ Error al importar archivo Excel: $e');
      throw Exception('Error al importar archivo Excel: $e');
    }
  }

  /// Importa desde estructura donde los parámetros están en filas y artículos en columnas
  static List<Articulo> _importarDesdeEstructuraParametros(Sheet sheet, int headerRow, Set<String> columnasSeleccionadas) {
    final articulos = <Articulo>[];
    
    // Obtener nombres de artículos desde la primera fila (encabezados)
    final nombresArticulos = <String>[];
    for (int col = 1; col < 20; col++) { // Máximo 20 columnas
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: headerRow));
      final nombre = cell.value?.toString().trim() ?? '';
      if (nombre.isNotEmpty && columnasSeleccionadas.contains(nombre)) {
        nombresArticulos.add(nombre);
        debugPrint('📋 Mapeando columna "$nombre" a índice $col');
      }
    }

    debugPrint('📋 Artículos encontrados: $nombresArticulos');

    // Crear un artículo por cada columna de artículos
    for (int colIndex = 0; colIndex < nombresArticulos.length; colIndex++) {
      final nombreArticulo = nombresArticulos[colIndex];
      final col = colIndex + 1; // +1 porque la columna 0 es "Parámetro"
      
      debugPrint('📦 Procesando artículo: $nombreArticulo');

      // Mapear parámetros a valores
      double demandaAnual = 0.0;
      double costoPedido = 0.0;
      double costoMantenimiento = 0.0;
      double costoFaltante = 0.0;
      double costoUnitario = 0.0;
      double espacioUnidad = 0.0;
      double desviacionDiaria = 0.0;
      double puntoReorden = 0.0;
      double tamanoLote = 0.0;

      // Leer parámetros desde las filas
      for (int row = headerRow + 1; row < sheet.maxRows; row++) {
        final parametroCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row));
        final parametro = parametroCell.value?.toString().trim().toLowerCase() ?? '';
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
        final valor = _parseDouble(sheet, col, row);

        debugPrint('📋 Leyendo parámetro: "$parametro" = $valor para $nombreArticulo');

        switch (parametro) {
          case 'demanda anual d_i':
          case 'demanda anual':
            demandaAnual = valor;
            break;
          case 'costo por pedido k_i':
          case 'costo por pedido':
            costoPedido = valor;
            break;
          case 'costo mant. anual h_i':
          case 'costo mantenimiento':
            costoMantenimiento = valor;
            break;
          case 'costo por faltante p_i':
          case 'costo por faltante':
            costoFaltante = valor;
            break;
          case 'costo unitario c_i':
          case 'costo unitario':
            costoUnitario = valor;
            break;
          case 'espacio por unidad s_i':
          case 'espacio por unidad':
            espacioUnidad = valor;
            break;
          case 'lead time l (años)':
          case 'lead time':
            // Lead time se maneja globalmente, no por artículo
            break;
          case 'desviación estándar diaria σ':
          case 'desviación estándar diaria':
          case 'desviación estándar diari': // Para capturar el texto truncado
            desviacionDiaria = valor;
            break;
          case 'punto de reorden r_i':
          case 'punto de reorden':
            puntoReorden = valor;
            break;
          case 'tamaño de lote q_i':
          case 'tamaño de lote':
          case 'tamaño de lote Q_i': // Para capturar con subíndice
            tamanoLote = valor;
            debugPrint('📦 Tamaño de lote detectado para $nombreArticulo: $valor');
            break;
          case 'restricción de espacio':
          case 'restricción':
            // Restricción se maneja globalmente
            break;
        }
      }

      final articulo = Articulo(
        nombre: nombreArticulo,
        demandaAnual: demandaAnual,
        costoPedido: costoPedido,
        costoMantenimiento: costoMantenimiento,
        costoFaltante: costoFaltante,
        costoUnitario: costoUnitario,
        espacioUnidad: espacioUnidad,
        desviacionDiaria: desviacionDiaria,
        puntoReorden: puntoReorden,
        tamanoLote: tamanoLote,
      );

      // Validar campos críticos y mostrar advertencias
      final camposFaltantes = <String>[];
      if (demandaAnual <= 0) {
        camposFaltantes.add('Demanda anual');
      }
      if (costoPedido <= 0) {
        camposFaltantes.add('Costo por pedido');
      }
      if (costoMantenimiento <= 0) {
        camposFaltantes.add('Costo mantenimiento');
      }
      if (costoFaltante <= 0) {
        camposFaltantes.add('Costo por faltante');
      }
      if (costoUnitario <= 0) {
        camposFaltantes.add('Costo unitario');
      }
      if (espacioUnidad <= 0) {
        camposFaltantes.add('Espacio por unidad');
      }
      if (desviacionDiaria < 0) {
        camposFaltantes.add('Desviación estándar diaria');
      }
      if (puntoReorden < 0) {
        camposFaltantes.add('Punto de reorden');
      }
      if (tamanoLote <= 0) {
        camposFaltantes.add('Tamaño de lote');
      }

      if (camposFaltantes.isNotEmpty) {
        debugPrint('⚠️ Artículo "$nombreArticulo" tiene campos faltantes o inválidos: $camposFaltantes');
        debugPrint('⚠️ Se usarán valores por defecto para los campos faltantes');
      }

      debugPrint('📊 Artículo "$nombreArticulo" importado con valores:');
      debugPrint('   - Demanda anual: $demandaAnual ${demandaAnual <= 0 ? '(⚠️ valor por defecto)' : ''}');
      debugPrint('   - Costo pedido: $costoPedido ${costoPedido <= 0 ? '(⚠️ valor por defecto)' : ''}');
      debugPrint('   - Costo mantenimiento: $costoMantenimiento ${costoMantenimiento <= 0 ? '(⚠️ valor por defecto)' : ''}');
      debugPrint('   - Costo faltante: $costoFaltante ${costoFaltante <= 0 ? '(⚠️ valor por defecto)' : ''}');
      debugPrint('   - Costo unitario: $costoUnitario ${costoUnitario <= 0 ? '(⚠️ valor por defecto)' : ''}');
      debugPrint('   - Espacio unidad: $espacioUnidad ${espacioUnidad <= 0 ? '(⚠️ valor por defecto)' : ''}');
      debugPrint('   - Desviación diaria: $desviacionDiaria ${desviacionDiaria < 0 ? '(⚠️ valor por defecto)' : ''}');
      debugPrint('   - Punto reorden: $puntoReorden ${puntoReorden < 0 ? '(⚠️ valor por defecto)' : ''}');
      debugPrint('   - Tamaño lote: $tamanoLote ${tamanoLote <= 0 ? '(⚠️ valor por defecto)' : ''}');

      articulos.add(articulo);
      debugPrint('✅ Artículo importado: ${articulo.nombre}');
    }

    debugPrint('🎉 Importación completada. Total de artículos: ${articulos.length}');
    return articulos;
  }

  /// Importa desde estructura estándar donde los artículos están en filas
  static List<Articulo> _importarDesdeEstructuraEstandar(Sheet sheet, int headerRow, Set<String> columnasSeleccionadas) {
    final articulos = <Articulo>[];

    // Mapear encabezados a índices solo para columnas seleccionadas
    final headers = <String, int>{};
    for (int col = 0; col < 20; col++) { // Máximo 20 columnas
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: headerRow));
      final header = cell.value?.toString().trim() ?? '';
      if (header.isNotEmpty && columnasSeleccionadas.contains(header)) {
        headers[header] = col;
        debugPrint('📋 Mapeando columna "$header" a índice $col');
      }
    }

    debugPrint('📋 Headers mapeados: $headers');

    // Leer datos de artículos
    int articulosImportados = 0;
    for (int row = headerRow + 1; row < sheet.maxRows; row++) {
      final nombreCell = sheet.cell(CellIndex.indexByColumnRow(
        columnIndex: headers['Nombre'] ?? 0,
        rowIndex: row,
      ));
      
      if (nombreCell.value == null || nombreCell.value.toString().trim().isEmpty) {
        continue; // Fila vacía
      }

      final nombre = nombreCell.value.toString();
      debugPrint('📦 Procesando artículo: $nombre');

      final articulo = Articulo(
        nombre: nombre,
        demandaAnual: _parseDouble(sheet, headers['Demanda Anual'] ?? 1, row),
        costoPedido: _parseDouble(sheet, headers['Costo por Pedido'] ?? 2, row),
        costoMantenimiento: _parseDouble(sheet, headers['Costo Mantenimiento'] ?? 3, row),
        costoFaltante: _parseDouble(sheet, headers['Costo por Faltante'] ?? 4, row),
        costoUnitario: _parseDouble(sheet, headers['Costo Unitario'] ?? 5, row),
        espacioUnidad: _parseDouble(sheet, headers['Espacio por Unidad'] ?? 6, row),
        desviacionDiaria: _parseDouble(sheet, headers['Desviación Estándar Diaria'] ?? 7, row),
        puntoReorden: _parseDouble(sheet, headers['Punto de Reorden'] ?? 8, row),
        tamanoLote: _parseDouble(sheet, headers['Tamaño de Lote'] ?? 9, row),
      );

      // Validar campos críticos y mostrar advertencias
      final camposFaltantes = <String>[];
      if (articulo.demandaAnual <= 0) {
        camposFaltantes.add('Demanda anual');
      }
      if (articulo.costoPedido <= 0) {
        camposFaltantes.add('Costo por pedido');
      }
      if (articulo.costoMantenimiento <= 0) {
        camposFaltantes.add('Costo mantenimiento');
      }
      if (articulo.costoFaltante <= 0) {
        camposFaltantes.add('Costo por faltante');
      }
      if (articulo.costoUnitario <= 0) {
        camposFaltantes.add('Costo unitario');
      }
      if (articulo.espacioUnidad <= 0) {
        camposFaltantes.add('Espacio por unidad');
      }
      if (articulo.desviacionDiaria < 0) {
        camposFaltantes.add('Desviación estándar diaria');
      }
      if (articulo.puntoReorden < 0) {
        camposFaltantes.add('Punto de reorden');
      }
      if (articulo.tamanoLote <= 0) {
        camposFaltantes.add('Tamaño de lote');
      }

      if (camposFaltantes.isNotEmpty) {
        debugPrint('⚠️ Artículo "$nombre" tiene campos faltantes o inválidos: $camposFaltantes');
        debugPrint('⚠️ Se usarán valores por defecto para los campos faltantes');
      }

      debugPrint('📊 Artículo "$nombre" importado con valores:');
      debugPrint('   - Demanda anual: ${articulo.demandaAnual} ${articulo.demandaAnual <= 0 ? '(⚠️ valor por defecto)' : ''}');
      debugPrint('   - Costo pedido: ${articulo.costoPedido} ${articulo.costoPedido <= 0 ? '(⚠️ valor por defecto)' : ''}');
      debugPrint('   - Costo mantenimiento: ${articulo.costoMantenimiento} ${articulo.costoMantenimiento <= 0 ? '(⚠️ valor por defecto)' : ''}');
      debugPrint('   - Costo faltante: ${articulo.costoFaltante} ${articulo.costoFaltante <= 0 ? '(⚠️ valor por defecto)' : ''}');
      debugPrint('   - Costo unitario: ${articulo.costoUnitario} ${articulo.costoUnitario <= 0 ? '(⚠️ valor por defecto)' : ''}');
      debugPrint('   - Espacio unidad: ${articulo.espacioUnidad} ${articulo.espacioUnidad <= 0 ? '(⚠️ valor por defecto)' : ''}');
      debugPrint('   - Desviación diaria: ${articulo.desviacionDiaria} ${articulo.desviacionDiaria < 0 ? '(⚠️ valor por defecto)' : ''}');
      debugPrint('   - Punto reorden: ${articulo.puntoReorden} ${articulo.puntoReorden < 0 ? '(⚠️ valor por defecto)' : ''}');
      debugPrint('   - Tamaño lote: ${articulo.tamanoLote} ${articulo.tamanoLote <= 0 ? '(⚠️ valor por defecto)' : ''}');

      articulos.add(articulo);
      articulosImportados++;
      debugPrint('✅ Artículo importado: ${articulo.nombre}');
    }

    debugPrint('🎉 Importación completada. Total de artículos: $articulosImportados');
    return articulos;
  }

  /// Exporta resultados a un archivo Excel
  static Future<String> exportarResultados(ResultadoSistema resultado) async {
    try {
      final excel = Excel.createExcel();
      
      // Eliminar la hoja por defecto "Sheet1" si existe
      if (excel.tables.containsKey('Sheet1')) {
        excel.delete('Sheet1');
        debugPrint('🗑️ ExcelRepository: Hoja "Sheet1" eliminada de exportarResultados');
      }
      
      final sheet = excel['Resultados'];

      // Encabezados para resultados por artículo
      final headers = [
        'Nombre',
        'Tamaño Lote (Q)',
        'Punto Reorden (R)',
        'Z-Score',
        'Backorders Esperados',
        'Costo Total',
        'Espacio Usado (m²)',
        'Costo Pedidos',
        'Costo Mantenimiento',
        'Costo Servicio',
      ];

      // Escribir encabezados
      for (int i = 0; i < headers.length; i++) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
          ..value = TextCellValue(headers[i])
          ..cellStyle = CellStyle(bold: true);
      }

      // Escribir datos de artículos
      for (int i = 0; i < resultado.resultados.length; i++) {
        final res = resultado.resultados[i];
        final row = i + 1;

        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).value = TextCellValue(res.nombre);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row)).value = DoubleCellValue(res.tamanoLote);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row)).value = DoubleCellValue(res.puntoReorden);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row)).value = DoubleCellValue(res.zScore);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row)).value = DoubleCellValue(res.backordersEsperados);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row)).value = DoubleCellValue(res.costoTotal);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: row)).value = DoubleCellValue(res.espacioUsado);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: row)).value = DoubleCellValue(res.costoPedidos);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: row)).value = DoubleCellValue(res.costoMantenimiento);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: row)).value = DoubleCellValue(res.costoServicio);
      }

      // Agregar resumen del sistema
      final summaryRow = resultado.resultados.length + 3;
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: summaryRow)).value = TextCellValue('RESUMEN DEL SISTEMA');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: summaryRow))
        .cellStyle = CellStyle(bold: true);

      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: summaryRow + 1)).value = TextCellValue('Costo Total Sistema:');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: summaryRow + 1)).value = DoubleCellValue(resultado.costoTotalSistema);

      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: summaryRow + 2)).value = TextCellValue('Espacio Total Usado:');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: summaryRow + 2)).value = DoubleCellValue(resultado.espacioTotalUsado);

      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: summaryRow + 3)).value = TextCellValue('Presupuesto Total:');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: summaryRow + 3)).value = DoubleCellValue(resultado.presupuestoTotal);

      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: summaryRow + 4)).value = TextCellValue('Número Total Pedidos:');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: summaryRow + 4)).value = DoubleCellValue(resultado.numeroTotalPedidos.toDouble());

      // Guardar archivo
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'inventario_qr_$timestamp.xlsx';
      final filePath = '${directory.path}/$fileName';
      
      final file = File(filePath);
      await file.writeAsBytes(excel.encode()!);

      return filePath;
    } catch (e) {
      throw Exception('Error al exportar a Excel: $e');
    }
  }

  /// Genera una plantilla Excel para importación
  static Future<String> generarPlantilla() async {
    try {
      final excel = Excel.createExcel();
      
      // Eliminar la hoja por defecto "Sheet1" si existe
      if (excel.tables.containsKey('Sheet1')) {
        excel.delete('Sheet1');
        debugPrint('🗑️ ExcelRepository: Hoja "Sheet1" eliminada de generarPlantilla');
      }
      
      final sheet = excel['Plantilla'];

      // Encabezados
      final headers = [
        'Nombre',
        'Demanda Anual',
        'Costo Pedido',
        'Costo Mantenimiento',
        'Costo Faltante',
        'Costo Unitario',
        'Espacio Unidad',
        'Desviación Diaria',
        'Punto Reorden',
        'Tamaño Lote',
      ];

      // Escribir encabezados
      for (int i = 0; i < headers.length; i++) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
          ..value = TextCellValue(headers[i])
          ..cellStyle = CellStyle(bold: true);
      }

      // Agregar datos de ejemplo
      final datosEjemplo = [
        ['Artículo 1', 1200, 100, 2, 5, 20, 0.5, 2, 120, 200],
        ['Artículo 2', 800, 80, 3, 6, 30, 1.0, 3, 90, 160],
        ['Artículo 3', 600, 60, 1.5, 4, 15, 0.3, 1.5, 60, 120],
      ];

      for (int row = 0; row < datosEjemplo.length; row++) {
        for (int col = 0; col < datosEjemplo[row].length; col++) {
          final value = datosEjemplo[row][col];
          if (value is String) {
            sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row + 1))
              .value = TextCellValue(value);
          } else if (value is int) {
            sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row + 1))
              .value = IntCellValue(value);
          } else if (value is double) {
            sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row + 1))
              .value = DoubleCellValue(value);
          }
        }
      }

      // Guardar plantilla
      final directory = await getApplicationDocumentsDirectory();
      const fileName = 'plantilla_inventario_qr.xlsx';
      final filePath = '${directory.path}/$fileName';
      
      final file = File(filePath);
      await file.writeAsBytes(excel.encode()!);

      return filePath;
    } catch (e) {
      throw Exception('Error al generar plantilla: $e');
    }
  }

  /// Parsea un valor double desde una celda Excel
  static double _parseDouble(Sheet sheet, int col, int row) {
    try {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
      final value = cell.value;
      
      if (value == null) {
        return 0.0;
      }
      
      switch (value) {
        case IntCellValue():
          return value.value.toDouble();
        case DoubleCellValue():
          return value.value;
        case TextCellValue():
          final text = value.value.toString();
          final trimmed = text.trim();
          if (trimmed.isEmpty) {
            return 0.0;
          }
          return double.tryParse(trimmed) ?? 0.0;
        default:
          return 0.0;
      }
    } catch (e) {
      return 0.0;
    }
  }

  /// Genera un template de Excel para importar artículos
  Future<String> generarTemplateExcel() async {
    debugPrint('📋 ExcelRepository: Generando template Excel...');
    
    try {
      final bytes = await _generarTemplateExcelBytes();
      final path = await _guardarArchivo(bytes, 'template_articulos.xlsx');
      
      debugPrint('✅ ExcelRepository: Template generado exitosamente en: $path');
      return path;
    } catch (e) {
      debugPrint('❌ ExcelRepository: Error al generar template: $e');
      rethrow;
    }
  }

  /// Exporta los resultados del modelo QR a Excel
  static Future<void> exportarResultadosExcel(ResultadoSistema resultado, [String? outputPath]) async {
    debugPrint('📤 ExcelRepository: Iniciando exportación de resultados...');
    
    try {
      final bytes = await _generarResultadosExcelBytes(resultado);
      String path;
      
      if (outputPath != null) {
        // Usar la ubicación específica proporcionada
        path = outputPath;
        final file = File(path);
        await file.writeAsBytes(bytes);
        debugPrint('✅ ExcelRepository: Resultados exportados exitosamente en: $path');
      } else {
        // Usar ubicación por defecto
        path = await _guardarArchivo(bytes, 'resultados_qr_modelo.xlsx');
        debugPrint('✅ ExcelRepository: Resultados exportados exitosamente en: $path');
      }
    } catch (e) {
      debugPrint('❌ ExcelRepository: Error al exportar resultados: $e');
      rethrow;
    }
  }

  /// Genera los bytes del archivo Excel con los resultados
  static Future<List<int>> _generarResultadosExcelBytes(ResultadoSistema resultado) async {
    final excel = Excel.createExcel();
    
    // Eliminar la hoja por defecto "Sheet1" si existe
    if (excel.tables.containsKey('Sheet1')) {
      excel.delete('Sheet1');
      debugPrint('🗑️ ExcelRepository: Hoja "Sheet1" eliminada');
    }
    
    final sheet = excel['Resultados QR Modelo'];

    // Encabezados
    final headers = [
      'Artículo',
      'Tamaño de Lote (Q)',
      'Punto de Reorden (R)',
      'Z-Score',
      'Backorders Esperados',
      'Costo de Pedidos',
      'Costo de Mantenimiento',
      'Costo de Servicio',
      'Costo Total',
      'Espacio Usado (m²)',
    ];

    // Escribir encabezados
    for (int i = 0; i < headers.length; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0)).value = TextCellValue(headers[i]);
    }

    // Escribir datos de cada artículo
    for (int i = 0; i < resultado.resultados.length; i++) {
      final resultadoArticulo = resultado.resultados[i];
      final row = i + 1;

      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).value = TextCellValue(resultadoArticulo.nombre);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row)).value = DoubleCellValue(resultadoArticulo.tamanoLote);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row)).value = DoubleCellValue(resultadoArticulo.puntoReorden);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row)).value = DoubleCellValue(resultadoArticulo.zScore);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row)).value = DoubleCellValue(resultadoArticulo.backordersEsperados);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row)).value = DoubleCellValue(resultadoArticulo.costoPedidos);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: row)).value = DoubleCellValue(resultadoArticulo.costoMantenimiento);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: row)).value = DoubleCellValue(resultadoArticulo.costoServicio);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: row)).value = DoubleCellValue(resultadoArticulo.costoTotal);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: row)).value = DoubleCellValue(resultadoArticulo.espacioUsado);
    }

    // Agregar resumen del sistema
    final summaryRow = resultado.resultados.length + 2;
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: summaryRow)).value = TextCellValue('RESUMEN DEL SISTEMA');

    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: summaryRow + 1)).value = TextCellValue('Costo Total del Sistema:');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: summaryRow + 1)).value = DoubleCellValue(resultado.costoTotalSistema);

    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: summaryRow + 2)).value = TextCellValue('Espacio Total Usado (m²):');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: summaryRow + 2)).value = DoubleCellValue(resultado.espacioTotalUsado);

    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: summaryRow + 3)).value = TextCellValue('Presupuesto Total:');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: summaryRow + 3)).value = DoubleCellValue(resultado.presupuestoTotal);

    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: summaryRow + 4)).value = TextCellValue('Número Total de Pedidos:');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: summaryRow + 4)).value = DoubleCellValue(resultado.numeroTotalPedidos.toDouble());

    return excel.encode()!;
  }

  /// Genera los bytes del template Excel
  Future<List<int>> _generarTemplateExcelBytes() async {
    final excel = Excel.createExcel();
    
    // Eliminar la hoja por defecto "Sheet1" si existe
    if (excel.tables.containsKey('Sheet1')) {
      excel.delete('Sheet1');
      debugPrint('🗑️ ExcelRepository: Hoja "Sheet1" eliminada del template');
    }
    
    final sheet = excel['Template Artículos'];

    // Encabezados
    final headers = [
      'Nombre del Artículo',
      'Demanda Anual (unidades)',
      'Costo por Pedido (soles)',
      'Costo Mantenimiento (soles/unidad)',
      'Costo por Faltante (soles/unidad)',
      'Costo Unitario (soles)',
      'Espacio por Unidad (m²)',
      'Desviación Estándar Diaria',
      'Punto de Reorden (unidades)',
      'Tamaño de Lote (unidades)',
    ];

    // Escribir encabezados
    for (int i = 0; i < headers.length; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0)).value = TextCellValue(headers[i]);
    }

    return excel.encode()!;
  }

  /// Guarda un archivo en el directorio de documentos
  static Future<String> _guardarArchivo(List<int> bytes, String nombreArchivo) async {
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/$nombreArchivo';
    
    final file = File(path);
    await file.writeAsBytes(bytes);
    
    debugPrint('💾 Archivo guardado en: $path');
    return path;
  }
} 