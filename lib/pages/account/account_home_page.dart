import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AccountHomePage extends StatelessWidget {
  const AccountHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('アカウント管理'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'アカウント管理画面',
              style: TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 20),
            const Text('アカウント情報や設定を管理します'),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => context.go('/accounts/sign-in'),
              child: const Text('サインイン'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => context.go('/accounts/add'),
              child: const Text('新規アカウント作成'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => context.go('/accounts/profile'),
              child: const Text('プロファイル'),
            ),
          ],
        ),
      ),
    );
  }
}
