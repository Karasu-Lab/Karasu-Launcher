import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:karasu_launcher/models/launcher_profiles.dart';
import 'package:karasu_launcher/providers/profiles_provider.dart';
import 'package:karasu_launcher/widgets/launch_config/profile_dialog.dart';
import 'package:karasu_launcher/widgets/launch_config/profile_filter.dart';
import 'package:karasu_launcher/widgets/launch_config/profile_list.dart';
import 'package:karasu_launcher/widgets/launch_config/profile_utils.dart';

class LaunchConfigTab extends ConsumerStatefulWidget {
  const LaunchConfigTab({super.key});

  @override
  ConsumerState<LaunchConfigTab> createState() => _LaunchConfigTabState();
}

class _LaunchConfigTabState extends ConsumerState<LaunchConfigTab> {
  bool showReleases = true;
  bool showSnapshots = false;
  bool showOldVersions = false;
  ProfileSortOption sortOption = ProfileSortOption.custom;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profilesData = ref.read(profilesProvider);
      if (profilesData != null) {
        final sortType = profilesData.settings.profileSorting;
        setState(() {
          if (sortType == 'byLastPlayed') {
            sortOption = ProfileSortOption.lastPlayed;
          } else if (sortType == 'byCreated') {
            sortOption = ProfileSortOption.created;
          } else {
            sortOption = ProfileSortOption.custom;
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final profilesData = ref.watch(profilesProvider);
    final selectedProfileId = ref.watch(selectedProfileProvider);

    if (profilesData == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // プロファイルの分類とフィルタリング
    final separatedProfiles = ProfileUtils.separateProfiles(
      profilesData.profiles,
    );
    final defaultProfiles = separatedProfiles['default'] ?? {};
    final customProfiles = separatedProfiles['custom'] ?? {};

    final filteredDefaultProfiles = ProfileUtils.filterProfiles(
      defaultProfiles,
      showReleases,
      showSnapshots,
      showOldVersions,
    );

    final filteredCustomProfiles = ProfileUtils.filterProfiles(
      customProfiles,
      showReleases,
      showSnapshots,
      showOldVersions,
    );

    // ソート
    ProfileUtils.sortProfiles(filteredCustomProfiles, sortOption);

    return Container(
      margin: const EdgeInsets.fromLTRB(0, 10, 0, 0),
      child: Scaffold(
        floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.green,
          child: const Icon(Icons.add),
          onPressed: () => _createNewProfile(context),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.startTop,
        body: Container(
          margin: const EdgeInsets.fromLTRB(0, 10, 0, 0),
          child: Padding(
            padding: const EdgeInsets.only(
              top: 60.0,
              left: 16.0,
              right: 16.0,
              bottom: 16.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Manage Profiles',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),

                _buildFilterRow(),

                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // デフォルトプロファイル
                        DefaultProfileList(
                          profiles: filteredDefaultProfiles,
                          selectedProfileId: selectedProfileId,
                        ),

                        // カスタムプロファイルのヘッダー
                        Text(
                          'Custom profile',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),

                        // カスタムプロファイルのリスト
                        customProfiles.isEmpty
                            ? const Center(
                              child: Text('There is no custom profiles'),
                            )
                            : CustomProfileList(
                              profiles: filteredCustomProfiles,
                              selectedProfileId: selectedProfileId,
                              sortOption: sortOption,
                              onEdit: _editProfile,
                              onDelete:
                                  (profileId) =>
                                      _deleteProfile(context, profileId),
                              onReorder:
                                  sortOption == ProfileSortOption.custom
                                      ? (orderedIds) => ref
                                          .read(profilesProvider.notifier)
                                          .saveProfileOrder(orderedIds)
                                      : null,
                            ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterRow() {
    return Row(
      children: [
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(top: 10.0),
            child: ProfileFilter(
              showReleases: showReleases,
              showSnapshots: showSnapshots,
              showOldVersions: showOldVersions,
              onReleasesChanged: (value) {
                setState(() {
                  showReleases = value;
                });
              },
              onSnapshotsChanged: (value) {
                setState(() {
                  showSnapshots = value;
                });
              },
              onOldVersionsChanged: (value) {
                setState(() {
                  showOldVersions = value;
                });
              },
            ),
          ),
        ),

        ProfileSortSelector(
          sortOption: sortOption,
          onSortChanged: (value) {
            if (value != null) {
              setState(() {
                sortOption = value;
              });

              String sortType;
              switch (value) {
                case ProfileSortOption.lastPlayed:
                  sortType = 'byLastPlayed';
                  break;
                case ProfileSortOption.created:
                  sortType = 'byCreated';
                  break;
                default:
                  sortType = 'byProfileOrder';
                  break;
              }
              ref
                  .read(profilesProvider.notifier)
                  .updateProfileSorting(sortType);
            }
          },
        ),
      ],
    );
  }

  void _createNewProfile(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => ProfileDialog(
            onSave: (profile) {
              final profileId =
                  'profile_${DateTime.now().millisecondsSinceEpoch}';
              ref
                  .read(profilesProvider.notifier)
                  .addOrUpdateProfile(profileId, profile);

              ref.read(selectedProfileProvider.notifier).state = profileId;
            },
          ),
    );
  }

  void _editProfile(String profileId, Profile profile) {
    showDialog(
      context: context,
      builder:
          (context) => ProfileDialog(
            profile: profile,
            onSave: (updatedProfile) {
              ref
                  .read(profilesProvider.notifier)
                  .addOrUpdateProfile(profileId, updatedProfile);
            },
          ),
    );
  }

  void _deleteProfile(BuildContext context, String profileId) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete profile'),
            content: const Text('Are you sure you want to delete this profile?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  ref.read(profilesProvider.notifier).removeProfile(profileId);

                  if (ref.read(selectedProfileProvider) == profileId) {
                    ref.read(selectedProfileProvider.notifier).state = null;
                  }
                },
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }
}
