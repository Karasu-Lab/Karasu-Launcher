import 'dart:io';
import 'package:flutter/material.dart' hide Action;
import 'package:karasu_launcher/models/version_info.dart';
import 'package:path/path.dart' as p;
import '../file_utils.dart';
import 'constants.dart';

/// ネイティブライブラリを抽出する
Future<void> extractNativeLibraries(
  VersionInfo versionInfo,
  String nativesDir, {
  ProgressCallback? onProgress,
}) async {
  debugPrint('Starting extraction of native libraries...');

  if (versionInfo.libraries == null) {
    debugPrint('No library information available');
    // Report 100% completion even if there's no information
    if (onProgress != null) {
      onProgress(1.0, 1, 1);
    }
    return;
  }

  final appDir = await createAppDirectory();
  final librariesDir = p.normalize(p.join(appDir.path, 'libraries'));
  final tempDir = p.normalize(
    p.join(
      appDir.path,
      'temp',
      'natives-${DateTime.now().millisecondsSinceEpoch}',
    ),
  );
  nativesDir = p.normalize(nativesDir);

  await Directory(tempDir).create(recursive: true);

  // ネイティブライブラリをフィルタリング
  final nativeLibraries = <Libraries>[];
  for (final lib in versionInfo.libraries!) {
    if (lib.name == null) continue;
    final String libName = lib.name!.toLowerCase();
    final bool isNativeLib =
        libName.contains('lwjgl') ||
        libName.contains('jinput') ||
        libName.contains('glfw') ||
        libName.contains('jemalloc') ||
        libName.contains('openal') ||
        (libName.contains('natives') && !libName.contains('natives-maven'));

    if (!isNativeLib) continue;

    bool shouldExtract = true;
    if (lib.rules != null) {
      shouldExtract = false;
      for (final rule in lib.rules!) {
        final bool osMatch =
            rule.os == null ||
            (Platform.isWindows && rule.os!.name == Name.windows) ||
            (Platform.isLinux && rule.os!.name == Name.linux) ||
            (Platform.isMacOS && rule.os!.name == Name.osx);

        if (osMatch) {
          shouldExtract = rule.action == Action.allow;
        }
      }
    }

    if (shouldExtract) {
      nativeLibraries.add(lib);
    }
  }

  // ネイティブライブラリがない場合は早期リターン
  if (nativeLibraries.isEmpty) {
    debugPrint('No native libraries to extract');
    if (onProgress != null) {
      onProgress(1.0, 1, 1);
    }
    return;
  }

  try {
    int processed = 0;
    final total = nativeLibraries.length;

    // 初期進捗を報告
    if (onProgress != null) {
      onProgress(0.0, 0, total);
    }

    for (final lib in nativeLibraries) {
      final libParts = lib.name!.split(':');
      if (libParts.length < 3) {
        processed++;
        if (onProgress != null) {
          onProgress(processed / total, processed, total);
        }
        continue;
      }

      final String group = libParts[0].replaceAll('.', '/');
      final String artifact = libParts[1];
      final String version = libParts[2];

      String nativeSuffix;
      if (Platform.isWindows) {
        nativeSuffix = 'natives-windows';
      } else if (Platform.isLinux) {
        nativeSuffix = 'natives-linux';
      } else if (Platform.isMacOS) {
        nativeSuffix = 'natives-osx';
      } else {
        processed++;
        if (onProgress != null) {
          onProgress(processed / total, processed, total);
        }
        continue;
      }

      final nativeJarPath = p.join(
        librariesDir,
        group,
        artifact,
        version,
        '$artifact-$version-$nativeSuffix.jar',
      );

      final fallbackJarPath = p.join(
        librariesDir,
        group,
        artifact,
        version,
        '$artifact-$version.jar',
      );

      final nativeJarFile = File(nativeJarPath);
      final fallbackJarFile = File(fallbackJarPath);

      if (!await nativeJarFile.exists() && !await fallbackJarFile.exists()) {
        debugPrint(
          'Native library not found at: \n$nativeJarPath\nor\n$fallbackJarPath',
        );
        processed++;
        if (onProgress != null) {
          onProgress(processed / total, processed, total);
        }
        continue;
      }

      final jarFileToUse =
          await nativeJarFile.exists() ? nativeJarFile : fallbackJarFile;
      debugPrint('Extracting native library: ${jarFileToUse.path}');

      final tempJarDir = p.join(
        tempDir,
        p.basenameWithoutExtension(jarFileToUse.path),
      );
      await extractJar(jarFileToUse.path, tempJarDir);

      await copyNativeFiles(tempJarDir, nativesDir);

      processed++;
      // 各ライブラリの処理完了時に正確な進捗を報告
      if (onProgress != null) {
        // 進捗が1.0を超えないようにする
        final progress = total > 0 ? processed / total : 1.0;
        onProgress(progress, processed, total);
      }
    }

    debugPrint('Native library extraction completed');
  } catch (e) {
    debugPrint('Error occurred during native library extraction: $e');
  } finally {
    try {
      await Directory(tempDir).delete(recursive: true);
    } catch (e) {
      debugPrint('Failed to delete temporary directory: $e');
    }

    // 完了時に確実に100%の進捗を報告
    if (onProgress != null) {
      onProgress(1.0, nativeLibraries.length, nativeLibraries.length);
    }
  }
}

/// JARファイルを展開する
Future<void> extractJar(String jarPath, String targetDir) async {
  try {
    await Directory(targetDir).create(recursive: true);

    try {
      final result = await Process.run('jar', [
        'xf',
        jarPath,
      ], workingDirectory: targetDir);

      if (result.exitCode == 0) {
        return;
      }
    } catch (e) {
      debugPrint('Failed to extract using jar command: $e');
    }

    try {
      final zipProcess = await Process.run(
        Platform.isWindows ? 'powershell' : 'unzip',
        Platform.isWindows
            ? [
              '-Command',
              "Expand-Archive -Path '$jarPath' -DestinationPath '$targetDir' -Force",
            ]
            : ['-o', jarPath, '-d', targetDir],
      );

      if (zipProcess.exitCode == 0) {
        return;
      }
    } catch (e) {
      debugPrint('Failed to extract as ZIP: $e');
    }

    debugPrint(
      'Warning: Failed to extract JAR file - additional libraries may be required',
    );
  } catch (e) {
    debugPrint('Failed to extract JAR file: $e');
  }
}

/// ネイティブファイルをコピーする
Future<void> copyNativeFiles(String sourceDir, String targetDir) async {
  try {
    final sourceDirectory = Directory(sourceDir);
    if (!await sourceDirectory.exists()) return;

    final entities = await sourceDirectory.list(recursive: true).toList();

    for (final entity in entities) {
      if (entity is File) {
        final relativePath = p.relative(entity.path, from: sourceDir);
        if (relativePath.endsWith('.dll') ||
            relativePath.endsWith('.so') ||
            relativePath.endsWith('.dylib')) {
          final targetPath = p.join(targetDir, p.basename(entity.path));
          if (!await File(targetPath).exists()) {
            await entity.copy(targetPath);
          }
        }
      }
    }
  } catch (e) {
    debugPrint('Failed to copy native files: $e');
  }
}
