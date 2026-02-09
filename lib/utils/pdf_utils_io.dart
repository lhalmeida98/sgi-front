import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';

Future<void> openPdfBytes(Uint8List bytes, {required String fileName}) async {
  final file = File('${Directory.systemTemp.path}/$fileName');
  await file.writeAsBytes(bytes, flush: true);
  await OpenFilex.open(file.path);
}

Future<bool> savePdfBytes(Uint8List bytes, {required String fileName}) async {
  final path = await FilePicker.platform.saveFile(
    type: FileType.custom,
    allowedExtensions: const ['pdf'],
    fileName: fileName,
  );
  if (path == null) {
    return false;
  }
  final file = File(path);
  await file.writeAsBytes(bytes, flush: true);
  return true;
}

Future<void> openXmlBytes(Uint8List bytes, {required String fileName}) async {
  final file = File('${Directory.systemTemp.path}/$fileName');
  await file.writeAsBytes(bytes, flush: true);
  await OpenFilex.open(file.path);
}

Future<bool> saveXmlBytes(Uint8List bytes, {required String fileName}) async {
  final path = await FilePicker.platform.saveFile(
    type: FileType.custom,
    allowedExtensions: const ['xml'],
    fileName: fileName,
  );
  if (path == null) {
    return false;
  }
  final file = File(path);
  await file.writeAsBytes(bytes, flush: true);
  return true;
}
