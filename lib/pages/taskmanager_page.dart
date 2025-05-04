import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:karasu_launcher/models/minecraft_state.dart';
import '../providers/minecraft_state_provider.dart';
import '../providers/authentication_provider.dart';
import '../providers/profiles_provider.dart';
import '../models/auth/account.dart';
import '../widgets/account/user_icon.dart';

final xuidVisibilityProvider = StateProvider.family<bool, String>(
  (ref, userId) => false,
);

class TaskManagerPage extends ConsumerStatefulWidget {
  const TaskManagerPage({super.key});

  @override
  ConsumerState<TaskManagerPage> createState() => _TaskManagerPageState();
}

class _TaskManagerPageState extends ConsumerState<TaskManagerPage> {
  @override
  Widget build(BuildContext context) {
    final minecraftState = ref.watch(minecraftStateProvider);
    final profilesAsync = ref.watch(profilesInitializedProvider);
    final accounts = ref.watch(authenticationProvider).accounts;

    final launchingUserIds = minecraftState.launchingUsers.keys.toList();

    final offlineUserIds = minecraftState.offlineUsers.keys.toList();

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              FlutterI18n.translate(context, 'taskManagerPage.title'),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),

          Expanded(
            child: profilesAsync.when(
              data: (profiles) {
                if (launchingUserIds.isEmpty) {
                  return _buildAccountsList(accounts);
                }

                return ListView.builder(
                  itemCount: launchingUserIds.length,
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final userId = launchingUserIds[index];
                    final isOffline = offlineUserIds.contains(userId);
                    final account = isOffline ? null : accounts[userId];
                    final profileIds =
                        minecraftState.userLaunchingProfiles[userId] ?? [];
                    final progress = minecraftState.userProgress[userId];

                    return Card(
                      color: Colors.grey[850],
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildUserHeader(account, isOffline, userId),
                            const Divider(color: Colors.grey),
                            const SizedBox(height: 8),
                            ...profileIds.map((profileId) {
                              final profileName =
                                  profiles?.profiles.entries
                                      .where(
                                        (entry) => entry.value.id == profileId,
                                      )
                                      .map((entry) => entry.value.name)
                                      .firstOrNull ??
                                  'Unknown Profile';

                              return _buildProfileItem(
                                profileId,
                                profileName,
                                progress,
                                userId,
                              );
                            }),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error:
                  (error, stack) => Center(
                    child: Text(
                      'エラーが発生しました: $error',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountsList(Map<String, Account> accounts) {
    if (accounts.isEmpty) {
      return Center(
        child: Text(
          FlutterI18n.translate(context, 'taskManagerPage.noAccounts'),
          style: const TextStyle(fontSize: 16, color: Colors.white70),
        ),
      );
    }

    return ListView.builder(
      itemCount: accounts.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final userId = accounts.keys.elementAt(index);
        final account = accounts[userId]!;

        return Card(
          color: Colors.grey[850],
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildUserHeader(account, false, userId),
          ),
        );
      },
    );
  }

  Widget _buildUserHeader(Account? account, bool isOffline, String userId) {
    return Consumer(
      builder: (context, ref, child) {
        final isXuidVisible = ref.watch(xuidVisibilityProvider(userId));

        return Row(
          children: [
            UserIcon(account: account, size: 36, borderRadius: 8),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isOffline
                        ? FlutterI18n.translate(
                          context,
                          'taskManagerPage.offlineUser',
                        )
                        : account?.profile?.name ??
                            FlutterI18n.translate(
                              context,
                              'taskManagerPage.unknownUser',
                            ),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          isOffline
                              ? FlutterI18n.translate(
                                context,
                                'taskManagerPage.userId',
                                translationParams: {'id': userId},
                              )
                              : isXuidVisible
                              ? FlutterI18n.translate(
                                context,
                                'taskManagerPage.xuid',
                                translationParams: {
                                  'id': account?.xuid ?? 'N/A',
                                },
                              )
                              : FlutterI18n.translate(
                                context,
                                'taskManagerPage.xuidHidden',
                              ),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      if (!isOffline && account?.xuid != null)
                        GestureDetector(
                          onTap: () {
                            ref
                                .read(xuidVisibilityProvider(userId).notifier)
                                .state = !isXuidVisible;
                          },
                          child: Icon(
                            isXuidVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                            size: 16,
                            color: Colors.grey,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProfileItem(
    String profileId,
    String profileName,
    UserProgress? progress,
    String userId,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          const Icon(Icons.play_circle_outline, color: Colors.green, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profileName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (progress != null)
                  LinearProgressIndicator(
                    value: progress.value,
                    backgroundColor: Colors.grey[700],
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.green,
                    ),
                  ),
                if (progress != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      progress.text,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
