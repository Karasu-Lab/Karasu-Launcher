import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:image_clipboard/image_clipboard.dart';
import 'package:karasu_launcher/models/screenshot.dart';
import 'package:karasu_launcher/providers/screenshots_provider.dart';
import 'package:karasu_launcher/widgets/common/confirmation_dialog.dart';
import 'package:karasu_launcher/widgets/common/error_dialog.dart';
import 'package:karasu_launcher/widgets/common/feature_in_development_dialog.dart';
import 'package:karasu_launcher/widgets/screenshots/screenshot_comment_dialog.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class ScreenshotDetailScreen extends ConsumerStatefulWidget {
  final File screenshot;
  final String profileName;
  final VoidCallback? onScreenshotDeleted;

  const ScreenshotDetailScreen({
    super.key,
    required this.screenshot,
    required this.profileName,
    this.onScreenshotDeleted,
  });

  @override
  ConsumerState<ScreenshotDetailScreen> createState() =>
      _ScreenshotDetailScreenState();
}

class _ScreenshotDetailScreenState
    extends ConsumerState<ScreenshotDetailScreen> {
  Screenshot? currentScreenshot;

  @override
  void initState() {
    super.initState();
    _loadScreenshot();
  }

  void _loadScreenshot() {
    final screenshotsNotifier = ref.read(
      screenshotsCollectionProvider.notifier,
    );

    List<Screenshot> allScreenshots = screenshotsNotifier.getAllScreenshots();

    for (var shot in allScreenshots) {
      if (shot.filePath == widget.screenshot.path) {
        setState(() {
          currentScreenshot = shot;
        });
        break;
      }
    }
  }

  void _refreshScreenshot() {
    setState(() {
      _loadScreenshot();
    });
  }

  Future<String> saveImageToFile(Uint8List imageData) async {
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/image.png');
    await file.writeAsBytes(imageData);
    return file.path;
  }

  Future<void> copyImageToClipboard(Uint8List imageData) async {
    final imagePath = await saveImageToFile(imageData);
    final normalizedPath = imagePath.replaceAll('\\', '/');
    final imageClipboard = ImageClipboard();
    await imageClipboard.copyImage(normalizedPath);
  }

  Future<void> _copyImageToClipboard() async {
    try {
      final bytes = await widget.screenshot.readAsBytes();
      copyImageToClipboard(bytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              FlutterI18n.translate(context, "screenshotDetailScreen.copied"),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        await ErrorDialog.show(
          context,
          message: FlutterI18n.translate(
            context,
            "screenshotDetailScreen.copyFailed",
            translationParams: {"error": e.toString()},
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final fileName = path.basename(widget.screenshot.path);
    final screenshotsNotifier = ref.read(
      screenshotsCollectionProvider.notifier,
    );

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(fileName),
            Text(widget.profileName, style: const TextStyle(fontSize: 12)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: FlutterI18n.translate(
              context,
              "screenshotDetailScreen.copyToClipboard",
            ),
            onPressed: _copyImageToClipboard,
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              FeatureInDevelopmentDialog.show(context);
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed:
                () => _confirmAndDeleteScreenshot(context, currentScreenshot),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: InteractiveViewer(
                panEnabled: true,
                boundaryMargin: const EdgeInsets.all(20),
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.file(widget.screenshot),
              ),
            ),
            const SizedBox(width: 16),

            if (currentScreenshot != null)
              Expanded(
                flex: 2,
                child: _buildCommentSection(
                  context,
                  currentScreenshot!,
                  screenshotsNotifier,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentSection(
    BuildContext context,
    Screenshot currentScreenshot,
    dynamic screenshotsNotifier,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  FlutterI18n.translate(
                    context,
                    "screenshotDetailScreen.comment",
                  ),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                PopupMenuButton(
                  icon: const Icon(Icons.more_vert),
                  tooltip: FlutterI18n.translate(
                    context,
                    "screenshotDetailScreen.editComment",
                  ),
                  onSelected: (value) {
                    if (value == 'edit') {
                      ScreenshotCommentDialog.show(
                        context,
                        currentScreenshot,
                      ).then((updatedScreenshot) {
                        if (updatedScreenshot != null && context.mounted) {
                          _refreshScreenshot();
                        }
                      });
                    } else if (value == 'delete') {
                      final updatedScreenshot = currentScreenshot.copyWith(
                        comment: '',
                      );

                      ref
                          .read(screenshotsCollectionProvider.notifier)
                          .updateScreenshotComment(
                            currentScreenshot.id,
                            updatedScreenshot,
                          )
                          .then((_) {
                            if (context.mounted) {
                              _refreshScreenshot();
                            }
                          });
                    }
                  },
                  itemBuilder:
                      (context) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              const Icon(Icons.edit),
                              const SizedBox(width: 12),
                              Text(
                                FlutterI18n.translate(
                                  context,
                                  "screenshotDetailScreen.editComment",
                                ),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              const Icon(Icons.delete_outline),
                              const SizedBox(width: 12),
                              Text(
                                FlutterI18n.translate(
                                  context,
                                  "screenshotDetailScreen.deleteComment",
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: GestureDetector(
                onTap:
                    () => ScreenshotCommentDialog.show(
                      context,
                      currentScreenshot,
                    ).then((updatedScreenshot) {
                      if (updatedScreenshot != null && context.mounted) {
                        _refreshScreenshot();
                      }
                    }),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest
                        .withAlpha((0.3 * 255).toInt()),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      currentScreenshot.comment?.isNotEmpty == true
                          ? currentScreenshot.comment!
                          : FlutterI18n.translate(
                            context,
                            "screenshotDetailScreen.noComment",
                          ),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color:
                            currentScreenshot.comment?.isNotEmpty == true
                                ? Theme.of(context).textTheme.bodyMedium?.color
                                : Theme.of(context).textTheme.bodyMedium?.color
                                    ?.withAlpha((0.6 * 255).toInt()),
                        fontStyle:
                            currentScreenshot.comment?.isNotEmpty == true
                                ? FontStyle.normal
                                : FontStyle.italic,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                FlutterI18n.translate(
                  context,
                  "screenshotDetailScreen.tapToEdit",
                ),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmAndDeleteScreenshot(
    BuildContext context,
    Screenshot? currentScreenshot,
  ) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: FlutterI18n.translate(
        context,
        "screenshotDetailScreen.deleteConfirm.title",
      ),
      content: FlutterI18n.translate(
        context,
        "screenshotDetailScreen.deleteConfirm.message",
      ),
      cancelText: FlutterI18n.translate(
        context,
        "screenshotDetailScreen.deleteConfirm.cancel",
      ),
      confirmText: FlutterI18n.translate(
        context,
        "screenshotDetailScreen.deleteConfirm.confirm",
      ),
    );

    if (confirmed) {
      try {
        if (currentScreenshot != null) {
          await ref
              .read(screenshotsCollectionProvider.notifier)
              .removeScreenshot(currentScreenshot.id);
        } else {
          await widget.screenshot.delete();
        }

        if (context.mounted) {
          Navigator.of(context).pop();
          if (widget.onScreenshotDeleted != null) {
            widget.onScreenshotDeleted!();
          }
        }
      } catch (e) {
        if (context.mounted) {
          await ErrorDialog.show(
            context,
            message: FlutterI18n.translate(
              context,
              "screenshotDetailScreen.error.deleteFailed",
              translationParams: {"error": e.toString()},
            ),
          );
        }
      }
    }
  }
}
