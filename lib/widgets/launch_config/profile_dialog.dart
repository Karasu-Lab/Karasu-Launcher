import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:karasu_launcher/models/launcher_profiles.dart';
import 'package:karasu_launcher/models/launcher_versions_v2.dart';
import 'package:karasu_launcher/models/mod_loader.dart';
import 'package:karasu_launcher/providers/profiles_provider.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

class ProfileDialog extends StatefulWidget {
  final Profile? profile;
  final Function(Profile) onSave;

  const ProfileDialog({super.key, this.profile, required this.onSave});

  @override
  State<ProfileDialog> createState() => _ProfileDialogState();
}

class _ProfileDialogState extends State<ProfileDialog> {
  late TextEditingController nameController;
  late TextEditingController gameDirController;
  late TextEditingController javaArgsController;
  String? selectedVersion;
  bool showSnapshots = false;
  bool showReleases = true;
  bool showOldVersions = false;
  bool showModVersions = false;
  ModLoaderType? selectedModLoader;
  @override
  void initState() {
    super.initState();
    final profile = widget.profile;
    nameController = TextEditingController(text: profile?.name ?? '');
    selectedVersion = profile?.lastVersionId;
    gameDirController = TextEditingController(text: profile?.gameDir ?? '');
    javaArgsController = TextEditingController(text: profile?.javaArgs ?? '');
  }

