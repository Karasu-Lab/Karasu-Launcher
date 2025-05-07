import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:karasu_launcher/models/launcher_versions_v2.dart';
import 'package:karasu_launcher/models/mod_loader.dart';
import 'package:karasu_launcher/models/version_info.dart';
import 'package:path/path.dart' as p;
import '../file_utils.dart';
import 'constants.dart';
import 'download_utils.dart';

/// バージョンマニフェストを取得する
Future<LauncherVersionsV2> fetchVersionManifest() async {
  try {
    // オンラインのマニフェストを取得
    final response = await http.get(Uri.parse(MINECRAFT_VERSION_MANIFEST_URL));

    if (response.statusCode != 200) {
      throw Exception('Failed to get version manifest: ${response.statusCode}');
    }

    final manifest = LauncherVersionsV2.fromJson(json.decode(response.body));

    // ローカルのバージョンを取得
    final localVersions = await loadLocalVersions();
    final onlineVersionIds = manifest.versions.map((v) => v.id).toSet();

    // オンラインに存在しないローカルバージョンを追加
    for (final localVersion in localVersions) {
      if (!onlineVersionIds.contains(localVersion.id)) {
        manifest.versions.add(
          MinecraftVersion(
            id: localVersion.id,
            type: localVersion.type,
            url: '', // ローカルバージョンのため、URLは不要
            time: DateTime.now().toIso8601String(), // 正確な時間は不明なため、現在時刻を使用
            releaseTime: DateTime.now().toIso8601String(),
            sha1: '', // ローカルバージョンのため、SHA1は不要
            complianceLevel: 0,
            modLoader: localVersion.modLoader,
          ),
        );
        debugPrint('ローカルバージョンを追加: ${localVersion.id}');
      }
    }

    return manifest;
  } catch (e) {
    throw Exception('Failed to parse version manifest: $e');
  }
}

/// バージョンJSONファイルのパスを取得する
Future<String> getVersionJsonPath(String versionId) async {
  final appDir = await createAppDirectory();
  final versionsDir = await createSubDirectory(appDir, 'versions');
  final versionDir = await createSubDirectory(versionsDir[0], versionId);
  return p.join(versionDir[0].path, '$versionId.json');
}

/// クライアントJARファイルのパスを取得する
Future<String> getClientJarPath(String versionId) async {
  final appDir = await createAppDirectory();
  final versionsDir = await createSubDirectory(appDir, 'versions');
  final versionDir = await createSubDirectory(versionsDir[0], versionId);
  return p.join(versionDir[0].path, '$versionId.jar');
}

/// バージョン情報を取得する
Future<VersionInfo> fetchVersionInfo(String versionId) async {
  final jsonPath = await getVersionJsonPath(versionId);
  final jsonFile = File(jsonPath);

  if (await jsonFile.exists()) {
    try {
      final cachedContent = await jsonFile.readAsString();
      final jsonData = json.decode(cachedContent) as Map<String, dynamic>;

      // MODローダー情報をチェック
      if (jsonData.containsKey('inheritsFrom')) {
        return await fetchModVersionInfo(versionId);
      }

      return VersionInfo.fromJson(jsonData);
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

/// MOD用のバージョン情報を取得する
Future<VersionInfo> fetchModVersionInfo(String versionId) async {
  final jsonPath = await getVersionJsonPath(versionId);
  final jsonFile = File(jsonPath);

  if (!await jsonFile.exists()) {
    throw Exception('MODバージョン情報ファイルが見つかりません: $jsonPath');
  }

  try {
    final content = await jsonFile.readAsString();
    final jsonData = json.decode(content) as Map<String, dynamic>;

    // MOD情報を抽出
    final modLoader = ModLoader.fromJsonContent(jsonData, versionId);

    if (modLoader?.inheritsFrom == null) {
      throw Exception('MOD設定に基本バージョン(inheritsFrom)が指定されていません');
    }

    // 基本バージョンの情報を取得
    final baseVersionId = modLoader!.inheritsFrom!;
    debugPrint('MODの基本バージョン: $baseVersionId');

    // 基本バージョンの情報を取得
    final baseVersionInfo = await fetchVersionInfo(baseVersionId);

    // MODバージョン情報で上書き
    final modVersionInfo = VersionInfo.fromJson(jsonData);

    // MODのライブラリを基本バージョンのライブラリと結合
    final combinedLibraries = [
      ...?baseVersionInfo.libraries,
      ...?modVersionInfo.libraries,
    ];

    // 結合したバージョン情報を作成
    final combinedVersionInfo = VersionInfo(
      id: modVersionInfo.id ?? versionId,
      assets: baseVersionInfo.assets,
      assetIndex: baseVersionInfo.assetIndex,
      downloads: baseVersionInfo.downloads,
      libraries: combinedLibraries,
      mainClass: modVersionInfo.mainClass ?? baseVersionInfo.mainClass,
      minimumLauncherVersion: baseVersionInfo.minimumLauncherVersion,
      releaseTime: modVersionInfo.releaseTime ?? baseVersionInfo.releaseTime,
      time: modVersionInfo.time ?? baseVersionInfo.time,
      type: modVersionInfo.type ?? baseVersionInfo.type,
      javaVersion: baseVersionInfo.javaVersion,
      logging: baseVersionInfo.logging,
      arguments: modVersionInfo.arguments ?? baseVersionInfo.arguments,
      complianceLevel: baseVersionInfo.complianceLevel,
      inheritsFrom: modVersionInfo.inheritsFrom,
    );

    return combinedVersionInfo;
  } catch (e) {
    throw Exception('MODバージョン情報のパースに失敗しました: $e');
  }
}

/// クライアントJARをダウンロードする
Future<File> downloadClientJar(VersionInfo versionInfo) async {
  final versionId = versionInfo.id ?? 'unknown';
  final clientJarPath = await getClientJarPath(versionId);
  final clientJarFile = File(clientJarPath);

  // すでにJARファイルが存在する場合はそれを返す
  if (await clientJarFile.exists()) {
    return clientJarFile;
  }

  // Forgeモッドの場合は、クライアントJARが存在しなくてもスキップする
  final jsonPath = await getVersionJsonPath(versionId);
  final jsonFile = File(jsonPath);
  if (await jsonFile.exists()) {
    try {
      final content = await jsonFile.readAsString();
      final jsonData = json.decode(content) as Map<String, dynamic>;
      final modLoader = ModLoader.fromJsonContent(jsonData, versionId);
      if (modLoader?.type == 'forge') {
        debugPrint('Forgeモッドのため、クライアントJARのダウンロードをスキップします: $versionId');
        return clientJarFile; // 空のファイルを返す
      }
    } catch (e) {
      debugPrint('MODローダー情報の読み込みに失敗しました: $e');
    }
  }

  // MODローダーの場合、downloads情報はベースバージョンから取得される
  if (versionInfo.downloads?.client == null ||
      versionInfo.downloads!.client!.url == null) {
    throw Exception('クライアントJARのURLが見つかりません');
  }

  return await downloadFile(
    versionInfo.downloads!.client!.url!,
    clientJarPath,
    expectedSize: versionInfo.downloads!.client!.size,
  );
}
