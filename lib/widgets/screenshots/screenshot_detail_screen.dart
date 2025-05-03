import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:karasu_launcher/models/screenshot.dart';
import 'package:karasu_launcher/providers/screenshots_provider.dart';
import 'package:karasu_launcher/widgets/common/confirmation_dialog.dart';
import 'package:karasu_launcher/widgets/common/error_dialog.dart';
import 'package:karasu_launcher/widgets/common/feature_in_development_dialog.dart';
import 'package:karasu_launcher/widgets/screenshots/screenshot_comment_dialog.dart';
import 'package:path/path.dart' as path;

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
                Text('コメント', style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                PopupMenuButton(
                  icon: const Icon(Icons.more_vert),
                  tooltip: 'コメントを編集',
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
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit),
                              SizedBox(width: 12),
                              Text('コメントを編集'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline),
                              SizedBox(width: 12),
                              Text('コメントを削除'),
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
                          : 'コメントはありません。タップして編集できます。',
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
                'タップでコメントを編集',
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
      title: 'Delete confirm',
      content: 'Are you sure you want to delete this screenshot?',
      cancelText: 'Cancel',
      confirmText: 'Delete',
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
          await ErrorDialog.show(context, message: 'ファイル削除中にエラーが発生しました: $e');
        }
      }
    }
  }
}
