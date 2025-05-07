import 'package:flutter/material.dart';
import 'package:karasu_launcher/widgets/custom_drop_down.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

enum ProfileSortOption { custom, lastPlayed, created }

class ProfileFilter extends StatelessWidget {
  final bool showReleases;
  final bool showSnapshots;
  final bool showOldVersions;
  final bool showModProfiles;
  final bool showVanillaProfiles;

  final bool showFabricProfiles;
  final bool showForgeProfiles;
  final bool showNeoForgeProfiles;
  final bool showQuiltProfiles;
  final bool showLiteLoaderProfiles;
  final ValueChanged<bool> onReleasesChanged;
  final ValueChanged<bool> onSnapshotsChanged;
  final ValueChanged<bool> onOldVersionsChanged;
  final ValueChanged<bool>? onModProfilesChanged;
  final ValueChanged<bool>? onVanillaProfilesChanged;

  final ValueChanged<bool>? onFabricProfilesChanged;
  final ValueChanged<bool>? onForgeProfilesChanged;
  final ValueChanged<bool>? onNeoForgeProfilesChanged;
  final ValueChanged<bool>? onQuiltProfilesChanged;
  final ValueChanged<bool>? onLiteLoaderProfilesChanged;

  const ProfileFilter({
    super.key,
    required this.showReleases,
    required this.showSnapshots,
    required this.showOldVersions,
    this.showModProfiles = false,
    this.showVanillaProfiles = true,
    this.showFabricProfiles = false,
    this.showForgeProfiles = false,
    this.showNeoForgeProfiles = false,
    this.showQuiltProfiles = false,
    this.showLiteLoaderProfiles = false,
    required this.onReleasesChanged,
    required this.onSnapshotsChanged,
    required this.onOldVersionsChanged,
    this.onModProfilesChanged,
    this.onVanillaProfilesChanged,
    this.onFabricProfilesChanged,
    this.onForgeProfilesChanged,
    this.onNeoForgeProfilesChanged,
    this.onQuiltProfilesChanged,
    this.onLiteLoaderProfilesChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          children: [
            FilterChip(
              label: Text(
                FlutterI18n.translate(context, 'profileFilter.showReleases'),
              ),
              selected: showReleases,
              onSelected: _handleReleasesChanged,
            ),
            FilterChip(
              label: Text(
                FlutterI18n.translate(context, 'profileFilter.showSnapshots'),
              ),
              selected: showSnapshots,
              onSelected: _handleSnapshotsChanged,
            ),
            FilterChip(
              label: Text(
                FlutterI18n.translate(context, 'profileFilter.showOldVersions'),
              ),
              selected: showOldVersions,
              onSelected: onOldVersionsChanged,
            ),
            if (onModProfilesChanged != null)
              FilterChip(
                label: Text(
                  FlutterI18n.translate(
                    context,
                    'profileFilter.showModProfiles',
                  ),
                ),
                selected: showModProfiles,
                onSelected: _handleModProfilesChanged,
              ),
            if (onVanillaProfilesChanged != null)
              FilterChip(
                label: Text(
                  FlutterI18n.translate(
                    context,
                    'profileFilter.showVanillaProfiles',
                  ),
                ),
                selected: showVanillaProfiles,
                onSelected: _handleVanillaProfilesChanged,
              ),
          ],
        ),
        if (showModProfiles && onModProfilesChanged != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: [
                if (onFabricProfilesChanged != null)
                  FilterChip(
                    label: const Text("Fabric"),
                    selected: showFabricProfiles,
                    onSelected: onFabricProfilesChanged,
                  ),
                if (onForgeProfilesChanged != null)
                  FilterChip(
                    label: const Text("Forge"),
                    selected: showForgeProfiles,
                    onSelected: onForgeProfilesChanged,
                  ),
                if (onNeoForgeProfilesChanged != null)
                  FilterChip(
                    label: const Text("NeoForge"),
                    selected: showNeoForgeProfiles,
                    onSelected: onNeoForgeProfilesChanged,
                  ),
                if (onQuiltProfilesChanged != null)
                  FilterChip(
                    label: const Text("Quilt"),
                    selected: showQuiltProfiles,
                    onSelected: onQuiltProfilesChanged,
                  ),
                if (onLiteLoaderProfilesChanged != null)
                  FilterChip(
                    label: const Text("LiteLoader"),
                    selected: showLiteLoaderProfiles,
                    onSelected: onLiteLoaderProfilesChanged,
                  ),
              ],
            ),
          ),
      ],
    );
  }

  void _handleReleasesChanged(bool value) {
    onReleasesChanged(value);

    if (value && onVanillaProfilesChanged != null && !showVanillaProfiles) {
      onVanillaProfilesChanged!(true);
    }

    if (!value &&
        !showSnapshots &&
        onVanillaProfilesChanged != null &&
        showVanillaProfiles) {
      onVanillaProfilesChanged!(false);
    }
  }

  void _handleSnapshotsChanged(bool value) {
    onSnapshotsChanged(value);

    if (value && onVanillaProfilesChanged != null && !showVanillaProfiles) {
      onVanillaProfilesChanged!(true);
    }

    if (!value &&
        !showReleases &&
        onVanillaProfilesChanged != null &&
        showVanillaProfiles) {
      onVanillaProfilesChanged!(false);
    }
  }

  void _handleVanillaProfilesChanged(bool value) {
    if (onVanillaProfilesChanged != null) {
      onVanillaProfilesChanged!(value);

      if (value && !showReleases) {
        onReleasesChanged(true);
      }

      if (!value) {
        if (showReleases) onReleasesChanged(false);
        if (showSnapshots) onSnapshotsChanged(false);
      }
    }
  }

  void _handleModProfilesChanged(bool value) {
    if (onModProfilesChanged != null) {
      onModProfilesChanged!(value);

      if (!value) {
        _resetAllLoaderFilters();
      }
    }
  }

  void _resetAllLoaderFilters() {
    if (onFabricProfilesChanged != null && showFabricProfiles) {
      onFabricProfilesChanged!(false);
    }
    if (onForgeProfilesChanged != null && showForgeProfiles) {
      onForgeProfilesChanged!(false);
    }
    if (onNeoForgeProfilesChanged != null && showNeoForgeProfiles) {
      onNeoForgeProfilesChanged!(false);
    }
    if (onQuiltProfilesChanged != null && showQuiltProfiles) {
      onQuiltProfilesChanged!(false);
    }
    if (onLiteLoaderProfilesChanged != null && showLiteLoaderProfiles) {
      onLiteLoaderProfilesChanged!(false);
    }
  }
}

class ProfileSortSelector extends StatelessWidget {
  final ProfileSortOption sortOption;
  final ValueChanged<ProfileSortOption?> onSortChanged;

  const ProfileSortSelector({
    super.key,
    required this.sortOption,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    return CustomDropdown<ProfileSortOption>(
      value: sortOption,
      items: [
        DropdownMenuItem(
          value: ProfileSortOption.custom,
          child: Text(
            FlutterI18n.translate(context, 'profileSortSelector.customOrder'),
          ),
        ),
        DropdownMenuItem(
          value: ProfileSortOption.lastPlayed,
          child: Text(
            FlutterI18n.translate(
              context,
              'profileSortSelector.lastPlayedOrder',
            ),
          ),
        ),
        DropdownMenuItem(
          value: ProfileSortOption.created,
          child: Text(
            FlutterI18n.translate(context, 'profileSortSelector.creationOrder'),
          ),
        ),
      ],
      onChanged: onSortChanged,
    );
  }
}
