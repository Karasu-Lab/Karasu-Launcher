import 'dart:convert';
import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:karasu_launcher/models/launcher_profiles.dart';
import 'package:karasu_launcher/models/launcher_versions_v2.dart';
import 'package:karasu_launcher/utils/file_utils.dart';

final profilesProvider =
    StateNotifierProvider<ProfilesNotifier, LauncherProfiles?>((ref) {
      return ProfilesNotifier();
    });

final selectedProfileProvider = StateProvider<String?>((ref) => null);

// プロファイル読み込み完了を管理するプロバイダー
final profilesInitializedProvider = FutureProvider<LauncherProfiles?>((
  ref,
) async {
  final profilesNotifier = ref.read(profilesProvider.notifier);
  return await profilesNotifier.initialized;
});

// プロファイル読み込み状態を追跡するプロバイダー
final profilesLoadingProvider = Provider<bool>((ref) {
  final asyncValue = ref.watch(profilesInitializedProvider);
  return asyncValue.isLoading;
});

// バージョン情報を取得するプロバイダー
final versionsProvider = FutureProvider<LauncherVersionsV2?>((ref) async {
  return await fetchVersionManifest();
});

// バージョンリストを取得するプロバイダー
final availableVersionsProvider = FutureProvider<List<MinecraftVersion>>((
  ref,
) async {
  final versionsData = await ref.watch(versionsProvider.future);
  if (versionsData == null) {
    return [];
  }
  return versionsData.versions;
});

// リリースバージョンのみを取得するプロバイダー
final releaseVersionsProvider = FutureProvider<List<MinecraftVersion>>((
  ref,
) async {
  final versions = await ref.watch(availableVersionsProvider.future);
  return versions.where((version) => version.type == 'release').toList();
});

// スナップショットバージョンのみを取得するプロバイダー
final snapshotVersionsProvider = FutureProvider<List<MinecraftVersion>>((
  ref,
) async {
  final versions = await ref.watch(availableVersionsProvider.future);
  return versions.where((version) => version.type == 'snapshot').toList();
});

// 最新バージョン情報を取得するプロバイダー
final latestVersionsProvider = FutureProvider<Map<String, String>>((ref) async {
  final versionsData = await ref.watch(versionsProvider.future);
  if (versionsData == null) {
    return {'release': 'unknown', 'snapshot': 'unknown'};
  }
  return {
    'release': versionsData.latest.release,
    'snapshot': versionsData.latest.snapshot,
  };
});

Future<LauncherVersionsV2?> fetchVersionManifest() async {
  try {
    final response = await http.get(
      Uri.parse(
        'https://piston-meta.mojang.com/mc/game/version_manifest_v2.json',
      ),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return LauncherVersionsV2.fromJson(data);
    } else {
      debugPrint('バージョン情報の取得に失敗しました: ${response.statusCode}');
      return null;
    }
  } catch (e) {
    debugPrint('バージョンマニフェスト取得エラー: $e');
    return null;
  }
}

class ProfilesNotifier extends StateNotifier<LauncherProfiles?> {
  // コンストラクタでは初期化処理を行わないように変更
  ProfilesNotifier() : super(null);

  // プロファイル読み込み中フラグ
  bool _isLoading = false;
  // 初期化完了フラグ
  bool _isInitialized = false;
  // プロファイル読み込みの完了を待つためのCompleter
  Completer<LauncherProfiles?>? _initCompleter;

  // プロファイルが初期化されているかどうかを返す
  bool get isInitialized => _isInitialized;

  // プロファイルの読み込みが完了するまで待つFutureを返す
  Future<LauncherProfiles?> get initialized async {
    if (_isInitialized) {
      return state;
    }

    if (_isLoading) {
      // 既に読み込み中の場合は、そのCompleterの完了を待つ
      return await _initCompleter!.future;
    }

    // 初めて呼び出された場合は、読み込みを開始
    return await loadProfiles();
  }

  // プロファイルを読み込む
  Future<LauncherProfiles?> loadProfiles() async {
    if (_isInitialized) {
      return state;
    }

    if (_isLoading) {
      // 既に読み込み中の場合は、そのCompleterの完了を待つ
      return await _initCompleter!.future;
    }

    _isLoading = true;
    _initCompleter = Completer<LauncherProfiles?>();

    try {
      await _loadProfiles();
      _isInitialized = true;
      _initCompleter!.complete(state);
    } catch (e) {
      debugPrint('プロファイルのロードに失敗しました: $e');
      _initCompleter!.completeError(e);
    } finally {
      _isLoading = false;
    }

    return state;
  }

