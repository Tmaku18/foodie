import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

class FileExportService {
  Future<File> exportJson(String filename, Map<String, dynamic> payload) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$filename.json');
    return file.writeAsString(const JsonEncoder.withIndent('  ').convert(payload));
  }

  Future<File> exportCsv(String filename, List<List<String>> rows) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$filename.csv');
    final content = rows.map((row) => row.map(_escapeCsv).join(',')).join('\n');
    return file.writeAsString(content);
  }

  String _escapeCsv(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
}
