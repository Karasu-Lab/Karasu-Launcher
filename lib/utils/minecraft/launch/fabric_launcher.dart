import 'dart:io';
import 'package:karasu_launcher/models/mod_loader.dart';
import 'package:karasu_launcher/models/version_info.dart';
import 'package:karasu_launcher/utils/minecraft/launch/modded_launcher.dart';
import 'package:karasu_launcher/utils/file_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

class FabricLauncher extends ModdedLauncher<ModLoader> {
  static const String FABRIC_MAVEN_URL = 'https://maven.fabricmc.net';

  @override
  Future<ModLoader?> getModLoaderInfo(String versionId) async {
    final modLoader = await getModLoaderForVersion(versionId);

    if (modLoader?.type == ModLoaderType.fabric) {
      return modLoader;
    }
    return null;
  }

  @override
  Future<List<String>> buildModLoaderJvmArguments(ModLoader modLoader) async {
    final args = <String>[];

    args.add('-DFabricMcEmu=net.minecraft.client.main.Main');

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
    ModLoader modLoader, {
    void Function(double progress, int current, int total)? onProgress,
  }) async {
    try {
      debugPrint('Fabricモッドファイルのダウンロード中...');

      // 必須のFabricライブラリリスト
      final baseLibraries = [
        'net.fabricmc:fabric-loader:${modLoader.version}',
        'net.fabricmc.fabric-api:fabric-api:${modLoader.version}',
        'net.fabricmc:intermediary:${modLoader.baseGameVersion}',
      ];

      debugPrint('Fabricコアライブラリをダウンロード中...');
      await downloadMavenLibraries(
        repoUrl: FABRIC_MAVEN_URL,
        mavenCoordinates: baseLibraries,
        onProgress: onProgress,
      );

      // MODローダー共通処理を呼び出してライブラリをダウンロード
      await super.downloadModFiles(modLoader, onProgress: onProgress);

      debugPrint('Fabricモッドファイルのダウンロード完了');
    } catch (e, stackTrace) {
      debugPrint('Fabricモッドファイルのダウンロード中にエラーが発生しました: $e');
      debugPrint('スタックトレース: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<void> preModLaunch(ModLoader modLoader) async {
    try {
      debugPrint('Fabric環境の準備中...');

      final appDir = await createAppDirectory();
      final fabricLibPath = p.join(
        appDir.path,
        'libraries',
        'net',
        'fabricmc',
        'fabric-loader',
        modLoader.version,
      );

      final loaderJarPath = p.join(
        fabricLibPath,
        'fabric-loader-${modLoader.version}.jar',
      );

      if (!await File(loaderJarPath).exists()) {
        debugPrint('FabricローダーJARが見つかりません。必要なライブラリをダウンロード中...');
        await downloadModFiles(modLoader);
      } else {
        debugPrint('FabricローダーJARが見つかりました: $loaderJarPath');
      }

      debugPrint('Fabric環境の準備が完了しました');
    } catch (e) {
      debugPrint('Fabric環境の準備中にエラーが発生しました: $e');
      rethrow;
    }
  }

  @override
  Future<void> postModLaunch(ModLoader modLoader) async {
    try {
      debugPrint('Fabric環境のクリーンアップ中...');

      final appDir = await createAppDirectory();
      final tempDir = Directory(p.join(appDir.path, 'temp', 'fabric'));

      if (await tempDir.exists()) {
        try {
          await tempDir.delete(recursive: true);
          debugPrint('一時Fabricファイルを削除しました');
        } catch (e) {
          debugPrint('警告: 一時Fabricファイルの削除に失敗しました: $e');
        }
      }

      debugPrint('Fabric環境のクリーンアップが完了しました');
    } catch (e) {
      debugPrint('Fabric環境のクリーンアップ中にエラーが発生しました: $e');
      rethrow;
    }
  }

  @override
  Future<String> getMainClass() async {
    try {
      final versionInfo = await getVersionInfo();
      if (versionInfo?.mainClass != null) {
        return versionInfo!.mainClass!;
      }

      final inheritedVersionInfo = await getInheritedVersionInfo();
      if (inheritedVersionInfo?.mainClass != null) {
        return inheritedVersionInfo!.mainClass!;
      }
    } catch (e) {
      debugPrint('Fabricメインクラスの取得中にエラーが発生しました: $e');
    }

    return 'net.fabricmc.loader.impl.launch.knot.KnotClient';
  }

  @override
  FabricLauncher get instance => FabricLauncher();

  @override
  bool get isModded => true;

  @override
  ModLoaderType? get modLoader => ModLoaderType.fabric;

  @override
  String getDefaultMavenRepo() {
    return FABRIC_MAVEN_URL;
  }

  Future<String?> getFabricLoaderJarPath(ModLoader modLoader) async {
    try {
      final appDir = await createAppDirectory();
      final loaderPath = p.join(
        appDir.path,
        'libraries',
        'net',
        'fabricmc',
        'fabric-loader',
        modLoader.version,
        'fabric-loader-${modLoader.version}.jar',
      );

      if (await File(loaderPath).exists()) {
        return loaderPath;
      }

      debugPrint('FabricローダーJARが見つかりません: $loaderPath');
      return null;
    } catch (e) {
      debugPrint('FabricローダーJARパスの取得中にエラーが発生しました: $e');
      return null;
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

      // MODローダー情報を取得
      final modLoader = await getModLoaderInfo(versionId);
      if (modLoader == null) {
        return buildFinalClasspath(libraryVersionMap);
      }

      final appDir = await createAppDirectory();
      final librariesDir = Directory(p.join(appDir.path, 'libraries'));

      // Fabricローダーをクラスパスに追加
      final loaderPath = await getFabricLoaderJarPath(modLoader);
      if (loaderPath != null) {
        const libraryKey = 'net.fabricmc:fabric-loader';
        libraryVersionMap[libraryKey] = (modLoader.version, loaderPath);
        debugPrint('FabricローダーをクラスパスKに追加しました: $loaderPath');
      }

      // Intermediaryをクラスパスに追加
      final intermediaryPath = p.join(
        librariesDir.path,
        'net',
        'fabricmc',
        'intermediary',
        modLoader.baseGameVersion,
        'intermediary-${modLoader.baseGameVersion}.jar',
      );

      if (await File(intermediaryPath).exists()) {
        const libraryKey = 'net.fabricmc:intermediary';
        libraryVersionMap[libraryKey] = (
          modLoader.baseGameVersion,
          intermediaryPath,
        );
      }

      // Fabric APIをクラスパスに追加
      final fabricApiPath = p.join(
        librariesDir.path,
        'net',
        'fabricmc',
        'fabric-api',
        'fabric-api',
        modLoader.version,
        'fabric-api-${modLoader.version}.jar',
      );
      if (await File(fabricApiPath).exists()) {
        const libraryKey = 'net.fabricmc.fabric-api:fabric-api';
        final existingVersion = libraryVersionMap[libraryKey]?.$1;
        if (existingVersion == null ||
            compareVersions(modLoader.version, existingVersion) > 0) {
          libraryVersionMap[libraryKey] = (modLoader.version, fabricApiPath);
          if (existingVersion != null) {
            debugPrint(
              'Fabric APIをアップグレード: $existingVersion → ${modLoader.version}',
            );
          } else {
            debugPrint('Fabric APIをクラスパスに追加しました: $fabricApiPath');
          }
        }
      }

      return buildFinalClasspath(libraryVersionMap);
    } catch (e) {
      debugPrint('Fabricクラスパスの構築中にエラーが発生しました: $e');
      return await super.buildClasspath(versionInfo, versionId);
    }
  }
}
