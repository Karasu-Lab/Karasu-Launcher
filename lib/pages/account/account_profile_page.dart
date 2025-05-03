import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:karasu_launcher/widgets/minecraft_face.dart';
import 'package:karasu_launcher/widgets/account/sign_out_dialog.dart';
import '../../providers/authentication_provider.dart';

class AccountProfilePage extends ConsumerWidget {
  const AccountProfilePage({super.key, required this.microsoftId});

  final String microsoftId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authenticationProvider);
    final account = authState.accounts[microsoftId];

    Future<void> confirmSignOut() async {
      final result = await SignOutDialog.show(
        context,
        accountName: account?.profile?.name ?? 'このアカウント',
        onSignOut: () async {
          await ref
              .read(authenticationProvider.notifier)
              .logoutMicrosoftAccount(microsoftId);
        },
      );

      if (result && context.mounted) {
        context.go('/accounts');
      }
    }

    final ownsMinecraft = account?.profile != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('アカウントプロフィール'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child:
            account == null
                ? const Center(child: Text('アカウント情報が見つかりません'))
                : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Column(
                        children: [
                          SizedBox(
                            width: 80,
                            height: 80,
                            child: MinecraftFace.network(
                              account.profile!.skinUrl!,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            account.profile?.name ?? 'ユーザー名不明',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'アカウント情報',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      title: const Text('Minecraft ID'),
                      subtitle: Text(account.profile!.id),
                      leading: const Icon(Icons.account_circle),
                    ),
                    ListTile(
                      title: const Text('Minecraft Java Edition'),
                      subtitle: Text(ownsMinecraft ? '所有権あり' : '所有権なし'),
                      leading: Icon(
                        ownsMinecraft ? Icons.check_circle : Icons.cancel,
                        color: ownsMinecraft ? Colors.green : Colors.red,
                      ),
                    ),
                    ListTile(
                      title: const Text('トークン情報'),
                      subtitle: Text(
                        account.hasValidMinecraftToken
                            ? 'Minecraftトークン有効'
                            : 'Minecraftトークン無効',
                      ),
                      leading: const Icon(Icons.token),
                    ),
                    const Spacer(),
                    Center(
                      child: ElevatedButton(
                        onPressed: confirmSignOut,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        child: const Text('サインアウト'),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
      ),
    );
  }
}
