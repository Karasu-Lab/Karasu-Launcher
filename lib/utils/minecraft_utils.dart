import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart' hide Action;
import 'package:http/http.dart' as http;
import 'package:karasu_launcher/models/auth/account.dart';
import 'package:karasu_launcher/models/launcher_profiles.dart';
import 'package:karasu_launcher/models/minecraft_state.dart'; // LogSourceを使用するためにインポート
import 'package:path/path.dart' as p;

import '../models/launcher_versions_v2.dart';
import '../models/version_info.dart';
import '../models/assets_indexes.dart';
import '../utils/file_utils.dart';

const String MINECRAFT_VERSION_MANIFEST_URL =
    'https://piston-meta.mojang.com/mc/game/version_manifest_v2.json';
const String MINECRAFT_RESOURCES_URL =
    'https://resources.download.minecraft.net';

typedef ProgressCallback =
    void Function(double progress, int current, int total);
typedef PrepareCompleteCallback = void Function();
typedef MinecraftExitCallback =
    void Function(
      int? exitCode,
      bool normal,
      String? userId,
      String? profileId,
    );
typedef MinecraftOutputCallback =
    void Function(String output, LogSource source);
typedef LaunchMinecraftCallback = void Function();

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

Future<LauncherVersionsV2> fetchVersionManifest() async {
  try {
    final response = await http.get(Uri.parse(MINECRAFT_VERSION_MANIFEST_URL));

    if (response.statusCode != 200) {
      throw Exception('Failed to get version manifest: ${response.statusCode}');
    }

    return LauncherVersionsV2.fromJson(json.decode(response.body));
  } catch (e) {
    throw Exception('Failed to parse version manifest: $e');
  }
}

Future<String> getVersionJsonPath(String versionId) async {
  final appDir = await createAppDirectory();
  final versionsDir = await createSubDirectory(appDir, 'versions');
  final versionDir = await createSubDirectory(versionsDir[0], versionId);
  return p.join(versionDir[0].path, '$versionId.json');
}

Future<String> getClientJarPath(String versionId) async {
  final appDir = await createAppDirectory();
  final versionsDir = await createSubDirectory(appDir, 'versions');
  final versionDir = await createSubDirectory(versionsDir[0], versionId);
  return p.join(versionDir[0].path, '$versionId.jar');
}

Future<VersionInfo> fetchVersionInfo(String versionId) async {
  final jsonPath = await getVersionJsonPath(versionId);
  final jsonFile = File(jsonPath);

  if (await jsonFile.exists()) {
    try {
      final cachedContent = await jsonFile.readAsString();
      return VersionInfo.fromJson(json.decode(cachedContent));
    } catch (e) {
      debugPrint('バージョン情報キャッシュからの読み込みに失敗しました: $e');
    }
  }

  final manifest = await fetchVersionManifest();

  final version = manifest.versions.firstWhere(
    (v) => v.id == versionId,
    orElse: () => throw Exception('指定されたバージョン $versionId が見つかりません'),
  );

  try {
    final file = await downloadFile(version.url, jsonPath);
    final content = await file.readAsString();
    return VersionInfo.fromJson(json.decode(content));
  } catch (e) {
    throw Exception('バージョン情報のパースに失敗しました: $e');
  }
}

Future<File> downloadClientJar(VersionInfo versionInfo) async {
  if (versionInfo.downloads?.client == null ||
      versionInfo.downloads!.client!.url == null) {
    throw Exception('クライアントJARのURLが見つかりません');
  }

  final versionId = versionInfo.id ?? 'unknown';
  final clientJarPath = await getClientJarPath(versionId);

  return await downloadFile(
    versionInfo.downloads!.client!.url!,
    clientJarPath,
    expectedSize: versionInfo.downloads!.client!.size,
  );
}

Future<void> downloadMinecraftClient(String versionId) async {
  try {
    final versionInfo = await fetchVersionInfo(versionId);

    final clientJarFile = await downloadClientJar(versionInfo);

    debugPrint('Client download completed: ${clientJarFile.path}');
  } catch (e) {
    throw Exception('Failed to download Minecraft client: $e');
  }
}

