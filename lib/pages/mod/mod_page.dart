import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ModPage extends StatelessWidget {
  const ModPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Mod管理ページ', style: TextStyle(fontSize: 24)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => context.go('/mod/modrinth'),
            child: const Text('Modrinthを開く'),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () => context.go('/mod/curseforge'),
            child: const Text('CurseForgeを開く'),
          ),
        ],
      ),
    );
  }
}