  Future<void> _loadProfiles() async {
    try {
      final profilesPath = await getLauncherProfilesJsonPath();
      final file = File(profilesPath);

      final versionsData = await fetchVersionManifest();

      if (!await file.exists()) {
        await _createDefaultProfiles(versionsData);
        return;
      }

      final jsonString = await file.readAsString();
      final json = jsonDecode(jsonString) as Map<String, dynamic>;

      state = LauncherProfiles.fromJson(json);
      await _ensureDefaultProfiles(versionsData);
    } catch (e) {
      debugPrint('プロファイルのロードに失敗しました: $e');
      await _createDefaultProfiles(null);
    }
  }

  Future<void> _createDefaultProfiles([
    LauncherVersionsV2? versionsData,
  ]) async {
    final String latestRelease =
        versionsData?.latest.release ?? 'latest-release';
    final String latestSnapshot =
        versionsData?.latest.snapshot ?? 'latest-snapshot';

    final defaultReleaseProfile = Profile(
      name: 'Latest Release',
      type: 'latest-release',
      created: DateTime.now().toIso8601String(),
      lastUsed: DateTime.now().toIso8601String(),
      lastVersionId: latestRelease,
    );

    final defaultSnapshotProfile = Profile(
      name: 'Latest Snapshot',
      type: 'latest-snapshot',
      created: DateTime.now().toIso8601String(),
      lastUsed: DateTime.now().toIso8601String(),
      lastVersionId: latestSnapshot,
    );

    final defaultSettings = Settings(
      crashAssistance: true,
      enableAdvanced: false,
      enableAnalytics: true,
      enableReleases: true,
      enableSnapshots: true,
      keepLauncherOpen: false,
      profileSorting: 'byLastPlayed',
      showGameLog: false,
      showMenu: true,
      soundOn: true,
    );

    final launcherProfiles = LauncherProfiles(
      profiles: {
        'latest_release': defaultReleaseProfile,
        'latest_snapshot': defaultSnapshotProfile,
      },
      settings: defaultSettings,
      version: 3,
    );

    state = launcherProfiles;

    await _saveProfiles();
  }

  Future<void> _ensureDefaultProfiles(LauncherVersionsV2? versionsData) async {
    if (state == null || versionsData == null) return;

    bool needsUpdate = false;
    final updatedProfiles = Map<String, Profile>.from(state!.profiles);

    // 最新リリースプロファイルの確認と更新
    final latestReleaseProfile = updatedProfiles['latest_release'];
    if (latestReleaseProfile == null) {
      // 存在しない場合は作成
      updatedProfiles['latest_release'] = Profile(
        name: 'Latest Release',
        type: 'latest-release',
        created: DateTime.now().toIso8601String(),
        lastUsed: DateTime.now().toIso8601String(),
        lastVersionId: versionsData.latest.release,
      );
      needsUpdate = true;
    } else if (latestReleaseProfile.lastVersionId !=
        versionsData.latest.release) {
      // バージョンが古い場合は更新
      updatedProfiles['latest_release'] = Profile(
        name: latestReleaseProfile.name,
        type: latestReleaseProfile.type,
        created: latestReleaseProfile.created,
        lastUsed: latestReleaseProfile.lastUsed,
        lastVersionId: versionsData.latest.release,
        gameDir: latestReleaseProfile.gameDir,
        icon: latestReleaseProfile.icon,
        javaArgs: latestReleaseProfile.javaArgs,
        javaDir: latestReleaseProfile.javaDir,
        skipJreVersionCheck: latestReleaseProfile.skipJreVersionCheck,
      );
      needsUpdate = true;
    }

    // 最新スナップショットプロファイルの確認と更新
    final latestSnapshotProfile = updatedProfiles['latest_snapshot'];
    if (latestSnapshotProfile == null) {
      // 存在しない場合は作成
      updatedProfiles['latest_snapshot'] = Profile(
        name: 'Latest Snapshot',
        type: 'latest-snapshot',
        created: DateTime.now().toIso8601String(),
        lastUsed: DateTime.now().toIso8601String(),
        lastVersionId: versionsData.latest.snapshot,
      );
      needsUpdate = true;
    } else if (latestSnapshotProfile.lastVersionId !=
        versionsData.latest.snapshot) {
      // バージョンが古い場合は更新
      updatedProfiles['latest_snapshot'] = Profile(
        name: latestSnapshotProfile.name,
        type: latestSnapshotProfile.type,
        created: latestSnapshotProfile.created,
        lastUsed: latestSnapshotProfile.lastUsed,
        lastVersionId: versionsData.latest.snapshot,
        gameDir: latestSnapshotProfile.gameDir,
        icon: latestSnapshotProfile.icon,
        javaArgs: latestSnapshotProfile.javaArgs,
        javaDir: latestSnapshotProfile.javaDir,
        skipJreVersionCheck: latestSnapshotProfile.skipJreVersionCheck,
      );
      needsUpdate = true;
    }

    if (needsUpdate) {
      state = LauncherProfiles(
        profiles: updatedProfiles,
        settings: state!.settings,
        version: state!.version,
      );
      await _saveProfiles();
    }
  }

