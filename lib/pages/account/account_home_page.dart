import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:karasu_launcher/models/auth/account.dart';
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
  bool _isReordering = false;
  String? _refreshingAccountId;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _switchAccount(String accountId) async {
    if (_switchingAccountId != null) return;

    setState(() {
      _switchingAccountId = accountId;
    });

    await ref.read(authenticationProvider.notifier).setActiveAccount(accountId);

    setState(() {
      _switchingAccountId = null;
    });
  }

  Decoration _getBorderDecoration(bool isActive, bool isSwitching) {
    if (isSwitching) {
      final double animValue = _animationController.value;

      final color = Color.lerp(Colors.blue, Colors.green, animValue)!;

      return BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(width: 2, color: color),
      );
    } else if (isActive) {
      return BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue, width: 2),
      );
    } else {
      return BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.transparent, width: 2),
      );
    }
  }

  Widget _buildAccountCard(Account account, bool isActive, int index) {
    final isSwitching = _switchingAccountId == account.id;

    Widget card;

    if (isSwitching) {
      card = AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return _buildCardWithDecoration(
            account,
            isActive,
            isSwitching,
            index,
          );
        },
      );
    } else {
      card = _buildCardWithDecoration(account, isActive, isSwitching, index);
    }

    return KeyedSubtree(key: ValueKey(account.id), child: card);
  }

  Widget _buildCardWithDecoration(
    Account account,
    bool isActive,
    bool isSwitching,
    int index,
  ) {
    final isRefreshing = _refreshingAccountId == account.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: _getBorderDecoration(isActive, isSwitching),
      padding: const EdgeInsets.all(2),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: isActive ? 4 : 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        clipBehavior: Clip.antiAlias,
        child: MouseRegion(
          cursor:
              isActive || _switchingAccountId != null
                  ? SystemMouseCursors.basic
                  : SystemMouseCursors.click,
          child: ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            onTap:
                isActive ||
                        _switchingAccountId != null ||
                        _refreshingAccountId != null
                    ? null
                    : () async {
                      setState(() {
                        _switchingAccountId = account.id;
                      });

                      await ref
                          .read(authenticationProvider.notifier)
                          .setActiveAccount(account.id);

                      setState(() {
                        _switchingAccountId = null;
                      });
                    },
            onLongPress:
                _switchingAccountId != null || _refreshingAccountId != null
                    ? null
                    : () {
                      context.go('/accounts/profiles/${account.id}');
                    },
            leading: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ReorderableDragStartListener(
                  index: index,
                  child: const Icon(
                    Icons.drag_handle,
                    color: Colors.grey,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 8),
                _isReordering
                    ? const SizedBox(width: 32, height: 32)
                    : isSwitching
                    ? SizedBox(
                      width: 32,
                      height: 32,
                      child: Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    )
                    : account.profile?.skinUrl != null
                    ? SizedBox(
                      width: 32,
                      height: 32,
                      child: MinecraftFace.network(
                        account.profile!.skinUrl!,
                        size: 32,
                        key: ValueKey('face_list_${account.id}'),
                      ),
                    )
                    : const CircleAvatar(child: Icon(Icons.person)),
              ],
            ),
            title: Text(
              account.profile?.name ?? 'Unknown',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  isActive
                      ? FlutterI18n.translate(
                        context,
                        'accountHome.activeAccount',
                      )
                      : '',
                  style: const TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  isRefreshing
                      ? FlutterI18n.translate(
                        context,
                        'accountHome.tokenRefreshing',
                      )
                      : account.hasValidMinecraftToken
                      ? FlutterI18n.translate(
                        context,
                        'accountHome.authenticated',
                      )
                      : FlutterI18n.translate(
                        context,
                        'accountHome.tokenExpired',
                      ),
                  style: TextStyle(
                    color:
                        isRefreshing
                            ? Colors.yellow
                            : account.hasValidMinecraftToken
                            ? Colors.green
                            : Colors.red,
                  ),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon:
                      isRefreshing
                          ? RotationTransition(
                            turns: _animationController..repeat(),
                            child: const Icon(
                              Icons.refresh,
                              color: Colors.blue,
                              size: 20,
                            ),
                          )
                          : const Icon(
                            Icons.refresh,
                            color: Colors.blue,
                            size: 20,
                          ),
                  tooltip: FlutterI18n.translate(
                    context,
                    'accountHome.refreshToken',
                  ),
                  onPressed:
                      _switchingAccountId != null ||
                              _refreshingAccountId != null
                          ? null
                          : () async {
                            setState(() {
                              _refreshingAccountId = account.id;
                              _switchingAccountId = account.id;
                              if (!_animationController.isAnimating) {
                                _animationController.reset();
                                _animationController.repeat();
                              }
                            });

                            if (!isActive) {
                              await ref
                                  .read(authenticationProvider.notifier)
                                  .setActiveAccount(account.id);
                            }

                            await ref
                                .read(authenticationProvider.notifier)
                                .refreshActiveAccount();

                            setState(() {
                              _refreshingAccountId = null;
                              _switchingAccountId = null;
                            });
                          },
                ),
                if (isActive == true)
                  IconButton(
                    icon: const Icon(Icons.check_box, color: Colors.green),
                    tooltip: FlutterI18n.translate(
                      context,
                      'accountHome.activeAccount',
                    ),
                    onPressed: null,
                  ),
                if (isActive == false)
                  IconButton(
                    icon: const Icon(
                      Icons.check_box_outline_blank_sharp,
                      color: Colors.grey,
                    ),
                    tooltip: 'アクティブにする',
                    onPressed:
                        _switchingAccountId != null ||
                                _refreshingAccountId != null
                            ? null
                            : () async {
                              setState(() {
                                _switchingAccountId = account.id;
                              });

                              await ref
                                  .read(authenticationProvider.notifier)
                                  .setActiveAccount(account.id);

                              setState(() {
                                _switchingAccountId = null;
                              });
                            },
                  ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios, size: 18),
                  tooltip: FlutterI18n.translate(
                    context,
                    'accountHome.profileDetails',
                  ),
                  onPressed:
                      _switchingAccountId != null ||
                              _refreshingAccountId != null
                          ? null
                          : () {
                            context.go('/accounts/profiles/${account.id}');
                          },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authenticationProvider);
    final activeAccount = ref.watch(activeAccountProvider);
    final accounts = authState.accounts;
    final isOfflineMode = activeAccount == null;

    return Scaffold(
      appBar: AppBar(
        title: Text(FlutterI18n.translate(context, 'accountHome.title')),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            tooltip: FlutterI18n.translate(context, 'accountHome.addAccount'),
            onPressed: () => context.go('/accounts/sign-in'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  FlutterI18n.translate(
                    context,
                    'accountHome.minecraftAccounts',
                  ),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isOfflineMode
                            ? Colors.orange.withAlpha((0.2 * 255).toInt())
                            : Colors.blue.withAlpha((0.2 * 255).toInt()),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isOfflineMode ? Colors.orange : Colors.blue,
                    ),
                  ),
                  child: Text(
                    FlutterI18n.translate(
                      context,
                      isOfflineMode
                          ? 'accountHome.offlineMode'
                          : 'accountHome.onlineMode',
                    ),
                    style: TextStyle(
                      color: isOfflineMode ? Colors.orange : Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            if (accounts.isEmpty) ...[
              Center(
                child: Text(
                  FlutterI18n.translate(context, 'accountHome.noAccounts'),
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ] else ...[
              Expanded(
                child: Column(
                  children: [
                    Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color:
                              isOfflineMode
                                  ? Colors.orange
                                  : Colors.transparent,
                          width: 2,
                        ),
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
                        title: Text(
                          FlutterI18n.translate(
                            context,
                            'accountHome.offlineMode',
                          ),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              FlutterI18n.translate(
                                context,
                                'accountHome.demoMode',
                              ),
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: ReorderableListView.builder(
                        buildDefaultDragHandles: false,
                        itemCount: accounts.entries.length,
                        onReorderStart: (_) {
                          if (_switchingAccountId != null ||
                              _refreshingAccountId != null) {
                            return;
                          }
                          setState(() {
                            _isReordering = true;
                          });
                        },
                        onReorderEnd: (_) {
                          setState(() {
                            _isReordering = false;
                          });
                        },
                        onReorder: (oldIndex, newIndex) async {
                          if (_switchingAccountId != null ||
                              _refreshingAccountId != null) {
                            return;
                          }

                          final success = await ref
                              .read(authenticationProvider.notifier)
                              .swapAccountIndexes(oldIndex, newIndex);

                          if (success && context.mounted) {
                            debugPrint(
                              "アカウントの順序を変更しました: $oldIndex → $newIndex",
                            );
                          }
                        },
                        itemBuilder: (context, index) {
                          final entry = accounts.entries.elementAt(index);
                          final account = entry.value;
                          final isActive =
                              activeAccount != null &&
                              account.id == activeAccount.id;

                          return _buildAccountCard(account, isActive, index);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            Center(
              child: Column(
                children: [
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
                      isOfflineMode
                          ? FlutterI18n.translate(
                            context,
                            'accountHome.toggleToOnline',
                          )
                          : FlutterI18n.translate(
                            context,
                            'accountHome.toggleToOffline',
                          ),
                      style: TextStyle(
                        fontSize: 16,
                        color: isOfflineMode ? Colors.orange : null,
                      ),
                    ),
                    onPressed: () async {
                      if (isOfflineMode) {
                        if (accounts.isNotEmpty) {
                          await ref
                              .read(authenticationProvider.notifier)
                              .restoreLastActiveAccount();
                        }
                      } else {
                        await ref
                            .read(authenticationProvider.notifier)
                            .clearActiveAccount();
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
