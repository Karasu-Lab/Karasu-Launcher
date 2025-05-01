import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AccountSignOutPage extends StatelessWidget {
  const AccountSignOutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('サインアウト'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('サインアウトしますか？', style: TextStyle(fontSize: 24)),
            const SizedBox(height: 20),
            const Text(
              'アカウントからサインアウトすると、ログイン情報が削除されます。',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    // サインアウト処理
                    // TODO: 実際のサインアウトロジックを実装
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('サインアウトしました')));
                    context.go('/accounts');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child: const Text('サインアウト'),
                ),
                const SizedBox(width: 16),
                TextButton(
                  onPressed: () {
                    // キャンセル処理
                    context.pop();
                  },
                  child: const Text('キャンセル'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
