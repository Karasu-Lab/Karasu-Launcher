import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
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
        accountName:
            account?.profile?.name ??
            FlutterI18n.translate(context, 'accountProfile.thisAccount'),
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
        title: Text(FlutterI18n.translate(context, 'accountProfile.title')),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child:
            account == null
                ? Center(
                  child: Text(
                    FlutterI18n.translate(
                      context,
                      'accountProfile.accountNotFound',
                    ),
                  ),
                )
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
                            account.profile?.name ??
                                FlutterI18n.translate(
                                  context,
                                  'accountProfile.usernameUnknown',
                                ),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      FlutterI18n.translate(
                        context,
                        'accountProfile.accountInfo',
                      ),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      title: Text(
                        FlutterI18n.translate(
                          context,
                          'accountProfile.minecraftId',
                        ),
                      ),
                      subtitle: Text(account.profile!.id),
                      leading: const Icon(Icons.account_circle),
                    ),
                    ListTile(
                      title: Text(
                        FlutterI18n.translate(
                          context,
                          'accountProfile.minecraftJavaEdition',
                        ),
                      ),
                      subtitle: Text(
                        ownsMinecraft
                            ? FlutterI18n.translate(
                              context,
                              'accountProfile.hasOwnership',
                            )
                            : FlutterI18n.translate(
                              context,
                              'accountProfile.noOwnership',
                            ),
                      ),
                      leading: Icon(
                        ownsMinecraft ? Icons.check_circle : Icons.cancel,
                        color: ownsMinecraft ? Colors.green : Colors.red,
                      ),
                    ),
                    ListTile(
                      title: Text(
                        FlutterI18n.translate(
                          context,
                          'accountProfile.tokenInfo',
                        ),
                      ),
                      subtitle: Text(
                        account.hasValidMinecraftToken
                            ? FlutterI18n.translate(
                              context,
                              'accountProfile.valid',
                            )
                            : FlutterI18n.translate(
                              context,
                              'accountProfile.invalid',
                            ),
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
                        child: Text(
                          FlutterI18n.translate(
                            context,
                            'accountProfile.signOut',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
      ),
    );
  }
}
