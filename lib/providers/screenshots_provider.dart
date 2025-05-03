import 'dart:io';
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:karasu_launcher/models/screenshot.dart';
import 'package:karasu_launcher/models/screenshots_collection.dart';
import 'package:karasu_launcher/services/screenshots_service.dart';

final screenshotsServiceProvider = Provider<ScreenshotsService>((ref) {
  return ScreenshotsService();
});

final screenshotsCollectionProvider = StateNotifierProvider<
  ScreenshotsNotifier,
  AsyncValue<ScreenshotsCollection>
>((ref) {
  final screenshotsService = ref.watch(screenshotsServiceProvider);
  return ScreenshotsNotifier(screenshotsService);
});

Future<void> updateScreenshotComment(
  WidgetRef ref,
  String id,
  Screenshot screenshot,
) async {
  final notifier = ref.read(screenshotsCollectionProvider.notifier);
  return await notifier.updateScreenshotComment(id, screenshot);
}

class ScreenshotsNotifier
    extends StateNotifier<AsyncValue<ScreenshotsCollection>> {
  final ScreenshotsService _screenshotsService;
  bool _mounted = true;
  ScreenshotsNotifier(this._screenshotsService)
    : super(const AsyncValue.loading()) {
    Future(() {
      loadScreenshots();
    });
  }
  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }

  Future<void> loadScreenshots() async {
    if (!_mounted) return;
    try {
      Future.microtask(() => state = const AsyncValue.loading());

      final collection = await _screenshotsService.loadScreenshots();

      if (_mounted) {
        Future.microtask(() => state = AsyncValue.data(collection));
      }
    } catch (e, stack) {
      if (_mounted) {
        Future.microtask(() => state = AsyncValue.error(e, stack));
      }
    }
  }

  Future<void> addScreenshot({
    required File file,
    required String profileId,
    String? comment,
    Map<String, dynamic>? metadata,
  }) async {
    if (!_mounted) return;
    try {
      final screenshot = await _screenshotsService.addScreenshot(
        filePath: file.path,
        profileId: profileId,
        comment: comment,
        metadata: metadata,
      );

      if (_mounted) {
        state.whenData((collection) {
          Future.microtask(
            () => state = AsyncValue.data(collection.addScreenshot(screenshot)),
          );
        });
      }
    } catch (e, stack) {
      if (_mounted) {
        Future.microtask(() => state = AsyncValue.error(e, stack));
      }
    }
  }

  Future<void> updateScreenshotComment(String id, Screenshot screenshot) async {
    if (!_mounted) return;
    try {
      final currentState = state;
      if (currentState is AsyncData<ScreenshotsCollection>) {
        final collection = currentState.value;
        final existingScreenshot = collection.screenshots[id];

        final Screenshot updatedScreenshot;
        if (id != screenshot.id) {
          updatedScreenshot = Screenshot(
            id: id,
            filePath: screenshot.filePath,
            profileId: screenshot.profileId,
            comment: screenshot.comment,
            createdAt: screenshot.createdAt,
            metadata: screenshot.metadata,
          );
        } else {
          updatedScreenshot = screenshot;
        }

        if (existingScreenshot != null) {
          await _screenshotsService.updateScreenshot(updatedScreenshot);
          final updatedCollection = collection.updateScreenshot(
            updatedScreenshot,
          );
          if (_mounted) {
            Future.microtask(() => state = AsyncValue.data(updatedCollection));
          }
        } else {
          await _screenshotsService.updateScreenshot(updatedScreenshot);

          final updatedCollection = collection.addScreenshot(updatedScreenshot);
          if (_mounted) {
            Future.microtask(() => state = AsyncValue.data(updatedCollection));
          }
        }
      }
    } catch (e, stack) {
      if (_mounted) {
        Future.microtask(() => state = AsyncValue.error(e, stack));
      }
    }
  }

  Future<void> removeScreenshot(String id) async {
    if (!_mounted) return;
    try {
      await _screenshotsService.removeScreenshot(id);

      if (_mounted) {
        state.whenData((collection) {
          Future.microtask(
            () => state = AsyncValue.data(collection.removeScreenshot(id)),
          );
        });
      }
    } catch (e, stack) {
      if (_mounted) {
        Future.microtask(() => state = AsyncValue.error(e, stack));
      }
    }
  }

  List<Screenshot> getScreenshotsByProfileId(String profileId) {
    return state.maybeWhen(
      data: (collection) => collection.getScreenshotsByProfileId(profileId),
      orElse: () => [],
    );
  }

  List<Screenshot> getAllScreenshots() {
    return state.maybeWhen(
      data: (collection) => collection.getAllScreenshots(),
      orElse: () => [],
    );
  }
}

final profileScreenshotsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((
      ref,
      profileId,
    ) async {
      final screenshotsState = ref.watch(screenshotsCollectionProvider);

      return screenshotsState.when(
        data: (collection) {
          final screenshotsMetadata = collection.getScreenshotsByProfileId(
            profileId,
          );
          final List<Map<String, dynamic>> screenshotFiles = [];

          for (final screenshot in screenshotsMetadata) {
            final file = File(screenshot.filePath);

            if (file.existsSync()) {
              screenshotFiles.add({
                'id': screenshot.id,
                'file': file,
                'comment': screenshot.comment,
                'createdAt': screenshot.createdAt,
                'metadata': screenshot.metadata,
              });
            }
          }

          screenshotFiles.sort((a, b) {
            final DateTime dateA = a['createdAt'];
            final DateTime dateB = b['createdAt'];
            return dateB.compareTo(dateA);
          });

          return screenshotFiles;
        },
        loading: () => <Map<String, dynamic>>[],
        error: (_, __) => <Map<String, dynamic>>[],
      );
    });
