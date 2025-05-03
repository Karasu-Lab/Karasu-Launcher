import 'package:json_annotation/json_annotation.dart';
import 'package:karasu_launcher/models/screenshot.dart';

part 'screenshots_collection.g.dart';

@JsonSerializable()
class ScreenshotsCollection {
  final Map<String, Screenshot> screenshots;
  final DateTime lastUpdated;

  ScreenshotsCollection({
    Map<String, Screenshot>? screenshots,
    DateTime? lastUpdated,
  })  : screenshots = screenshots ?? {},
        lastUpdated = lastUpdated ?? DateTime.now();

  factory ScreenshotsCollection.fromJson(Map<String, dynamic> json) =>
      _$ScreenshotsCollectionFromJson(json);

  Map<String, dynamic> toJson() => _$ScreenshotsCollectionToJson(this);

  ScreenshotsCollection copyWith({
    Map<String, Screenshot>? screenshots,
    DateTime? lastUpdated,
  }) {
    return ScreenshotsCollection(
      screenshots: screenshots ?? this.screenshots,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  ScreenshotsCollection addScreenshot(Screenshot screenshot) {
    final updatedScreenshots = Map<String, Screenshot>.from(screenshots);
    updatedScreenshots[screenshot.id] = screenshot;
    return copyWith(
      screenshots: updatedScreenshots,
      lastUpdated: DateTime.now(),
    );
  }

  ScreenshotsCollection updateScreenshot(Screenshot screenshot) {
    if (!screenshots.containsKey(screenshot.id)) {
      return this;
    }
    
    final updatedScreenshots = Map<String, Screenshot>.from(screenshots);
    updatedScreenshots[screenshot.id] = screenshot;
    return copyWith(
      screenshots: updatedScreenshots,
      lastUpdated: DateTime.now(),
    );
  }

  ScreenshotsCollection removeScreenshot(String screenshotId) {
    if (!screenshots.containsKey(screenshotId)) {
      return this;
    }

    final updatedScreenshots = Map<String, Screenshot>.from(screenshots);
    updatedScreenshots.remove(screenshotId);
    return copyWith(
      screenshots: updatedScreenshots,
      lastUpdated: DateTime.now(),
    );
  }

  List<Screenshot> getScreenshotsByProfileId(String profileId) {
    return screenshots.values
        .where((screenshot) => screenshot.profileId == profileId)
        .toList();
  }

  List<Screenshot> getAllScreenshots() {
    return screenshots.values.toList();
  }
}