  void _checkAndSetModLoader(
    String versionId,
    List<MinecraftVersion> versions,
  ) {
    final selectedVersionDetails = versions.firstWhere(
      (v) => v.id == versionId,
      orElse:
          () => MinecraftVersion(
            id: versionId,
            type: 'unknown',
            url: '',
            time: '',
            releaseTime: '',
            sha1: '',
            complianceLevel: 0,
          ),
    );

    if (selectedVersionDetails.modLoader != null) {
      setState(() {
        showModVersions = true;
        selectedModLoader = selectedVersionDetails.modLoader!.type;
      });
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    gameDirController.dispose();
    javaArgsController.dispose();
    super.dispose();
  }

  Future<void> _pickFolder() async {
    final result = await FilePicker.platform.getDirectoryPath();
    if (result != null) {
      setState(() {
        gameDirController.text = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.profile != null;

    return AlertDialog(
      title: Text(
        isEditing
            ? FlutterI18n.translate(context, 'profileDialog.editProfile')
            : FlutterI18n.translate(context, 'profileDialog.createProfile'),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: FlutterI18n.translate(
                  context,
                  'profileDialog.profileName',
                ),
                hintText: FlutterI18n.translate(
                  context,
                  'profileDialog.profileNameHint',
                ),
              ),
            ),
            const SizedBox(height: 16),

            _buildVersionSelector(),

            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: gameDirController,
                    decoration: InputDecoration(
                      labelText: FlutterI18n.translate(
                        context,
                        'profileDialog.gameDirectory',
                      ),
                      hintText: FlutterI18n.translate(
                        context,
                        'profileDialog.gameDirectoryHint',
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.folder_open),
                  onPressed: _pickFolder,
                  tooltip: FlutterI18n.translate(
                    context,
                    'profileDialog.selectFolder',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: javaArgsController,
              decoration: InputDecoration(
                labelText: FlutterI18n.translate(
                  context,
                  'profileDialog.javaArguments',
                ),
                hintText: FlutterI18n.translate(
                  context,
                  'profileDialog.javaArgumentsHint',
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(FlutterI18n.translate(context, 'profileDialog.cancel')),
        ),
        TextButton(
          onPressed: () {
            final name = nameController.text.trim();

            if (name.isEmpty || selectedVersion == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    FlutterI18n.translate(
                      context,
                      'profileDialog.requiredFields',
                    ),
                  ),
                ),
              );
              return;
            }

            final newProfile = Profile(
              name: name,
              type: 'custom',
              created:
                  widget.profile?.created ?? DateTime.now().toIso8601String(),
              lastUsed: DateTime.now().toIso8601String(),
              lastVersionId: selectedVersion!,
              gameDir:
                  gameDirController.text.trim().isEmpty
                      ? null
                      : gameDirController.text.trim(),
              javaArgs:
                  javaArgsController.text.trim().isEmpty
                      ? null
                      : javaArgsController.text.trim(),
              icon: widget.profile?.icon,
              javaDir: widget.profile?.javaDir,
              skipJreVersionCheck: widget.profile?.skipJreVersionCheck ?? false,
            );

            widget.onSave(newProfile);
            Navigator.of(context).pop();
          },
          child: Text(FlutterI18n.translate(context, 'profileDialog.save')),
        ),
      ],
    );
  }

  Widget _buildVersionSelector() {
    return Consumer(
      builder: (context, ref, child) {
        final latestVersions = ref.watch(latestVersionsProvider);

        final versionsProvider = availableVersionsProvider;
        final versions = ref.watch(versionsProvider);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              FlutterI18n.translate(context, 'profileDialog.version'),
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Checkbox(
                  value: showReleases,
                  onChanged: (value) {
                    setState(() {
                      showReleases = value ?? true;
                    });
                  },
                ),
                Text(
                  FlutterI18n.translate(context, 'profileFilter.showReleases'),
                ),
                const SizedBox(width: 20),
                Checkbox(
                  value: showSnapshots,
                  onChanged: (value) {
                    setState(() {
                      showSnapshots = value ?? false;
                    });
                  },
                ),
                Text(
                  FlutterI18n.translate(context, 'profileFilter.showSnapshots'),
                ),
                const SizedBox(width: 20),
                Checkbox(
                  value: showOldVersions,
                  onChanged: (value) {
                    setState(() {
                      showOldVersions = value ?? false;
                    });
                  },
                ),
                Text(
                  FlutterI18n.translate(
                    context,
                    'profileFilter.showOldVersions',
                  ),
                ),
              ],
            ),

            Row(
              children: [
                Checkbox(
                  value: showModVersions,
                  onChanged: (value) {
                    setState(() {
                      showModVersions = value ?? false;

                      if (showModVersions && selectedModLoader == null) {
                        selectedModLoader = ModLoaderType.fabric;
                      } else if (!showModVersions) {
                        selectedModLoader = null;
                      }
                    });
                  },
                ),
                Text(
                  FlutterI18n.translate(
                    context,
                    'profileDialog.showModVersions',
                  ),
                ),
              ],
            ),

            if (showModVersions)
              Padding(
                padding: const EdgeInsets.only(left: 32.0, top: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      FlutterI18n.translate(
                        context,
                        'profileDialog.selectModLoader',
                      ),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8.0,
                      children: [
                        for (final loaderType in ModLoaderType.values)
                          if (loaderType != ModLoaderType.other)
                            ChoiceChip(
                              label: Text(loaderType.name.toUpperCase()),
                              selected: selectedModLoader == loaderType,
                              onSelected: (bool selected) {
                                setState(() {
                                  if (selected) {
                                    selectedModLoader = loaderType;
                                    if (nameController.text.trim().isEmpty &&
                                        selectedVersion != null) {
                                      nameController.text =
                                          '$selectedVersion (${loaderType.name})';
                                    }
                                  }
                                });
                              },
                            ),
                      ],
                    ),
                  ],
                ),
              ),

            latestVersions.when(
              data:
                  (latest) => Row(
                    children: [
                      if (showReleases)
                        ElevatedButton.icon(
                          icon: const Icon(Icons.videogame_asset, size: 16),
                          label: Text(
                            FlutterI18n.translate(
                              context,
                              'profileDialog.latestRelease',
                            ),
                          ),
                          onPressed: () {
                            setState(() {
                              selectedVersion = latest['release'];
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      if (showReleases && showSnapshots)
                        const SizedBox(width: 8),
                      if (showSnapshots)
                        ElevatedButton.icon(
                          icon: const Icon(Icons.science, size: 16),
                          label: Text(
                            FlutterI18n.translate(
                              context,
                              'profileDialog.latestSnapshot',
                            ),
                          ),
                          onPressed: () {
                            setState(() {
                              selectedVersion = latest['snapshot'];
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                    ],
                  ),
              loading: () => const SizedBox(),
              error: (_, __) => const SizedBox(),
            ),
            const SizedBox(height: 12),
            versions.when(
              data: (versionList) {
                List<MinecraftVersion> filteredVersions = [];

                if (showModVersions && selectedModLoader != null) {
                  filteredVersions =
                      versionList
                          .where(
                            (version) =>
                                version.modLoader != null &&
                                version.modLoader!.type == selectedModLoader,
                          )
                          .toList();
                } else {
                  filteredVersions =
                      versionList
                          .where(
                            (version) =>
                                (showReleases && version.type == 'release') ||
                                (showSnapshots && version.type == 'snapshot') ||
                                (showOldVersions &&
                                    version.type != 'release' &&
                                    version.type != 'snapshot'),
                          )
                          .toList();
                }

                final bool selectedVersionExists =
                    selectedVersion != null &&
                    filteredVersions.any(
                      (version) => version.id == selectedVersion,
                    );

                if (!selectedVersionExists && filteredVersions.isNotEmpty) {
                  selectedVersion = filteredVersions.first.id;
                }

                return filteredVersions.isEmpty
                    ? Text(
                      FlutterI18n.translate(
                        context,
                        'profileDialog.noVersionsAvailable',
                      ),
                    )
                    : selectedVersion == null
                    ? Text(
                      FlutterI18n.translate(
                        context,
                        'profileDialog.loadingVersions',
                      ),
                    )
                    : _buildScrollableVersionList(filteredVersions, context);
              },
              loading: () => const LinearProgressIndicator(),
              error:
                  (_, __) => Text(
                    FlutterI18n.translate(
                      context,
                      'profileDialog.failedToLoadVersions',
                    ),
                  ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildScrollableVersionList(
    List<MinecraftVersion> versions,
    BuildContext context,
  ) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Container(
        height: 250,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                '${FlutterI18n.translate(context, 'profileDialog.selected')}: ${selectedVersion ?? FlutterI18n.translate(context, 'profileDialog.none')}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(versions.length, (index) {
                    final version = versions[index];
                    final isSelected = version.id == selectedVersion;
                    final bool hasMod = version.modLoader != null;

                    return SizedBox(
                      height: 40,
                      width: double.infinity,
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            selectedVersion = version.id;

                            if (nameController.text.trim().isEmpty) {
                              if (version.modLoader != null) {
                                nameController.text =
                                    '${version.id} (${version.modLoader!.type.name})';
                              } else {
                                nameController.text = version.id;
                              }
                            }
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Row(
                            children: [
                              Icon(
                                hasMod
                                    ? Icons.extension
                                    : version.type == 'release'
                                    ? Icons.videogame_asset
                                    : version.type == 'snapshot'
                                    ? Icons.science
                                    : Icons.history,
                                size: 16,
                                color:
                                    isSelected
                                        ? Theme.of(context).colorScheme.primary
                                        : null,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: RichText(
                                  overflow: TextOverflow.ellipsis,
                                  text: TextSpan(
                                    style: TextStyle(
                                      color:
                                          isSelected
                                              ? Theme.of(
                                                context,
                                              ).colorScheme.primary
                                              : Theme.of(
                                                context,
                                              ).textTheme.bodyLarge?.color,
                                      fontWeight:
                                          isSelected
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                    ),
                                    children: [
                                      TextSpan(text: version.id),
                                      if (hasMod)
                                        TextSpan(
                                          text:
                                              ' (${version.modLoader?.type.name.toUpperCase()} ${version.modLoader?.version})',
                                          style: TextStyle(
                                            fontStyle: FontStyle.italic,
                                            fontSize: 12,
                                            color:
                                                isSelected
                                                    ? Theme.of(context)
                                                        .colorScheme
                                                        .primary
                                                        .withAlpha(
                                                          (0.8 * 255).toInt(),
                                                        )
                                                    : Theme.of(context)
                                                        .textTheme
                                                        .bodyMedium
                                                        ?.color
                                                        ?.withAlpha(
                                                          (0.8 * 255).toInt(),
                                                        ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
