import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:karasu_launcher/pages/settings/settings_layout.dart';
import 'package:karasu_launcher/pages/settings/general_settings_page.dart';
import 'package:karasu_launcher/pages/settings/java_settings_page.dart';
import 'package:karasu_launcher/pages/settings/data_management_page.dart';
import 'package:karasu_launcher/providers/router_provider.dart';

enum SettingsSection { general, java, data }

final settingsRouterProvider = createRouterProvider<SettingsSection>(
  SettingsSection.general,
);

class SettingsPage extends ConsumerStatefulWidget {
  final String section;

  const SettingsPage({super.key, this.section = 'general'});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeRouterFromSection(widget.section);
    });
  }

  void _initializeRouterFromSection(String sectionName) {
    final section = _getSectionFromString(sectionName);
    if (ref.read(settingsRouterProvider).currentRoute != section) {
      ref.read(settingsRouterProvider.notifier).navigate(section);
    }
  }

  SettingsSection _getSectionFromString(String section) {
    switch (section) {
      case 'general':
        return SettingsSection.general;
      case 'java':
        return SettingsSection.java;
      case 'data':
        return SettingsSection.data;
      default:
        return SettingsSection.general;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentSection = ref.watch(settingsRouterProvider).currentRoute;

    return SettingsLayout(
      currentSection: currentSection,
      onSectionChanged: (section) {
        ref.read(settingsRouterProvider.notifier).navigate(section);
      },
      child: _getSettingsPage(currentSection),
    );
  }

  Widget _getSettingsPage(SettingsSection section) {
    switch (section) {
      case SettingsSection.general:
        return const GeneralSettingsPage();
      case SettingsSection.java:
        return const JavaSettingsPage();
      case SettingsSection.data:
        return const DataManagementPage();
    }
  }
}
