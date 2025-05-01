import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:karasu_launcher/models/launcher_profiles.dart';
import 'package:karasu_launcher/providers/profiles_provider.dart';
import 'package:karasu_launcher/widgets/launch_config/profile_card.dart';
import 'package:karasu_launcher/widgets/launch_config/reorderable_grid_view.dart';
import 'package:karasu_launcher/widgets/launch_config/profile_filter.dart';

class DefaultProfileList extends ConsumerWidget {
  final List<MapEntry<String, Profile>> profiles;
  final String? selectedProfileId;

  const DefaultProfileList({
    super.key,
    required this.profiles,
    required this.selectedProfileId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (profiles.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Default profile',
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 150,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: profiles.length,
            itemBuilder: (context, index) {
              final profileEntry = profiles[index];
              final profileId = profileEntry.key;
              final profile = profileEntry.value;

              return SizedBox(
                width: 250,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ProfileCard(
                    profileId: profileId,
                    profile: profile,
                    isSelected: profileId == selectedProfileId,
                    onSelected: () {
                      ref.read(selectedProfileProvider.notifier).state = profileId;
                    },
                    onEdit: null,
                    onDelete: null,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class CustomProfileList extends ConsumerWidget {
  final List<MapEntry<String, Profile>> profiles;
  final String? selectedProfileId;
  final ProfileSortOption sortOption;
  final void Function(String profileId, Profile profile) onEdit;
  final void Function(String profileId) onDelete;
  final void Function(List<String> orderedIds)? onReorder;

  const CustomProfileList({
    super.key,
    required this.profiles,
    required this.selectedProfileId,
    required this.sortOption,
    required this.onEdit,
    required this.onDelete,
    this.onReorder,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (profiles.isEmpty) {
      return const Center(child: Text('フィルター条件に一致するプロファイルがありません'));
    }

    return sortOption == ProfileSortOption.custom && onReorder != null
        ? _buildReorderableGrid(context, ref)
        : _buildRegularGrid(context, ref);
  }

  Widget _buildReorderableGrid(BuildContext context, WidgetRef ref) {
    return ReorderableGridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 300,
        childAspectRatio: 1.2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: profiles.length,
      itemBuilder: (context, index) {
        final profileEntry = profiles[index];
        final profileId = profileEntry.key;
        final profile = profileEntry.value;

        return ProfileCard(
          key: ValueKey(profileId),
          profileId: profileId,
          profile: profile,
          isSelected: profileId == selectedProfileId,
          onSelected: () {
            ref.read(selectedProfileProvider.notifier).state = profileId;
          },
          onEdit: () => onEdit(profileId, profile),
          onDelete: () => onDelete(profileId),
        );
      },
      onReorder: (int oldIndex, int newIndex) {
        if (onReorder != null) {
          final mutableProfiles = [...profiles];
          if (oldIndex < newIndex) newIndex -= 1;
          final item = mutableProfiles.removeAt(oldIndex);
          mutableProfiles.insert(newIndex, item);
          
          final orderedIds = mutableProfiles.map((e) => e.key).toList();
          onReorder!(orderedIds);
        }
      },
    );
  }

  Widget _buildRegularGrid(BuildContext context, WidgetRef ref) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 300,
        childAspectRatio: 1.2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: profiles.length,
      itemBuilder: (context, index) {
        final profileEntry = profiles[index];
        final profileId = profileEntry.key;
        final profile = profileEntry.value;

        return ProfileCard(
          profileId: profileId,
          profile: profile,
          isSelected: profileId == selectedProfileId,
          onSelected: () {
            ref.read(selectedProfileProvider.notifier).state = profileId;
          },
          onEdit: () => onEdit(profileId, profile),
          onDelete: () => onDelete(profileId),
        );
      },
    );
  }
}
