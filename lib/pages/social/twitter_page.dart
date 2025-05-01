import 'package:flutter/material.dart';

class TwitterPage extends StatelessWidget {
  const TwitterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Twitter連携', style: TextStyle(fontSize: 24)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              // Twitterの操作
            },
            child: const Text('Twitterと連携する'),
          ),
        ],
      ),
    );
  }
}
