import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:karasu_launcher/widgets/java_path_selector.dart';

class JavaSettingsPage extends ConsumerStatefulWidget {
  const JavaSettingsPage({Key? key}) : super(key: key);

  @override
  ConsumerState<JavaSettingsPage> createState() => _JavaSettingsPageState();
}

class _JavaSettingsPageState extends ConsumerState<JavaSettingsPage> {
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            FlutterI18n.translate(context, 'settingsPage.java'),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 8.0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                FlutterI18n.translate(
                  context,
                  'settingsPage.javaPath.title',
                ),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              const JavaPathSelector(requiredVersion: '17'),
            ],
          ),
        ),
        const Divider(),
      ],
    );
  }
}