Future<void> downloadMinecraftComplete(String versionId) async {
  try {
    await downloadMinecraftClient(versionId);
    await downloadMinecraftAssets(versionId);
    await downloadMinecraftLibraries(versionId);

    debugPrint('Complete download of Minecraft version $versionId finished');
  } catch (e) {
    throw Exception('Failed to complete Minecraft download: $e');
  }
}

Future<AssetsIndexes> fetchAssetIndex(VersionInfo versionInfo) async {
  if (versionInfo.assetIndex == null || versionInfo.assetIndex!.url == null) {
    throw Exception('アセットインデックスのURLが見つかりません');
  }

  final appDir = await createAppDirectory();
  final indexesDir = await createSubDirectory(appDir, 'assets');
  final indexesSubDir = await createSubDirectory(indexesDir[0], 'indexes');

  final indexId = versionInfo.assetIndex!.id ?? versionInfo.id ?? 'unknown';
  final indexFile = File(p.join(indexesSubDir[0].path, '$indexId.json'));

  final file = await downloadFile(
    versionInfo.assetIndex!.url!,
    indexFile.path,
    expectedSize: versionInfo.assetIndex!.size,
  );

  final content = await file.readAsString();
  return AssetsIndexes.fromJson(json.decode(content));
}

Future<File> downloadAsset(String hash, Directory assetsObjectsDir) async {
  final prefix = hash.substring(0, 2);
  final assetUrl = '$MINECRAFT_RESOURCES_URL/$prefix/$hash';

  final assetDir = await createSubDirectory(assetsObjectsDir, prefix);
  final assetFile = File(p.join(assetDir[0].path, hash));

  return await downloadFile(assetUrl, assetFile.path);
}

Future<void> downloadMinecraftAssets(
  String versionId, {
  ProgressCallback? onProgress,
}) async {
  try {
    final appDir = await createAppDirectory();

    final assetsDir = await createSubDirectory(appDir, 'assets');
    final assetsObjectsDir = await createSubDirectory(assetsDir[0], 'objects');
    await createSubDirectory(assetsDir[0], 'indexes');

    final versionInfo = await fetchVersionInfo(versionId);

    final assetIndex = await fetchAssetIndex(versionInfo);

    int totalSize = 0;
    for (final entry in assetIndex.objects.entries) {
      totalSize += entry.value.size;
    }

    int downloaded = 0;
    int downloadedSize = 0;
    final totalAssets = assetIndex.objects.length;

    debugPrint(
      'Starting download: $totalAssets assets (Total: ${(totalSize / 1024 / 1024).toStringAsFixed(2)}MB)',
    );

    for (final entry in assetIndex.objects.entries) {
      final assetObj = entry.value;
      try {
        await downloadAsset(assetObj.hash, assetsObjectsDir[0]);
        downloaded++;
        downloadedSize += assetObj.size;

        final currentPercentage = (downloadedSize * 100 / totalSize);

        if (onProgress != null) {
          onProgress(downloadedSize / totalSize, downloaded, totalAssets);
        }

        if (downloaded % 10 == 0 ||
            (currentPercentage.floor() >
                ((downloadedSize - assetObj.size) * 100 / totalSize)
                    .floor())) {}
      } catch (e) {
        debugPrint('Failed to download asset ${entry.key}: $e');
      }
    }

    final percentage = (downloadedSize * 100 / totalSize).toStringAsFixed(1);
    debugPrint('Download complete: $downloaded / $totalAssets assets ($percentage%)');
  } catch (e) {
    throw Exception('Failed to download Minecraft assets: $e');
  }
}

Future<File?> downloadLibrary(Libraries library, Directory librariesDir) async {
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
    debugPrint('Library download complete: $downloaded / $totalLibraries items ($percentage%)');
  } catch (e) {
    throw Exception('Failed to download Minecraft libraries: $e');
  }
}

