import 'package:flutter/material.dart';
import 'package:karasu_launcher/pages/settings/settings_page.dart';
import 'package:karasu_launcher/widgets/settings/animated_settings_menu.dart';

class SettingsLayout extends StatelessWidget {
  final Widget child;
  final SettingsSection currentSection;
  final Function(SettingsSection) onSectionChanged;

  const SettingsLayout({
    super.key,
    required this.child,
    required this.currentSection,
    required this.onSectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: Row(
        children: [
          AnimatedSettingsMenu(
            currentSection: currentSection,
            onSectionChanged: onSectionChanged,
          ),
          const VerticalDivider(width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }
}
