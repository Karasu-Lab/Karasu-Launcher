import '../models/java_patch_note.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class MinecraftAdaptor {
  static const String baseUrl = 'https://launchercontent.mojang.com';
  
  Future<JavaPatchNote> getJavaPatchNotes() async {
    final client = RestClient(baseUrl);
    final response = await client.get('/javaPatchNotes.json');
    
    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonData = json.decode(response.body);
      return JavaPatchNote.fromJson(jsonData);
    } else {
      throw Exception('Failed to load patch notes. Status code: ${response.statusCode}');
    }
  }

  Future<JavaPatchNoteEntry?> getJavaPatchNoteByVersion(String version) async {
    final patchNotes = await getJavaPatchNotes();
    
    for (final entry in patchNotes.entries) {
      if (entry.version == version) {
        return entry;
      }
    }
    
    throw Exception('Patch notes for version $version not found');
  }
}

class RestClient {
  final String baseUrl;
  
  RestClient(this.baseUrl);
  
  Future<RestResponse> get(String path) async {
    try {
      final uri = Uri.parse('$baseUrl$path');
      final client = http.Client();
      final response = await client.get(uri);
      client.close();
      
      return RestResponse(
        response.statusCode, 
        response.body, 
        response.headers['content-type'] ?? 'application/json'
      );
    } catch (e) {
      throw Exception('Failed to make request: $e');
    }
  }
}

class RestResponse {
  final int statusCode;
  final dynamic body;
  final String contentType;
  
  RestResponse(this.statusCode, this.body, this.contentType);
}