// Importaciones para manejo multiplataforma de Excel
import 'dart:io' show File if (dart.library.html) '';
// ignore: unnecessary_import
import 'dart:typed_data';

import 'package:archive/archive.dart' as arc;
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:inventario_qr/models/articulo.model.dart';
import 'package:inventario_qr/models/resultado.model.dart';
import 'package:inventario_qr/utils/logger.dart';
// Descarga web con import condicional
import 'package:inventario_qr/utils/web_download_stub.dart'
    if (dart.library.html) 'package:inventario_qr/utils/web_download_html.dart';
import 'package:path_provider/path_provider.dart';
import 'package:xml/xml.dart' as xml;

/// Repositorio para manejar la importación y exportación de archivos Excel
class ExcelRepository {
  static const Map<String, int> _templateColumnIndex = {
    'Nombre del Artículo': 0,
    'Demanda Anual (unidades)': 1,
    'Costo por Pedido (soles)': 2,
    'Costo Mantenimiento (soles/unidad)': 3,
    'Costo por Faltante (soles/unidad)': 4,
    'Costo Unitario (soles)': 5,
    'Espacio por Unidad (m²)': 6,
    'Desviación Estándar Diaria': 7,
    'Punto de Reorden (unidades)': 8,
    'Tamaño de Lote (unidades)': 9,
  };
  static int _excelColLettersToIndex(String cellRef) {
    // Extract letters from reference (e.g., 'BC23' -> 'BC')
    final letters = StringBuffer();
    for (int i = 0; i < cellRef.length; i++) {
      final ch = cellRef[i];
      if ((ch.codeUnitAt(0) >= 65 && ch.codeUnitAt(0) <= 90) || (ch.codeUnitAt(0) >= 97 && ch.codeUnitAt(0) <= 122)) {
        letters.write(ch.toUpperCase());
      } else {
        break;
      }
    }
    String s = letters.toString();
    int idx = 0;
    for (int i = 0; i < s.length; i++) {
      idx = idx * 26 + (s.codeUnitAt(i) - 64); // 'A' -> 1
    }
    return idx - 1; // zero-based
  }
  /// Detecta formato por cabecera de bytes
  static String _detectarFormatoExcel(Uint8List bytes) {
    // XLSX: archivo ZIP: magic number 50 4B 03 04 (PK\x03\x04)
    if (bytes.length >= 4 &&
        bytes[0] == 0x50 &&
        bytes[1] == 0x4B &&
        bytes[2] == 0x03 &&
        bytes[3] == 0x04) {
      return 'xlsx';
    }
    // XLS (BIFF) empieza con D0 CF 11 E0 (OLE Compound)
    if (bytes.length >= 4 &&
        bytes[0] == 0xD0 &&
        bytes[1] == 0xCF &&
        bytes[2] == 0x11 &&
        bytes[3] == 0xE0) {
      return 'xls';
    }
    return 'desconocido';
  }

