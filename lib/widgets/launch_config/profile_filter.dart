import 'package:flutter/material.dart';
import 'package:karasu_launcher/widgets/custom_drop_down.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

enum ProfileSortOption { custom, lastPlayed, created }

class ProfileFilter extends StatelessWidget {
  final bool showReleases;
  final bool showSnapshots;
  final bool showOldVersions;
  final ValueChanged<bool> onReleasesChanged;
  final ValueChanged<bool> onSnapshotsChanged;
  final ValueChanged<bool> onOldVersionsChanged;

  const ProfileFilter({
    super.key,
    required this.showReleases,
    required this.showSnapshots,
    required this.showOldVersions,
    required this.onReleasesChanged,
    required this.onSnapshotsChanged,
    required this.onOldVersionsChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 20,
      children: [
        _buildCheckbox(
          value: showReleases,
          onChanged: onReleasesChanged,
          label: FlutterI18n.translate(context, 'profileFilter.showReleases'),
        ),
        _buildCheckbox(
          value: showSnapshots,
          onChanged: onSnapshotsChanged,
          label: FlutterI18n.translate(context, 'profileFilter.showSnapshots'),
        ),
        _buildCheckbox(
          value: showOldVersions,
          onChanged: onOldVersionsChanged,
          label: FlutterI18n.translate(
            context,
            'profileFilter.showOldVersions',
          ),
        ),
      ],
    );
  }

  Widget _buildCheckbox({
    required bool value,
    required ValueChanged<bool> onChanged,
    required String label,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Checkbox(
          value: value,
          onChanged: (newValue) => onChanged(newValue ?? value),
        ),
        Text(label),
      ],
    );
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
