import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:karasu_launcher/models/screenshot.dart';
import 'package:karasu_launcher/providers/profiles_provider.dart';
import 'package:karasu_launcher/providers/screenshots_provider.dart';
import 'package:karasu_launcher/utils/file_utils.dart';
import 'package:karasu_launcher/widgets/screenshots/screenshot_detail_screen.dart';
import 'package:karasu_launcher/widgets/screenshots/screenshot_timeline_item.dart';
import 'package:path/path.dart' as path;

class ScreenshotsContent extends ConsumerStatefulWidget {
  const ScreenshotsContent({super.key});

  @override
  ConsumerState<ScreenshotsContent> createState() => _ScreenshotsContentState();
}

class _ScreenshotsContentState extends ConsumerState<ScreenshotsContent> {
  Map<String, List<File>> _screenshotsByProfile = {};
  bool _isLoadingScreenshots = true;
  Set<String> _selectedProfileIds = {};

  @override
  void initState() {
    super.initState();

    _loadScreenshots();
  }

  Future<void> _registerScreenshotIfNeeded(File file, String profileId) async {
    try {
      final screenshotsNotifier = ref.read(
        screenshotsCollectionProvider.notifier,
      );
      final existingScreenshots = screenshotsNotifier.getAllScreenshots();

      final alreadyRegistered = existingScreenshots.any(
        (s) => s.filePath == file.path && s.profileId == profileId,
      );

      if (!alreadyRegistered) {
        await screenshotsNotifier.addScreenshot(
          file: file,
          profileId: profileId,
        );
        debugPrint('スクリーンショットを登録しました: ${file.path}');
      }
    } catch (e) {
      debugPrint('スクリーンショット登録エラー: $e');
    }
  }

