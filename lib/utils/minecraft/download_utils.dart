import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../utils/file_utils.dart';

/// ファイルをダウンロードする共通関数
Future<File> downloadFile(
  String url,
  String filePath, {
  int? expectedSize,
}) async {
  final file = File(filePath);

  if (await file.exists()) {
    final fileSize = await file.length();
    if (expectedSize == null || fileSize == expectedSize) {
      return file;
    }
    debugPrint('File size mismatch, re-downloading: $filePath');
  }

  await createParentDirectoryFromFilePath(filePath);

  try {
    final response = await http.get(Uri.parse(url));

    if (response.statusCode != 200) {
      throw Exception('Failed to download file: ${response.statusCode}');
    }

    return await file.writeAsBytes(response.bodyBytes);
  } catch (e) {
    throw Exception('Error occurred while downloading file: $e');
  }
}
