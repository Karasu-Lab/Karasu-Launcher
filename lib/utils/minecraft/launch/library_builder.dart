import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:karasu_launcher/models/launcher_profiles.dart';
import 'package:karasu_launcher/models/version_info.dart';
import 'package:karasu_launcher/models/mod_loader.dart';
import 'package:karasu_launcher/utils/file_utils.dart';
import 'package:path/path.dart' as p;
import 'package:pub_semver/pub_semver.dart';

/// ライブラリの引数を構築するためのクラス
class LibraryBuilder {
  /// ライブラリバージョンのマップ (ライブラリキー => (バージョン, パス))
  final Map<String, (String, String)> _libraryVersionMap = <String, (String, String)>{};
  
  /// コンストラクタ
  LibraryBuilder();

  /// 指定されたバージョン情報とバージョンIDに基づいてクラスパスを構築する
  Future<String> buildClasspath(
    VersionInfo versionInfo,
    String versionId,
  ) async {
    try {
      final appDir = await createAppDirectory();
      final librariesDir = p.join(appDir.path, 'libraries');
      final versionsDir = p.join(appDir.path, 'versions');
      final versionJarPath = p.join(versionsDir, versionId, '$versionId.jar');

      // ライブラリマップをクリア
      _libraryVersionMap.clear();

      // Minecraftクライアントを追加
      if (await File(versionJarPath).exists()) {
        _libraryVersionMap['minecraft:client'] = (versionId, versionJarPath);
      }

      // 有効なライブラリを追加
      if (versionInfo.libraries != null) {
        final validLibraries = _filterValidLibraries(versionInfo.libraries!);
        for (final library in validLibraries) {
          String? libraryPath;
          String? libraryVersion;
          String? libraryKey;

          if (library.downloads?.artifact != null) {
            final artifact = library.downloads!.artifact!;
            if (artifact.path != null) {
              libraryPath = p.join(librariesDir, artifact.path!);
              final nameParts = library.name?.split(':');
              if (nameParts != null && nameParts.length >= 3) {
                libraryKey = '${nameParts[0]}:${nameParts[1]}';
                libraryVersion = nameParts[2];
              }
            }
          } else if (library.name != null) {
            final parts = library.name!.split(':');
            if (parts.length >= 3) {
              final normalizedGroup =
                  parts[0].replaceAll('/', '.').toLowerCase();
              final artifact = parts[1];
              final version = parts[2];
              libraryKey = '$normalizedGroup:$artifact';
              libraryVersion = version;

              String fileName = '$artifact-$version.jar';
              if (parts.length > 3 && parts[3].isNotEmpty) {
                fileName = '$artifact-$version-${parts[3]}.jar';
              }

              final relativePath = p.join(
                parts[0].replaceAll('.', '/'),
                artifact,
                version,
                fileName,
              );
              libraryPath = p.join(librariesDir, relativePath);
            }
          }

          if (libraryPath != null &&
              libraryKey != null &&
              libraryVersion != null &&
              await File(libraryPath).exists()) {
            libraryPath = p.normalize(libraryPath);
            final existingEntry = _libraryVersionMap[libraryKey];

            if (existingEntry == null ||
                compareVersions(libraryVersion, existingEntry.$1) > 0) {
              if (existingEntry != null) {
                debugPrint(
                  'Upgrading library $libraryKey from ${existingEntry.$1} to $libraryVersion',
                );
              }
              _libraryVersionMap[libraryKey] = (libraryVersion, libraryPath);
            } else if (compareVersions(libraryVersion, existingEntry.$1) == 0 &&
                libraryPath != existingEntry.$2) {
              debugPrint(
                'Warning: Duplicate library version for $libraryKey: $libraryVersion. Using ${existingEntry.$2}',
              );
            }
          }
        }
      }
      
      final paths = _libraryVersionMap.values.map((e) => e.$2).toList();
      return buildFinalClasspathString(paths);
    } catch (e) {
      debugPrint('Error building classpath: $e');
      throw Exception('Failed to build classpath: $e');
    }
  }
  
  /// バージョンを比較する
  int compareVersions(String v1, String v2) {
    try {
      final cleanV1 = cleanVersionString(v1);
      final cleanV2 = cleanVersionString(v2);

      final semV1 = Version.parse(cleanV1);
      final semV2 = Version.parse(cleanV2);

      return semV1.compareTo(semV2);
    } catch (e) {
      debugPrint('SemVer parsing failed, using string comparison: $e');
      return v1.compareTo(v2);
    }
  }

  /// バージョン文字列をクリーンアップする
  String cleanVersionString(String version) {
    if (version.contains('-')) {
      final parts = version.split('-');
      return '${parts[0]}-${parts.sublist(1).join('.')}';
    }

    final versionParts = version.split('.');
    if (versionParts.length == 1) {
      return '$version.0.0';
    } else if (versionParts.length == 2) {
      return '$version.0';
    }

    return version;
  }
  