  /// Lee encabezados (primera fila) desde XLSX usando ZIP/XML (fallback Web)
  static Future<List<String>> _leerEncabezadosXlsxFallback(Uint8List bytes) async {
    final data = arc.ZipDecoder().decodeBytes(bytes);
    // Buscar workbook para saber la primera hoja
    final workbookFile = data.files.firstWhere(
      (f) => f.name == 'xl/workbook.xml',
      orElse: () => throw Exception('workbook.xml no encontrado'),
    );
    final workbookXml = xml.XmlDocument.parse(String.fromCharCodes(workbookFile.content as List<int>));
    final sheets = workbookXml.findAllElements('sheet');
    if (sheets.isEmpty) {
      return [];
    }
    final firstSheetId = sheets.first.getAttribute('r:id') ?? '';
    // Buscar rels para mapear r:id -> sheetX.xml
    final relsFile = data.files.firstWhere(
      (f) => f.name == 'xl/_rels/workbook.xml.rels',
      orElse: () => throw Exception('workbook.xml.rels no encontrado'),
    );
    final relsXml = xml.XmlDocument.parse(String.fromCharCodes(relsFile.content as List<int>));
    String target = 'worksheets/sheet1.xml';
    for (final rel in relsXml.findAllElements('Relationship')) {
      if (rel.getAttribute('Id') == firstSheetId) {
        target = rel.getAttribute('Target') ?? target;
        break;
      }
    }
    // Normalizar ruta de la hoja
    var targetPath = target.startsWith('/') ? target.substring(1) : target;
    // Si target ya incluye 'xl/', no prefijar nuevamente
    final expectedPath = targetPath.startsWith('xl/') ? targetPath : 'xl/$targetPath';
    final sheetFile = data.files.firstWhere(
      (f) => f.name == expectedPath,
      orElse: () => throw Exception('Hoja no encontrada: $target'),
    );
    final sheetXml = xml.XmlDocument.parse(String.fromCharCodes(sheetFile.content as List<int>));
    // sharedStrings para decodificar textos (manejar distintos paths)
    List<String> sharedStrings = [];
    try {
      final sstFile = data.files.firstWhere(
        (f) => f.name == 'xl/sharedStrings.xml' || f.name == '/xl/sharedStrings.xml',
      );
      final sstXml = xml.XmlDocument.parse(String.fromCharCodes(sstFile.content as List<int>));
      sharedStrings = sstXml
          .findAllElements('si')
          .map((si) => si.findAllElements('t').map((t) => t.innerText).join())
          .toList();
    } catch (_) {}
    final rows = sheetXml.findAllElements('row');
    if (rows.isEmpty) {
      return [];
    }
    final firstRow = rows.first;
    final cells = firstRow.findAllElements('c');
    int maxCol = 0;
    final colValues = <int, String>{};
    for (final c in cells) {
      final ref = c.getAttribute('r') ?? 'A1';
      final col = _excelColLettersToIndex(ref);
      if (col > maxCol) {
        maxCol = col;
      }
      final t = c.getAttribute('t');
      String value = '';
      if (t == 'inlineStr') {
        final isNode = c.getElement('is');
        value = isNode?.getElement('t')?.innerText ?? '';
      } else {
        final v = c.getElement('v')?.innerText;
        if (v == null) {
          value = '';
        } else if (t == 's') {
          final idx = int.tryParse(v) ?? -1;
          value = idx >= 0 && idx < sharedStrings.length ? sharedStrings[idx] : '';
        } else {
          value = v;
        }
      }
      colValues[col] = value;
    }
    final headers = List<String>.filled(maxCol + 1, '');
    colValues.forEach((k, v) => headers[k] = v);
    return headers;
  }