Future<void> downloadRequiredMinecraftFiles(
  String versionId, {
  ProgressCallback? onAssetsProgress,
  ProgressCallback? onLibrariesProgress,
  ProgressCallback? onNativesProgress,
}) async {
  try {
    await downloadMinecraftClient(versionId);
    await downloadMinecraftAssets(versionId, onProgress: onAssetsProgress);
    await downloadMinecraftLibraries(
      versionId,
      onProgress: onLibrariesProgress,
    );

    final versionInfo = await fetchVersionInfo(versionId);
    final appDir = await createAppDirectory();
    final nativeDir = p.join(appDir.path, 'natives', versionId);
    await Directory(nativeDir).create(recursive: true);
    await extractNativeLibraries(
      versionInfo,
      nativeDir,
      onProgress: onNativesProgress,
    );

    debugPrint('Download of required files for Minecraft version $versionId completed');
  } catch (e) {
    throw Exception('Failed to download Minecraft files: $e');
  }
}

Future<Process> launchMinecraft(
  Profile profile, {
  ProgressCallback? onAssetsProgress,
  ProgressCallback? onLibrariesProgress,
  ProgressCallback? onNativesProgress,
  PrepareCompleteCallback? onPrepareComplete,
  MinecraftExitCallback? onExit,
  MinecraftOutputCallback? onStdout,
  MinecraftOutputCallback? onStderr,
  LaunchMinecraftCallback? onMinecraftLaunch,
  Account? account,
  String? offlinePlayerName,
}) async {
  try {
    final versionId = profile.lastVersionId;
    if (versionId == null || versionId.isEmpty) {
      throw Exception('No version ID specified in profile');
    }

    final gameDir =
        profile.gameDir != null && profile.gameDir!.isNotEmpty
            ? Directory(profile.gameDir!)
            : await createAppDirectory();

    debugPrint('Launching Minecraft version $versionId...');

    await downloadRequiredMinecraftFiles(
      versionId,
      onAssetsProgress: onAssetsProgress,
      onLibrariesProgress: onLibrariesProgress,
      onNativesProgress: onNativesProgress,
    );

    final versionInfo = await fetchVersionInfo(versionId);
    final classpath = await buildClasspath(versionInfo, versionId);
    final appDir = await createAppDirectory();
    final nativeDir = p.join(appDir.path, 'natives', versionId);

    final jvmArgs = await constructJvmArguments(
      versionInfo: versionInfo,
      nativeDir: nativeDir,
      classpath: classpath,
      appDir: appDir.path,
      gameDir: gameDir.path,
    );

    final finalJvmArgs = List<String>.from(jvmArgs);
    if (profile.javaArgs != null && profile.javaArgs!.isNotEmpty) {
      final customArgs = profile.javaArgs!.split(' ');
      for (final arg in customArgs) {
        if (arg.startsWith('-X') ||
            arg.startsWith('-D') ||
            arg.startsWith('-XX')) {
          final option = arg.split('=')[0];
          finalJvmArgs.removeWhere(
            (a) => a.startsWith('$option=') || a == option,
          );
          finalJvmArgs.add(arg);
        }
      }
    }
    final mainClass = versionInfo.mainClass;
    if (mainClass == null || mainClass.isEmpty) {
      throw Exception('No mainClass specified in version info');
    }

    final gameArgs = await constructGameArgumentsWithAuth(
      versionInfo: versionInfo,
      appDir: appDir.path,
      gameDir: gameDir.path,
      versionId: versionId,
      account: account,
      offlinePlayerName: offlinePlayerName,
    );

    final javaPath = await findJavaPath(profile);
    final command = [...finalJvmArgs, mainClass, ...gameArgs];

    debugPrint('Java path: $javaPath');
    debugPrint('Game directory: ${gameDir.path}');
    debugPrint('Launch command: $javaPath ${command.join(' ')}');

    if (onPrepareComplete != null) {
      onPrepareComplete();
    }

    final process = await Process.start(
      javaPath,
      command,
      workingDirectory: gameDir.path,
    );

    process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(
          (data) {
            debugPrint('[Minecraft] $data');
            if (onStdout != null) {
              onStdout(data, LogSource.javaStdOut);
            }
          },
          onError: (error) {
            debugPrint('[Minecraft] Error processing standard output: $error');
          },
        );

    process.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(
          (data) {
            debugPrint('[Minecraft Error] $data');
            if (onStderr != null) {
              onStderr(data, LogSource.javaStdErr);
            }
          },
          onError: (error) {
            debugPrint('[Minecraft Error] Error processing standard error output: $error');
          },
        );

    debugPrint('Minecraft process launched. PID: ${process.pid}');

    if (onMinecraftLaunch != null) {
      onMinecraftLaunch();
    }

    process.exitCode.then((exitCode) {
      if (onExit != null) {
        final isNormalExit = exitCode == 0 || exitCode == 143; // 143はSIGTERM
        onExit(exitCode, isNormalExit, account?.id, profile.id);
      }
      debugPrint('Minecraft process exited. Exit code: $exitCode');
    });

    return process;
  } catch (e) {
    throw Exception('Failed to launch Minecraft: $e');
  }
}

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
  final librariesDir = p.join(appDir.path, 'libraries');
  final tempDir = p.join(
    appDir.path,
    'temp',
    'natives-${DateTime.now().millisecondsSinceEpoch}',
  );
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

      final nativeJarFile = File(nativeJarPath);

      if (!await nativeJarFile.exists()) {
        debugPrint('Native library not found: $nativeJarPath');
        processed++;
        if (onProgress != null) {
          onProgress(processed / total, processed, total);
        }
        continue;
      }

      debugPrint('Extracting native library: $nativeJarPath');

      final tempJarDir = p.join(
        tempDir,
        p.basenameWithoutExtension(nativeJarPath),
      );
      await extractJar(nativeJarFile.path, tempJarDir);

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

    debugPrint('Warning: Failed to extract JAR file - additional libraries may be required');
  } catch (e) {
    debugPrint('Failed to extract JAR file: $e');
  }
}

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

