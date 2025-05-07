import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:karasu_launcher/providers/loading_provider.dart';

class WindowButtons extends ConsumerWidget {
  const WindowButtons({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loadingState = ref.watch(loadingProvider);
    final isLoading = loadingState.isLoading;

    final buttonColors = WindowButtonColors(
      iconNormal: Colors.white,
      mouseOver: Colors.deepPurple.shade300,
      mouseDown: Colors.deepPurple.shade500,
      iconMouseOver: Colors.white,
      iconMouseDown: Colors.white,
    );

    final closeButtonColors = WindowButtonColors(
      iconNormal: Colors.white,
      mouseOver: Colors.red,
      mouseDown: Colors.red.shade700,
      iconMouseOver: Colors.white,
      iconMouseDown: Colors.white,
    );

    final loadingButtons = Row(
      children: [
        MinimizeWindowButton(colors: buttonColors),
        MaximizeWindowButton(colors: buttonColors),
        CloseWindowButton(colors: closeButtonColors),
      ],
    );

    final completeButtons = Row(
      children: [
        IconButton(
          onPressed: () {
            context.go('/about');
          },
          icon: const Icon(Icons.info),
        ),
        MinimizeWindowButton(colors: buttonColors),
        MaximizeWindowButton(colors: buttonColors),
        CloseWindowButton(colors: closeButtonColors),
      ],
    );

    return isLoading ? loadingButtons : completeButtons;
  }
}
