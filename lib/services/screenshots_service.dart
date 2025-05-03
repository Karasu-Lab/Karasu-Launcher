import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:karasu_launcher/models/screenshot.dart';
import 'package:karasu_launcher/models/screenshots_collection.dart';
import 'package:karasu_launcher/utils/file_utils.dart';
import 'package:path/path.dart' as path;

class ScreenshotsService {
  static const String _screenshotsFileName = 'screenshots.json';

  Future<String> getScreenshotsFilePath() async {
    final appDir = await createAppDirectory();
    return path.join(appDir.path, _screenshotsFileName);
  }

  Future<ScreenshotsCollection> loadScreenshots() async {
    try {
      final filePath = await getScreenshotsFilePath();
      final file = File(filePath);

      if (!await file.exists()) {
        return ScreenshotsCollection();
      }

      final jsonString = await file.readAsString();
      final jsonMap = json.decode(jsonString) as Map<String, dynamic>;
      return ScreenshotsCollection.fromJson(jsonMap);
    } catch (e) {
      // ファイルの読み込みに失敗した場合は新しいコレクションを返す
      return ScreenshotsCollection();
    }
  }

  Future<void> saveScreenshots(ScreenshotsCollection collection) async {
    try {
      final filePath = await getScreenshotsFilePath();
      final file = File(filePath);
      
      // ディレクトリが存在しない場合は作成
      final directory = file.parent;
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      
      final jsonString = json.encode(collection.toJson());
      await file.writeAsString(jsonString);
    } catch (e) {
      throw Exception('スクリーンショット情報の保存に失敗しました: $e');
    }
  }

  Future<Screenshot> addScreenshot({
    required String filePath,
    required String profileId,
    String? comment,
    Map<String, dynamic>? metadata,
  }) async {
    final collection = await loadScreenshots();
    
    final screenshot = Screenshot(
      filePath: filePath,
      profileId: profileId,
      comment: comment,
      metadata: metadata,
    );
    
    final updatedCollection = collection.addScreenshot(screenshot);
    await saveScreenshots(updatedCollection);
    
    return screenshot;
  }
  Future<Screenshot?> getScreenshotById(String id) async {
    final collection = await loadScreenshots();
    return collection.screenshots[id];
  }

  Future<void> updateScreenshot(Screenshot screenshot) async {
    final collection = await loadScreenshots();
    // 既存のスクリーンショットがない場合は追加、ある場合は更新
    final existingScreenshot = collection.screenshots[screenshot.id];
    final updatedCollection = existingScreenshot != null 
        ? collection.updateScreenshot(screenshot) 
        : collection.addScreenshot(screenshot);
    await saveScreenshots(updatedCollection);
  }

  Future<void> removeScreenshot(String id) async {
    final collection = await loadScreenshots();
    final updatedCollection = collection.removeScreenshot(id);
    await saveScreenshots(updatedCollection);
  }

  Future<List<Screenshot>> getScreenshotsByProfileId(String profileId) async {
    final collection = await loadScreenshots();
    return collection.getScreenshotsByProfileId(profileId);
  }

  Future<List<Screenshot>> getAllScreenshots() async {
    final collection = await loadScreenshots();
    return collection.getAllScreenshots();
  }
}
