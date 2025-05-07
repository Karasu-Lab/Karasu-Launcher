import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:karasu_launcher/models/auth/account.dart';
import 'package:karasu_launcher/models/launcher_profiles.dart';
import 'package:karasu_launcher/models/mod_loader.dart';
import 'package:karasu_launcher/models/version_info.dart';
import 'package:karasu_launcher/providers/java_provider.dart';
import 'package:karasu_launcher/providers/log_provider.dart';
import 'package:karasu_launcher/utils/file_utils.dart';
import 'package:karasu_launcher/utils/maven_repo_downloader.dart';
import 'package:karasu_launcher/utils/minecraft_utils.dart';

/// MOD対応ランチャーの抽象クラス
abstract class ModdedLauncher<T extends ModLoader> extends StandardLauncher {
  /// MODローダー情報を取得する
  Future<T?> getModLoaderInfo(String versionId);

  /// MOD固有のJVM引数を構築する
  Future<List<String>> buildModLoaderJvmArguments(T modLoader);

  /// MOD固有の前処理を実行する
  Future<void> preModLaunch(T modLoader);

  /// MOD固有の後処理を実行する
  Future<void> postModLaunch(T modLoader);

  /// 継承元のバージョン情報を取得する
  Future<VersionInfo?> getInheritedVersionInfo() async {
    try {
      final inheritedVersion = await fetchVersionInfo(
        (await getVersionInfo())!.inheritsFrom!,
      );
      return inheritedVersion;
    } catch (e) {
      return null;
    }
  }

  /// 特定のMavenリポジトリからライブラリをダウンロードする
  Future<List<File>> downloadMavenLibraries({
    required String repoUrl,
    required List<String> mavenCoordinates,
    ProgressCallback? onProgress,
  }) async {
    try {
      final appDir = await createAppDirectory();
      final librariesDir = Directory(p.join(appDir.path, 'libraries'));

      if (!await librariesDir.exists()) {
        await librariesDir.create(recursive: true);
      }

      debugPrint('Mavenリポジトリからライブラリをダウンロード中: $repoUrl');

      final downloadedFiles = <File>[];
      int downloadCount = 0;
      final totalLibraries = mavenCoordinates.length;

      for (final coordinate in mavenCoordinates) {
        try {
          final file = await MavenRepoDownloader.downloadArtifact(
            mavenCoordinate: coordinate,
            repoUrl: repoUrl,
            destinationDir: librariesDir,
          );

          downloadedFiles.add(file);
          downloadCount++;

          if (onProgress != null) {
            onProgress(
              downloadCount / totalLibraries,
              downloadCount,
              totalLibraries,
            );
          }
        } catch (e) {
          debugPrint('ライブラリのダウンロードに失敗しました: $coordinate - $e');
        }
      }

      debugPrint('ライブラリのダウンロード完了: $downloadCount/$totalLibraries');
      return downloadedFiles;
    } catch (e) {
      debugPrint('Mavenライブラリのダウンロード中にエラーが発生しました: $e');
      return [];
    }
  }

  /// MODファイルをダウンロードする
  Future<void> downloadModFiles(
    T modLoader, {
    void Function(double progress, int current, int total)? onProgress,
  }) async {
    try {
      debugPrint('MODファイルのダウンロード開始');
      final appDir = await createAppDirectory();
      final librariesDir = Directory(p.join(appDir.path, 'libraries'));

      if (!await librariesDir.exists()) {
        await librariesDir.create(recursive: true);
      }

      final modsDir = Directory(p.join(appDir.path, 'mods'));
      if (!await modsDir.exists()) {
        await modsDir.create(recursive: true);
      }

      // MODローダーの依存ライブラリをダウンロード
      if (modLoader.libraries != null && modLoader.libraries!.isNotEmpty) {
        final mavenLibraries = <String>[];
        final libraryUrls = <String, String>{};

        // ライブラリリストを構築
        for (final libMap in modLoader.libraries!) {
          if (libMap.containsKey('name')) {
            final libName = libMap['name'] as String;
            if (libMap.containsKey('url')) {
              libraryUrls[libName] = libMap['url'] as String;
            }
            mavenLibraries.add(libName);
          }
        }

        // デフォルトリポジトリからライブラリをダウンロード
        final defaultLibraries =
            mavenLibraries
                .where((lib) => !libraryUrls.containsKey(lib))
                .toList();

        if (defaultLibraries.isNotEmpty) {
          await downloadMavenLibraries(
            repoUrl: getDefaultMavenRepo(),
            mavenCoordinates: defaultLibraries,
            onProgress: onProgress,
          );
        }

        // カスタムリポジトリからライブラリをダウンロード
        for (final entry in libraryUrls.entries) {
          await downloadMavenLibraries(
            repoUrl: entry.value,
            mavenCoordinates: [entry.key],
            onProgress: null, // 個別のライブラリには進捗を表示しない
          );
        }
      }

      debugPrint('MODファイルのダウンロード完了');
    } catch (e) {
      debugPrint('MODファイルのダウンロード中にエラーが発生しました: $e');
      rethrow;
    }
  }

