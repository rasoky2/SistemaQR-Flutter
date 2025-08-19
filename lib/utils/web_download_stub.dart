import 'dart:typed_data';

/// Stub para plataformas no web - no hace nada
Future<void> downloadBytesWeb(Uint8List bytes, String fileName, {String mimeType = 'application/octet-stream'}) async {
  // No-op en plataformas no web
}

/// Stub para descarga de paquetes portables
Future<void> downloadPortableWeb(Uint8List bytes, String fileName) async {
  // No-op en plataformas no web
}

/// Stub para descarga de archivos Excel
Future<void> downloadExcelWeb(Uint8List bytes, String fileName) async {
  // No-op en plataformas no web
}

/// Stub para descarga de paquetes portables con mejor UX
Future<void> downloadPortablePackageWeb(Uint8List bytes, String fileName) async {
  // No-op en plataformas no web
}