Future<String> buildClasspath(VersionInfo versionInfo, String versionId) async {
  try {
    final appDir = await createAppDirectory();
    final libraries = <String>[];
    final clientJarPath = await getClientJarPath(versionId);
    libraries.add(clientJarPath);

    if (versionInfo.libraries != null) {
      final librariesDir = p.join(appDir.path, 'libraries');

      for (final lib in versionInfo.libraries!) {
        // OS固有のルールをチェック
        if (lib.rules != null) {
          bool allow = false;
          for (final rule in lib.rules!) {
            if ((rule.os == null ||
                (Platform.isWindows && rule.os!.name == 'windows') ||
                (Platform.isLinux && rule.os!.name == 'linux') ||
                (Platform.isMacOS && rule.os!.name == 'osx'))) {
              allow = rule.action == 'allow';
            }
          }
          if (!allow) continue;
        }

        if (lib.downloads?.artifact != null &&
            lib.downloads!.artifact!.path != null) {
          final libPath = p.join(librariesDir, lib.downloads!.artifact!.path!);
          libraries.add(libPath);
        }
      }
    }

    final pathSeparator = Platform.isWindows ? ';' : ':';
    return libraries.join(pathSeparator);
  } catch (e) {
    throw Exception('クラスパスの構築に失敗しました: $e');
  }
}

Future<List<String>> constructJvmArguments({
  required VersionInfo versionInfo,
  required String nativeDir,
  required String classpath,
  required String appDir,
  required String gameDir,
}) async {
  final args = <String>[];

  args.add('-Djava.library.path=$nativeDir');
  args.add('-Dminecraft.launcher.brand=karasu_launcher');
  args.add('-Dminecraft.launcher.version=1.0.0');
  args.add('-cp');
  args.add(classpath);
  if (versionInfo.arguments != null && versionInfo.arguments!.jvm != null) {
    for (final arg in versionInfo.arguments!.jvm!) {
      if (arg.value is String) {
        String processedArg = arg.value
            .replaceAll('\${natives_directory}', nativeDir)
            .replaceAll('\${launcher_name}', 'karasu_launcher')
            .replaceAll('\${launcher_version}', '1.0.0')
            .replaceAll('\${classpath}', classpath);
        args.add(processedArg);
      } else {
        try {
          final jvmArg = arg;
          bool shouldAdd = true;
          if (jvmArg.rules != null) {
            if (jvmArg.rules!.isNotEmpty) {
              shouldAdd = false;
              for (final rule in jvmArg.rules!) {
                final action = rule.action;
                final os = rule.os;

                bool osMatch =
                    os == null ||
                    (os.name == 'windows' && Platform.isWindows) ||
                    (os.name == 'linux' && Platform.isLinux) ||
                    (os.name == 'osx' && Platform.isMacOS);

                if (osMatch) {
                  shouldAdd = action == 'allow';
                }
              }
            }
          }
          if (shouldAdd && arg.value != null) {
            final value = arg.value;
            if (value is String) {
              args.add(
                value
                    .replaceAll('\${natives_directory}', nativeDir)
                    .replaceAll('\${launcher_name}', 'karasu_launcher')
                    .replaceAll('\${launcher_version}', '1.0.0')
                    .replaceAll('\${classpath}', classpath),
              );
            } else if (value is List) {
              for (final item in value) {
                if (item is String) {
                  args.add(
                    item
                        .replaceAll('\${natives_directory}', nativeDir)
                        .replaceAll('\${launcher_name}', 'karasu_launcher')
                        .replaceAll('\${launcher_version}', '1.0.0')
                        .replaceAll('\${classpath}', classpath),
                  );
                }
              }
            }
          }
        } catch (e) {
          debugPrint('JVM引数の処理でエラーが発生しました: $e');
        }
      }
    }
  } else {
    args.add('-Djava.library.path=$nativeDir');
    args.add('-Dminecraft.launcher.brand=karasu_launcher');
    args.add('-Dminecraft.launcher.version=1.0.0');
    args.add('-cp');
    args.add(classpath);
    args.add('-Xmx2G');
  }

  return args;
}

