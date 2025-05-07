import 'dart:convert';
import 'dart:io';
import 'package:karasu_launcher/models/forge_mod_loader.dart';
import 'package:karasu_launcher/models/mod_loader.dart';
import 'package:karasu_launcher/models/version_info.dart';
import 'package:karasu_launcher/utils/file_utils.dart';
import 'package:karasu_launcher/utils/minecraft/launch/modded_launcher.dart';
import 'package:karasu_launcher/utils/maven_repo_downloader.dart';
import 'package:flutter/foundation.dart';
import 'package:karasu_launcher/utils/minecraft_utils.dart';
import 'package:path/path.dart' as p;

/// ForgeモッドローダーのランチャークラスTK
class ForgeLauncher extends ModdedLauncher<ForgeModLoader> {
  /// Forgeのメインリポジトリ
  static const String FORGE_MAVEN_URL = 'https://maven.minecraftforge.net';

  /// Minecraftのライブラリリポジトリ
  static const String MINECRAFT_LIBRARY_URL = 'https://libraries.minecraft.net';

  /// 使用可能なMavenリポジトリのリスト
  final List<String> _mavenRepositories = [
    FORGE_MAVEN_URL,
    MINECRAFT_LIBRARY_URL,
    'https://maven.fabricmc.net', // 一部のForgeモッドはFabricのライブラリに依存する場合もある
    'https://repo1.maven.org/maven2', // Maven Central
  ];

  @override
  Future<ForgeModLoader?> getModLoaderInfo(String versionId) async {
    final modLoader = await getModLoaderForVersion(versionId);
    if (modLoader?.type == ModLoaderType.forge) {
      return modLoader as ForgeModLoader;
    }
    return null;
  }

  @override
  Future<ForgeModLoader?> getModLoaderForVersion(String? versionId) async {
    if (versionId == null || versionId.isEmpty) {
      return null;
    }

    try {
      final versionJsonPath = await getVersionJsonPath(versionId);
      final jsonFile = File(versionJsonPath);

      if (await jsonFile.exists()) {
        final content = await jsonFile.readAsString();
        final jsonData = json.decode(content) as Map<String, dynamic>;
        return ForgeModLoader.fromJsonContent(jsonData, versionId);
      }
    } catch (e) {
      debugPrint('Failed to get MOD loader information: $e');
    }

    return null;
  }

  @override
  Future<List<String>> buildModLoaderJvmArguments(ModLoader modLoader) async {
    final args = <String>[];

    // Forgeに必要な標準的なJVM引数を追加
    args.addAll([
      '-Dforge.logging.console.level=info',
      '-Dforge.logging.markers=SCAN,REGISTRIES,REGISTRYDUMP',
      '-Dforge.enabledGameTestNamespaces=forge',
      '-Dfml.ignoreInvalidMinecraftCertificates=true',
      '-Dfml.ignorePatchDiscrepancies=true',
    ]);

    // バージョン固有の引数があれば追加
    if (modLoader.arguments != null &&
        modLoader.arguments!.containsKey('jvm')) {
      final jvmArgs = modLoader.arguments!['jvm'];
      if (jvmArgs is List) {
        args.addAll(jvmArgs.cast<String>());
      }
    }

    return args;
  }

