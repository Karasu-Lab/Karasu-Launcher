import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:karasu_launcher/models/assets_indexes.dart';
import 'package:karasu_launcher/models/mod_loader.dart';
import 'package:karasu_launcher/models/version_info.dart';
import 'package:path/path.dart' as p;
import '../file_utils.dart';
import 'constants.dart';
import 'download_utils.dart';
import 'version_utils.dart';

/// アセットインデックスを取得する
Future<AssetsIndexes> fetchAssetIndex(VersionInfo versionInfo) async {
  // Modローダー情報を確認し、継承元バージョンからアセットインデックスを取得する必要があるか確認
  ModLoader? modLoader;
  String? baseVersionId;

  if (versionInfo.id != null) {
    final versionJsonPath = await getVersionJsonPath(versionInfo.id!);
    final jsonFile = File(versionJsonPath);

    if (await jsonFile.exists()) {
      try {
        final content = await jsonFile.readAsString();
        final jsonData = json.decode(content) as Map<String, dynamic>;
        modLoader = ModLoader.fromJsonContent(jsonData, versionInfo.id!);
        baseVersionId = modLoader?.inheritsFrom;
      } catch (e) {
        debugPrint('Modローダー情報の読み込みに失敗しました: $e');
      }
    }
  }

  // 継承元バージョンからアセットインデックス情報を取得
  if (baseVersionId != null &&
      (versionInfo.assetIndex == null || versionInfo.assetIndex!.url == null)) {
    debugPrint('Modローダーの継承元バージョン($baseVersionId)からアセットインデックス情報を取得します');
    try {
      final baseVersionInfo = await fetchVersionInfo(baseVersionId);
      if (baseVersionInfo.assetIndex != null &&
          baseVersionInfo.assetIndex!.url != null) {
        // 継承元のアセットインデックス情報を使用
        versionInfo = VersionInfo(
          id: versionInfo.id,
          assets: baseVersionInfo.assets,
          assetIndex: baseVersionInfo.assetIndex,
          downloads: versionInfo.downloads,
          libraries: versionInfo.libraries,
          mainClass: versionInfo.mainClass,
          minimumLauncherVersion: versionInfo.minimumLauncherVersion,
          releaseTime: versionInfo.releaseTime,
          time: versionInfo.time,
          type: versionInfo.type,
          javaVersion: versionInfo.javaVersion,
          logging: versionInfo.logging,
          arguments: versionInfo.arguments,
          complianceLevel: versionInfo.complianceLevel,
        );
      }
    } catch (e) {
      debugPrint('継承元バージョンのアセットインデックス情報取得に失敗しました: $e');
    }
  }

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

/// アセットファイルをダウンロードする
Future<File> downloadAsset(String hash, Directory assetsObjectsDir) async {
  final prefix = hash.substring(0, 2);
  final assetUrl = '$MINECRAFT_RESOURCES_URL/$prefix/$hash';

  final assetDir = await createSubDirectory(assetsObjectsDir, prefix);
  final assetFile = File(p.join(assetDir[0].path, hash));

  return await downloadFile(assetUrl, assetFile.path);
}

/// Minecraftのアセットをダウンロードする
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
    debugPrint(
      'Download complete: $downloaded / $totalAssets assets ($percentage%)',
    );
  } catch (e) {
    throw Exception('Failed to download Minecraft assets: $e');
  }
}
