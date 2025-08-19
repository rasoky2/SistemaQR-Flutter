//ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:inventario_qr/utils/logger.dart';

/// Descarga archivos en web con soporte para diferentes tipos
Future<void> downloadBytesWeb(Uint8List bytes, String fileName, {String mimeType = 'application/octet-stream'}) async {
  try {
    // Crear blob con el tipo MIME correcto
    final blob = html.Blob([bytes], mimeType);
    
    // Crear URL del blob
    final url = html.Url.createObjectUrlFromBlob(blob);
    
    // Crear elemento anchor para descarga usando cascade
    final anchor = html.AnchorElement(href: url)
      ..download = fileName
      ..style.display = 'none';
    
    // Agregar al DOM, hacer clic y remover
    html.document.body?.append(anchor);
    anchor..click()
    ..remove();
    
    // Limpiar URL del blob
    html.Url.revokeObjectUrl(url);
    
    logDebug('✅ Descarga web iniciada: $fileName');
  } catch (e) {
    logDebug('❌ Error en descarga web: $e');
    rethrow;
  }
}

/// Descarga específica para paquetes portables
Future<void> downloadPortableWeb(Uint8List bytes, String fileName) async {
  await downloadBytesWeb(
    bytes, 
    fileName, 
    mimeType: 'application/zip'
  );
}

/// Descarga específica para archivos Excel
Future<void> downloadExcelWeb(Uint8List bytes, String fileName) async {
  await downloadBytesWeb(
    bytes, 
    fileName, 
    mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
  );
}

/// Descarga específica para paquetes portables con mejor UX
Future<void> downloadPortablePackageWeb(Uint8List bytes, String fileName) async {
  try {
    // Mostrar notificación de descarga
    logDebug('📦 Iniciando descarga de paquete portable: $fileName');
    
    // Descargar con tipo MIME correcto para ZIP
    await downloadBytesWeb(
      bytes, 
      fileName, 
      mimeType: 'application/zip'
    );
    
    logDebug('✅ Paquete portable descargado exitosamente');
  } catch (e) {
    logDebug('❌ Error al descargar paquete portable: $e');
    rethrow;
  }
}