  /// 有効なライブラリをフィルタリングする
  List<Libraries> _filterValidLibraries(List<Libraries> libraries) {
    return libraries.where((lib) {
      if (lib.rules == null || lib.rules!.isEmpty) {
        return true;
      }
      bool shouldInclude = false;
      for (final rule in lib.rules!) {
        final action = rule.action;
        final os = rule.os;
        bool osMatch =
            os == null ||
            (os.name == Name.windows && Platform.isWindows) ||
            (os.name == Name.linux && Platform.isLinux) ||
            (os.name == Name.osx && Platform.isMacOS);

        if (osMatch) {
          shouldInclude = action == Action.allow;
        }
      }

      return shouldInclude;
    }).toList();
  }
  
  /// 最終的なクラスパス文字列を構築する
  String buildFinalClasspathString(List<String> paths) {
    final separator = Platform.isWindows ? ';' : ':';
    final validPaths = paths.where((path) => path.isNotEmpty).toList();
    final uniquePaths = validPaths.toSet().toList();

    // セパレータを含むパスをフィルタリング（ダブルクォートで保護されている場合を除く）
    final cleanPaths =
        uniquePaths.where((path) {
          // ダブルクォートで囲まれているパスは既に保護されているので許可
          if (path.startsWith('"') && path.endsWith('"')) {
            return true;
          }
          // セパレータを含まないパスのみ許可
          return !path.contains(separator);
        }).toList();

    // 最終的なパスリストを生成（空白を含むパスをダブルクォートで囲む）
    final finalPaths =
        cleanPaths.map((path) {
          // 既にダブルクォートで囲まれているパスはそのまま
          if (path.startsWith('"') && path.endsWith('"')) {
            return path;
          }
          // 空白を含むパスをダブルクォートで囲む
          if (path.contains(' ')) {
            return '"$path"';
          }
          return path;
        }).toList();
    
    if (finalPaths.length < paths.length) {
      debugPrint(
        'Warning: Filtered ${paths.length - finalPaths.length} invalid paths from classpath',
      );
      final excludedPaths =
          paths
              .where(
                (path) =>
                    !finalPaths.contains(path) &&
                    !finalPaths.contains('"$path"'),
              )
              .toList();
      if (excludedPaths.isNotEmpty) {
        debugPrint('Excluded paths: ${excludedPaths.join(', ')}');
      }
    }

    final result = finalPaths.join(separator);
    debugPrint('Final classpath contains ${finalPaths.length} entries');
    return result;
  }
  
  /// プロファイルからライブラリ引数を自動生成する
  Future<String> buildClasspathFromProfile(
    Profile profile,
    VersionInfo versionInfo,
  ) async {
    final versionId = profile.lastVersionId;
    if (versionId == null || versionId.isEmpty) {
      throw Exception('Profile does not have a valid version ID');
    }
    
    // プロファイル固有のカスタマイズがあれば適用する
    // 例: カスタムLibraryパスなど
    
    return await buildClasspath(versionInfo, versionId);
  }
  
  /// 追加のライブラリを追加する
  void addLibrary(String key, String version, String path) {
    if (path.isEmpty) return;
    
    final existingEntry = _libraryVersionMap[key];
    if (existingEntry == null || compareVersions(version, existingEntry.$1) > 0) {
      _libraryVersionMap[key] = (version, path);
      debugPrint('Added library $key ($version) to classpath: $path');
    }
  }
  
  /// MODローダー用のライブラリを追加する
  Future<void> addModLoaderLibraries(ModLoader modLoader, String librariesDirPath) async {
    if (modLoader.libraries == null || modLoader.libraries!.isEmpty) {
      return;
    }
    
    debugPrint('Adding ${modLoader.libraries!.length} mod loader libraries to classpath');
    
    for (final lib in modLoader.libraries!) {
      if (lib.containsKey('name')) {
        final name = lib['name'] as String;
        final parts = name.split(':');
        if (parts.length >= 3) {
          final groupId = parts[0];
          final artifactId = parts[1];
          final version = parts[2];
          final key = '$groupId:$artifactId';
          
          String classifier = '';
          if (parts.length > 3) {
            classifier = parts[3];
          }
          
          final fileName = classifier.isEmpty 
              ? '$artifactId-$version.jar' 
              : '$artifactId-$version-$classifier.jar';
          
          final groupPath = groupId.replaceAll('.', '/');
          final libPath = p.join(
            librariesDirPath,
            groupPath,
            artifactId,
            version,
            fileName,
          );
          
          if (await File(libPath).exists()) {
            addLibrary(key, version, libPath);
          }
        }
      }
    }
  }
  
  /// ライブラリバージョンマップを取得
  Map<String, (String, String)> getLibraryVersionMap() {
    return Map<String, (String, String)>.unmodifiable(_libraryVersionMap);
  }
  
  /// ライブラリバージョンマップをクリア
  void clearLibraryVersionMap() {
    _libraryVersionMap.clear();
  }
}
