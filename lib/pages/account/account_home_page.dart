import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:karasu_launcher/widgets/minecraft_face.dart';
import '../../providers/authentication_provider.dart';

class AccountHomePage extends ConsumerStatefulWidget {
  const AccountHomePage({super.key});

  @override
  ConsumerState<AccountHomePage> createState() => _AccountHomePageState();
}

class _AccountHomePageState extends ConsumerState<AccountHomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  String? _switchingAccountId;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authenticationProvider);
    final activeAccount = ref.watch(activeAccountProvider);
    final accounts = authState.accounts;
    final isRefreshing = authState.isRefreshing;
    final isOfflineMode = activeAccount == null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('アカウント管理'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Minecraftアカウント',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                if (isOfflineMode)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withAlpha((0.2 * 255).toInt()),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange),
                    ),
                    child: const Text(
                      'オフラインモード',
                      style: TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),

            if (accounts.isEmpty) ...[
              const Center(
                child: Text('アカウントがありません', style: TextStyle(fontSize: 16)),
              ),
            ] else ...[
              if (isOfflineMode)
                Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.orange, width: 2),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    leading: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.orange.withAlpha((0.2 * 255).toInt()),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.videogame_asset_outlined,
                        color: Colors.orange,
                        size: 20,
                      ),
                    ),
                    title: const Text(
                      'オフラインモード',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                    subtitle: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 4),
                        Text(
                          'アクティブなアカウント',
                          style: TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          'デモモードでMinecraftを起動します',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  itemCount: accounts.entries.length,
                  itemBuilder: (context, index) {
                    final entry = accounts.entries.elementAt(index);
                    final account = entry.value;
                    final isActive =
                        activeAccount != null && account.id == activeAccount.id;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: isActive ? 4 : 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side:
                            _switchingAccountId == account.id
                                ? BorderSide(
                                  color:
                                      HSVColor.fromAHSV(
                                        1.0,
                                        (_animationController.value * 360) %
                                            360,
                                        1.0,
                                        1.0,
                                      ).toColor(),
                                  width: 2,
                                )
                                : isActive
                                ? const BorderSide(color: Colors.blue, width: 2)
                                : BorderSide.none,
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading:
                            account.profile?.skinUrl != null
                                ? SizedBox(
                                  width: 32,
                                  height: 32,
                                  child: MinecraftFace.network(
                                    account.profile!.skinUrl!,
                                  ),
                                )
                                : const CircleAvatar(child: Icon(Icons.person)),
                        title: Text(
                          account.profile?.name ?? 'Unknown',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              isActive ? 'アクティブなアカウント' : '',
                              style: const TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              account.hasValidMinecraftToken
                                  ? '認証済み'
                                  : 'トークン期限切れ',
                              style: TextStyle(
                                color:
                                    account.hasValidMinecraftToken
                                        ? Colors.green
                                        : Colors.red,
                              ),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!isActive)
                              IconButton(
                                icon: const Icon(Icons.check_circle_outline),
                                tooltip: 'アクティブにする',
                                onPressed: () async {
                                  setState(() {
                                    _switchingAccountId = account.id;
                                  });

                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('アカウントを切り替えています...'),
                                        duration: Duration(seconds: 1),
                                      ),
                                    );
                                  }

                                  final isTokenValid = await ref
                                      .read(authenticationProvider.notifier)
                                      .setActiveAccount(account.id);

                                  setState(() {
                                    _switchingAccountId = null;
                                  });

                                  if (context.mounted) {
                                    if (isTokenValid) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            '${account.profile?.name ?? "Unknown"}をアクティブアカウントに設定しました',
                                          ),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            '${account.profile?.name ?? "Unknown"}をアクティブアカウントに設定しましたが、トークンの検証に失敗しました。「トークンを更新」ボタンをお試しください。',
                                          ),
                                          backgroundColor: Colors.orange,
                                          duration: const Duration(seconds: 5),
                                        ),
                                      );
                                    }
                                  }
                                },
                              ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),
                              tooltip: '削除',
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder:
                                      (ctx) => AlertDialog(
                                        title: const Text('アカウント削除'),
                                        content: Text(
                                          '${account.profile?.name ?? "Unknown"}のアカウントを削除しますか？',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed:
                                                () => Navigator.of(ctx).pop(),
                                            child: const Text('キャンセル'),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              Navigator.of(ctx).pop();
                                              ref
                                                  .read(
                                                    authenticationProvider
                                                        .notifier,
                                                  )
                                                  .removeAccount(account.id);
                                            },
                                            child: const Text(
                                              '削除',
                                              style: TextStyle(
                                                color: Colors.red,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 20),

            Center(
              child: Column(
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(220, 45),
                      backgroundColor: Theme.of(context).primaryColor,
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text(
                      '新規アカウント追加',
                      style: TextStyle(fontSize: 16),
                    ),
                    onPressed: () => context.go('/accounts/sign-in'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(220, 45),
                      backgroundColor:
                          isOfflineMode
                              ? Colors.orange.withAlpha((0.1 * 255).toInt())
                              : null,
                      side: BorderSide(
                        color:
                            isOfflineMode
                                ? Colors.orange
                                : Colors.grey.shade400,
                      ),
                    ),
                    icon: Icon(
                      isOfflineMode
                          ? Icons.login
                          : Icons.videogame_asset_outlined,
                    ),
                    label: Text(
                      isOfflineMode ? 'オンラインモードに戻る' : 'オフラインモードに切り替え',
                      style: TextStyle(
                        fontSize: 16,
                        color: isOfflineMode ? Colors.orange : null,
                      ),
                    ),
                    onPressed: () async {
                      if (isOfflineMode) {
                        if (accounts.isNotEmpty) {
                          final lastUsedAccount =
                              await ref
                                  .read(authenticationProvider.notifier)
                                  .restoreLastActiveAccount();

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  lastUsedAccount != null
                                      ? '${lastUsedAccount.profile?.name ?? "Unknown"}でオンラインモードに戻りました'
                                      : 'アカウントを選択してください',
                                ),
                                backgroundColor:
                                    lastUsedAccount != null
                                        ? Colors.green
                                        : Colors.orange,
                              ),
                            );
                          }
                        }
                      } else {
                        await ref
                            .read(authenticationProvider.notifier)
                            .clearActiveAccount();

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('オフラインモードに切り替えました'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  if (authState.isAuthenticated) ...[
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(220, 45),
                      ),
                      icon:
                          isRefreshing
                              ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.blue,
                                  ),
                                ),
                              )
                              : const Icon(Icons.refresh),
                      label: Text(
                        isRefreshing ? '更新中...' : 'トークンを更新',
                        style: const TextStyle(fontSize: 16),
                      ),
                      onPressed:
                          isRefreshing
                              ? null
                              : () async {
                                final profile =
                                    await ref
                                        .read(authenticationProvider.notifier)
                                        .refreshActiveAccount();

                                if (context.mounted) {
                                  if (profile != null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          '${profile.name}のトークンを更新しました',
                                        ),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  } else {
                                    final account =
                                        ref
                                            .read(authenticationProvider)
                                            .activeAccount;
                                    if (account != null &&
                                        account.hasValidMinecraftToken) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'トークンを更新しました (${account.profile?.name ?? "Unknown"})',
                                          ),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('トークンの更新に失敗しました'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                }
                              },
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(220, 45),
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                      icon: const Icon(Icons.logout),
                      label: const Text(
                        'ログアウト',
                        style: TextStyle(fontSize: 16),
                      ),
                      onPressed: () => context.go('/accounts/sign-out'),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