Future<List<String>> constructGameArgumentsWithAuth({
  required VersionInfo versionInfo,
  required String appDir,
  required String gameDir,
  required String versionId,
  Account? account,
  String? offlinePlayerName,
}) async {
  // オフラインモードの場合
  if (account == null) {
    debugPrint('No account information. Launching in offline mode');
    final username = offlinePlayerName ?? 'Player';
    final args = await constructGameArguments(
      versionInfo: versionInfo,
      appDir: appDir,
      gameDir: gameDir,
      versionId: versionId,
      username: username,
      uuid: '00000000-0000-0000-0000-000000000000',
      accessToken: '00000000000000000000000000000000',
      userType: 'mojang', // オフラインモードではmojangタイプを使用
      xuid: null,
      clientId: null,
    );

    // --demoフラグが含まれていなければ追加（重複防止）
    if (!args.contains('--demo')) {
      debugPrint('Launching in demo mode');
      args.add('--demo');
    }

    // クライアントID、XUID関連の引数を削除
    removeAuthRelatedArgs(args);

    return args;
  }

  // アカウントがある場合は、所有権チェックを行う
  bool hasGameOwnership = false;
  if (account.minecraftAccessToken != null) {
    try {
      // この関数は認証サービスに依存していますが、直接importすると循環参照になるため、
      // 簡易版の所有権チェックをここで実装します
      final response = await http.get(
        Uri.parse('https://api.minecraftservices.com/entitlements/mcstore'),
        headers: {'Authorization': 'Bearer ${account.minecraftAccessToken}'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['items'] != null) {
          final items = data['items'] as List;
          hasGameOwnership = items.isNotEmpty;
        }
      }
      debugPrint('Minecraft ownership check result: $hasGameOwnership');
    } catch (e) {
      debugPrint('Ownership check error: $e');
      // Consider as no ownership in case of error
      hasGameOwnership = false;
    }
  } else {
    // Consider as no ownership if no access token
    debugPrint('No access token available. Assuming no game ownership.');
    hasGameOwnership = false;
  }

  // Microsoftアカウント認証情報
  final xuid = account.xuid;
  // Minecraftのclientidは固定値（公開情報）
  const clientId = "00000000402b5328";

  final args = await constructGameArguments(
    versionInfo: versionInfo,
    appDir: appDir,
    gameDir: gameDir,
    versionId: versionId,
    username: account.profile?.name ?? 'Player',
    uuid: account.profile?.id ?? '00000000-0000-0000-0000-000000000000',
    accessToken:
        account.minecraftAccessToken ?? '00000000000000000000000000000000',
    userType: 'msa', // Microsoft認証の場合はmsa
    xuid: xuid, // XUIDがある場合のみ設定
    clientId: clientId, // クライアントID
  );

  // 所有権がない場合はデモモードで起動
  if (!hasGameOwnership) {
    debugPrint('No ownership of Minecraft: Java Edition. Launching in demo mode');
    // --demoフラグが含まれていなければ追加（重複防止）
    if (!args.contains('--demo')) {
      args.add('--demo');
    }
  }

  return args;
}

