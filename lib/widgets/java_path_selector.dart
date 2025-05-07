import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import '../providers/java_provider.dart';

class JavaPathSelector extends ConsumerStatefulWidget {
  final String requiredVersion;

  const JavaPathSelector({super.key, required this.requiredVersion});

  @override
  ConsumerState<JavaPathSelector> createState() => _JavaPathSelectorState();
}

class _JavaPathSelectorState extends ConsumerState<JavaPathSelector> {
  bool? _isValidVersion;
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: ref.read(javaProvider).customJavaHome,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _checkJavaVersion(BuildContext context, String? path) async {
    if (path == null) {
      setState(() => _isValidVersion = false);
      return;
    }
    final javaprovider = ref.read(javaProvider);
    final isValid = await javaprovider.checkJavaVersion(
      '$path/bin/${Platform.isWindows ? 'javaw.exe' : 'java'}',
    );

    setState(() => _isValidVersion = isValid);
    if (isValid) {
      javaprovider.customJavaHome = path;
    }
  }

  @override
  Widget build(BuildContext context) {
    final javaprovider = ref.watch(javaProvider);

    // JavaHomeが変更された場合、コントローラーのテキストを更新
    if (javaprovider.customJavaHome != _controller.text) {
      _controller.text = javaprovider.customJavaHome ?? '';
    }

    return Row(
      children: [
        if (_isValidVersion != null)
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Icon(
              _isValidVersion == true ? Icons.check_circle : Icons.error,
              color: _isValidVersion == true ? Colors.green : Colors.red,
            ),
          ),
        Expanded(
          child: TextField(
            controller: _controller,
            onChanged: (value) {
              javaprovider.customJavaHome = value;
              _checkJavaVersion(context, value);
            },
            decoration: InputDecoration(
              hintText: FlutterI18n.translate(
                context,
                'javaPathSelector.selectJavaHome',
              ),
              border: const OutlineInputBorder(),
            ),
            readOnly: true,
          ),
        ),
        IconButton(
          onPressed: () async {
            final result = await FilePicker.platform.getDirectoryPath(
              dialogTitle: FlutterI18n.translate(
                context,
                'javaPathSelector.dialogTitle',
              ),
            );
            if (result != null) {
              javaprovider.customJavaHome = result;
              if (context.mounted) {
                _checkJavaVersion(context, result);
              }
            }
          },
          icon: const Icon(Icons.folder),
        ),
      ],
    );
  }
}
