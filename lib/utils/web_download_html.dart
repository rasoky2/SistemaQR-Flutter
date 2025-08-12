import 'dart:typed_data';
import 'dart:html' as html;

Future<void> downloadBytesWeb(Uint8List bytes, String fileName, {String mimeType = 'application/octet-stream'}) async {
  final blob = html.Blob([bytes], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..download = fileName
    ..click();
  html.Url.revokeObjectUrl(url);
}


