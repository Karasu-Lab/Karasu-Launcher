import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

class GameContent extends ConsumerWidget {
  const GameContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Text(FlutterI18n.translate(context, 'gameContent.tabContent')),
    );
  }
}