  @override
  Future<void> downloadModFiles(
    ForgeModLoader modLoader, {
    void Function(double progress, int current, int total)? onProgress,
  }) async {
    try {
      debugPrint('Starting Forge mod files download...');
      final appDir = await createAppDirectory();
      final librariesDir = Directory(p.join(appDir.path, 'libraries'));
      final versionsDir = Directory(p.join(appDir.path, 'versions'));

      // ベースとなるバージョンJARが存在するか確認
      final versionDir = Directory(
        p.join(versionsDir.path, modLoader.inheritsFrom ?? modLoader.id!),
      );
      final versionJar = File(
        p.join(
          versionDir.path,
          '${modLoader.inheritsFrom ?? modLoader.id!}.jar',
        ),
      );

      if (!await versionJar.exists()) {
        debugPrint('Base version JAR not found. Download required.');
        throw Exception('Base version JAR not found: ${versionJar.path}');
      }

      // Forgeのライブラリが定義されている場合
      if (modLoader.libraries != null && modLoader.libraries!.isNotEmpty) {
        int current = 0;
        final total = modLoader.libraries!.length;

        debugPrint('Downloading $total Forge libraries...');

        for (final lib in modLoader.libraries!) {
          try {
            // downloadsフィールドからアーティファクト情報を取得
            final artifact = lib['downloads']?['artifact'];
            if (artifact != null) {
              final String path = artifact['path'];
              String? url = artifact['url'];
              final String? sha1 = artifact['sha1'];
              final int? size = artifact['size'];

              // URLがない場合でも、name属性からMaven座標を取得してダウンロードを試みる
              if ((url == null || url.isEmpty) && lib.containsKey('name')) {
                final String name = lib['name'];
                final String fileName = path.split('/').last;

                // 複数のリポジトリから順番にダウンロードを試みる
                bool downloaded = false;
                for (final repo in _mavenRepositories) {
                  try {
                    await MavenRepoDownloader.downloadArtifact(
                      mavenCoordinate: name,
                      repoUrl: repo,
                      destinationDir: librariesDir,
                      customFileName: fileName,
                    );
                    debugPrint('Downloaded library $name from repository $repo');
                    downloaded = true;
                    break;
                  } catch (repoError) {
                    debugPrint('Failed to download from repository $repo: $repoError');
                  }
                }

                if (!downloaded) {
                  debugPrint('Warning: Failed to download library $name');
                }
              }
              // 直接URLが提供されている場合は、そのURLからダウンロード
              else if (url != null && url.isNotEmpty) {
                final targetFile = File(p.join(librariesDir.path, path));
                final targetDir = targetFile.parent;

                if (!await targetDir.exists()) {
                  await targetDir.create(recursive: true);
                }

                // ファイルが存在しないか、SHA1が異なる場合にダウンロード
                if (!await targetFile.exists() ||
                    (sha1 != null &&
                        await MavenRepoDownloader.getFileSha1(targetFile) !=
                            sha1)) {
                  debugPrint('Downloading library: $path');
                  await MavenRepoDownloader.downloadFromDirectUrl(
                    url: url,
                    filePath: targetFile.path,
                    sha1: sha1,
                    fileSize: size,
                  );
                }
              }
            }
          } catch (libError) {
            debugPrint('Error occurred while downloading library: $libError');
          }

          current++;
          onProgress?.call(current / total, current, total);
        }
      }

      // Modsディレクトリが存在することを確認
      final modsDir = Directory(p.join(appDir.path, 'mods'));
      if (!await modsDir.exists()) {
        await modsDir.create(recursive: true);
      }

      // 親クラスの共通ダウンロード処理を呼び出す
      await super.downloadModFiles(modLoader, onProgress: onProgress);

      debugPrint('Forge dependencies downloaded successfully');
    } catch (e, stackTrace) {
      debugPrint('Error occurred while downloading Forge mod files: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<String> buildClasspath(
    VersionInfo versionInfo,
    String versionId,
  ) async {
    try {
      // 親クラスのbuildClasspathを呼び出してベースとなるクラスパスを構築
      await super.buildClasspath(versionInfo, versionId);

      // ライブラリマップを取得
      final libraryVersionMap = Map<String, (String, String)>.from(
        getClassPathMap(),
      );

      final appDir = await createAppDirectory();

      // Forgeモッドローダー情報を取得
      final modLoader = await getModLoaderInfo(versionId);
      if (modLoader != null) {
        if (modLoader.libraries != null) {
          final librariesDir = p.join(appDir.path, 'libraries');

          // すべてのForgeライブラリをクラスパスに追加
          for (final lib in modLoader.libraries!) {
            final artifact = lib['downloads']?['artifact'];
            if (artifact != null) {
              final String path = artifact['path'];
              final targetFile = File(p.join(librariesDir, path));

              if (await targetFile.exists()) {
                final libPath = targetFile.path;

                // パスからライブラリ情報を抽出
                final parts = path.split('/');
                if (parts.length >= 3) {
                  // ファイル名からアーティファクトIDとバージョンを抽出
                  final fileName = parts.last;
                  final fileNameParts = fileName.split('-');
                  final artifactId = fileNameParts.first;

                  String? version;
                  if (fileNameParts.length >= 2) {
                    // バージョン部分を抽出（拡張子を除く）
                    final versionPart = fileNameParts.sublist(1).join('-');
                    version = versionPart.replaceAll(
                      RegExp(r'\.(jar|zip)$'),
                      '',
                    );
                  }

                  // グループIDを抽出
                  final groupParts = parts.sublist(0, parts.length - 3);
                  final groupId = groupParts.join('.');

                  // クラスパスマップに追加
                  if (groupId.isNotEmpty &&
                      artifactId.isNotEmpty &&
                      version != null) {
                    final libraryKey = '$groupId:$artifactId';
                    final existingEntry = libraryVersionMap[libraryKey];

                    // 同じライブラリの場合はより新しいバージョンを使用
                    if (existingEntry == null ||
                        compareVersions(version, existingEntry.$1) > 0) {
                      if (existingEntry != null) {
                        debugPrint(
                          'Upgrading Forge library $libraryKey: ${existingEntry.$1} → $version',
                        );
                      } else {
                        debugPrint('Adding Forge library to classpath: $libPath');
                      }
                      libraryVersionMap[libraryKey] = (version, libPath);
                    }
                  }
                }
              }
            }
          }
        }
      }
      var inheritedVersion = await getInheritedVersionInfo();
      if (inheritedVersion != null) {
        var versionDir = Directory(
          p.join(appDir.path, 'versions', inheritedVersion.id),
        );
        var versionJar = File(
          p.join(versionDir.path, '${inheritedVersion.id}.jar'),
        );

        if (await versionJar.exists()) {
          // Minecraft本体のJARファイルを追加（これが重要！）
          // ForgeではMinecraft本体JARは最も優先度が高くなければならない
          // 重要: Forgeの場合、"net.minecraft.launchwrapper.Launch"がメインクラスで
          // Minecraftのクラスを見つけられるように正しいライブラリ順序が必要
          final libraryKey = 'minecraft:client';
          libraryVersionMap[libraryKey] = (
            inheritedVersion.id!,
            versionJar.path,
          );
          debugPrint('Adding Minecraft core JAR to classpath: ${versionJar.path}');

          // ForgeのLaunchwrapperがMinecraftクラスを確実に見つけられるようにするため
          // 明示的にkeyをJARパスとして追加する（別のエントリとして）
          final directJarKey = versionJar.path;
          libraryVersionMap[directJarKey] = (
            inheritedVersion.id!,
            versionJar.path,
          );
          debugPrint('Adding Minecraft core JAR with direct path: ${versionJar.path}');
        } else {
          debugPrint('Warning: Version JAR not found: ${versionJar.path}');

          // JAR が見つからない場合はダウンロードを試みる
          try {
            debugPrint('Attempting to download version JAR: ${inheritedVersion.id}');
            await downloadMinecraftClient(inheritedVersion.id!);

            // ダウンロード後に再度チェック
            if (await versionJar.exists()) {
              final libraryKey = 'minecraft:client';
              libraryVersionMap[libraryKey] = (
                inheritedVersion.id!,
                versionJar.path,
              );
              debugPrint('Adding Minecraft core JAR to classpath: ${versionJar.path}');

              // ForgeのLaunchwrapperがMinecraftクラスを確実に見つけられるようにするため
              // 明示的にkeyをJARパスとして追加する（別のエントリとして）
              final directJarKey = versionJar.path;
              libraryVersionMap[directJarKey] = (
                inheritedVersion.id!,
                versionJar.path,
              );
              debugPrint('Adding Minecraft core JAR with direct path: ${versionJar.path}');
            }
          } catch (e) {
            debugPrint('Failed to download version JAR: $e');
          }
        }
      }

      // 最終的なクラスパスを構築
      return buildFinalClasspath(libraryVersionMap);
    } catch (e) {
      debugPrint('Error occurred during Forge classpath construction: $e');
      return await super.buildClasspath(versionInfo, versionId);
    }
  }

  @override
  Future<void> preModLaunch(ModLoader modLoader) async {
    try {
      debugPrint('Preparing Forge environment...');
      final appDir = await createAppDirectory();
      final forgeModLoader = modLoader as ForgeModLoader;

      // 必要なディレクトリが存在することを確認
      final versionsDir = Directory(p.join(appDir.path, 'versions'));
      final librariesDir = Directory(p.join(appDir.path, 'libraries'));
      final modsDir = Directory(p.join(appDir.path, 'mods'));

      for (final dir in [versionsDir, librariesDir, modsDir]) {
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }
      }

      // ベースバージョンJARが存在することを確認
      final versionJar = File(
        p.join(
          versionsDir.path,
          forgeModLoader.inheritsFrom ?? forgeModLoader.id!,
          '${forgeModLoader.inheritsFrom ?? forgeModLoader.id!}.jar',
        ),
      );

      if (!await versionJar.exists()) {
        throw Exception('Required version JAR not found: ${versionJar.path}');
      }

      // 必要なライブラリが存在することを確認
      if (forgeModLoader.libraries != null) {
        for (final lib in forgeModLoader.libraries!) {
          final artifact = lib['downloads']?['artifact'];
          if (artifact != null) {
            final String path = artifact['path'];
            final targetFile = File(p.join(librariesDir.path, path));

            if (!await targetFile.exists()) {
              // 不足しているライブラリを補完するため、ダウンロードを再試行
              debugPrint('Required Forge library not found: ${targetFile.path}');
              debugPrint('Downloading missing libraries...');

              await downloadModFiles(forgeModLoader);
              break;
            }
          }
        }
      }

      debugPrint('Forge environment preparation complete');
    } catch (e, stackTrace) {
      debugPrint('Error occurred during Forge environment preparation: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<void> postModLaunch(ModLoader modLoader) async {
    try {
      debugPrint('Cleaning up Forge environment...');

      // Forge固有の一時ファイルをクリーンアップする場合はここに処理を追加
      final appDir = await createAppDirectory();
      final tempDir = Directory(p.join(appDir.path, 'temp', 'forge'));

      if (await tempDir.exists()) {
        try {
          await tempDir.delete(recursive: true);
          debugPrint('Temporary Forge files deleted');
        } catch (e) {
          debugPrint('Warning: Failed to delete temporary Forge files: $e');
        }
      }

      debugPrint('Forge environment cleanup complete');
    } catch (e) {
      debugPrint('Error occurred during Forge environment cleanup: $e');
      rethrow;
    }
  }

  @override
  String getDefaultMavenRepo() {
    return FORGE_MAVEN_URL;
  }

  /// 複数のリポジトリURLを取得
  List<String> getMavenRepositories() {
    return _mavenRepositories;
  }

  @override
  ForgeLauncher get instance => ForgeLauncher();

  @override
  bool get isModded => true;

  @override
  ModLoaderType? get modLoader => ModLoaderType.forge;

  @override
  Future<String> getMainClass() async {
    try {
      final versionInfo = await getVersionInfo();
      if (versionInfo?.mainClass != null) {
        return versionInfo!.mainClass!;
      }

      final forgeModLoader = await getModLoaderInfo(versionInfo?.id ?? '');
      if (forgeModLoader?.mainClass != null) {
        return forgeModLoader!.mainClass!;
      }

      // 標準のForgeメインクラスを返す
      return 'net.minecraft.launchwrapper.Launch';
    } catch (e) {
      debugPrint('Error occurred while getting Forge main class: $e');
      return 'net.minecraft.client.main.Main';
    }
  }
}