  Future<void> _saveProfiles() async {
    try {
      if (state == null) return;

      final profilesPath = await getLauncherProfilesJsonPath();
      final file = File(profilesPath);
      final jsonString = const JsonEncoder.withIndent(
        '  ',
      ).convert(state!.toJson());

      await file.writeAsString(jsonString);
    } catch (e) {
      debugPrint('プロファイルの保存に失敗しました: $e');
    }
  }

  Future<void> addOrUpdateProfile(String id, Profile profile) async {
    if (state == null) await _loadProfiles();
    if (state == null) return;
    final updatedProfiles = Map<String, Profile>.from(state!.profiles);
    updatedProfiles[id] = profile;

    state = LauncherProfiles(
      profiles: updatedProfiles,
      settings: state!.settings,
      version: state!.version,
    );
    await _saveProfiles();
  }

  Future<void> removeProfile(String id) async {
    if (state == null) return;

    // デフォルトプロファイルは削除できないようにする
    if (id == 'latest_release' || id == 'latest_snapshot') {
      debugPrint('デフォルトプロファイルは削除できません');
      return;
    }

    if (state!.profiles.length <= 2) {
      debugPrint('少なくとも2つのデフォルトプロファイルは必要です');
      return;
    }

    final updatedProfiles = Map<String, Profile>.from(state!.profiles);
    updatedProfiles.remove(id);

    state = LauncherProfiles(
      profiles: updatedProfiles,
      settings: state!.settings,
      version: state!.version,
    );

    await _saveProfiles();
  }

  // プロファイルのソート設定を保存
  Future<void> updateProfileSorting(String sortingType) async {
    if (state == null) return;

    final updatedSettings = Settings(
      crashAssistance: state!.settings.crashAssistance,
      enableAdvanced: state!.settings.enableAdvanced,
      enableAnalytics: state!.settings.enableAnalytics,
      enableReleases: state!.settings.enableReleases,
      enableSnapshots: state!.settings.enableSnapshots,
      keepLauncherOpen: state!.settings.keepLauncherOpen,
      profileSorting: sortingType, // ソート設定を更新
      showGameLog: state!.settings.showGameLog,
      showMenu: state!.settings.showMenu,
      soundOn: state!.settings.soundOn,
    );

    state = LauncherProfiles(
      profiles: state!.profiles,
      settings: updatedSettings,
      version: state!.version,
    );

    await _saveProfiles();
  }

  // カスタムプロファイル並び順を保存
  Future<void> saveProfileOrder(List<String> orderedProfileIds) async {
    if (state == null) return;

    // 各プロファイルにorderプロパティを追加して保存
    final updatedProfiles = Map<String, Profile>.from(state!.profiles);

    for (int i = 0; i < orderedProfileIds.length; i++) {
      final profileId = orderedProfileIds[i];
      if (updatedProfiles.containsKey(profileId)) {
        final profile = updatedProfiles[profileId]!;
        // 現在のプロファイルの値を保持したまま、order属性のみ更新
        updatedProfiles[profileId] = Profile(
          name: profile.name,
          type: profile.type,
          created: profile.created,
          lastUsed: profile.lastUsed,
          lastVersionId: profile.lastVersionId,
          gameDir: profile.gameDir,
          javaArgs: profile.javaArgs,
          javaDir: profile.javaDir,
          icon: profile.icon,
          skipJreVersionCheck: profile.skipJreVersionCheck,
          order: i, // 並び順を設定
        );
      }
    }

    state = LauncherProfiles(
      profiles: updatedProfiles,
      settings: state!.settings,
      version: state!.version,
    );

    await _saveProfiles();
  }

  Future<void> updateSettings(Settings settings) async {
    if (state == null) return;

    state = LauncherProfiles(
      profiles: state!.profiles,
      settings: settings,
      version: state!.version,
    );

    await _saveProfiles();
  }

  Future<void> updateProfileLastUsed(String id) async {
    if (state == null || !state!.profiles.containsKey(id)) return;

    final profile = state!.profiles[id]!;

    final updatedProfile = Profile(
      name: profile.name,
      type: profile.type,
      created: profile.created,
      gameDir: profile.gameDir,
      icon: profile.icon,
      javaArgs: profile.javaArgs,
      javaDir: profile.javaDir,
      lastVersionId: profile.lastVersionId,
      lastUsed: DateTime.now().toIso8601String(),
      skipJreVersionCheck: profile.skipJreVersionCheck,
    );

    await addOrUpdateProfile(id, updatedProfile);
  }

  Future<LauncherProfiles?> reloadProfiles() async {
    debugPrint('プロファイルの再読み込みを開始します');
    // 初期化状態をリセット
    _isInitialized = false;
    _isLoading = false;
    // 再度読み込み処理を呼び出す
    return await loadProfiles();
  }
}