  /// Maven座標からライブラリパスを取得する
  Future<String?> getLibraryPathFromMavenCoordinate(
    String mavenCoordinate,
    String librariesDirPath,
  ) async {
    try {
      final parts = mavenCoordinate.split(':');
      if (parts.length < 3) {
        debugPrint('無効なMaven座標形式です: $mavenCoordinate');
        return null;
      }

      final groupId = parts[0];
      final artifactId = parts[1];
      final version = parts[2];

      String classifier = '';
      String packaging = 'jar';

      if (parts.length > 3) {
        if (parts.length == 4) {
          packaging = parts[3];
        } else if (parts.length >= 5) {
          classifier = parts[3];
          packaging = parts[4];
        }
      }

      final groupPath = groupId.replaceAll('.', '/');

      final fileName =
          classifier.isEmpty
              ? '$artifactId-$version.$packaging'
              : '$artifactId-$version-$classifier.$packaging';

      final libPath = p.join(
        librariesDirPath,
        groupPath,
        artifactId,
        version,
        fileName,
      );

      return libPath;
    } catch (e) {
      debugPrint('Maven座標の解析中にエラーが発生しました $mavenCoordinate: $e');
      return null;
    }
  }

  /// デフォルトのMavenリポジトリURLを取得する（サブクラスでオーバーライド可能）
  String getDefaultMavenRepo() {
    return 'https://maven.fabricmc.net';
  }

  /// クラスパスマップから最終的なクラスパス文字列を構築する  /// 最終的なクラスパスを構築するメソッド
  /// Forgeでは特にMinecraft本体JARが優先されるようにする
  String buildFinalClasspath(Map<String, (String, String)> libraryVersionMap) {
    final pathSeparator = Platform.isWindows ? ';' : ':';
    final paths = <String>[];

    // 特別なキー "minecraft:client" （Minecraft本体JAR）があれば先頭に追加
    final minecraftClient = libraryVersionMap['minecraft:client'];
    if (minecraftClient != null) {
      paths.add(minecraftClient.$2);
      debugPrint('クラスパスの先頭にMinecraft本体JARを配置: ${minecraftClient.$2}');
    }

    // その他のすべてのライブラリパスを追加
    for (final entry in libraryVersionMap.entries) {
      // "minecraft:client"以外のパスと、既に追加したもの以外を追加
      if (entry.key != 'minecraft:client' &&
          !paths.contains(entry.value.$2) &&
          entry.value.$2.isNotEmpty) {
        // パスにパスセパレータが含まれていないことを確認（環境変数の混入防止）
        if (!entry.value.$2.contains(pathSeparator)) {
          paths.add(entry.value.$2);
        } else {
          debugPrint('警告: 無効なクラスパスエントリをスキップします: ${entry.value.$2}');
        }
      }
    }

    debugPrint('クラスパス項目数: ${paths.length}個');
    return paths.join(pathSeparator);
  }

  @override
  Future<List<String>> constructJvmArguments({
    required VersionInfo versionInfo,
    required String nativeDir,
    required String classpath,
    required String appDir,
    required String gameDir,
  }) async {
    final baseArgs = await super.constructJvmArguments(
      versionInfo: versionInfo,
      nativeDir: nativeDir,
      classpath: classpath,
      appDir: appDir,
      gameDir: gameDir,
    );

    // MODローダー情報を取得
    final modLoader = await getModLoaderInfo(versionInfo.id ?? '');
    if (modLoader == null) {
      return baseArgs;
    }

    // MOD固有のJVM引数を追加
    final modArgs = await buildModLoaderJvmArguments(modLoader);
    return [...baseArgs, ...modArgs];
  }

