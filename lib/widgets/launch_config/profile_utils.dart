import 'package:karasu_launcher/models/launcher_profiles.dart';
import 'package:karasu_launcher/widgets/launch_config/profile_filter.dart';

class ProfileUtils {
  static bool isReleaseVersion(String version) {
    final releasePattern = RegExp(r'^\d+\.\d+(\.\d+)?$');
    return releasePattern.hasMatch(version);
  }

  static bool isSnapshotVersion(String version) {
    return version.contains('w') ||
        version.contains('pre') ||
        version.contains('snapshot');
  }

  static Map<String, Map<String, Profile>> separateProfiles(
    Map<String, Profile> profiles,
  ) {
    final defaultProfiles = <String, Profile>{};
    final customProfiles = <String, Profile>{};

    profiles.forEach((key, profile) {
      if (key == 'latest_release' || key == 'latest_snapshot') {
        defaultProfiles[key] = profile;
      } else {
        customProfiles[key] = profile;
      }
    });

    return {'default': defaultProfiles, 'custom': customProfiles};
  }

  static List<MapEntry<String, Profile>> filterProfiles(
    Map<String, Profile> profiles,
    bool showReleases,
    bool showSnapshots,
    bool showOldVersions,
  ) {
    return profiles.entries.where((entry) {
      final profile = entry.value;

      if (profile.lastVersionId != null) {
        final isRelease = isReleaseVersion(profile.lastVersionId!);
        final isSnapshot = isSnapshotVersion(profile.lastVersionId!);
        final isOldVersion = !isRelease && !isSnapshot;

        return (isRelease && showReleases) ||
            (isSnapshot && showSnapshots) ||
            (isOldVersion && showOldVersions);
      }

      return true;
    }).toList();
  }

  static void sortProfiles(
    List<MapEntry<String, Profile>> profiles,
    ProfileSortOption sortOption,
  ) {
    switch (sortOption) {
      case ProfileSortOption.lastPlayed:
        profiles.sort((a, b) {
          final aDate =
              DateTime.tryParse(a.value.lastUsed ?? '') ?? DateTime(1970);
          final bDate =
              DateTime.tryParse(b.value.lastUsed ?? '') ?? DateTime(1970);
          return bDate.compareTo(aDate);
        });
        break;
      case ProfileSortOption.created:
        profiles.sort((a, b) {
          final aDate =
              DateTime.tryParse(a.value.created ?? '') ?? DateTime(1970);
          final bDate =
              DateTime.tryParse(b.value.created ?? '') ?? DateTime(1970);
          return bDate.compareTo(aDate);
        });
        break;
      case ProfileSortOption.custom:
        profiles.sort((a, b) {
          final aOrder = a.value.order ?? 999999;
          final bOrder = b.value.order ?? 999999;
          return aOrder.compareTo(bOrder);
        });
        break;
    }
  }
}
