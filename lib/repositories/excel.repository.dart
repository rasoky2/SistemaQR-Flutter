// Importaciones para manejo multiplataforma de Excel
// ignore_for_file: cascade_invocations

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
import 'package:inventario_qr/utils/math_utils.dart';
// Descarga web con import condicional
import 'package:inventario_qr/utils/web_download_stub.dart'
    if (dart.library.html) 'package:inventario_qr/utils/web_download_html.dart';
import 'package:path_provider/path_provider.dart';
import 'package:xml/xml.dart' as xml;

/// Resultado de importación con información de cálculos automáticos
class ImportacionResultado {
  final List<Articulo> articulos;
  final List<String> articulosConCalculosAutomaticos;
  final List<String> detallesCalculos;

  ImportacionResultado({
    required this.articulos,
    required this.articulosConCalculosAutomaticos,
    required this.detallesCalculos,
  });
}

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
  /// IMPLEMENTACIÓN MEJORADA: Lee columnas con fallback inteligente para web
  static Future<List<String>> leerColumnasExcel(String? filePath, [Uint8List? fileBytes]) async {
    try {
      logDebug('Iniciando lectura MEJORADA de columnas Excel...');
      
      // Si no hay path ni bytes, usar columnas estándar
      if ((filePath == null || filePath.isEmpty) && fileBytes == null) {
        logDebug('No se proporcionó archivo, usando columnas estándar');
        return _obtenerColumnasEstandar();
      }
      
      Uint8List bytes;
      
      if (fileBytes != null) {
        bytes = fileBytes;
        logDebug('Usando bytes proporcionados: ${bytes.length} bytes');
      } else if (!kIsWeb && filePath != null) {
        // Leer archivo del sistema (móvil/desktop)
        final file = File(filePath);
        if (!await file.exists()) {
          throw Exception('Archivo no encontrado: $filePath');
        }
        bytes = await file.readAsBytes();
        logDebug('Archivo leído: $filePath (${bytes.length} bytes)');
      } else {
        logDebug('Plataforma Web sin bytes - usando columnas estándar');
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
        logDebug('Excel decodificado con librería excel');
        
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
            logDebug('Header[excel] idx=$i => "$cellValue" (${cell.value.runtimeType})');
          }
        }
        
        if (columnas.isNotEmpty) {
          logDebug('Columnas leídas con librería excel: ${columnas.length}');
          return columnas;
        }
      } catch (e) {
        logDebug('Error con librería excel: $e');
        if (kIsWeb) {
          // Fallback Web: parsear XLSX (ZIP) y extraer primera hoja encabezados
          try {
            final columnas = await _leerEncabezadosXlsxFallback(bytes);
            for (int i = 0; i < columnas.length; i++) {
              logDebug('Header[zip] idx=$i => "${columnas[i]}"');
            }
            if (columnas.isNotEmpty) {
              logDebug('Columnas leídas con fallback ZIP/XML: ${columnas.length}');
              return columnas;
            }
          } catch (e2) {
            logDebug('Fallback ZIP/XML falló: $e2');
          }
        }
      }
      
      logDebug('Usando columnas estándar como último recurso');
      return _obtenerColumnasEstandar();
      
    } catch (e) {
      logDebug('Error general al leer columnas: $e');
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

  static Future<ImportacionResultado> importarArticulosConColumnas(Set<String> columnasSeleccionadas, String filePath, [Uint8List? fileBytes, double leadTimeDias = 36.5]) async {
    try {
      logDebug('Iniciando importación REAL desde archivo Excel usando librería excel...');
      logDebug('Archivo: $filePath');
      logDebug('Columnas seleccionadas: $columnasSeleccionadas');
      logDebug('⏱️ Lead Time configurado: $leadTimeDias días');
      
      // Si no hay path ni bytes, retornar vacío
      if ((filePath.isEmpty) && fileBytes == null) {
        logDebug('No se proporcionó archivo');
        return ImportacionResultado(
          articulos: [],
          articulosConCalculosAutomaticos: [],
          detallesCalculos: [],
        );
      }
      
      Uint8List bytes;
      
      if (fileBytes != null) {
        // Usar bytes proporcionados (desde web o file_picker)
        bytes = fileBytes;
        logDebug('Usando bytes proporcionados: ${bytes.length} bytes');
      } else if (!kIsWeb) {
        // Leer archivo del sistema (móvil/desktop)
        final file = File(filePath);
        if (!await file.exists()) {
          throw Exception('Archivo no encontrado: $filePath');
        }
        bytes = await file.readAsBytes();
        logDebug('Archivo leído: $filePath (${bytes.length} bytes)');
      } else {
        logDebug('Plataforma Web sin bytes');
        return ImportacionResultado(
          articulos: [],
          articulosConCalculosAutomaticos: [],
          detallesCalculos: [],
        );
      }
      
      // Validar formato
      final formato = _detectarFormatoExcel(bytes);
      if (formato != 'xlsx') {
        throw Exception('Formato no soportado ($formato). Use archivos .xlsx');
      }

      // Decodificar Excel usando librería 'excel'
      try {
        final excel = Excel.decodeBytes(List<int>.from(bytes));
        logDebug('Excel decodificado exitosamente');
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
        // Construir mapeo dinámico por encabezados si existen, con fallback a plantilla
        final headerRow = sheet.rows.first;
        final headerToIndex = <String, int>{};
        for (int i = 0; i < headerRow.length; i++) {
          final cell = headerRow[i];
          if (cell != null) {
            final text = _getCellStringValue(cell).trim();
            if (text.isNotEmpty) {
              headerToIndex[text] = i;
            }
          }
        }
        final columnMap = <String, int>{};
        for (final key in _templateColumnIndex.keys) {
          columnMap[key] = headerToIndex[key] ?? _templateColumnIndex[key]!;
        }
        logDebug('️ Mapeo por encabezados aplicado (fallback a plantilla cuando falta): $columnMap');
        // Procesar filas
        final articulos = <Articulo>[];
        // Listas para rastrear cálculos automáticos
        final articulosConCalculosAutomaticos = <String>[];
        final detallesCalculos = <String>[];
        
        for (int rowIndex = 1; rowIndex < sheet.rows.length; rowIndex++) {
          final row = sheet.rows[rowIndex];
          try {
            final nombreIndex = columnMap['Nombre del Artículo'] ?? 0;
            final nombre = _getCellStringValueFromRow(row, nombreIndex);
            if (nombre.isEmpty) {
              logDebug('️ Fila ${rowIndex + 1}: Nombre vacío, saltando...');
              continue;
            }
            if (rowIndex <= 5) {
              logDebug('Fila ${rowIndex + 1} raw:');
              columnMap.forEach((key, idx) {
                final raw = (idx >= 0 && idx < row.length && row[idx] != null) ? row[idx]!.value : null;
                final asStr = _getCellStringValueFromRow(row, idx);
                final asNum = _getCellDoubleValueFromRow(row, idx, double.nan);
                logDebug('   [$key] idx=$idx raw=${raw?.runtimeType} val="$asStr" num=$asNum');
              });
            }
            // Extraer base
            final demanda = _getCellDoubleValueFromRow(row, columnMap['Demanda Anual (unidades)'] ?? -1, 0);
            final costoPedido = _getCellDoubleValueFromRow(row, columnMap['Costo por Pedido (soles)'] ?? -1, 0);
            final costoMantenimiento = _getCellDoubleValueFromRow(row, columnMap['Costo Mantenimiento (soles/unidad)'] ?? -1, 0);
            final costoFaltante = _getCellDoubleValueFromRow(row, columnMap['Costo por Faltante (soles/unidad)'] ?? -1, 0);
            final costoUnitario = _getCellDoubleValueFromRow(row, columnMap['Costo Unitario (soles)'] ?? -1, 0);
            final espacioUnidad = _getCellDoubleValueFromRow(row, columnMap['Espacio por Unidad (m²)'] ?? -1, 0);
            final desviacionDiaria = _getCellDoubleValueFromRow(row, columnMap['Desviación Estándar Diaria'] ?? -1, 0);
            // Punto de reorden
            double puntoReorden = _getCellDoubleValueFromRow(row, columnMap['Punto de Reorden (unidades)'] ?? -1, 0);
            final int rIdx = columnMap['Punto de Reorden (unidades)'] ?? -1;
            final bool rEsFormula = (rIdx >= 0 && rIdx < row.length && row[rIdx] != null) &&
                row[rIdx]!.value.runtimeType.toString().contains('FormulaCellValue');
            
            // Calcular punto de reorden automáticamente si es fórmula, inválido o no se proporciona
            if (rEsFormula || puntoReorden <= 0) {
              final muL = MathUtils.calcularDemandaLeadTime(demanda, leadTimeDias);
              puntoReorden = muL;
              
              // Registrar cálculo automático
              articulosConCalculosAutomaticos.add(nombre);
              detallesCalculos.add('$nombre: Punto de Reorden (R) = ${muL.toStringAsFixed(2)} (calculado automáticamente como μL = D×L/365)');
              
              logDebug('ℹ️ R calculado automáticamente (μL): $puntoReorden usando leadTime=$leadTimeDias días');
            }
            
            // Tamaño de lote (EOQ si fórmula o inválido)
            double tamanoLote = _getCellDoubleValueFromRow(row, columnMap['Tamaño de Lote (unidades)'] ?? -1, 0);
            final int qIdx = columnMap['Tamaño de Lote (unidades)'] ?? -1;
            final bool qEsFormula = (qIdx >= 0 && qIdx < row.length && row[qIdx] != null) &&
                row[qIdx]!.value.runtimeType.toString().contains('FormulaCellValue');
                
            if (qEsFormula || tamanoLote <= 0) {
              final qCalc = MathUtils.calcularEOQ(demanda, costoPedido, costoMantenimiento);
              
              // Registrar cálculo automático
              if (!articulosConCalculosAutomaticos.contains(nombre)) {
                articulosConCalculosAutomaticos.add(nombre);
              }
              detallesCalculos.add('$nombre: Tamaño de Lote (Q) = ${qCalc.toStringAsFixed(2)} (calculado automáticamente por EOQ)');
              
              logDebug('Q calculado por EOQ (fórmula/0 detectado): $qCalc');
              tamanoLote = qCalc;
            }

            final articulo = Articulo(
              nombre: nombre,
              demandaAnual: demanda,
              costoPedido: costoPedido,
              costoMantenimiento: costoMantenimiento,
              costoFaltante: costoFaltante,
              costoUnitario: costoUnitario,
              espacioUnidad: espacioUnidad,
              desviacionDiaria: desviacionDiaria,
              puntoReorden: puntoReorden,
              tamanoLote: tamanoLote,
            );
            articulos.add(articulo);
            logDebug('Fila ${rowIndex + 1}: Artículo creado - ${articulo.nombre}');
          } catch (e) {
            logDebug('Error en fila ${rowIndex + 1}: $e');
          }
        }
        logDebug('Importación completada. Total de artículos: ${articulos.length}');
        logDebug('Artículos con cálculos automáticos: ${articulosConCalculosAutomaticos.length}');
        
        return ImportacionResultado(
          articulos: articulos,
          articulosConCalculosAutomaticos: articulosConCalculosAutomaticos,
          detallesCalculos: detallesCalculos,
        );
      } catch (e) {
        logDebug('Error al decodificar con excel: $e');
        if (kIsWeb) {
          // Fallback Web: parsear ZIP/XML
          try {
            final datos = await _leerHojaCompletaXlsxFallback(bytes);
            // Usar mapeo fijo por plantilla para fallback
            final columnMap = Map<String, int>.from(_templateColumnIndex);
            logDebug('️ Mapeo fijo por plantilla aplicado (zip): $columnMap');
            final articulos = <Articulo>[];
            for (int rowIndex = 1; rowIndex < datos.length; rowIndex++) {
              final row = datos[rowIndex];
              String getStr(int idx) => (idx >= 0 && idx < row.length && row[idx] != null) ? row[idx].toString() : '';
              double getNum(int idx, double def) => _parseDoubleFromString(getStr(idx), def);
              final nombre = getStr(columnMap['Nombre del Artículo'] ?? 0);
              if (nombre.isEmpty) {
                continue;
              }
              if (rowIndex <= 5) {
                logDebug('Fila[zip] ${rowIndex + 1} raw:');
                columnMap.forEach((key, idx) {
                  final s = getStr(idx);
                  final n = _parseDoubleFromString(s, double.nan);
                  logDebug('   [$key] idx=$idx val="$s" num=$n');
                });
              }
              // Base
              final demanda = getNum(columnMap['Demanda Anual (unidades)'] ?? -1, 0);
              final costoPedido = getNum(columnMap['Costo por Pedido (soles)'] ?? -1, 0);
              final costoMantenimiento = getNum(columnMap['Costo Mantenimiento (soles/unidad)'] ?? -1, 0);
              final costoFaltante = getNum(columnMap['Costo por Faltante (soles/unidad)'] ?? -1, 0);
              final costoUnitario = getNum(columnMap['Costo Unitario (soles)'] ?? -1, 0);
              final espacioUnidad = getNum(columnMap['Espacio por Unidad (m²)'] ?? -1, 0);
              final desviacionDiaria = getNum(columnMap['Desviación Estándar Diaria'] ?? -1, 0);
              // Punto de reorden: si es fórmula (detectamos por texto que contiene '=' o letras), usamos μL
              final rStr = getStr(columnMap['Punto de Reorden (unidades)'] ?? -1);
              double puntoReorden = getNum(columnMap['Punto de Reorden (unidades)'] ?? -1, 0);
              
              // Calcular punto de reorden automáticamente si es fórmula, inválido o no se proporciona
              if (rStr.contains('=') || rStr.contains('SQRT') || rStr.contains('(') || puntoReorden <= 0) {
                puntoReorden = MathUtils.calcularDemandaLeadTime(demanda, leadTimeDias);
                logDebug('ℹ️ R calculado automáticamente en fallback ZIP/XML (μL): $puntoReorden usando leadTime=$leadTimeDias días');
              }
              
              // Q: si parece fórmula, usar EOQ
              final qStr = getStr(columnMap['Tamaño de Lote (unidades)'] ?? -1);
              double tamanoLote = getNum(columnMap['Tamaño de Lote (unidades)'] ?? -1, 1);
              if (qStr.contains('=') || qStr.toUpperCase().contains('SQRT') || tamanoLote <= 0) {
                tamanoLote = MathUtils.calcularEOQ(demanda, costoPedido, costoMantenimiento);
                logDebug('Q calculado automáticamente en fallback ZIP/XML (EOQ): $tamanoLote');
              }

              articulos.add(Articulo(
                nombre: nombre,
                demandaAnual: demanda,
                costoPedido: costoPedido,
                costoMantenimiento: costoMantenimiento,
                costoFaltante: costoFaltante,
                costoUnitario: costoUnitario,
                espacioUnidad: espacioUnidad,
                desviacionDiaria: desviacionDiaria,
                puntoReorden: puntoReorden,
                tamanoLote: tamanoLote,
              ));
            }
            logDebug('Importación con fallback ZIP/XML. Filas: ${articulos.length}');
            return ImportacionResultado(
              articulos: articulos,
              articulosConCalculosAutomaticos: [],
              detallesCalculos: [],
            );
          } catch (e2) {
            logDebug('Fallback ZIP/XML falló: $e2');
          }
        }
        throw Exception('Error al importar desde Excel: $e');
      }
    } catch (e) {
      logDebug('Error al importar desde Excel: $e');
      throw Exception('Error al importar desde Excel: $e');
    }
  }

  /// Métodos helper para trabajar con la librería 'excel'

  /// Parser robusto para números localizados (maneja comas decimales y separadores de miles)
  static double _parseDoubleFromString(String stringValue, double defaultValue) {
    String s = stringValue.trim();
    if (s.isEmpty) {
      return defaultValue;
    }
    // Eliminar símbolos y espacios comunes (moneda, NBSP, etc.) conservando dígitos, signos y separadores
    s = s
        .replaceAll('\u00A0', '')
        .replaceAll(' ', '')
        .replaceAll(RegExp(r'[^0-9,\.\-]'), '');

    if (s.isEmpty) {
      return defaultValue;
    }

    final hasComma = s.contains(',');
    final hasDot = s.contains('.');

    if (hasComma && hasDot) {
      // Si ambos existen, inferir decimal por el separador que aparece más a la derecha
      final lastComma = s.lastIndexOf(',');
      final lastDot = s.lastIndexOf('.');
      if (lastComma > lastDot) {
        // Formato tipo 1.234,56 -> quitar puntos (miles) y cambiar coma a punto
        s = s.replaceAll('.', '').replaceAll(',', '.');
      } else {
        // Formato tipo 1,234.56 -> quitar comas (miles), dejar punto como decimal
        s = s.replaceAll(',', '');
      }
    } else if (hasComma && !hasDot) {
      // Solo coma: asumir coma decimal
      s = s.replaceAll(',', '.');
    }

    return double.tryParse(s) ?? defaultValue;
  }

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
        final stringValue = (value as TextCellValue).value.toString();
        return _parseDoubleFromString(stringValue, defaultValue);
      case 'BoolCellValue':
        return (value as BoolCellValue).value ? 1.0 : 0.0;
      default:
        final stringValue = value.toString();
        return _parseDoubleFromString(stringValue, defaultValue);
    }
  }
  /// Aplica redondeo según configuración del provider
  static double _aplicarRedondeoConfigurado(
    double valor,
    String tipo, {
    String? tipoRedondeo,
    int? decimales,
  }) {
    if (tipoRedondeo == 'unidades') {
      return MathUtils.redondearInteligente(valor, tipo: 'unidades');
    } else {
      return MathUtils.redondearInteligente(
        valor,
        tipo: 'unidades_decimales',
        decimales: decimales ?? 0,
      );
    }
  }

  /// Exporta resultados a un archivo Excel usando librería 'excel'
  static Future<String> exportarResultados(
    ResultadoSistema resultado, {
    List<Articulo>? articulos,
    // Configuraciones de redondeo del provider
    String? tipoRedondeoPuntoReorden,
    String? tipoRedondeoTamanoLote,
    int? decimalesPuntoReorden,
    int? decimalesTamanoLote,
  }) async {
    try {
      logDebug('Iniciando exportación de resultados con librería excel...');
      logDebug('Configuraciones de redondeo: PuntoReorden=$tipoRedondeoPuntoReorden($decimalesPuntoReorden), TamanoLote=$tipoRedondeoTamanoLote($decimalesTamanoLote)');
      
      // Crear nuevo Excel (usa hoja predeterminada)
      final excel = Excel.createExcel();
      
      // Usar la hoja predeterminada (Sheet1)
      final sheet = excel.tables.keys.first;
      final worksheet = excel[sheet];

      // Encabezados que coinciden exactamente con la interfaz
      final headers = [
        'Artículo',           // Coincide con DataTable
        'Q',                  // Coincide con DataTable
        'R',                  // Coincide con DataTable
        'Z-Score',            // Coincide con DataTable
        'Backorders',         // Coincide con DataTable
        'Costo Total',        // Coincide con DataTable
        'Espacio (m²)',       // Coincide con DataTable
      ];

      // Escribir encabezados con colores del tema
      for (int i = 0; i < headers.length; i++) {
        final cell = worksheet
            .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
        cell.value = TextCellValue(headers[i]);
        // Color del tema MDSJ para encabezados
        cell.cellStyle = CellStyle(
          backgroundColorHex: ExcelColor.blue, // Usar azul similar al primary del tema
          fontColorHex: ExcelColor.white,
          bold: true,
        );
      }

      // Escribir datos que coinciden exactamente con la interfaz
      for (int i = 0; i < resultado.resultados.length; i++) {
        final res = resultado.resultados[i];
        final row = i + 1; // Empezar desde la fila 1 (índice basado en 0)

        // Aplicar redondeo configurado del provider
        final tamanoLoteRedondeado = _aplicarRedondeoConfigurado(
          res.tamanoLote,
          'tamanoLote',
          tipoRedondeo: tipoRedondeoTamanoLote,
          decimales: decimalesTamanoLote,
        );
        final puntoReordenRedondeado = _aplicarRedondeoConfigurado(
          res.puntoReorden,
          'puntoReorden',
          tipoRedondeo: tipoRedondeoPuntoReorden,
          decimales: decimalesPuntoReorden,
        );

        // Formato exacto como en la interfaz (sin colores alternados)
        worksheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).value = TextCellValue(res.nombre);
        worksheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row)).value = TextCellValue(tamanoLoteRedondeado.toStringAsFixed(decimalesTamanoLote ?? 0)); // Q: según configuración
        worksheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row)).value = TextCellValue(puntoReordenRedondeado.toStringAsFixed(decimalesPuntoReorden ?? 0)); // R: según configuración
        worksheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row)).value = TextCellValue(res.zScore.toStringAsFixed(2)); // Z-Score: 2 decimales
        worksheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row)).value = TextCellValue(res.backordersEsperados.toStringAsFixed(2)); // Backorders: 2 decimales
        worksheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row)).value = TextCellValue(MathUtils.formatearNumeroParaExcel(res.costoTotal)); // Costo Total: formato número
        worksheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: row)).value = TextCellValue(MathUtils.formatearNumeroParaExcel(res.espacioUsado)); // Espacio: formato número
      }

      // Agregar resumen del sistema en la parte derecha (columna H)
      final summaryStartCol = 8; // Columna H (índice 8)
      final summaryStartRow = 0; // Empezar desde la fila 0 (mismo nivel que los encabezados)

      // Encabezado del resumen con color del tema
      final summaryHeaderCell = worksheet.cell(CellIndex.indexByColumnRow(columnIndex: summaryStartCol, rowIndex: summaryStartRow));
      summaryHeaderCell.value = TextCellValue('Resumen del Sistema');
      summaryHeaderCell.cellStyle = CellStyle(
        backgroundColorHex: ExcelColor.blue, // Usar el mismo color que los encabezados
        fontColorHex: ExcelColor.white,
        bold: true,
      );

      // Datos del resumen (sin colores de fondo)
      final summaryData = [
        ['Costo Total Sistema:', MathUtils.formatearNumeroParaExcel(resultado.costoTotalSistema)],
        ['Espacio Total Usado:', MathUtils.formatearNumeroParaExcel(resultado.espacioTotalUsado)],
        ['Presupuesto Total:', MathUtils.formatearNumeroParaExcel(resultado.presupuestoTotal)],
        ['Número Total Pedidos:', resultado.numeroTotalPedidos.toString()],
      ];

      for (int i = 0; i < summaryData.length; i++) {
        final row = summaryStartRow + i + 1;
        
        // Etiqueta (columna H) - solo negrita
        final labelCell = worksheet.cell(CellIndex.indexByColumnRow(columnIndex: summaryStartCol, rowIndex: row));
        labelCell.value = TextCellValue(summaryData[i][0]);
        labelCell.cellStyle = CellStyle(
          bold: true,
        );
        
        // Valor (columna I) - sin formato especial
        final valueCell = worksheet.cell(CellIndex.indexByColumnRow(columnIndex: summaryStartCol + 1, rowIndex: row));
        valueCell.value = TextCellValue(summaryData[i][1]);
      }

      // Agregar artículos del sistema en la misma hoja (después de los resultados)
      if (articulos != null && articulos.isNotEmpty) {
        final articulosStartRow = resultado.resultados.length + 4; // Espacio adicional después de los resultados
        
        // Encabezados para artículos del sistema
        final articulosHeaders = [
          'Nombre',
          'Demanda Anual',
          'Costo Pedido (s/)',
          'Costo Mantenimiento (s/)',
          'Costo Faltante (s/)',
          'Costo Unitario (s/)',
          'Espacio Unidad (m²)',
          'Desviación Diaria',
          'Punto Reorden',
          'Tamaño Lote',
        ];

        // Escribir encabezados de artículos con colores del tema
        for (int i = 0; i < articulosHeaders.length; i++) {
          final cell = worksheet
              .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: articulosStartRow));
          cell.value = TextCellValue(articulosHeaders[i]);
          // Color del tema MDSJ para encabezados de artículos
          cell.cellStyle = CellStyle(
            backgroundColorHex: ExcelColor.blue, // Usar el mismo color que los otros encabezados
            fontColorHex: ExcelColor.white,
            bold: true,
          );
        }

        // Escribir datos de artículos (sin colores alternados)
        for (int i = 0; i < articulos.length; i++) {
          final articulo = articulos[i];
          final row = articulosStartRow + i + 1; // Empezar desde la fila siguiente a los encabezados

          // Aplicar redondeo configurado del provider para artículos
          final tamanoLoteRedondeado = _aplicarRedondeoConfigurado(
            articulo.tamanoLote,
            'tamanoLote',
            tipoRedondeo: tipoRedondeoTamanoLote,
            decimales: decimalesTamanoLote,
          );
          final puntoReordenRedondeado = _aplicarRedondeoConfigurado(
            articulo.puntoReorden,
            'puntoReorden',
            tipoRedondeo: tipoRedondeoPuntoReorden,
            decimales: decimalesPuntoReorden,
          );

          // Formato exacto como en la interfaz
          worksheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).value = TextCellValue(articulo.nombre);
          worksheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row)).value = TextCellValue(articulo.demandaAnual.toStringAsFixed(2));
          worksheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row)).value = TextCellValue(MathUtils.formatearNumeroParaExcel(articulo.costoPedido));
          worksheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row)).value = TextCellValue(MathUtils.formatearNumeroParaExcel(articulo.costoMantenimiento));
          worksheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row)).value = TextCellValue(MathUtils.formatearNumeroParaExcel(articulo.costoFaltante));
          worksheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row)).value = TextCellValue(MathUtils.formatearNumeroParaExcel(articulo.costoUnitario));
          worksheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: row)).value = TextCellValue(MathUtils.formatearNumeroParaExcel(articulo.espacioUnidad));
          worksheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: row)).value = TextCellValue(articulo.desviacionDiaria.toStringAsFixed(2));
          worksheet.cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: row)).value = TextCellValue(puntoReordenRedondeado.toStringAsFixed(decimalesPuntoReorden ?? 0)); // R: según configuración
          worksheet.cell(CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: row)).value = TextCellValue(tamanoLoteRedondeado.toStringAsFixed(decimalesTamanoLote ?? 0)); // Q: según configuración
        }
      }

      // Guardar archivo usando método compatible con web
      final fileName = 'inventario_qr_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      if (kIsWeb) {
        // En Web, la propia librería excel descarga el archivo
        excel.save(fileName: fileName);
        logDebug('Web: descarga iniciada por excel.save(fileName: ...)');
        return fileName;
      } else {
        final bytes = excel.save();
        if (bytes == null || bytes.isEmpty) {
          throw Exception('Error: Los bytes del archivo Excel están vacíos');
        }
        logDebug('Excel generado: ${bytes.length} bytes');
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
      logDebug('Proporcionando plantilla Excel pregenerada...');
      // Cargar SIEMPRE la plantilla desde assets
      final byteData = await rootBundle.load('assets/templates/plantilla_inventario.xlsx');
      final uint8bytes = byteData.buffer.asUint8List();
      logDebug('Plantilla cargada desde assets: ${uint8bytes.length} bytes');

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
      logDebug('Error al cargar plantilla pregenerada: $e');
      logDebug('Creando plantilla básica como fallback...');
      
      // Fallback: si falla la carga del asset, reportar error
      rethrow;
    }
  }

  /// DESCARGAR ARCHIVO COMPRIMIDO DESDE ASSETS (MULTIPLATAFORMA)
  static Future<String> descargarArchivoZip(String nombreArchivo) async {
    try {
      logDebug('ExcelRepository: Descargando archivo comprimido: $nombreArchivo...');
      
      // CARGAR ARCHIVO DESDE ASSETS
      final byteData = await rootBundle.load('assets/templates/$nombreArchivo');
      final uint8bytes = byteData.buffer.asUint8List();
      logDebug('ExcelRepository: Archivo comprimido cargado desde assets: ${uint8bytes.length} bytes');
      
      if (kIsWeb) {
        // Mapear tipo MIME según la extensión para soporte multi-formato
        String mimeType = 'application/octet-stream';
        if (nombreArchivo.endsWith('.zip')) {
          mimeType = 'application/zip';
        } else if (nombreArchivo.endsWith('.rar')) {
          mimeType = 'application/vnd.rar';
        }

        // WEB: Descargar directamente desde assets
        await downloadBytesWeb(
          uint8bytes,
          nombreArchivo,
          mimeType: mimeType,
        );
        logDebug('ExcelRepository: Archivo comprimido descargado en web: $nombreArchivo');
        return 'Descargado: $nombreArchivo';
      } else {
        // NATIVO: Guardar en directorio temporal
        return await _guardarArchivo(uint8bytes, nombreArchivo);
      }
    } catch (e) {
      logDebug('ExcelRepository: Error al descargar archivo ZIP: $e');
      rethrow;
    }
  }

  /// Guarda un archivo en el directorio de documentos (móviles/escritorio)
  static Future<String> _guardarArchivo(List<int> bytes, String nombreArchivo) async {
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/$nombreArchivo';
    
    final file = File(path);
    await file.writeAsBytes(bytes);
    
    logDebug('Archivo guardado en: $path');
    return path;
  }
} 