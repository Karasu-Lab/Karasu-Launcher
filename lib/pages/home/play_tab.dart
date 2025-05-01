import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:karasu_launcher/providers/profiles_provider.dart';
import 'package:karasu_launcher/utils/file_utils.dart';
import 'package:path/path.dart' as path;

class PlayTab extends ConsumerStatefulWidget {
  const PlayTab({super.key});

  @override
  ConsumerState<PlayTab> createState() => _PlayTabState();
}

class _PlayTabState extends ConsumerState<PlayTab> {
  String _currentView = 'game';
  Map<String, List<File>> _screenshotsByProfile = {};
  bool _isLoadingScreenshots = true;
  Set<String> _selectedProfileIds = {};

  @override
  void initState() {
    super.initState();

    _loadScreenshots();
  }

  @override
  void dispose() {
    super.dispose();
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
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(26),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildTabButton(
                icon: Icons.videogame_asset,
                label: 'ゲーム',
                isSelected: _currentView == 'game',
                onTap: () => setState(() => _currentView = 'game'),
              ),
              _buildTabButton(
                icon: Icons.photo_library,
                label: 'スクリーンショット',
                isSelected: _currentView == 'screenshots',
                onTap: () => setState(() => _currentView = 'screenshots'),
              ),
            ],
          ),
        ),
        Expanded(
          child:
              _currentView == 'game' ? _buildGameTab() : _buildScreenshotsTab(),
        ),
      ],
    );
  }

  Widget _buildTabButton({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? Theme.of(context).colorScheme.primary.withAlpha(25)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color:
                  isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurface,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color:
                    isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameTab() {
    return const Center(child: Text('Game tab contents'));
  }

  Widget _buildScreenshotsTab() {
    final profilesData = ref.watch(profilesProvider);

    if (_isLoadingScreenshots) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_screenshotsByProfile.isEmpty) {
      return const Center(child: Text('There is no screenshot file.'));
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
                      'プロファイルフィルター',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const Spacer(),
                    if (_selectedProfileIds.length > 1)
                      TextButton.icon(
                        icon: const Icon(Icons.clear_all, size: 16),
                        label: const Text('すべて解除'),
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
                            '${_getProfileDisplayName(entry.key, profilesData)} (${entry.value.length}枚)',
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
          const Expanded(child: Center(child: Text('プロファイルを選択してください')))
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
      return 'デフォルト（最新バージョン）';
    } else if (profileId == 'latest-release') {
      return 'デフォルト（最新リリース）';
    } else if (profileId == 'latest-snapshot') {
      return 'デフォルト（最新スナップショット）';
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
            Text('選択したプロファイルにはスクリーンショットがありません。'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadScreenshots,
      child: GridView.builder(
        padding: const EdgeInsets.all(8.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8.0,
          mainAxisSpacing: 8.0,
        ),
        itemCount: allScreenshots.length,
        itemBuilder: (context, index) {
          final item = allScreenshots[index];
          final screenshot = item['file'] as File;
          final profileName = item['profileName'] as String;

          return GestureDetector(
            onTap:
                () => _showScreenshotDetail(context, screenshot, profileName),
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(
                    screenshot,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[300],
                        child: const Center(child: Icon(Icons.broken_image)),
                      );
                    },
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      color: const Color.fromRGBO(0, 0, 0, 0.5),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            path.basenameWithoutExtension(screenshot.path),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                          ),
                          if (_selectedProfileIds.length > 1)
                            Text(
                              profileName,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 8,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
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
            Text('$profileName にはスクリーンショットがありません。'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadScreenshots,
      child: GridView.builder(
        padding: const EdgeInsets.all(8.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8.0,
          mainAxisSpacing: 8.0,
        ),
        itemCount: screenshots.length,
        itemBuilder: (context, index) {
          final screenshot = screenshots[index];
          return GestureDetector(
            onTap:
                () => _showScreenshotDetail(context, screenshot, profileName),
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(
                    screenshot,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[300],
                        child: const Center(child: Icon(Icons.broken_image)),
                      );
                    },
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      color: const Color.fromRGBO(0, 0, 0, 0.5),
                      child: Text(
                        path.basenameWithoutExtension(screenshot.path),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
            (context) => Scaffold(
              appBar: AppBar(
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(path.basename(screenshot.path)),
                    Text(profileName, style: const TextStyle(fontSize: 12)),
                  ],
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.share),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'The feature which is share is in development.',
                          ),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder:
                            (context) => AlertDialog(
                              title: const Text('Delete confirm'),
                              content: const Text(
                                'Are you sure you want to delete this screenshot?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed:
                                      () => Navigator.of(context).pop(false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed:
                                      () => Navigator.of(context).pop(true),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                      );

                      if (confirmed == true) {
                        try {
                          await screenshot.delete();
                          if (mounted && context.mounted) {
                            Navigator.of(context).pop();
                            _loadScreenshots();
                          }
                        } catch (e) {
                          if (mounted && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Error was occured while deleting the file.: $e',
                                ),
                              ),
                            );
                          }
                        }
                      }
                    },
                  ),
                ],
              ),
              body: Center(
                child: InteractiveViewer(
                  panEnabled: true,
                  boundaryMargin: const EdgeInsets.all(20),
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Image.file(screenshot),
                ),
              ),
            ),
      ),
    );
  }
}
