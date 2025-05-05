import 'dart:convert';
import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:karasu_launcher/models/launcher_profiles.dart';
import 'package:karasu_launcher/models/launcher_versions_v2.dart';
import 'package:karasu_launcher/models/mod_loader.dart';
import 'package:karasu_launcher/utils/file_utils.dart';
import 'package:uuid/uuid.dart';

final profilesProvider =
    StateNotifierProvider<ProfilesNotifier, LauncherProfiles?>((ref) {
      return ProfilesNotifier();
    });

final selectedProfileProvider = StateProvider<String?>((ref) => null);

final profilesInitializedProvider = FutureProvider<LauncherProfiles?>((
  ref,
) async {
  final profilesNotifier = ref.read(profilesProvider.notifier);
  return await profilesNotifier.initialized;
});

final profilesLoadingProvider = Provider<bool>((ref) {
  final asyncValue = ref.watch(profilesInitializedProvider);
  return asyncValue.isLoading;
});

final versionsProvider = FutureProvider<LauncherVersionsV2?>((ref) async {
  final manifestData = await fetchVersionManifest();

  // ローカルのMODローダーバージョンを取得
  final localVersions = await loadLocalVersions();

  // オンラインとローカルのバージョンを結合
  if (manifestData != null && localVersions.isNotEmpty) {
    return manifestData.mergeWithLocalVersions(localVersions);
  }

  return manifestData;
});

final availableVersionsProvider = FutureProvider<List<MinecraftVersion>>((
  ref,
) async {
  final versionsData = await ref.watch(versionsProvider.future);
  if (versionsData == null) {
    return [];
  }
  return versionsData.versions;
});

final releaseVersionsProvider = FutureProvider<List<MinecraftVersion>>((
  ref,
) async {
  final versions = await ref.watch(availableVersionsProvider.future);
  return versions.where((version) => version.type == 'release').toList();
});

final snapshotVersionsProvider = FutureProvider<List<MinecraftVersion>>((
  ref,
) async {
  final versions = await ref.watch(availableVersionsProvider.future);
  return versions.where((version) => version.type == 'snapshot').toList();
});

final modVersionsProvider = FutureProvider<List<MinecraftVersion>>((ref) async {
  final versions = await ref.watch(availableVersionsProvider.future);
  return versions.where((version) => version.modLoader != null).toList();
});

final fabricVersionsProvider = FutureProvider<List<MinecraftVersion>>((
  ref,
) async {
  final versions = await ref.watch(modVersionsProvider.future);
  return versions
      .where((version) => version.modLoader?.type == ModLoaderType.fabric)
      .toList();
});

final forgeVersionsProvider = FutureProvider<List<MinecraftVersion>>((
  ref,
) async {
  final versions = await ref.watch(modVersionsProvider.future);
  return versions
      .where((version) => version.modLoader?.type == ModLoaderType.forge)
      .toList();
});

final quiltVersionsProvider = FutureProvider<List<MinecraftVersion>>((
  ref,
) async {
  final versions = await ref.watch(modVersionsProvider.future);
  return versions
      .where((version) => version.modLoader?.type == ModLoaderType.quilt)
      .toList();
});

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
      debugPrint('Failed to fetch version information: ${response.statusCode}');
      return null;
    }
  } catch (e) {
    debugPrint('Error fetching version manifest: $e');
    return null;
  }
}

class ProfilesNotifier extends StateNotifier<LauncherProfiles?> {
  ProfilesNotifier() : super(null);

  bool _isLoading = false;
  bool _isInitialized = false;
  Completer<LauncherProfiles?>? _initCompleter;

  bool get isInitialized => _isInitialized;

  Future<LauncherProfiles?> get initialized async {
    if (_isInitialized) {
      return state;
    }

    if (_isLoading) {
      return await _initCompleter!.future;
    }

    return await loadProfiles();
  }