  Future<void> _loadScreenshots() async {
    setState(() {
      _isLoadingScreenshots = true;
    });

    final profilesData = ref.read(profilesProvider);
    if (profilesData == null) {
      setState(() {
        _isLoadingScreenshots = false;
      });
      return;
    }

    Map<String, List<File>> screenshotsByProfile = {};

    final screenshotsNotifier = ref.read(
      screenshotsCollectionProvider.notifier,
    );
    await screenshotsNotifier.loadScreenshots();

    try {
      final appDir = await createAppDirectory();
      final defaultScreenshotsDir = Directory(
        path.join(appDir.path, 'screenshots'),
      );

      if (await defaultScreenshotsDir.exists()) {
        final defaultScreenshots =
            await defaultScreenshotsDir
                .list()
                .where(
                  (entity) =>
                      entity is File &&
                      [
                        '.png',
                        '.jpg',
                        '.jpeg',
                      ].contains(path.extension(entity.path).toLowerCase()),
                )
                .cast<File>()
                .toList();

        defaultScreenshots.sort((a, b) {
          return b.lastModifiedSync().compareTo(a.lastModifiedSync());
        });

        if (defaultScreenshots.isNotEmpty) {
          screenshotsByProfile['latest'] = defaultScreenshots;

          for (final file in defaultScreenshots) {
            _registerScreenshotIfNeeded(file, 'latest');
          }
        }
      } else {
        await defaultScreenshotsDir.create(recursive: true);
      }
    } catch (e) {
      debugPrint('Could not get screenshots: $e');
    }

    for (final entry in profilesData.profiles.entries) {
      final profileId = entry.key;
      final profile = entry.value;

      if (profile.gameDir != null && profile.gameDir!.isNotEmpty) {
        final gameDir = Directory(profile.gameDir!);
        if (await gameDir.exists()) {
          final screenshotsDir = Directory(
            path.join(gameDir.path, 'screenshots'),
          );
          if (await screenshotsDir.exists()) {
            try {
              final screenshots =
                  await screenshotsDir
                      .list()
                      .where(
                        (entity) =>
                            entity is File &&
                            ['.png', '.jpg', '.jpeg'].contains(
                              path.extension(entity.path).toLowerCase(),
                            ),
                      )
                      .cast<File>()
                      .toList();
              screenshots.sort((a, b) {
                return b.lastModifiedSync().compareTo(a.lastModifiedSync());
              });

              screenshotsByProfile[profileId] = screenshots;

              for (final file in screenshots) {
                _registerScreenshotIfNeeded(file, profileId);
              }
            } catch (e) {
              debugPrint(
                'Error loading screenshots for profile $profileId: $e',
              );
            }
          }
        }
      }
    }

    if (mounted) {
      setState(() {
        _screenshotsByProfile = screenshotsByProfile;
        _isLoadingScreenshots = false;

        if (_selectedProfileIds.isEmpty && screenshotsByProfile.isNotEmpty) {
          _selectedProfileIds = {screenshotsByProfile.keys.first};
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final profilesData = ref.watch(profilesProvider);

    if (_isLoadingScreenshots) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_screenshotsByProfile.isEmpty) {
      return Center(
        child: Text(
          FlutterI18n.translate(context, 'screenshotsContent.noScreenshots'),
        ),
      );
    }

    final sortedProfiles = Map.fromEntries(
      _screenshotsByProfile.entries.toList()..sort((a, b) {
        final nameA =
            profilesData?.profiles[a.key]?.name ??
            (a.key == 'latest' ? 'Default Latest version' : a.key);
        final nameB =
            profilesData?.profiles[b.key]?.name ??
            (b.key == 'latest' ? 'Default Latest version' : b.key);
        return nameA.compareTo(nameB);
      }),
    );

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
                child: Row(
                  children: [
                    Text(
                      FlutterI18n.translate(
                        context,
                        'screenshotsContent.profileFilter',
                      ),
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const Spacer(),
                    if (_selectedProfileIds.length > 1)
                      TextButton.icon(
                        icon: const Icon(Icons.clear_all, size: 16),
                        label: Text(
                          FlutterI18n.translate(
                            context,
                            'screenshotsContent.clearAll',
                          ),
                        ),
                        onPressed: () {
                          setState(() {
                            _selectedProfileIds = {};
                          });
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    TextButton.icon(
                      icon: const Icon(Icons.refresh, size: 16),
                      label: Text(
                        FlutterI18n.translate(
                          context,
                          'screenshotsContent.refresh',
                        ),
                      ),
                      onPressed: _loadScreenshots,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final entry in sortedProfiles.entries)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: FilterChip(
                          label: Text(
                            '${_getProfileDisplayName(entry.key, profilesData)} ${FlutterI18n.translate(context, 'screenshotsContent.screenshotCount', translationParams: {'count': entry.value.length.toString()})}',
                            style: TextStyle(
                              color:
                                  _selectedProfileIds.contains(entry.key)
                                      ? Colors.white
                                      : Theme.of(
                                        context,
                                      ).textTheme.bodyMedium?.color,
                            ),
                          ),
                          selected: _selectedProfileIds.contains(entry.key),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedProfileIds.add(entry.key);
                              } else {
                                if (_selectedProfileIds.length > 1) {
                                  _selectedProfileIds.remove(entry.key);
                                }
                              }
                            });
                          },
                          showCheckmark: true,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),

        if (_selectedProfileIds.isEmpty)
          Expanded(
            child: Center(
              child: Text(
                FlutterI18n.translate(
                  context,
                  'screenshotsContent.selectProfile',
                ),
              ),
            ),
          )
        else
          Expanded(child: _buildMultiProfileScreenshotGrid()),
      ],
    );
  }

  String _getProfileDisplayName(String profileId, profilesData) {
    String? name = profilesData?.profiles[profileId]?.name;

    if (name != null && name.isNotEmpty) {
      return name;
    }

    if (profileId == 'latest') {
      return FlutterI18n.translate(
        context,
        'screenshotsContent.defaultProfileName',
      );
    } else if (profileId == 'latest-release') {
      return FlutterI18n.translate(
        context,
        'screenshotsContent.defaultReleaseProfileName',
      );
    } else if (profileId == 'latest-snapshot') {
      return FlutterI18n.translate(
        context,
        'screenshotsContent.defaultSnapshotProfileName',
      );
    }

    return profileId;
  }

  Widget _buildMultiProfileScreenshotGrid() {
    List<Map<String, dynamic>> allScreenshots = [];

    for (String profileId in _selectedProfileIds) {
      final screenshots = _screenshotsByProfile[profileId] ?? [];
      final profilesData = ref.read(profilesProvider);
      final profileName = _getProfileDisplayName(profileId, profilesData);

      for (var screenshot in screenshots) {
        allScreenshots.add({
          'file': screenshot,
          'profileId': profileId,
          'profileName': profileName,
          'lastModified': screenshot.lastModifiedSync(),
        });
      }
    }

    allScreenshots.sort(
      (a, b) => (b['lastModified'] as DateTime).compareTo(
        a['lastModified'] as DateTime,
      ),
    );

    if (allScreenshots.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.photo_album_outlined,
              size: 48,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              FlutterI18n.translate(
                context,
                'screenshotsContent.noScreenshotsForProfile',
              ),
            ),
          ],
        ),
      );
    }

    Map<String, List<Map<String, dynamic>>> groupedScreenshots = {};
    for (var screenshot in allScreenshots) {
      final DateTime date = screenshot['lastModified'] as DateTime;
      final String dateKey =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      groupedScreenshots.putIfAbsent(dateKey, () => []);
      groupedScreenshots[dateKey]!.add(screenshot);
    }

    List<String> sortedDates =
        groupedScreenshots.keys.toList()..sort((a, b) => b.compareTo(a));

    return RefreshIndicator(
      onRefresh: _loadScreenshots,
      child: ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: sortedDates.length,
        itemBuilder: (context, index) {
          final dateKey = sortedDates[index];
          final screenshots = groupedScreenshots[dateKey]!;

          final parts = dateKey.split('-');
          final formattedDate =
              '${parts[0]}${FlutterI18n.translate(context, 'screenshotsContent.year')}'
              '${parts[1]}${FlutterI18n.translate(context, 'screenshotsContent.month')}'
              '${parts[2]}${FlutterI18n.translate(context, 'screenshotsContent.day')}';

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  formattedDate,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Column(
                children:
                    screenshots.map((item) {
                      final screenshot = item['file'] as File;
                      final profileName = item['profileName'] as String;
                      final lastModified = item['lastModified'] as DateTime;

                      return _buildTimelineItem(
                        context: context,
                        screenshot: screenshot,
                        profileName: profileName,
                        dateTime: lastModified,
                        profileId: item['profileId'] as String,
                      );
                    }).toList(),
              ),
              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTimelineItem({
    required BuildContext context,
    required File screenshot,
    required String profileName,
    required DateTime dateTime,
    required String profileId,
  }) {
    final screenshotsNotifier = ref.read(
      screenshotsCollectionProvider.notifier,
    );
    List<Screenshot> allScreenshots = screenshotsNotifier.getAllScreenshots();

    return ScreenshotTimelineItem(
      screenshot: screenshot,
      profileName: profileName,
      dateTime: dateTime,
      profileId: profileId,
      onTap: _showScreenshotDetail,
      allScreenshots: allScreenshots,
      onEditComment: (Screenshot updatedScreenshot) {
        setState(() {});
      },
      showProfileChip: _selectedProfileIds.length > 1,
    );
  }

  Widget _buildScreenshotGrid(String profileId) {
    final screenshots = _screenshotsByProfile[profileId] ?? [];
    final profilesData = ref.read(profilesProvider);
    final profileName = _getProfileDisplayName(profileId, profilesData);

    if (screenshots.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.photo_album_outlined,
              size: 48,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              FlutterI18n.translate(
                context,
                'screenshotsContent.noScreenshotsForProfile',
              ),
            ),
          ],
        ),
      );
    }

    final sortedScreenshots = List<Map<String, dynamic>>.from(
      screenshots.map(
        (screenshot) => {
          'file': screenshot,
          'lastModified': screenshot.lastModifiedSync(),
        },
      ),
    )..sort(
      (a, b) => (b['lastModified'] as DateTime).compareTo(
        a['lastModified'] as DateTime,
      ),
    );

    Map<String, List<Map<String, dynamic>>> groupedScreenshots = {};
    for (var screenshot in sortedScreenshots) {
      final DateTime date = screenshot['lastModified'] as DateTime;
      final String dateKey =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      groupedScreenshots.putIfAbsent(dateKey, () => []);
      groupedScreenshots[dateKey]!.add(screenshot);
    }

    List<String> sortedDates =
        groupedScreenshots.keys.toList()..sort((a, b) => b.compareTo(a));

    return RefreshIndicator(
      onRefresh: _loadScreenshots,
      child: ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: sortedDates.length,
        itemBuilder: (context, index) {
          final dateKey = sortedDates[index];
          final screenshots = groupedScreenshots[dateKey]!;

          final parts = dateKey.split('-');
          final formattedDate =
              '${parts[0]}${FlutterI18n.translate(context, 'screenshotsContent.year')}'
              '${parts[1]}${FlutterI18n.translate(context, 'screenshotsContent.month')}'
              '${parts[2]}${FlutterI18n.translate(context, 'screenshotsContent.day')}';

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  formattedDate,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              Column(
                children:
                    screenshots.map((item) {
                      final screenshot = item['file'] as File;
                      final lastModified = item['lastModified'] as DateTime;

                      return _buildTimelineItem(
                        context: context,
                        screenshot: screenshot,
                        profileName: profileName,
                        dateTime: lastModified,
                        profileId: profileId,
                      );
                    }).toList(),
              ),
              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }

  void _showScreenshotDetail(
    BuildContext context,
    File screenshot,
    String profileName,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => ScreenshotDetailScreen(
              screenshot: screenshot,
              profileName: profileName,
              onScreenshotDeleted: _loadScreenshots,
            ),
      ),
    );
  }
}