/// 認証関連の不要な引数を削除する
void removeAuthRelatedArgs(List<String> args) {
  final authRelatedArgs = [
    '--clientId',
    '--xuid',
    '-clientId',
    '\${clientid}',
    '\${auth_xuid}',
  ];

  for (int i = 0; i < args.length; i++) {
    if (authRelatedArgs.contains(args[i])) {
      // 引数とその値を削除（値がある場合）
      args.removeAt(i);
      if (i < args.length &&
          !args[i].startsWith('--') &&
          !args[i].startsWith('-')) {
        args.removeAt(i);
      }
      i--; // インデックスを調整
    } else if (args[i].startsWith('--clientId=') ||
        args[i].startsWith('-clientId=') ||
        args[i].contains('\${clientid}') ||
        args[i].contains('\${auth_xuid}')) {
      // Key=Value形式の引数や置換されていないプレースホルダーを含む引数を削除
      args.removeAt(i);
      i--; // インデックスを調整
    }
  }
}

Future<List<String>> constructGameArguments({
  required VersionInfo versionInfo,
  required String appDir,
  required String gameDir,
  required String versionId,
  String? username = 'Player',
  String? uuid = '00000000-0000-0000-0000-000000000000',
  String? accessToken = '00000000000000000000000000000000',
  String? userType = 'mojang',
  String? xuid,
  String? clientId,
}) async {
  final parsedUuid = uuid!;
  final args = <String>[];

  if (versionInfo.arguments != null && versionInfo.arguments!.game != null) {
    final tempArgs = <String>[];

    for (final arg in versionInfo.arguments!.game!) {
      try {
        bool shouldAdd = true;
        dynamic argValue = arg.value;
        if (arg.rules != null && arg.rules!.isNotEmpty) {
          shouldAdd = false;
          for (final rule in arg.rules!) {
            if (rule.action == 'allow') {
              if (rule.features != null) {
                shouldAdd = false;
              } else {
                shouldAdd = true;
              }
              break;
            }
          }
        }

        if (shouldAdd && argValue != null) {
          if (argValue is String) {
            String value = replaceArgumentPlaceholders(
              argValue,
              username!,
              versionId,
              gameDir,
              appDir,
              versionInfo.assetIndex?.id ?? 'legacy',
              parsedUuid,
              accessToken!,
              userType!,
              versionInfo.type ?? 'release',
              xuid,
              clientId,
            );
            // プレースホルダーが残っている場合でも、userTypeがmsaの場合は追加
            final containsUnresolvedPlaceholders =
                value.contains('\${clientid}') ||
                value.contains('\${auth_xuid}');

            if (!containsUnresolvedPlaceholders ||
                (userType == 'msa' && xuid != null && clientId != null)) {
              tempArgs.add(value);
            }
          } else if (argValue is List) {
            for (final item in argValue) {
              if (item is String) {
                String value = replaceArgumentPlaceholders(
                  item,
                  username!,
                  versionId,
                  gameDir,
                  appDir,
                  versionInfo.assetIndex?.id ?? 'legacy',
                  parsedUuid,
                  accessToken!,
                  userType!,
                  versionInfo.type ?? 'release',
                  xuid,
                  clientId,
                );
                // プレースホルダーが残っている場合でも、userTypeがmsaの場合は追加
                final containsUnresolvedPlaceholders =
                    value.contains('\${clientid}') ||
                    value.contains('\${auth_xuid}');

                if (!containsUnresolvedPlaceholders ||
                    (userType == 'msa' && xuid != null && clientId != null)) {
                  tempArgs.add(value);
                }
              }
            }
          }
        }
      } catch (e) {
        debugPrint('ゲーム引数の処理でエラーが発生しました: $e');
      }
    }

    final quickplayRelatedKeywords = [
      '--quickPlayPath',
      '--quickPlaySingleplayer',
      '--quickPlayMultiplayer',
      '--quickPlayRealms',
      '--demo',
      '--width',
      '--height',
    ];

    for (int i = 0; i < tempArgs.length; i++) {
      bool shouldSkipArg = false;

      for (final keyword in quickplayRelatedKeywords) {
        if (tempArgs[i] == keyword) {
          shouldSkipArg = true;
          if (i + 1 < tempArgs.length && !tempArgs[i + 1].startsWith('--')) {
            i++;
          }
          break;
        }
      }

      if (!shouldSkipArg) {
        args.add(tempArgs[i]);
      }
    }

    debugPrint('Final game arguments: ${args.join(' ')}');
  } else {
    final defaultArgs = [
      '--username',
      username,
      '--version',
      versionId,
      '--gameDir',
      gameDir,
      '--assetsDir',
      p.join(appDir, 'assets'),
      '--assetIndex',
      versionInfo.assetIndex?.id ?? 'legacy',
      '--uuid',
      uuid,
      '--accessToken',
      accessToken,
      '--userType',
      userType,
      '--versionType',
      versionInfo.type ?? 'release',
    ];

    // Microsoftアカウントの場合、追加の認証引数を追加
    if (userType == 'msa' && xuid != null && clientId != null) {
      defaultArgs.add('--xuid');
      defaultArgs.add(xuid);
      defaultArgs.add('--clientId');
      defaultArgs.add(clientId);
    }

    for (final arg in defaultArgs) {
      String processedArg = replaceArgumentPlaceholders(
        arg!,
        username!,
        versionId,
        gameDir,
        appDir,
        versionInfo.assetIndex?.id ?? 'legacy',
        parsedUuid,
        accessToken!,
        userType!,
        versionInfo.type ?? 'release',
        xuid,
        clientId,
      );
      args.add(processedArg);
    }
  }

  return args;
}

