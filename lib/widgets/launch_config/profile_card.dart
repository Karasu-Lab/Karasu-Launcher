import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:karasu_launcher/models/launcher_profiles.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:karasu_launcher/providers/authentication_provider.dart';
import 'package:karasu_launcher/providers/profiles_provider.dart';
import 'package:karasu_launcher/services/minecraft_service.dart';
import 'package:karasu_launcher/providers/minecraft_state_provider.dart';

class ProfileCard extends ConsumerWidget {
  final String profileId;
  final Profile profile;
  final bool isSelected;
  final VoidCallback? onSelected;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ProfileCard({
    super.key,
    required this.profileId,
    required this.profile,
    required this.isSelected,
    required this.onSelected,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDefaultProfile =
        profileId == 'latest_release' || profileId == 'latest_snapshot';

    final minecraftState = ref.watch(minecraftStateProvider);

    final profileGameDir = profile.id ?? profile.gameDir ?? 'unknown';
    final isProfileRunning = minecraftState.userLaunchingProfiles.entries.any(
      (entry) => entry.value.contains(profileGameDir),
    );

    final isAnyProfileLaunching = minecraftState.isLaunching;

    final canDelete = !isDefaultProfile && !isProfileRunning;

    final canLaunch = !isProfileRunning && !isAnyProfileLaunching;

    return Card(
      elevation: isSelected ? 8 : 2,
      color: isSelected ? Theme.of(context).colorScheme.primaryContainer : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onSelected,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Icon(
                        profile.type == 'latest-release'
                            ? Icons.videogame_asset
                            : profile.type == 'latest-snapshot'
                            ? Icons.science
                            : Icons.games,
                        color:
                            isSelected
                                ? Theme.of(context).colorScheme.primary
                                : null,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          profile.name!,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color:
                                isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : null,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        FlutterI18n.translate(
                          context,
                          'profileCard.version',
                          translationParams: {
                            'version':
                                profile.lastVersionId ??
                                FlutterI18n.translate(
                                  context,
                                  'profileCard.unknownVersion',
                                ),
                          },
                        ),
                        style: const TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        FlutterI18n.translate(
                          context,
                          'profileCard.lastPlayed',
                          translationParams: {
                            'date': _formatDate(
                              context,
                              profile.lastUsed ?? "",
                            ),
                          },
                        ),
                        style: const TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: isDefaultProfile ? null : onEdit,
                      child: IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: null,
                        tooltip:
                            isDefaultProfile
                                ? FlutterI18n.translate(
                                  context,
                                  'profileCard.cannotEditTooltip',
                                )
                                : FlutterI18n.translate(
                                  context,
                                  'profileCard.editTooltip',
                                ),
                        color: isDefaultProfile ? Colors.grey : null,
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.symmetric(horizontal: 6.0),
                      ),
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: canDelete ? onDelete : null,
                      child: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: null,
                        tooltip:
                            isDefaultProfile
                                ? FlutterI18n.translate(
                                  context,
                                  'profileCard.cannotDeleteTooltip',
                                )
                                : isProfileRunning
                                ? FlutterI18n.translate(
                                  context,
                                  'profileCard.cannotDeleteRunningTooltip',
                                )
                                : FlutterI18n.translate(
                                  context,
                                  'profileCard.deleteTooltip',
                                ),
                        color: canDelete ? Colors.red : Colors.grey,
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.symmetric(horizontal: 6.0),
                      ),
                    ),
                  ),
                  Builder(
                    builder: (context) {
                      return Material(
                        color: Colors.transparent,
                        child: SizedBox(
                          width: 36,
                          height: 36,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap:
                                canLaunch
                                    ? () {
                                      final minecraftStateNotifier = ref.read(
                                        minecraftStateProvider.notifier,
                                      );
                                      final minecraftService = ref.read(
                                        minecraftServiceProvider,
                                      );
                                      final profilesData = ref.read(
                                        profilesProvider,
                                      );
                                      final activeAccount = ref.read(
                                        activeAccountProvider,
                                      );

                                      if (profilesData == null) return;

                                      final profile =
                                          profilesData.profiles[profileId];
                                      if (profile == null) return;

                                      final profileGameDir =
                                          profile.id ??
                                          profile.gameDir ??
                                          'unknown';
                                      final userId =
                                          activeAccount?.id ?? 'offline-user';

                                      ref
                                          .read(profilesProvider.notifier)
                                          .updateProfileLastUsed(profileId);

                                      minecraftStateNotifier
                                          .setUserLaunchingProfile(
                                            userId,
                                            profileGameDir,
                                            isOfflineUser:
                                                activeAccount == null,
                                          );

                                      minecraftService.launchMinecraftAsService(
                                        profile,
                                      );
                                    }
                                    : null,
                            child: Center(
                              child:
                                  isProfileRunning
                                      ? const Icon(
                                        Icons.check_circle,
                                        color: Colors.blue,
                                        size: 24,
                                      )
                                      : Icon(
                                        Icons.play_circle_fill,
                                        color:
                                            canLaunch
                                                ? Colors.green
                                                : Colors.grey,
                                        size: 24,
                                      ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(BuildContext context, String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      return '${date.year}/${date.month}/${date.day}';
    } catch (_) {
      return FlutterI18n.translate(context, 'profileCard.unknown');
    }
  }
}
