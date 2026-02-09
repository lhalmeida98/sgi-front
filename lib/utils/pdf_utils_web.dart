import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

Future<void> openPdfBytes(Uint8List bytes, {required String fileName}) async {
  final blob = html.Blob([bytes], 'application/pdf');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.window.open(url, '_blank');
  unawaited(_revokeLater(url));
}

Future<bool> savePdfBytes(Uint8List bytes, {required String fileName}) async {
  final blob = html.Blob([bytes], 'application/pdf');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..download = fileName
    ..style.display = 'none';
  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  unawaited(_revokeLater(url));
  return true;
}

Future<void> openXmlBytes(Uint8List bytes, {required String fileName}) async {
  final blob = html.Blob([bytes], 'application/xml');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.window.open(url, '_blank');
  unawaited(_revokeLater(url));
}

Future<bool> saveXmlBytes(Uint8List bytes, {required String fileName}) async {
  final blob = html.Blob([bytes], 'application/xml');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..download = fileName
    ..style.display = 'none';
  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  unawaited(_revokeLater(url));
  return true;
}

Future<void> _revokeLater(String url) async {
  await Future<void>.delayed(const Duration(seconds: 2));
  html.Url.revokeObjectUrl(url);
}
