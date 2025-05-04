import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

Future<Directory> getAppDirectory() async {
  try {
    final appDocDir = await getApplicationDocumentsDirectory();
    return Directory(appDocDir.path.replaceAll('\\', '/'));
  } catch (e) {
    throw Exception('Failed to get application directory: $e');
  }
}

Future<Directory> createAppDirectory() async {
  try {
    final appDocDir = await getAppDirectory();

    final karasuDirPath = p.join(appDocDir.path, '.karasu_launcher');

    final karasuDir = Directory(karasuDirPath);

    if (!await karasuDir.exists()) {
      return await karasuDir.create(recursive: true);
    }

    return karasuDir;
  } catch (e) {
    throw Exception('Failed to create application directory: $e');
  }
}

Future<List<Directory>> createSubDirectory(
  Directory parentDir,
  String folderName,
) async {
  try {
    return await createSubDirectories(parentDir, [folderName]);
  } catch (e) {
    throw Exception('Could not create sub directory: $e');
  }
}

Future<List<Directory>> createSubDirectories(
  Directory parentDir,
  List<String> folderNames,
) async {
  try {
    final List<Directory> createdDirs = [];

    for (final folderName in folderNames) {
      final dirPath = p.join(parentDir.path, folderName);
      final directory = Directory(dirPath);

      if (!await directory.exists()) {
        final createdDir = await directory.create(recursive: true);
        createdDirs.add(createdDir);
      } else {
        createdDirs.add(directory);
      }
    }

    return createdDirs;
  } catch (e) {
    throw Exception('Could not create sub directories: $e');
  }
}

Future<Directory> createDirectoryFromPath(String path) async {
  final directory = Directory(path);

  if (!await directory.exists()) {
    return await directory.create(recursive: true);
  }

  return directory;
}

Future<Directory> createParentDirectoryFromFilePath(String filePath) async {
  final parentPath = p.dirname(filePath);
  return await createDirectoryFromPath(parentPath);
}

Future<String> getLauncherProfilesJsonPath() async {
  final appDir = await createAppDirectory();
  return p.join(appDir.path, 'launcher_profiles.json');
}
