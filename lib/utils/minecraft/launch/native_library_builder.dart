import 'dart:io';
import 'package:flutter/material.dart' hide Action;
import 'package:karasu_launcher/models/version_info.dart';
import 'package:karasu_launcher/utils/minecraft/constants.dart';
import 'package:path/path.dart' as p;
import '../../file_utils.dart';
import '../native_utils.dart' as native_utils;

/// ネイティブライブラリの構築を担当するクラス
class NativeLibraryBuilder {
  /// ネイティブライブラリを抽出して準備する
  Future<void> extractNativeLibraries(
    VersionInfo versionInfo,
    String versionId,
    String nativeDestDir, {
    ProgressCallback? onProgress,
  }) async {
    debugPrint('NativeLibraryBuilder: ネイティブライブラリの抽出を開始します...');

    if (versionInfo.libraries == null) {
      debugPrint('ライブラリ情報がありません');
      if (onProgress != null) {
        onProgress(1.0, 1, 1);
      }
      return;
    }

    // ネイティブディレクトリを確保
    final nativesDir = p.normalize(nativeDestDir);
    await Directory(nativesDir).create(recursive: true);

    // 一時ディレクトリの作成
    final appDir = await createAppDirectory();
    final tempDir = p.normalize(
      p.join(
        appDir.path,
        'temp',
        'natives-${DateTime.now().millisecondsSinceEpoch}',
      ),
    );
    await Directory(tempDir).create(recursive: true);

    try {
      // ネイティブライブラリをフィルタリング
      final nativeLibraries = _filterNativeLibraries(versionInfo.libraries!);

      // ネイティブライブラリがない場合は早期リターン
      if (nativeLibraries.isEmpty) {
        debugPrint('抽出するネイティブライブラリがありません');
        if (onProgress != null) {
          onProgress(1.0, 1, 1);
        }
        return;
      }

      final librariesDir = p.join(appDir.path, 'libraries');
      int processed = 0;
      final total = nativeLibraries.length;

      // 初期進捗を報告
      if (onProgress != null) {
        onProgress(0.0, 0, total);
      }

      for (final lib in nativeLibraries) {
        await _extractNativeLibrary(lib, librariesDir, tempDir, nativesDir);

        processed++;
        // 各ライブラリの処理完了時に進捗を報告
        if (onProgress != null) {
          final progress = total > 0 ? processed / total : 1.0;
          onProgress(progress, processed, total);
        }
      }

      debugPrint('ネイティブライブラリの抽出が完了しました');
    } catch (e) {
      debugPrint('ネイティブライブラリの抽出中にエラーが発生しました: $e');
    } finally {
      try {
        await Directory(tempDir).delete(recursive: true);
      } catch (e) {
        debugPrint('一時ディレクトリの削除に失敗しました: $e');
      }

      // 完了時に100%の進捗を報告
      if (onProgress != null) {
        onProgress(
          1.0,
          versionInfo.libraries!.length,
          versionInfo.libraries!.length,
        );
      }
    }
  }

  /// ネイティブライブラリをフィルタリングする
  List<Libraries> _filterNativeLibraries(List<Libraries> libraries) {
    final nativeLibraries = <Libraries>[];

    for (final lib in libraries) {
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

    return nativeLibraries;
  }

  /// 個別のネイティブライブラリを抽出する
  Future<void> _extractNativeLibrary(
    Libraries lib,
    String librariesDir,
    String tempDir,
    String nativesDir,
  ) async {
    final libParts = lib.name!.split(':');
    if (libParts.length < 3) {
      debugPrint('ライブラリ名が無効です: ${lib.name}');
      return;
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
      debugPrint('サポートされていないプラットフォームです');
      return;
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
      debugPrint('ネイティブライブラリが見つかりません: \n$nativeJarPath\nまたは\n$fallbackJarPath');
      return;
    }

    final jarFileToUse =
        await nativeJarFile.exists() ? nativeJarFile : fallbackJarFile;
    debugPrint('ネイティブライブラリを抽出: ${jarFileToUse.path}');

    final tempJarDir = p.join(
      tempDir,
      p.basenameWithoutExtension(jarFileToUse.path),
    );

    await native_utils.extractJar(jarFileToUse.path, tempJarDir);

    // 既存のファイルが存在する場合はスキップするオプションを追加
    await native_utils.copyNativeFiles(
      tempJarDir,
      nativesDir,
      skipExisting: true,
    );
  }

  /// JavaのSystemプロパティ用のネイティブライブラリパスを構築する
  String buildNativeLibraryPath(String nativesDir) {
    // nativesDirのみを返す（追加のパスなし）
    return nativesDir;
  }
}
