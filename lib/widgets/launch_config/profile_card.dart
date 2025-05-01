import 'package:flutter/material.dart';
import 'package:karasu_launcher/models/launcher_profiles.dart';

class ProfileCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final isDefaultProfile =
        profileId == 'latest_release' || profileId == 'latest_snapshot';

    return Card(
      elevation: isSelected ? 8 : 2,
      color: isSelected ? Theme.of(context).colorScheme.primaryContainer : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: InkWell(
        onTap: onSelected,
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
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
              const SizedBox(height: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'バージョン: ${profile.lastVersionId ?? "不明"}',
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '最終プレイ: ${_formatDate(profile.lastUsed ?? "")}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: isDefaultProfile ? null : onEdit,
                    tooltip:
                        isDefaultProfile ? 'You cannot edit this profile' : 'Edit this profile',
                    color: isDefaultProfile ? Colors.grey : null,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: isDefaultProfile ? null : onDelete,
                    tooltip:
                        isDefaultProfile ? 'You cannot delete this profile' : 'Delete this profile',
                    color: isDefaultProfile ? Colors.grey : Colors.red,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      return '${date.year}/${date.month}/${date.day}';
    } catch (_) {
      return 'Unknown';
    }
  }
}
