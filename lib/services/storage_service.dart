import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class StorageService {
  final String fileName = 'flashcards_data.json';

  Future<File> _localFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$fileName');
  }

  Future<Map<String, dynamic>> readData() async {
    try {
      final file = await _localFile();
      if (!await file.exists()) {
        return {};
      }
      final contents = await file.readAsString();
      if (contents.trim().isEmpty) return {};
      return json.decode(contents) as Map<String, dynamic>;
    } catch (e) {
      // return empty on error
      return {};
    }
  }

  Future<void> writeData(Map<String, dynamic> data) async {
    final file = await _localFile();
    final encoded = json.encode(data);
    await file.writeAsString(encoded);
  }
}