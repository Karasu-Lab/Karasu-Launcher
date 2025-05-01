import 'package:flutter/material.dart';

class GitHubPage extends StatelessWidget {
  const GitHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('GitHub連携', style: TextStyle(fontSize: 24)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              // GitHubの操作
            },
            child: const Text('GitHubと連携する'),
          ),
        ],
      ),
    );
  }
}