  /// Lee toda la primera hoja como matriz dinámica usando ZIP/XML (fallback Web)
  static Future<List<List<dynamic>>> _leerHojaCompletaXlsxFallback(Uint8List bytes) async {
    final data = arc.ZipDecoder().decodeBytes(bytes);
    // workbook y rels
    final workbookFile = data.files.firstWhere((f) => f.name == 'xl/workbook.xml');
    final workbookXml = xml.XmlDocument.parse(String.fromCharCodes(workbookFile.content as List<int>));
    final sheets = workbookXml.findAllElements('sheet');
    if (sheets.isEmpty) {
      return [];
    }
    final firstSheetId = sheets.first.getAttribute('r:id') ?? '';
    final relsFile = data.files.firstWhere((f) => f.name == 'xl/_rels/workbook.xml.rels');
    final relsXml = xml.XmlDocument.parse(String.fromCharCodes(relsFile.content as List<int>));
    String target = 'worksheets/sheet1.xml';
    for (final rel in relsXml.findAllElements('Relationship')) {
      if (rel.getAttribute('Id') == firstSheetId) {
        target = rel.getAttribute('Target') ?? target;
        break;
      }
    }
    // sharedStrings para decodificar textos
    List<String> sharedStrings = [];
    try {
      final sstFile = data.files.firstWhere((f) => f.name == 'xl/sharedStrings.xml');
      final sstXml = xml.XmlDocument.parse(String.fromCharCodes(sstFile.content as List<int>));
      sharedStrings = sstXml
          .findAllElements('si')
          .map((si) => si.findAllElements('t').map((t) => t.innerText).join())
          .toList();
    } catch (_) {}
    var targetPath = target.startsWith('/') ? target.substring(1) : target;
    final expectedPath = targetPath.startsWith('xl/') ? targetPath : 'xl/$targetPath';
    final sheetFile = data.files.firstWhere((f) => f.name == expectedPath);
    final sheetXml = xml.XmlDocument.parse(String.fromCharCodes(sheetFile.content as List<int>));
    final result = <List<dynamic>>[];
    for (final row in sheetXml.findAllElements('row')) {
      final cells = row.findAllElements('c');
      int maxCol = 0;
      final colValues = <int, String>{};
      for (final c in cells) {
        final ref = c.getAttribute('r') ?? 'A1';
        final col = _excelColLettersToIndex(ref);
        if (col > maxCol) {
          maxCol = col;
        }
        final t = c.getAttribute('t');
        String value = '';
        if (t == 'inlineStr') {
          final isNode = c.getElement('is');
          value = isNode?.getElement('t')?.innerText ?? '';
        } else {
          final v = c.getElement('v')?.innerText;
          if (v == null) {
            value = '';
          } else if (t == 's') {
            final idx = int.tryParse(v) ?? -1;
            value = idx >= 0 && idx < sharedStrings.length ? sharedStrings[idx] : '';
          } else {
            value = v;
          }
        }
        colValues[col] = value;
      }
      final rowValues = List<dynamic>.filled(maxCol + 1, '');
      colValues.forEach((k, v) => rowValues[k] = v);
      result.add(rowValues);
    }
    return result;
  }
  /// ✅ IMPLEMENTACIÓN MEJORADA: Lee columnas con fallback inteligente para web
  static Future<List<String>> leerColumnasExcel(String? filePath, [Uint8List? fileBytes]) async {
    try {
      logDebug('🔍 Iniciando lectura MEJORADA de columnas Excel...');
      
      // Si no hay path ni bytes, usar columnas estándar
      if ((filePath == null || filePath.isEmpty) && fileBytes == null) {
        logDebug('📁 No se proporcionó archivo, usando columnas estándar');
        return _obtenerColumnasEstandar();
      }
      
      Uint8List bytes;
      
      if (fileBytes != null) {
        bytes = fileBytes;
        logDebug('📄 Usando bytes proporcionados: ${bytes.length} bytes');
      } else if (!kIsWeb && filePath != null) {
        // Leer archivo del sistema (móvil/desktop)
        final file = File(filePath);
        if (!await file.exists()) {
          throw Exception('Archivo no encontrado: $filePath');
        }
        bytes = await file.readAsBytes();
        logDebug('📄 Archivo leído: $filePath (${bytes.length} bytes)');
      } else {
        logDebug('🌐 Plataforma Web sin bytes - usando columnas estándar');
        return _obtenerColumnasEstandar();
      }
      
      // En web no usamos JS externo; si recibimos bytes, intentamos directamente con excel
      // Validar formato
      final formato = _detectarFormatoExcel(bytes);
      if (formato != 'xlsx') {
        throw Exception('Formato no soportado ($formato). Use archivos .xlsx');
      }
      
      // Fallback a librería 'excel' estándar
      try {
        final excel = Excel.decodeBytes(List<int>.from(bytes));
        logDebug('📊 Excel decodificado con librería excel');
        
        if (excel.tables.isEmpty) {
          return _obtenerColumnasEstandar();
        }
        
        final sheetName = excel.tables.keys.first;
        final sheet = excel.tables[sheetName];
        
        if (sheet == null || sheet.rows.isEmpty) {
          return _obtenerColumnasEstandar();
        }
        
        final headerRow = sheet.rows.first;
        final columnas = <String>[];
        
        for (int i = 0; i < headerRow.length; i++) {
          final cell = headerRow[i];
          if (cell?.value != null) {
            final cellValue = _getCellStringValue(cell!);
            if (cellValue.isNotEmpty) {
              columnas.add(cellValue);
            }
            logDebug('🧭 Header[excel] idx=$i => "$cellValue" (${cell.value.runtimeType})');
          }
        }
        
        if (columnas.isNotEmpty) {
          logDebug('✅ Columnas leídas con librería excel: ${columnas.length}');
          return columnas;
        }
      } catch (e) {
        logDebug('❌ Error con librería excel: $e');
        if (kIsWeb) {
          // Fallback Web: parsear XLSX (ZIP) y extraer primera hoja encabezados
          try {
            final columnas = await _leerEncabezadosXlsxFallback(bytes);
            for (int i = 0; i < columnas.length; i++) {
              logDebug('🧭 Header[zip] idx=$i => "${columnas[i]}"');
            }
            if (columnas.isNotEmpty) {
              logDebug('✅ Columnas leídas con fallback ZIP/XML: ${columnas.length}');
              return columnas;
            }
          } catch (e2) {
            logDebug('❌ Fallback ZIP/XML falló: $e2');
          }
        }
      }
      
      logDebug('🔄 Usando columnas estándar como último recurso');
      return _obtenerColumnasEstandar();
      
    } catch (e) {
      logDebug('❌ Error general al leer columnas: $e');
      return _obtenerColumnasEstandar();
    }
  }

