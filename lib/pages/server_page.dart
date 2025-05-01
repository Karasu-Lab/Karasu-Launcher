import 'package:flutter/material.dart';

class ServerPage extends StatelessWidget {
  const ServerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Minecraft サーバー管理', style: TextStyle(fontSize: 24)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              // サーバー起動などの操作
            },
            child: const Text('サーバーを起動'),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              // サーバー設定などの操作
            },
            child: const Text('サーバー設定'),
          ),
        ],
      ),
    );
  }
}
