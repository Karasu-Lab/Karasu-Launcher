import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:karasu_launcher/models/auth/minecraft_profile.dart';
import 'package:karasu_launcher/models/auth/account.dart';
import 'package:karasu_launcher/providers/authentication_provider.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

class XboxAccountTile extends ConsumerWidget {
  final Account account;
  final bool isActive;
  final VoidCallback? onTap;
  final VoidCallback? onSignOut;
  final VoidCallback? onRefresh;

  const XboxAccountTile({
    super.key,
    required this.account,
    this.isActive = false,
    this.onTap,
    this.onSignOut,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = account.profile;
    final hasValidToken =
        account.hasValidMinecraftToken && account.hasValidXboxToken;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color:
            isActive
                ? Theme.of(context).colorScheme.primaryContainer
                : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              isActive
                  ? Theme.of(context).colorScheme.primary
                  : Colors.transparent,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color.fromRGBO(0, 0, 0, 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                _buildProfileAvatar(profile),
                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        profile?.name ??
                            FlutterI18n.translate(
                              context,
                              "xboxAccount.unknown",
                            ),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color:
                              isActive
                                  ? Theme.of(context).colorScheme.primary
                                  : null,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hasValidToken
                            ? FlutterI18n.translate(
                              context,
                              "xboxAccount.authenticated",
                            )
                            : FlutterI18n.translate(
                              context,
                              "xboxAccount.tokenRefreshRequired",
                            ),
                        style: TextStyle(
                          fontSize: 12,
                          color: hasValidToken ? Colors.green : Colors.red,
                        ),
                      ),
                      if (account.profile?.id != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          FlutterI18n.translate(
                            context,
                            "xboxAccount.uuid",
                            translationParams: {
                              "id": _formatUuid(account.profile!.id),
                            },
                          ),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),

                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (onRefresh != null)
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        tooltip: FlutterI18n.translate(
                          context,
                          "xboxAccount.refreshToken",
                        ),
                        onPressed: onRefresh,
                        visualDensity: VisualDensity.compact,
                      ),
                    if (onSignOut != null)
                      IconButton(
                        icon: const Icon(Icons.logout),
                        tooltip: FlutterI18n.translate(
                          context,
                          "xboxAccount.signOut",
                        ),
                        onPressed: onSignOut,
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileAvatar(MinecraftProfile? profile) {
    if (profile != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(color: Colors.grey[800]),
          child:
              profile.skinUrl != null
                  ? Image.network(
                    profile.skinUrl!,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (context, error, stackTrace) => const Icon(
                          Icons.account_box,
                          size: 32,
                          color: Colors.white70,
                        ),
                  )
                  : const Icon(
                    Icons.account_circle,
                    size: 32,
                    color: Colors.white70,
                  ),
        ),
      );
    } else {
      return Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          Icons.account_circle,
          size: 32,
          color: Colors.white70,
        ),
      );
    }
  }

  String _formatUuid(String uuid) {
    if (uuid.length == 32) {
      return '${uuid.substring(0, 8)}-${uuid.substring(8, 12)}-'
          '${uuid.substring(12, 16)}-${uuid.substring(16, 20)}-'
          '${uuid.substring(20)}';
    }
    return uuid;
  }
}

class XboxAccountButton extends ConsumerWidget {
  final VoidCallback? onAccountChanged;

  const XboxAccountButton({super.key, this.onAccountChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authenticationProvider);
    final activeAccount = authState.activeAccount;

    Widget avatarWidget = Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(Icons.account_circle, color: Colors.white70, size: 24),
    );

    if (activeAccount != null) {
      if (activeAccount.hasValidMinecraftToken) {
        if (activeAccount.profile?.skinUrl != null) {
          avatarWidget = ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              activeAccount.profile!.skinUrl!,
              width: 32,
              height: 32,
              fit: BoxFit.cover,
              errorBuilder:
                  (context, error, stackTrace) => Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.account_circle,
                      color: Colors.white70,
                      size: 24,
                    ),
                  ),
            ),
          );
        } else {
          avatarWidget = Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.account_box,
              color: Colors.white70,
              size: 24,
            ),
          );
        }
      } else {
        avatarWidget = Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.sports_esports,
            color: Colors.white70,
            size: 24,
          ),
        );
      }
    }

    return Tooltip(
      message: FlutterI18n.translate(context, "xboxAccount.title"),
      child: InkWell(
        onTap: () => _showAccountsDialog(context, ref),
        borderRadius: BorderRadius.circular(16),
        child: Padding(padding: const EdgeInsets.all(4.0), child: avatarWidget),
      ),
    );
  }

  Future<void> _showAccountsDialog(BuildContext context, WidgetRef ref) async {
    final authNotifier = ref.read(authenticationProvider.notifier);
    final authState = ref.read(authenticationProvider);

    await showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    FlutterI18n.translate(context, "xboxAccount.title"),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...authState.accounts.entries.map((entry) {
                    final account = entry.value;
                    final accountId = entry.key;
                    final isActive =
                        accountId == authState.activeMicrosoftAccountId;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: XboxAccountTile(
                        account: account,
                        isActive: isActive,
                        onTap:
                            isActive
                                ? null
                                : () async {
                                  await authNotifier.setActiveAccount(
                                    accountId,
                                  );
                                  if (onAccountChanged != null) {
                                    onAccountChanged!();
                                  }
                                  if (context.mounted) {
                                    Navigator.pop(context);
                                  }
                                },
                        onRefresh: () async {
                          if (isActive) {
                            await authNotifier.refreshActiveAccount();
                            if (onAccountChanged != null) {
                              onAccountChanged!();
                            }
                            if (context.mounted) {
                              Navigator.pop(context);
                            }
                          } else {
                            await authNotifier.setActiveAccount(accountId);
                            await authNotifier.refreshActiveAccount();
                            if (onAccountChanged != null) {
                              onAccountChanged!();
                            }
                            if (context.mounted) {
                              Navigator.pop(context);
                            }
                          }
                        },
                        onSignOut: () async {
                          final confirmed = await _confirmSignOut(
                            context,
                            account,
                          );
                          if (confirmed) {
                            await authNotifier.removeAccount(accountId);
                            if (onAccountChanged != null) {
                              onAccountChanged!();
                            }
                            if (context.mounted) {
                              Navigator.pop(context);
                            }
                          }
                        },
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: Text(
                        FlutterI18n.translate(
                          context,
                          "xboxAccount.addNewAccount",
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/accounts/add');
                      },
                    ),
                  ),

                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      child: Text(
                        FlutterI18n.translate(context, "xboxAccount.close"),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Future<bool> _confirmSignOut(BuildContext context, Account account) async {
    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(FlutterI18n.translate(context, "accountSignOut.title")),
            content: Text(
              FlutterI18n.translate(
                context,
                "accountSignOut.confirmationMessage",
                translationParams: {
                  "accountName":
                      account.profile?.name ??
                      FlutterI18n.translate(
                        context,
                        "accountProfile.thisAccount",
                      ),
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  FlutterI18n.translate(context, "accountSignOut.cancel"),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: Text(
                  FlutterI18n.translate(context, "accountSignOut.signOut"),
                ),
              ),
            ],
          ),
    );
    return result ?? false;
  }
}
