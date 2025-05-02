import 'package:flutter/material.dart';

class AccountAddPage extends StatelessWidget {
  const AccountAddPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('アカウント追加'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('新規アカウント追加', style: TextStyle(fontSize: 24)),
              const SizedBox(height: 20),
              const TextField(
                decoration: InputDecoration(
                  labelText: 'ユーザー名',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              const TextField(
                decoration: InputDecoration(
                  labelText: 'メールアドレス',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              const TextField(
                decoration: InputDecoration(
                  labelText: 'パスワード',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 24),
              ElevatedButton(onPressed: () {}, child: const Text('アカウント作成')),
            ],
          ),
        ),
      ),
    );
  }
}
