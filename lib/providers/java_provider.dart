import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

final javaProvider = ChangeNotifierProvider<JavaProvider>(
  (ref) => JavaProvider()..loadJavaHome(),
);

class JavaProvider extends ChangeNotifier {
  static const String _javaHomeKey = 'java_home_path';
  static const String _javaVersionsKey = 'java_versions';
  String? _customJavaHome;

  Map<String, String> _javaVersions = {};

  String? get customJavaHome => _customJavaHome;
  Map<String, String> get javaVersions => _javaVersions;

  set customJavaHome(String? path) {
    if (_customJavaHome != path) {
      _customJavaHome = path;
      _saveJavaHome();
      notifyListeners();
    }
  }

  Future<void> _saveJavaHome() async {
    final prefs = await SharedPreferences.getInstance();
    if (_customJavaHome != null) {
      await prefs.setString(_javaHomeKey, _customJavaHome!);
    } else {
      await prefs.remove(_javaHomeKey);
    }
  }

  Future<void> loadJavaHome() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPath = prefs.getString(_javaHomeKey);
    if (savedPath != null) {
      _customJavaHome = savedPath;
    }

    final versionsJson = prefs.getString(_javaVersionsKey);
    if (versionsJson != null) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(versionsJson);
        _javaVersions = decoded.map(
          (key, value) => MapEntry(key, value.toString()),
        );
      } catch (e) {
        debugPrint('Failed to load Java versions: $e');
        _javaVersions = {};
      }
    }

    notifyListeners();
  }

  Future<void> saveJavaVersions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_javaVersionsKey, jsonEncode(_javaVersions));
  }

  String? get customJavaBinaryPath {
    if (_customJavaHome == null) return null;
    return p.join(
      _customJavaHome!,
      'bin',
      Platform.isWindows ? 'javaw.exe' : 'java',
    );
  }

  String? getJavaBinaryPath(String version) {
    final path = _javaVersions[version];
    if (path == null) return null;

    return p.join(path, 'bin', Platform.isWindows ? 'javaw.exe' : 'java');
  }

  Future<bool> addJavaPath(String path) async {
    if (!await Directory(path).exists()) {
      return false;
    }

    final javaBinaryPath = p.join(
      path,
      'bin',
      Platform.isWindows ? 'javaw.exe' : 'java',
    );

    final javaVersionDetails = await getJavaVersionDetails(javaBinaryPath);
    if (javaVersionDetails == null) {
      return false;
    }

    final version = javaVersionDetails['version'];
    final majorVersion = javaVersionDetails['majorVersion'];

    if (majorVersion < 8) {
      return false;
    }

    if (_javaVersions.containsKey(version)) {
      return false;
    }

    _javaVersions[version] = path;
    await saveJavaVersions();
    notifyListeners();
    return true;
  }

  Future<void> removeJavaVersion(String version) async {
    if (_javaVersions.containsKey(version)) {
      _javaVersions.remove(version);
      await saveJavaVersions();
      notifyListeners();
    }
  }

  Future<bool> checkJavaVersion(String? javaPath) async {
    if (javaPath == null) return false;

    try {
      final result = await Process.run(javaPath, [
        '-version',
      ], runInShell: true);
      final output = result.stderr as String;

      final versionMatch = RegExp(r'version "(.+?)"').firstMatch(output);
      if (versionMatch == null) return false;

      final version = versionMatch.group(1);
      if (version == null) return false;

      final majorVersion = _extractMajorVersion(version);
      if (majorVersion == null) return false;

      return majorVersion >= 8;
    } catch (e) {
      debugPrint('Java version check failed: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> getJavaVersionDetails(String javaPath) async {
    try {
      final result = await Process.run(javaPath, [
        '-version',
      ], runInShell: true);

      final output = result.stderr as String;

      final versionMatch = RegExp(r'version "(.+?)"').firstMatch(output);
      if (versionMatch == null) return null;

      final version = versionMatch.group(1);
      if (version == null) return null;

      final majorVersion = _extractMajorVersion(version);
      if (majorVersion == null) return null;

      return {
        'version': version,
        'majorVersion': majorVersion,
        'fullOutput': output,
      };
    } catch (e) {
      debugPrint('Java version check failed: $e');
      return null;
    }
  }

  int? _extractMajorVersion(String version) {
    final legacyMatch = RegExp(r'1\.(\d+)\.0').firstMatch(version);
    if (legacyMatch != null) {
      return int.tryParse(legacyMatch.group(1) ?? '');
    }

    final modernMatch = RegExp(r'(\d+)').firstMatch(version);
    return int.tryParse(modernMatch?.group(1) ?? '');
  }

  Map<String, String> getSavedJavaVersions() {
    return Map<String, String>.from(_javaVersions);
  }

  String? getJavaPath(String version) {
    return _javaVersions[version];
  }

  String? findJavaPathByMajorVersion(int majorVersion) {
    for (final entry in _javaVersions.entries) {
      final versionStr = entry.key;
      final majorMatch = RegExp(r'(\d+)').firstMatch(versionStr);
      if (majorMatch != null) {
        final version = int.tryParse(majorMatch.group(1) ?? '');
        if (version == majorVersion) {
          return entry.value;
        }
      }
    }

    return null;
  }

  Future<String?> findJavaPathByMajorVersionAsync(int majorVersion) async {
    for (final entry in _javaVersions.entries) {
      final javaBinaryPath = getJavaBinaryPath(entry.key);
      if (javaBinaryPath == null) continue;

      final details = await getJavaVersionDetails(javaBinaryPath);
      if (details != null && details['majorVersion'] == majorVersion) {
        return entry.value;
      }
    }

    return findJavaPathByMajorVersion(majorVersion);
  }

  List<String> getAvailableVersions() {
    return _javaVersions.keys.toList();
  }

  // メジャーバージョンでJavaバージョンをフィルタリングする
  List<String> filterVersionsByMajor(int majorVersion) {
    return _javaVersions.keys.where((version) {
      // バージョン文字列からメジャーバージョンを抽出
      final majorMatch = RegExp(r'(\d+)').firstMatch(version);
      if (majorMatch != null) {
        final versionNumber = int.tryParse(majorMatch.group(1) ?? '');
        return versionNumber == majorVersion;
      }
      return false;
    }).toList();
  }
  
  // バージョン文字列からメジャーバージョンを抽出する（静的メソッド）
  static int? extractMajorVersionFromString(String version) {
    final majorMatch = RegExp(r'(\d+)').firstMatch(version);
    return int.tryParse(majorMatch?.group(1) ?? '');
  }
}