  /// Retorna las columnas estándar predefinidas
  static List<String> _obtenerColumnasEstandar() {
    return [
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
  }

  /// ✅ IMPLEMENTACIÓN REAL: Importa artículos desde archivo Excel usando librería 'excel'
  /// Lee el archivo Excel especificado y extrae los datos según las columnas seleccionadas
  static Future<List<Articulo>> importarArticulosConColumnas(Set<String> columnasSeleccionadas, String filePath, [Uint8List? fileBytes]) async {
    try {
      logDebug('🚀 Iniciando importación REAL desde archivo Excel usando librería excel...');
      logDebug('📄 Archivo: $filePath');
      logDebug('📋 Columnas seleccionadas: $columnasSeleccionadas');
      
      // Si no hay path ni bytes, retornar vacío
      if ((filePath.isEmpty) && fileBytes == null) {
        logDebug('📁 No se proporcionó archivo');
        return [];
      }
      
      Uint8List bytes;
      
      if (fileBytes != null) {
        // Usar bytes proporcionados (desde web o file_picker)
        bytes = fileBytes;
        logDebug('📄 Usando bytes proporcionados: ${bytes.length} bytes');
      } else if (!kIsWeb) {
        // Leer archivo del sistema (móvil/desktop)
        final file = File(filePath);
        if (!await file.exists()) {
          throw Exception('Archivo no encontrado: $filePath');
        }
        bytes = await file.readAsBytes();
        logDebug('📄 Archivo leído: $filePath (${bytes.length} bytes)');
      } else {
        logDebug('🌐 Plataforma Web sin bytes');
        return [];
      }
      
      // Validar formato
      final formato = _detectarFormatoExcel(bytes);
      if (formato != 'xlsx') {
        throw Exception('Formato no soportado ($formato). Use archivos .xlsx');
      }

      // Decodificar Excel usando librería 'excel'
      try {
        final excel = Excel.decodeBytes(List<int>.from(bytes));
        logDebug('📊 Excel decodificado exitosamente');
        // ... resto continúa
        
        // Obtener la primera hoja
        if (excel.tables.isEmpty) {
          throw Exception('No se encontraron hojas en el archivo Excel');
        }
        final sheetName = excel.tables.keys.first;
        final sheet = excel.tables[sheetName];
        if (sheet == null || sheet.rows.isEmpty) {
          throw Exception('La hoja Excel está vacía');
        }
        // Usar mapeo fijo por plantilla
        final columnMap = Map<String, int>.from(_templateColumnIndex);
        logDebug('🗺️ Mapeo fijo por plantilla aplicado: $columnMap');
        // Procesar filas
        final articulos = <Articulo>[];
        for (int rowIndex = 1; rowIndex < sheet.rows.length; rowIndex++) {
          final row = sheet.rows[rowIndex];
          try {
            final nombreIndex = columnMap['Nombre del Artículo'] ?? 0;
            final nombre = _getCellStringValueFromRow(row, nombreIndex);
            if (nombre.isEmpty) {
              logDebug('⚠️ Fila ${rowIndex + 1}: Nombre vacío, saltando...');
              continue;
            }
            if (rowIndex <= 5) {
              logDebug('🔎 Fila ${rowIndex + 1} raw:');
              columnMap.forEach((key, idx) {
                final raw = (idx >= 0 && idx < row.length && row[idx] != null) ? row[idx]!.value : null;
                final asStr = _getCellStringValueFromRow(row, idx);
                final asNum = _getCellDoubleValueFromRow(row, idx, double.nan);
                logDebug('   [$key] idx=$idx raw=${raw?.runtimeType} val="$asStr" num=$asNum');
              });
            }
            final articulo = Articulo(
              nombre: nombre,
              demandaAnual: _getCellDoubleValueFromRow(row, columnMap['Demanda Anual (unidades)'] ?? -1, 0),
              costoPedido: _getCellDoubleValueFromRow(row, columnMap['Costo por Pedido (soles)'] ?? -1, 0),
              costoMantenimiento: _getCellDoubleValueFromRow(row, columnMap['Costo Mantenimiento (soles/unidad)'] ?? -1, 0),
              costoFaltante: _getCellDoubleValueFromRow(row, columnMap['Costo por Faltante (soles/unidad)'] ?? -1, 0),
              costoUnitario: _getCellDoubleValueFromRow(row, columnMap['Costo Unitario (soles)'] ?? -1, 0),
              espacioUnidad: _getCellDoubleValueFromRow(row, columnMap['Espacio por Unidad (m²)'] ?? -1, 0),
              desviacionDiaria: _getCellDoubleValueFromRow(row, columnMap['Desviación Estándar Diaria'] ?? -1, 0),
              puntoReorden: _getCellDoubleValueFromRow(row, columnMap['Punto de Reorden (unidades)'] ?? -1, 0),
              tamanoLote: _getCellDoubleValueFromRow(row, columnMap['Tamaño de Lote (unidades)'] ?? -1, 1),
            );
            articulos.add(articulo);
            logDebug('✅ Fila ${rowIndex + 1}: Artículo creado - ${articulo.nombre}');
          } catch (e) {
            logDebug('❌ Error en fila ${rowIndex + 1}: $e');
          }
        }
        logDebug('🎉 Importación completada. Total de artículos: ${articulos.length}');
        return articulos;
      } catch (e) {
        logDebug('❌ Error al decodificar con excel: $e');
        if (kIsWeb) {
          // Fallback Web: parsear ZIP/XML
          try {
            final datos = await _leerHojaCompletaXlsxFallback(bytes);
            // Usar mapeo fijo por plantilla para fallback
            final columnMap = Map<String, int>.from(_templateColumnIndex);
            logDebug('🗺️ Mapeo fijo por plantilla aplicado (zip): $columnMap');
            final articulos = <Articulo>[];
            for (int rowIndex = 1; rowIndex < datos.length; rowIndex++) {
              final row = datos[rowIndex];
              String getStr(int idx) => (idx >= 0 && idx < row.length && row[idx] != null) ? row[idx].toString() : '';
              double getNum(int idx, double def) {
                String s = getStr(idx).trim();
                if (s.isEmpty) {
                  return def;
                }
                // Si NO hay punto y SÍ hay coma, asume coma como separador decimal
                if (!s.contains('.') && s.contains(',')) {
                  s = s.replaceAll(',', '.');
                }
                // Eliminar espacios finos o normales usados como separador de miles
                s = s.replaceAll('\u00A0', '').replaceAll(' ', '');
                final parsed = double.tryParse(s);
                return parsed ?? def;
              }
              final nombre = getStr(columnMap['Nombre del Artículo'] ?? 0);
              if (nombre.isEmpty) {
                continue;
              }
              if (rowIndex <= 5) {
                logDebug('🔎 Fila[zip] ${rowIndex + 1} raw:');
                columnMap.forEach((key, idx) {
                  final s = getStr(idx);
                  final n = double.tryParse(s);
                  logDebug('   [$key] idx=$idx val="$s" num=${n ?? 'NaN'}');
                });
              }
              articulos.add(Articulo(
                nombre: nombre,
                demandaAnual: getNum(columnMap['Demanda Anual (unidades)'] ?? -1, 0),
                costoPedido: getNum(columnMap['Costo por Pedido (soles)'] ?? -1, 0),
                costoMantenimiento: getNum(columnMap['Costo Mantenimiento (soles/unidad)'] ?? -1, 0),
                costoFaltante: getNum(columnMap['Costo por Faltante (soles/unidad)'] ?? -1, 0),
                costoUnitario: getNum(columnMap['Costo Unitario (soles)'] ?? -1, 0),
                espacioUnidad: getNum(columnMap['Espacio por Unidad (m²)'] ?? -1, 0),
                desviacionDiaria: getNum(columnMap['Desviación Estándar Diaria'] ?? -1, 0),
                puntoReorden: getNum(columnMap['Punto de Reorden (unidades)'] ?? -1, 0),
                tamanoLote: getNum(columnMap['Tamaño de Lote (unidades)'] ?? -1, 1),
              ));
            }
            logDebug('✅ Importación con fallback ZIP/XML. Filas: ${articulos.length}');
            return articulos;
          } catch (e2) {
            logDebug('❌ Fallback ZIP/XML falló: $e2');
          }
        }
        throw Exception('Error al importar desde Excel: $e');
      }
    } catch (e) {
      logDebug('❌ Error al importar desde Excel: $e');
      throw Exception('Error al importar desde Excel: $e');
    }
  }

  /// Métodos helper para trabajar con la librería 'excel'

  /// Extrae valor string de celda Excel (librería 'excel')
  static String _getCellStringValue(Data cell) {
    final value = cell.value;
    if (value == null) {
      return '';
    }
    
    // Manejar diferentes tipos de CellValue
    switch (value.runtimeType.toString()) {
      case 'TextCellValue':
        return (value as TextCellValue).value.toString().trim();
      case 'IntCellValue':
        return (value as IntCellValue).value.toString().trim();
      case 'DoubleCellValue':
        return (value as DoubleCellValue).value.toString().trim();
      case 'BoolCellValue':
        return (value as BoolCellValue).value.toString().trim();
      case 'DateCellValue':
        final dateValue = value as DateCellValue;
        return '${dateValue.day}/${dateValue.month}/${dateValue.year}';
      case 'DateTimeCellValue':
        final dateTimeValue = value as DateTimeCellValue;
        return '${dateTimeValue.day}/${dateTimeValue.month}/${dateTimeValue.year}';
      default:
        return value.toString().trim();
    }
  }

  /// Extrae valor string de celda Excel desde fila
  static String _getCellStringValueFromRow(List<Data?> row, int columnIndex) {
    if (columnIndex < 0 || columnIndex >= row.length || row[columnIndex] == null) {
      return '';
    }
    return _getCellStringValue(row[columnIndex]!);
  }

  /// Extrae valor double de celda Excel desde fila
  static double _getCellDoubleValueFromRow(List<Data?> row, int columnIndex, double defaultValue) {
    if (columnIndex < 0 || columnIndex >= row.length || row[columnIndex] == null) {
      return defaultValue;
    }
    
    final cell = row[columnIndex]!;
    final value = cell.value;
    
    if (value == null) {
      return defaultValue;
    }
    
    // Manejar diferentes tipos de CellValue
    switch (value.runtimeType.toString()) {
      case 'IntCellValue':
        return (value as IntCellValue).value.toDouble();
      case 'DoubleCellValue':
        return (value as DoubleCellValue).value;
      case 'TextCellValue':
        final stringValue = (value as TextCellValue).value.toString().trim();
        if (stringValue.isEmpty) {
          return defaultValue;
        }
        return double.tryParse(stringValue) ?? defaultValue;
      case 'BoolCellValue':
        return (value as BoolCellValue).value ? 1.0 : 0.0;
      default:
        final stringValue = value.toString().trim();
        if (stringValue.isEmpty) {
          return defaultValue;
        }
        return double.tryParse(stringValue) ?? defaultValue;
    }
  }
  /// Exporta resultados a un archivo Excel usando librería 'excel'
  static Future<String> exportarResultados(ResultadoSistema resultado) async {
    try {
      logDebug('📤 Iniciando exportación de resultados con librería excel...');
      
      // Crear nuevo Excel
      final excel = Excel.createExcel();
      final sheetName = 'Resultados';
      
      // Crear hoja de resultados
      final sheet = excel[sheetName];

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

      // Escribir encabezados usando librería 'excel'
      for (int i = 0; i < headers.length; i++) {
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
            .value = TextCellValue(headers[i]);
      }

      // Escribir datos de artículos
      for (int i = 0; i < resultado.resultados.length; i++) {
        final res = resultado.resultados[i];
        final row = i + 1; // Empezar desde la fila 1 (índice basado en 0)

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

      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: summaryRow + 1)).value = TextCellValue('Costo Total Sistema:');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: summaryRow + 1)).value = DoubleCellValue(resultado.costoTotalSistema);

      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: summaryRow + 2)).value = TextCellValue('Espacio Total Usado:');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: summaryRow + 2)).value = DoubleCellValue(resultado.espacioTotalUsado);

      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: summaryRow + 3)).value = TextCellValue('Presupuesto Total:');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: summaryRow + 3)).value = DoubleCellValue(resultado.presupuestoTotal);

      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: summaryRow + 4)).value = TextCellValue('Número Total Pedidos:');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: summaryRow + 4)).value = IntCellValue(resultado.numeroTotalPedidos);

      // Guardar archivo usando método compatible con web
      final fileName = 'inventario_qr_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      if (kIsWeb) {
        // En Web, la propia librería excel descarga el archivo
        excel.save(fileName: fileName);
        logDebug('📥 Web: descarga iniciada por excel.save(fileName: ...)');
        return fileName;
      } else {
        final bytes = excel.save();
        if (bytes == null || bytes.isEmpty) {
          throw Exception('Error: Los bytes del archivo Excel están vacíos');
        }
        logDebug('📊 Excel generado: ${bytes.length} bytes');
        final filePath = await _guardarArchivo(bytes, fileName);
        return filePath;
      }
    } catch (e) {
      throw Exception('Error al exportar a Excel: $e');
    }
  }

  /// Proporciona la plantilla Excel pregenerada desde assets
  static Future<String> generarPlantilla() async {
    try {
      logDebug('📋 Proporcionando plantilla Excel pregenerada...');
      // Cargar SIEMPRE la plantilla desde assets
      final byteData = await rootBundle.load('assets/templates/plantilla_inventario.xlsx');
      final uint8bytes = byteData.buffer.asUint8List();
      logDebug('✅ Plantilla cargada desde assets: ${uint8bytes.length} bytes');

      if (kIsWeb) {
        await downloadBytesWeb(
          uint8bytes,
          'plantilla_inventario.xlsx',
          mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        );
        return 'plantilla_inventario.xlsx';
      } else {
        return await _guardarArchivo(uint8bytes, 'plantilla_inventario.xlsx');
      }
      
    } catch (e) {
      logDebug('❌ Error al cargar plantilla pregenerada: $e');
      logDebug('🔄 Creando plantilla básica como fallback...');
      
      // Fallback: si falla la carga del asset, reportar error
      rethrow;
    }
  }

  /// Guarda un archivo en el directorio de documentos (móviles/escritorio)
  static Future<String> _guardarArchivo(List<int> bytes, String nombreArchivo) async {
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/$nombreArchivo';
    
    final file = File(path);
    await file.writeAsBytes(bytes);
    
    logDebug('💾 Archivo guardado en: $path');
    return path;
  }
} 