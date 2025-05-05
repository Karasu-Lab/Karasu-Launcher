import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

class MavenArtifact {
  final String groupId;
  final String artifactId;
  final String version;
  final String? classifier;
  final String extension;

  MavenArtifact({
    required this.groupId,
    required this.artifactId,
    required this.version,
    this.classifier,
    this.extension = 'jar',
  });

  factory MavenArtifact.parse(String mavenCoordinate) {
    final parts = mavenCoordinate.split(':');

    if (parts.length < 3) {
      throw ArgumentError('無効なMaven座標です: $mavenCoordinate');
    }

    final groupId = parts[0];
    final artifactId = parts[1];
    final version = parts[2];
    String? classifier;
    String extension = 'jar';

    if (parts.length > 3) {
      if (parts.length == 4) {
        if (parts[3].contains('.')) {
          extension = parts[3];
        } else {
          classifier = parts[3];
        }
      } else if (parts.length == 5) {
        classifier = parts[3];
        extension = parts[4];
      }
    }

    return MavenArtifact(
      groupId: groupId,
      artifactId: artifactId,
      version: version,
      classifier: classifier,
      extension: extension,
    );
  }

  String getFileName() {
    if (classifier != null && classifier!.isNotEmpty) {
      return '$artifactId-$version-$classifier.$extension';
    }
    return '$artifactId-$version.$extension';
  }

  String getRepositoryPath() {
    final groupPath = groupId.replaceAll('.', '/');
    final basePath = '$groupPath/$artifactId/$version/$artifactId-$version';

    if (classifier != null && classifier!.isNotEmpty) {
      return '$basePath-$classifier.$extension';
    }
    return '$basePath.$extension';
  }

  @override
  String toString() {
    if (classifier != null && classifier!.isNotEmpty) {
      return '$groupId:$artifactId:$version:$classifier:$extension';
    }
    return '$groupId:$artifactId:$version';
  }
}

class MavenRepoDownloader {
  static Future<File> downloadArtifact({
    required String mavenCoordinate,
    required String repoUrl,
    required Directory destinationDir,
    String? customFileName,
    bool forceDownload = false,
  }) async {
    try {
      final artifact = MavenArtifact.parse(mavenCoordinate);

      final groupPath = artifact.groupId.replaceAll('.', '/');

      final artifactDir = p.join(
        destinationDir.path,
        groupPath,
        artifact.artifactId,
        artifact.version,
      );

      final fileName = customFileName ?? artifact.getFileName();

      final filePath = p.join(artifactDir, fileName);
      final file = File(filePath);

      if (!forceDownload && await file.exists()) {
        debugPrint('ファイルが既に存在します: $filePath');
        return file;
      }

      final artifactPath = artifact.getRepositoryPath();
      final downloadUrl =
          '$repoUrl${repoUrl.endsWith('/') ? '' : '/'}$artifactPath';

      debugPrint('ダウンロード中: $downloadUrl -> $filePath');

      await Directory(artifactDir).create(recursive: true);

      final response = await http.get(Uri.parse(downloadUrl));

      if (response.statusCode != 200) {
        throw Exception('ファイルのダウンロードに失敗しました: ${response.statusCode}');
      }

      await file.writeAsBytes(response.bodyBytes);
      debugPrint('ダウンロード完了: $filePath');

      return file;
    } catch (e) {
      throw Exception('Mavenアーティファクトのダウンロードに失敗しました: $e');
    }
  }

  static Future<List<File>> downloadArtifacts({
    required List<String> artifacts,
    required String repoUrl,
    required Directory destinationDir,
    bool forceDownload = false,
  }) async {
    final List<File> downloadedFiles = [];

    for (final artifact in artifacts) {
      try {
        final file = await downloadArtifact(
          mavenCoordinate: artifact,
          repoUrl: repoUrl,
          destinationDir: destinationDir,
          forceDownload: forceDownload,
        );
        downloadedFiles.add(file);
      } catch (e) {
        debugPrint('アーティファクトのダウンロードに失敗しました: $artifact - $e');
      }
    }

    return downloadedFiles;
  }
}
