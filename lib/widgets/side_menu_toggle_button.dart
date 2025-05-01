import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/side_menu_provider.dart';

class SideMenuToggleButton extends ConsumerWidget {
  const SideMenuToggleButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOpen = ref.watch(sideMenuOpenProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0), // 垂直パディングを調整
      child: IconButton(
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return ScaleTransition(scale: animation, child: child);
          },
          child: Icon(
            isOpen ? Icons.menu_open : Icons.menu,
            key: ValueKey<bool>(isOpen),
            color: Colors.white,
            size: 24,
          ),
        ),
        onPressed: () {
          ref.read(sideMenuOpenProvider.notifier).state = !isOpen;
        },
        tooltip: isOpen ? 'メニューを閉じる' : 'メニューを開く',
        padding: const EdgeInsets.all(6.0),
        constraints: const BoxConstraints(minWidth: 40.0, minHeight: 40.0),
        splashColor: Colors.transparent,
        hoverColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
    );
  }
}
