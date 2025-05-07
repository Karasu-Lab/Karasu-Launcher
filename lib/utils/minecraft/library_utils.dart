import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart' hide Action;
import 'package:karasu_launcher/models/mod_loader.dart';
import 'package:karasu_launcher/models/version_info.dart';
import 'package:karasu_launcher/utils/maven_repo_downloader.dart';
import 'package:path/path.dart' as p;
import 'package:pub_semver/pub_semver.dart';
import '../file_utils.dart';
import 'constants.dart';
import 'download_utils.dart';
import 'version_utils.dart';

/// ライブラリをダウンロードする
Future<File?> downloadLibrary(Libraries library, Directory librariesDir) async {
  if (library.name == null) {
    debugPrint('ライブラリ名が指定されていません');
    return null;
  }

  // Maven URLが指定されている場合
  final String? mavenUrl = library.url;
  if (mavenUrl != null && mavenUrl.isNotEmpty) {
    try {
      final repoUrl = mavenUrl.endsWith('/') ? mavenUrl : '$mavenUrl/';

      debugPrint('Mavenリポジトリからライブラリをダウンロードします: ${library.name} ($repoUrl)');

      return await MavenRepoDownloader.downloadArtifact(
        mavenCoordinate: library.name!,
        repoUrl: repoUrl,
        destinationDir: librariesDir,
      );
    } catch (e) {
      debugPrint('Mavenリポジトリからのダウンロードに失敗しました: ${library.name} - $e');
    }
  }

  // 従来の方法でダウンロード（downloads.artifactを使用）
  if (library.downloads?.artifact == null ||
      library.downloads!.artifact!.url == null ||
      library.downloads!.artifact!.path == null) {
    debugPrint('ライブラリ ${library.name} にアーティファクト情報がありません');
    return null;
  }

  final path = library.downloads!.artifact!.path!;
  final libraryPath = p.join(librariesDir.path, path);

  try {
    return await downloadFile(
      library.downloads!.artifact!.url!,
      libraryPath,
      expectedSize: library.downloads!.artifact!.size,
    );
  } catch (e) {
    debugPrint('Failed to download library ${library.name}: $e');
    return null;
  }
}

/// Fabricモッド用の追加ライブラリをダウンロード
Future<void> _downloadFabricLibraries(
  ModLoader modLoader,
  Directory librariesDir,
) async {
  try {
    const FABRIC_MAVEN_URL = 'https://maven.fabricmc.net';

    // Fabricの基本ライブラリ（常に必要なもの）を定義
    final baseLibraries = [
      'net.fabricmc:fabric-loader:${modLoader.version}',
      'net.fabricmc:intermediary:${modLoader.baseGameVersion}',
    ];

    debugPrint('Fabricの基本ライブラリをダウンロードします');
    await MavenRepoDownloader.downloadArtifacts(
      artifacts: baseLibraries,
      repoUrl: FABRIC_MAVEN_URL,
      destinationDir: librariesDir,
    );
  } catch (e) {
    debugPrint('Fabricライブラリのダウンロードに失敗しました: $e');
  }
}

/// Minecraftのライブラリをダウンロードする
Future<void> downloadMinecraftLibraries(
  String versionId, {
  ProgressCallback? onProgress,
}) async {
  try {
    final appDir = await createAppDirectory();
    final librariesDir = await createSubDirectory(appDir, 'libraries');

    final versionInfo = await fetchVersionInfo(versionId);

    if (versionInfo.libraries == null || versionInfo.libraries!.isEmpty) {
      debugPrint('No libraries for this version: $versionId');
      return;
    }

    // MODローダーを検出
    ModLoader? modLoader;
    if (versionInfo.id != null) {
      final versionJsonPath = await getVersionJsonPath(versionId);
      final jsonFile = File(versionJsonPath);

      if (await jsonFile.exists()) {
        final content = await jsonFile.readAsString();
        final jsonData = json.decode(content) as Map<String, dynamic>;
        modLoader = ModLoader.fromJsonContent(jsonData, versionId);
      }
    }

    // Fabricモッドの場合、追加のライブラリをダウンロード
    if (modLoader?.type == ModLoaderType.fabric) {
      debugPrint('Fabricモッドローダーを検出しました: ${modLoader?.version}');
      await _downloadFabricLibraries(modLoader!, librariesDir[0]);
    } else if (modLoader?.type == ModLoaderType.forge) {
      debugPrint('Forgeモッドローダーを検出しました: ${modLoader?.version}');
      // Forgeの場合、追加の処理が必要ならここに実装
    }

    int totalSize = 0;
    for (final library in versionInfo.libraries!) {
      if (library.downloads?.artifact?.size != null) {
        totalSize += library.downloads!.artifact!.size!;
      }
    }

    int downloaded = 0;
    int downloadedSize = 0;
    final totalLibraries = versionInfo.libraries!.length;

    debugPrint(
      'Library download starting: $totalLibraries total (Total: ${(totalSize / 1024 / 1024).toStringAsFixed(2)}MB)',
    );

    for (final library in versionInfo.libraries!) {
      try {
        final file = await downloadLibrary(library, librariesDir[0]);
        downloaded++;

        if (file != null && library.downloads?.artifact?.size != null) {
          downloadedSize += library.downloads!.artifact!.size!;
        }

        final currentPercentage =
            totalSize > 0 ? (downloadedSize * 100 / totalSize) : 100.0;

        if (onProgress != null) {
          onProgress(
            totalSize > 0 ? downloadedSize / totalSize : 1.0,
            downloaded,
            totalLibraries,
          );
        }

        if (downloaded % 5 == 0 ||
            (totalSize > 0 &&
                currentPercentage.floor() >
                    ((downloadedSize -
                                (library.downloads?.artifact?.size ?? 0)) *
                            100 /
                            totalSize)
                        .floor())) {}
      } catch (e) {
        debugPrint('Failed to process library download ${library.name}: $e');
      }
    }

    final percentage =
        totalSize > 0
            ? (downloadedSize * 100 / totalSize).toStringAsFixed(1)
            : "100.0";
    debugPrint(
      'Library download complete: $downloaded / $totalLibraries items ($percentage%)',
    );
  } catch (e) {
    throw Exception('Failed to download Minecraft libraries: $e');
  }
}

