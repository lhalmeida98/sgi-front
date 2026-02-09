import 'dart:typed_data';

Future<void> openPdfBytes(Uint8List bytes, {required String fileName}) async {
  throw UnsupportedError('PDF opening is not supported on this platform.');
}

Future<bool> savePdfBytes(Uint8List bytes, {required String fileName}) async {
  throw UnsupportedError('PDF saving is not supported on this platform.');
}

Future<void> openXmlBytes(Uint8List bytes, {required String fileName}) async {
  throw UnsupportedError('XML opening is not supported on this platform.');
}

Future<bool> saveXmlBytes(Uint8List bytes, {required String fileName}) async {
  throw UnsupportedError('XML saving is not supported on this platform.');
}