String replaceArgumentPlaceholders(
  String arg,
  String username,
  String versionId,
  String gameDir,
  String appDir,
  String assetsIndexName,
  String uuid,
  String accessToken,
  String userType,
  String versionType, [
  String? xuid,
  String? clientId,
]) {
  String result = arg
      .replaceAll('\${auth_player_name}', username)
      .replaceAll('\${version_name}', versionId)
      .replaceAll('\${game_directory}', gameDir)
      .replaceAll('\${assets_root}', p.join(appDir, 'assets'))
      .replaceAll('\${assets_index_name}', assetsIndexName)
      .replaceAll('\${auth_uuid}', uuid)
      .replaceAll('\${auth_access_token}', accessToken)
      .replaceAll('\${user_type}', userType)
      .replaceAll('\${version_type}', versionType)
      .replaceAll('\${resolution_width}', '854')
      .replaceAll('\${resolution_height}', '480');

  // Microsoftアカウント認証関連の引数を置換
  if (xuid != null) {
    result = result.replaceAll('\${auth_xuid}', xuid);
  }

  if (clientId != null) {
    result = result.replaceAll('\${clientid}', clientId);
  }

  return result;
}

Future<String> findJavaPath(Profile profile) async {
  if (profile.javaDir != null && profile.javaDir!.isNotEmpty) {
    final javaPath =
        Platform.isWindows
            ? p.join(profile.javaDir!, 'bin', 'javaw.exe')
            : p.join(profile.javaDir!, 'bin', 'java');
    if (await File(javaPath).exists()) {
      return javaPath;
    }
  }

  final appDir = await createAppDirectory();
  final runtimesDir = p.join(appDir.path, 'runtimes');
  final jdk21Dir = p.join(runtimesDir, 'jdk-21');

  final javaPath =
      Platform.isWindows
          ? p.join(jdk21Dir, 'bin', 'javaw.exe')
          : p.join(jdk21Dir, 'bin', 'java');

  if (await File(javaPath).exists()) {
    return javaPath;
  }

  final javaHome = Platform.environment['JAVA_HOME'];
  if (javaHome != null && javaHome.isNotEmpty) {
    final javaPath =
        Platform.isWindows
            ? p.join(javaHome, 'bin', 'javaw.exe')
            : p.join(javaHome, 'bin', 'java');
    if (await File(javaPath).exists()) {
      return javaPath;
    }
  }

  return Platform.isWindows ? 'javaw.exe' : 'java';
}
