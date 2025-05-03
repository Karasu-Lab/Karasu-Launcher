import 'dart:io';

import 'package:flutter/material.dart';
import 'package:karasu_launcher/models/screenshot.dart';
import 'package:karasu_launcher/widgets/screenshots/screenshot_comment_dialog.dart';
import 'package:karasu_launcher/widgets/screenshots/screenshot_register_dialog.dart';
import 'package:path/path.dart' as path;

class ScreenshotTimelineItem extends StatelessWidget {
  final File screenshot;
  final String profileName;
  final DateTime dateTime;
  final String profileId;
  final Function(BuildContext, File, String) onTap;
  final List<Screenshot> allScreenshots;
  final Function(Screenshot) onEditComment;
  final bool showProfileChip;

  const ScreenshotTimelineItem({
    super.key,
    required this.screenshot,
    required this.profileName,
    required this.dateTime,
    required this.profileId,
    required this.onTap,
    required this.allScreenshots,
    required this.onEditComment,
    this.showProfileChip = true,
  });

  @override
  Widget build(BuildContext context) {
    final formattedTime =
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';

    final screenWidth = MediaQuery.of(context).size.width;
    const double timelineLeftMargin = 80.0;
    const double circleDiameter = 16.0;
    const double lineWidth = 2.0;
    const double rightMargin = 16.0;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: timelineLeftMargin,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 12.0, top: 16.0),
                  child: Text(
                    formattedTime,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(
            width: circleDiameter,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: lineWidth,
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withAlpha((0.5 * 255).toInt()),
                  ),
                ),

                Positioned(
                  top: 16.0,
                  child: Container(
                    width: circleDiameter,
                    height: circleDiameter,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).colorScheme.surface,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: GestureDetector(
              onTap: () => onTap(context, screenshot, profileName),
              child: Card(
                margin: const EdgeInsets.only(
                  left: 8.0,
                  right: rightMargin,
                  bottom: 16.0,
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildProfileChip(),
                        _buildScreenshotPreview(
                          context,
                          screenWidth,
                          timelineLeftMargin,
                          circleDiameter,
                          rightMargin,
                        ),
                        _buildFileName(context),
                      ],
                    ),

                    Positioned(
                      top: 0,
                      right: 0,
                      child: Material(
                        color: Colors.transparent,
                        child: IconButton(
                          icon: const Icon(Icons.edit_note),
                          tooltip: 'コメントを編集',
                          onPressed: () => _handleEditComment(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileChip() {
    return Visibility(
      visible: showProfileChip,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Chip(
          label: Text(profileName, style: const TextStyle(fontSize: 12)),
          padding: EdgeInsets.zero,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }

  Widget _buildScreenshotPreview(
    BuildContext context,
    double screenWidth,
    double timelineLeftMargin,
    double circleDiameter,
    double rightMargin,
  ) {
    return Container(
      width:
          screenWidth -
          timelineLeftMargin -
          circleDiameter -
          24.0 -
          rightMargin,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.3,
      ),
      child: ClipRRect(
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: FittedBox(
            fit: BoxFit.contain,
            child: Image.file(
              screenshot,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[300],
                  width: 200,
                  height: 150,
                  child: const Center(child: Icon(Icons.broken_image)),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFileName(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        path.basenameWithoutExtension(screenshot.path),
        style: Theme.of(context).textTheme.bodyMedium,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  void _handleEditComment(BuildContext context) {
    Screenshot? currentScreenshot;

    for (var shot in allScreenshots) {
      if (shot.filePath == screenshot.path && shot.profileId == profileId) {
        currentScreenshot = shot;
        break;
      }
    }

    if (currentScreenshot != null) {
      ScreenshotCommentDialog.show(context, currentScreenshot).then((
        updatedScreenshot,
      ) {
        if (updatedScreenshot != null) {
          onEditComment(updatedScreenshot);
        }
      });
    } else {
      ScreenshotRegisterDialog.show(context).then((confirmed) {
        if (confirmed) {
          final newScreenshot = Screenshot(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            filePath: screenshot.path,
            profileId: profileId,
            createdAt: dateTime,
          );
          ScreenshotCommentDialog.show(context, newScreenshot).then((
            updatedScreenshot,
          ) {
            if (updatedScreenshot != null) {
              onEditComment(updatedScreenshot);
            }
          });
        }
      });
    }
  }
}