  Future<LauncherProfiles?> loadProfiles() async {
    if (_isInitialized) {
      return state;
    }

    if (_isLoading) {
      return await _initCompleter!.future;
    }

    _isLoading = true;
    _initCompleter = Completer<LauncherProfiles?>();

    try {
      await _loadProfiles();
      _isInitialized = true;
      _initCompleter!.complete(state);
    } catch (e) {
      debugPrint('Failed to load profiles: $e');
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

      bool hasNullIds = false;
      final updatedProfiles = Map<String, Profile>.from(state!.profiles);

      updatedProfiles.forEach((profileId, profile) {
        if (profile.id == null) {
          updatedProfiles[profileId] = Profile(
            id: const Uuid().v4(),
            name: profile.name,
            type: profile.type,
            created: profile.created,
            lastUsed: profile.lastUsed,
            lastVersionId: profile.lastVersionId,
            gameDir: profile.gameDir,
            icon: profile.icon,
            javaArgs: profile.javaArgs,
            javaDir: profile.javaDir,
            skipJreVersionCheck: profile.skipJreVersionCheck,
            order: profile.order,
          );
          hasNullIds = true;
        }
      });

      if (hasNullIds) {
        debugPrint('Assigned UUIDs to profiles with null ids');
        state = LauncherProfiles(
          profiles: updatedProfiles,
          settings: state!.settings,
          version: state!.version,
        );
        await _saveProfiles();
      }

      await _ensureDefaultProfiles(versionsData);
    } catch (e) {
      debugPrint('Failed to load profiles: $e');
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
      id: const Uuid().v4(),
      name: 'Latest Release',
      type: 'latest-release',
      created: DateTime.now().toIso8601String(),
      lastUsed: DateTime.now().toIso8601String(),
      lastVersionId: latestRelease,
    );

    final defaultSnapshotProfile = Profile(
      id: const Uuid().v4(),
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

    final latestReleaseProfile = updatedProfiles['latest_release'];
    if (latestReleaseProfile == null) {
      updatedProfiles['latest_release'] = Profile(
        id: const Uuid().v4(),
        name: 'Latest Release',
        type: 'latest-release',
        created: DateTime.now().toIso8601String(),
        lastUsed: DateTime.now().toIso8601String(),
        lastVersionId: versionsData.latest.release,
      );
      needsUpdate = true;
    } else if (latestReleaseProfile.lastVersionId !=
        versionsData.latest.release) {
      updatedProfiles['latest_release'] = Profile(
        id: latestReleaseProfile.id,
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
        order: latestReleaseProfile.order,
      );
      needsUpdate = true;
    }

    final latestSnapshotProfile = updatedProfiles['latest_snapshot'];
    if (latestSnapshotProfile == null) {
      updatedProfiles['latest_snapshot'] = Profile(
        id: const Uuid().v4(),
        name: 'Latest Snapshot',
        type: 'latest-snapshot',
        created: DateTime.now().toIso8601String(),
        lastUsed: DateTime.now().toIso8601String(),
        lastVersionId: versionsData.latest.snapshot,
      );
      needsUpdate = true;
    } else if (latestSnapshotProfile.lastVersionId !=
        versionsData.latest.snapshot) {
      updatedProfiles['latest_snapshot'] = Profile(
        id: latestSnapshotProfile.id,
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
        order: latestSnapshotProfile.order,
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
      debugPrint('Failed to save profiles: $e');
    }
  }

  Future<void> addOrUpdateProfile(String id, Profile profile) async {
    if (state == null) await _loadProfiles();
    if (state == null) return;

    final updatedProfiles = Map<String, Profile>.from(state!.profiles);

    final profileWithId =
        profile.id == null
            ? Profile(
              id: const Uuid().v4(),
              name: profile.name,
              type: profile.type,
              created: profile.created,
              lastUsed: profile.lastUsed,
              lastVersionId: profile.lastVersionId,
              gameDir: profile.gameDir,
              icon: profile.icon,
              javaArgs: profile.javaArgs,
              javaDir: profile.javaDir,
              skipJreVersionCheck: profile.skipJreVersionCheck,
              order: profile.order,
            )
            : profile;

    updatedProfiles[id] = profileWithId;

    state = LauncherProfiles(
      profiles: updatedProfiles,
      settings: state!.settings,
      version: state!.version,
    );
    await _saveProfiles();
  }

  Future<void> removeProfile(String id) async {
    if (state == null) return;

    if (id == 'latest_release' || id == 'latest_snapshot') {
      debugPrint('Default profiles cannot be deleted');
      return;
    }

    if (state!.profiles.length <= 2) {
      debugPrint('At least two default profiles are required');
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

  Future<void> updateProfileSorting(String sortingType) async {
    if (state == null) return;

    final updatedSettings = Settings(
      crashAssistance: state!.settings.crashAssistance,
      enableAdvanced: state!.settings.enableAdvanced,
      enableAnalytics: state!.settings.enableAnalytics,
      enableReleases: state!.settings.enableReleases,
      enableSnapshots: state!.settings.enableSnapshots,
      keepLauncherOpen: state!.settings.keepLauncherOpen,
      profileSorting: sortingType,
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

  Future<void> saveProfileOrder(List<String> orderedProfileIds) async {
    if (state == null) return;

    final updatedProfiles = Map<String, Profile>.from(state!.profiles);

    for (int i = 0; i < orderedProfileIds.length; i++) {
      final profileId = orderedProfileIds[i];
      if (updatedProfiles.containsKey(profileId)) {
        final profile = updatedProfiles[profileId]!;
        updatedProfiles[profileId] = Profile(
          id: profile.id,
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
          order: i,
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
      id: profile.id,
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
      order: profile.order,
    );

    await addOrUpdateProfile(id, updatedProfile);
  }

  Future<LauncherProfiles?> reloadProfiles() async {
    debugPrint('Starting profile reload');
    _isInitialized = false;
    _isLoading = false;
    return await loadProfiles();
  }
}
