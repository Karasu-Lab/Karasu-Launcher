import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:karasu_launcher/models/launcher_profiles.dart';
import 'package:karasu_launcher/providers/profiles_provider.dart';

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

  @override
  void initState() {
    super.initState();
    final profile = widget.profile;
    nameController = TextEditingController(text: profile?.name ?? '');
    selectedVersion = profile?.lastVersionId;
    gameDirController = TextEditingController(text: profile?.gameDir ?? '');
    javaArgsController = TextEditingController(text: profile?.javaArgs ?? '');
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
      title: Text(isEditing ? 'Edit this profile' : 'Create new profile'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Profile name',
                hintText: 'My cool profile',
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
                    decoration: const InputDecoration(
                      labelText: 'Game directory (Optional)',
                      hintText: 'If this entry is empty, this value will be default.',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.folder_open),
                  onPressed: _pickFolder,
                  tooltip: 'Select folder',
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: javaArgsController,
              decoration: const InputDecoration(
                labelText: 'Java arguments (Optional)',
                hintText: '-Xmx2G -XX:+UnlockExperimentalVMOptions',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            final name = nameController.text.trim();

            if (name.isEmpty || selectedVersion == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profile name and version are required')),
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
          child: const Text('Save'),
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
            const Text('Version', style: TextStyle(fontSize: 16)),
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
                const Text('Show Releases'),
                const SizedBox(width: 20),
                Checkbox(
                  value: showSnapshots,
                  onChanged: (value) {
                    setState(() {
                      showSnapshots = value ?? false;
                    });
                  },
                ),
                const Text('Show Snapshots'),
                const SizedBox(width: 20),
                Checkbox(
                  value: showOldVersions,
                  onChanged: (value) {
                    setState(() {
                      showOldVersions = value ?? false;
                    });
                  },
                ),
                const Text('Show Old Versions'),
              ],
            ),

            latestVersions.when(
              data:
                  (latest) => Row(
                    children: [
                      if (showReleases)
                        ElevatedButton.icon(
                          icon: const Icon(Icons.videogame_asset, size: 16),
                          label: const Text('Latest Release'),
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
                          label: const Text('Latest Snapshot'),
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
                final filteredVersions =
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

                final bool selectedVersionExists =
                    selectedVersion != null &&
                    filteredVersions.any(
                      (version) => version.id == selectedVersion,
                    );

                if (!selectedVersionExists && filteredVersions.isNotEmpty) {
                  selectedVersion = filteredVersions.first.id;
                }

                return filteredVersions.isEmpty
                    ? const Text('There are no versions available')
                    : selectedVersion == null
                    ? const Text('Loading versions...')
                    : _buildScrollableVersionList(filteredVersions, context);
              },
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const Text('Failed to load versions'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildScrollableVersionList(
    List<dynamic> versions,
    BuildContext context,
  ) {
    return Padding(
      padding: EdgeInsets.all(10),
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
                'Selected: ${selectedVersion ?? "None"}',
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

                    return SizedBox(
                      height: 40,
                      width: double.infinity,
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            selectedVersion = version.id;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Row(
                            children: [
                              Icon(
                                version.type == 'release'
                                    ? Icons.videogame_asset
                                    : version.type == 'snapshot'
                                    ? Icons.science
                                    : Icons.history,
                                size: 16,
                                color:
                                    isSelected
                                        ? Theme.of(context).primaryColor
                                        : null,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  version.id,
                                  style: TextStyle(
                                    fontWeight:
                                        isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                    color:
                                        isSelected
                                            ? Theme.of(context).primaryColor
                                            : null,
                                  ),
                                  overflow: TextOverflow.ellipsis,
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