/// ライブラリ情報を保持するクラス
class _LibraryInfo {
  final String groupId;
  final String artifactId;
  final String version;
  final String path;

  _LibraryInfo({
    required this.groupId,
    required this.artifactId,
    required this.version,
    required this.path,
  });
}

/// ライブラリを管理するためのマップ型
typedef _LibraryMap = Map<String, _LibraryInfo>;

/// ライブラリマップに追加（バージョン比較して重複を処理）
void _addToLibraryMap(
  _LibraryMap libraryMap,
  MavenArtifact artifact,
  String path,
) {
  final key = '${artifact.groupId}:${artifact.artifactId}';

  // 既に同じライブラリが存在する場合、バージョンを比較
  if (libraryMap.containsKey(key)) {
    final existingVersion = libraryMap[key]!.version;
    final newVersion = artifact.version;

    // シンプルなバージョン比較（セマンティックバージョニングの完全な比較は複雑なため、簡易的に実装）
    if (_compareVersions(newVersion, existingVersion) > 0) {
      // 新しいバージョンの方が大きい場合、更新
      debugPrint('ライブラリのバージョンを更新: $key $existingVersion -> $newVersion');
      libraryMap[key] = _LibraryInfo(
        groupId: artifact.groupId,
        artifactId: artifact.artifactId,
        version: artifact.version,
        path: path,
      );
    }
  } else {
    // 新しいライブラリの追加
    libraryMap[key] = _LibraryInfo(
      groupId: artifact.groupId,
      artifactId: artifact.artifactId,
      version: artifact.version,
      path: path,
    );
  }
}

/// バージョン文字列を比較する関数
int _compareVersions(String a, String b) {
  try {
    final versionA = Version.parse(a);
    final versionB = Version.parse(b);

    return versionA.compareTo(versionB);
  } catch (e) {
    return a.compareTo(b);
  }
}

/// MODローダー固有の追加ライブラリをクラスパスに追加
Future<void> _addModLoaderLibraries(
  ModLoader modLoader,
  List<String> libraries,
  _LibraryMap libraryMap,
  Directory appDir,
) async {
  final librariesDir = p.join(appDir.path, 'libraries');

  if (modLoader.type == ModLoaderType.fabric) {
    // Fabric特有のライブラリパスを追加
    final fabricLoaderPath = p.join(
      librariesDir,
      'net',
      'fabricmc',
      'fabric-loader',
      modLoader.version,
      'fabric-loader-${modLoader.version}.jar',
    );

    final intermediaryPath = p.join(
      librariesDir,
      'net',
      'fabricmc',
      'intermediary',
      modLoader.baseGameVersion,
      'intermediary-${modLoader.baseGameVersion}.jar',
    );

    if (await File(fabricLoaderPath).exists()) {
      _addToLibraryMap(
        libraryMap,
        MavenArtifact(
          groupId: 'net.fabricmc',
          artifactId: 'fabric-loader',
          version: modLoader.version,
        ),
        fabricLoaderPath,
      );
    }

    if (await File(intermediaryPath).exists()) {
      _addToLibraryMap(
        libraryMap,
        MavenArtifact(
          groupId: 'net.fabricmc',
          artifactId: 'intermediary',
          version: modLoader.baseGameVersion,
        ),
        intermediaryPath,
      );
    }

    // modsフォルダ内のJARファイルもクラスパスに追加
    try {
      final modsDir = Directory(p.join(appDir.path, 'mods'));
      if (await modsDir.exists()) {
        final modFiles =
            await modsDir
                .list()
                .where(
                  (entity) =>
                      entity is File &&
                      entity.path.toLowerCase().endsWith('.jar'),
                )
                .toList();

        for (final modFile in modFiles) {
          libraries.add(modFile.path);
        }
      }
    } catch (e) {
      debugPrint('modsフォルダの処理中にエラーが発生しました: $e');
    }
  } else if (modLoader.type == ModLoaderType.forge) {
    // Forge特有のライブラリパスを追加（必要に応じて実装）
  }
}

