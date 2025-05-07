import 'package:flutter_riverpod/flutter_riverpod.dart';

class FilterNotifier<T> extends StateNotifier<T> {
  FilterNotifier(super.initialState);

  void updateFilter(T newState) {
    state = newState;
  }

  void updateFilterValue(String key, dynamic value) {
    if (state is ProfileFilterSettings) {
      final currentState = state as ProfileFilterSettings;
      state = _updateProfileFilterSettings(currentState, key, value) as T;
    }
  }

  ProfileFilterSettings _updateProfileFilterSettings(
    ProfileFilterSettings currentState,
    String key,
    dynamic value,
  ) {
    return switch (key) {
      'showReleases' => currentState.copyWith(showReleases: value as bool),
      'showSnapshots' => currentState.copyWith(showSnapshots: value as bool),
      'showOldVersions' => currentState.copyWith(
        showOldVersions: value as bool,
      ),
      'showModProfiles' => currentState.copyWith(
        showModProfiles: value as bool,
      ),
      'showVanillaProfiles' => currentState.copyWith(
        showVanillaProfiles: value as bool,
      ),
      'showFabricProfiles' => currentState.copyWith(
        showFabricProfiles: value as bool,
      ),
      'showForgeProfiles' => currentState.copyWith(
        showForgeProfiles: value as bool,
      ),
      'showNeoForgeProfiles' => currentState.copyWith(
        showNeoForgeProfiles: value as bool,
      ),
      'showQuiltProfiles' => currentState.copyWith(
        showQuiltProfiles: value as bool,
      ),
      'showLiteLoaderProfiles' => currentState.copyWith(
        showLiteLoaderProfiles: value as bool,
      ),
      _ => currentState,
    };
  }
}

class ProfileFilterSettings {
  final bool showReleases;
  final bool showSnapshots;
  final bool showOldVersions;
  final bool showModProfiles;
  final bool showVanillaProfiles;

  final bool? showFabricProfiles;
  final bool? showForgeProfiles;
  final bool? showNeoForgeProfiles;
  final bool? showQuiltProfiles;
  final bool? showLiteLoaderProfiles;

  ProfileFilterSettings({
    this.showReleases = true,
    this.showSnapshots = false,
    this.showOldVersions = false,
    this.showModProfiles = false,
    this.showVanillaProfiles = true,
    this.showFabricProfiles = false,
    this.showForgeProfiles = false,
    this.showNeoForgeProfiles = false,
    this.showQuiltProfiles = false,
    this.showLiteLoaderProfiles = false,
  });

  ProfileFilterSettings fromMap(Map<String, dynamic> map) {
    return ProfileFilterSettings(
      showReleases: map['showReleases'] ?? showReleases,
      showSnapshots: map['showSnapshots'] ?? showSnapshots,
      showOldVersions: map['showOldVersions'] ?? showOldVersions,
      showModProfiles: map['showModProfiles'] ?? showModProfiles,
      showVanillaProfiles: map['showVanillaProfiles'] ?? showVanillaProfiles,
      showFabricProfiles: map['showFabricProfiles'] ?? showFabricProfiles,
      showForgeProfiles: map['showForgeProfiles'] ?? showForgeProfiles,
      showNeoForgeProfiles: map['showNeoForgeProfiles'] ?? showNeoForgeProfiles,
      showQuiltProfiles: map['showQuiltProfiles'] ?? showQuiltProfiles,
      showLiteLoaderProfiles:
          map['showLiteLoaderProfiles'] ?? showLiteLoaderProfiles,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'showReleases': showReleases,
      'showSnapshots': showSnapshots,
      'showOldVersions': showOldVersions,
      'showModProfiles': showModProfiles,
      'showVanillaProfiles': showVanillaProfiles,
      'showFabricProfiles': showFabricProfiles,
      'showForgeProfiles': showForgeProfiles,
      'showNeoForgeProfiles': showNeoForgeProfiles,
      'showQuiltProfiles': showQuiltProfiles,
      'showLiteLoaderProfiles': showLiteLoaderProfiles,
    };
  }

  ProfileFilterSettings copyWith({
    bool? showReleases,
    bool? showSnapshots,
    bool? showOldVersions,
    bool? showModProfiles,
    bool? showVanillaProfiles,
    bool? showFabricProfiles,
    bool? showForgeProfiles,
    bool? showNeoForgeProfiles,
    bool? showQuiltProfiles,
    bool? showLiteLoaderProfiles,
  }) {
    return ProfileFilterSettings(
      showReleases: showReleases ?? this.showReleases,
      showSnapshots: showSnapshots ?? this.showSnapshots,
      showOldVersions: showOldVersions ?? this.showOldVersions,
      showModProfiles: showModProfiles ?? this.showModProfiles,
      showVanillaProfiles: showVanillaProfiles ?? this.showVanillaProfiles,
      showFabricProfiles: showFabricProfiles ?? this.showFabricProfiles,
      showForgeProfiles: showForgeProfiles ?? this.showForgeProfiles,
      showNeoForgeProfiles: showNeoForgeProfiles ?? this.showNeoForgeProfiles,
      showQuiltProfiles: showQuiltProfiles ?? this.showQuiltProfiles,
      showLiteLoaderProfiles:
          showLiteLoaderProfiles ?? this.showLiteLoaderProfiles,
    );
  }
}

final profileFilterProvider = StateNotifierProvider<
  FilterNotifier<ProfileFilterSettings>,
  ProfileFilterSettings
>((ref) {
  return FilterNotifier<ProfileFilterSettings>(
    ProfileFilterSettings(
      showReleases: true,
      showSnapshots: true,
      showOldVersions: true,
      showModProfiles: true,
      showVanillaProfiles: true,
    ),
  );
});