  @override
  Future<Process> launchMinecraft(
    Profile profile, {
    void Function(double progress, int current, int total)? onAssetsProgress,
    void Function(double progress, int current, int total)? onLibrariesProgress,
    void Function(double progress, int current, int total)? onNativesProgress,
    void Function()? onPrepareComplete,
    void Function(
      int exitCode,
      bool isNormalExit,
      String? accountId,
      String? profileId,
    )?
    onExit,
    void Function(String data, LogSource source)? onStdout,
    void Function(String data, LogSource source)? onStderr,
    void Function()? onMinecraftLaunch,
    Account? account,
    String? offlinePlayerName,
    JavaProvider? javaProvider,
  }) async {
    // バージョンIDからMODローダー情報を取得
    final modLoader = await getModLoaderInfo(profile.lastVersionId ?? '');
    if (modLoader != null) {
      // MOD固有の前処理を実行
      await preModLaunch(modLoader);

      // MODファイルをダウンロード
      await downloadModFiles(modLoader);
    }

    // 通常のMinecraft起動プロセス
    final process = await super.launchMinecraft(
      profile,
      onAssetsProgress: onAssetsProgress,
      onLibrariesProgress: onLibrariesProgress,
      onNativesProgress: onNativesProgress,
      onPrepareComplete: onPrepareComplete,
      onExit: (exitCode, isNormalExit, accountId, profileId) async {
        if (modLoader != null) {
          // MOD固有の後処理を実行
          await postModLaunch(modLoader);
        }
        onExit?.call(exitCode!, isNormalExit, accountId, profileId);
      },
      onStdout: onStdout,
      onStderr: onStderr,
      onMinecraftLaunch: onMinecraftLaunch,
      account: account,
      offlinePlayerName: offlinePlayerName,
      javaProvider: javaProvider,
    );

    return process;
  }

  @override
  bool get isModded => true;

  @override
  Future<String> getMainClass() async {
    final versionInfo = await getVersionInfo();
    if (versionInfo == null) {
      return super.getMainClass();
    }

    try {
      final modLoader = await getModLoaderInfo(versionInfo.id ?? '');
      if (modLoader != null && modLoader.mainClass != null) {
        return modLoader.mainClass!;
      }
    } catch (e) {
      return super.getMainClass();
    }

    return super.getMainClass();
  }

  @override
  Future<String> buildClasspath(
    VersionInfo versionInfo,
    String versionId,
  ) async {
    try {
      // 基本のクラスパスを構築
      await super.buildClasspath(versionInfo, versionId);

      // 既存のライブラリマップを取得
      final libraryVersionMap = Map<String, (String, String)>.from(
        getClassPathMap(),
      );

      // MODローダー情報を取得
      final modLoader = await getModLoaderInfo(versionId);
      if (modLoader == null) {
        return buildFinalClasspath(libraryVersionMap);
      }

      final appDir = await createAppDirectory();
      final librariesDir = Directory(p.join(appDir.path, 'libraries'));

      // MODに依存するライブラリを追加
      if (modLoader.libraries != null && modLoader.libraries!.isNotEmpty) {
        debugPrint('クラスパスにMODライブラリを追加中...');

        for (final libMap in modLoader.libraries!) {
          if (libMap.containsKey('name')) {
            final libName = libMap['name'] as String;

            try {
              // Maven座標の解析
              final parts = libName.split(':');
              if (parts.length < 3) {
                debugPrint('無効なMaven座標形式です: $libName');
                continue;
              }

              final groupId = parts[0];
              final artifactId = parts[1];
              final version = parts[2];
              final libraryKey = '$groupId:$artifactId';

              final libPath = await getLibraryPathFromMavenCoordinate(
                libName,
                librariesDir.path,
              );

              if (libPath != null && await File(libPath).exists()) {
                final existingVersion = libraryVersionMap[libraryKey]?.$1;
                if (existingVersion == null ||
                    compareVersions(version, existingVersion) > 0) {
                  if (existingVersion != null) {
                    debugPrint(
                      'ライブラリをアップグレード $libraryKey: $existingVersion → $version',
                    );
                  } else {
                    debugPrint('クラスパスにライブラリを追加: $libPath');
                  }
                  libraryVersionMap[libraryKey] = (version, libPath);
                } else {
                  debugPrint(
                    'ライブラリの古いバージョンをスキップ $libraryKey: $version (現在: $existingVersion)',
                  );
                }
              }
            } catch (e) {
              debugPrint('警告: ライブラリ $libName をクラスパスに追加できませんでした: $e');
            }
          }
        }
      }

      return buildFinalClasspath(libraryVersionMap);
    } catch (e) {
      debugPrint('MODクラスパスの構築中にエラーが発生しました: $e');
      return await super.buildClasspath(versionInfo, versionId);
    }
  }
}