/// クラスパスを構築する
Future<String> buildClasspath(VersionInfo versionInfo, String versionId) async {
  try {
    final appDir = await createAppDirectory();
    final libraryPaths = <String>[]; // Setではなくリストを使用
    final clientJarPath = await getClientJarPath(versionId);
    libraryPaths.add(clientJarPath);

    // MODローダー情報を取得
    ModLoader? modLoader;
    final versionJsonPath = await getVersionJsonPath(versionId);
    final jsonFile = File(versionJsonPath);

    if (await jsonFile.exists()) {
      final content = await jsonFile.readAsString();
      final jsonData = json.decode(content) as Map<String, dynamic>;
      modLoader = ModLoader.fromJsonContent(jsonData, versionId);
    }

    // ライブラリ情報を収集（重複を適切に処理するためにマップを使用）
    final libraryMap = <String, _LibraryInfo>{};

    if (versionInfo.libraries != null) {
      final librariesDir = p.join(appDir.path, 'libraries');

      for (final lib in versionInfo.libraries!) {
        // OS固有のルールをチェック
        if (lib.rules != null) {
          bool allow = false;
          for (final rule in lib.rules!) {
            if ((rule.os == null ||
                (Platform.isWindows && rule.os!.name == Name.windows) ||
                (Platform.isLinux && rule.os!.name == Name.linux) ||
                (Platform.isMacOS && rule.os!.name == Name.osx))) {
              allow = rule.action == Action.allow;
            }
          }
          if (!allow) continue;
        }

        // Maven URLが指定されている場合のライブラリパス処理
        if (lib.name != null) {
          try {
            final artifact = MavenArtifact.parse(lib.name!);
            final fileName = artifact.getFileName();
            final groupPath = artifact.groupId.replaceAll('.', '/');

            // Maven座標に基づいた適切なパスを構築
            final libPath = p.join(
              librariesDir,
              groupPath,
              artifact.artifactId,
              artifact.version,
              fileName,
            );

            if (await File(libPath).exists()) {
              _addToLibraryMap(libraryMap, artifact, libPath);
              continue;
            }
          } catch (e) {
            debugPrint('Mavenライブラリパスの解析に失敗しました: ${lib.name} - $e');
          }
        }

        // 通常のダウンロード処理によるライブラリパス
        if (lib.downloads?.artifact != null &&
            lib.downloads!.artifact!.path != null) {
          final libPath = p.join(librariesDir, lib.downloads!.artifact!.path!);
          if (await File(libPath).exists()) {
            final pathParts = libPath.split(p.separator);
            // パスからMaven情報を抽出
            if (pathParts.length >= 4) {
              final artifactId = pathParts[pathParts.length - 3];
              final version = pathParts[pathParts.length - 2];

              // groupIdを推測
              final groupPath = pathParts
                  .sublist(
                    pathParts.indexOf('libraries') + 1,
                    pathParts.length - 3,
                  )
                  .join('.');

              try {
                final artifact = MavenArtifact(
                  groupId: groupPath,
                  artifactId: artifactId,
                  version: version,
                );
                _addToLibraryMap(libraryMap, artifact, libPath);
              } catch (e) {
                libraryPaths.add(libPath); // 解析できない場合はそのまま追加
              }
            } else {
              libraryPaths.add(libPath);
            }
          } else {
            debugPrint('ライブラリファイルが見つかりません: $libPath');
          }
        }
      }
    }

    // MODローダー固有の追加ライブラリを追加
    if (modLoader != null) {
      await _addModLoaderLibraries(modLoader, libraryPaths, libraryMap, appDir);
    }

    // 重複のないライブラリマップから最終的なパスリストを作成
    libraryPaths.addAll(libraryMap.values.map((info) => info.path));

    final pathSeparator = Platform.isWindows ? ';' : ':';
    return libraryPaths.join(pathSeparator);
  } catch (e) {
    throw Exception('クラスパスの構築に失敗しました: $e');
  }
}
