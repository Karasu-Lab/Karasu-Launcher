import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SocialHomePage extends StatelessWidget {
  const SocialHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('ソーシャル連携', style: TextStyle(fontSize: 24)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () => context.go('/social/github'),
                child: const Text('GitHubを開く'),
              ),
              const SizedBox(width: 20),
              ElevatedButton(
                onPressed: () => context.go('/social/twitter'),
                child: const Text('Twitterを開く'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
