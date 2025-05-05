import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:karasu_launcher/models/launcher_versions_v2.dart';
import 'package:karasu_launcher/models/mod_loader.dart';

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

Future<Directory> getMinecraftDirectory() async {
  try {
    return await createAppDirectory();
  } catch (e) {
    throw Exception('Failed to get Minecraft directory: $e');
  }
}

Future<Directory> getMinecraftVersionsDirectory() async {
  final minecraftDir = await getMinecraftDirectory();
  final versionsDir = Directory(p.join(minecraftDir.path, 'versions'));

  if (!await versionsDir.exists()) {
    await versionsDir.create(recursive: true);
  }

  return versionsDir;
}

Future<String> getLauncherProfilesJsonPath() async {
  final minecraftDir = await getMinecraftDirectory();
  final launcherProfilesPath = p.join(
    minecraftDir.path,
    'launcher_profiles.json',
  );

  final file = File(launcherProfilesPath);
  if (!await file.exists()) {
    await createParentDirectoryFromFilePath(launcherProfilesPath);
    await file.writeAsString('{}');
  }

  return launcherProfilesPath;
}

Future<List<MinecraftVersion>> loadLocalVersions() async {
  try {
    final versionsDir = await getMinecraftVersionsDirectory();
    final List<MinecraftVersion> localVersions = [];

    if (!await versionsDir.exists()) {
      debugPrint('Versions directory does not exist: ${versionsDir.path}');
      return localVersions;
    }

    final List<FileSystemEntity> versionDirs =
        await versionsDir.list().toList();

    for (final entity in versionDirs) {
      if (entity is Directory) {
        final versionDir = entity;
        final versionName = p.basename(versionDir.path);

        final jsonFile = File(p.join(versionDir.path, '$versionName.json'));

        if (await jsonFile.exists()) {
          try {
            final String jsonContent = await jsonFile.readAsString();
            final Map<String, dynamic> versionJson = jsonDecode(jsonContent);

            ModLoader? modLoader = ModLoader.fromJsonContent(
              versionJson,
              versionName,
            );

            if (modLoader != null) {
              localVersions.add(
                MinecraftVersion.fromLocalVersion(
                  id: versionName,
                  type: versionJson['type'] ?? 'unknown',
                  localPath: jsonFile.path,
                  modLoader: modLoader,
                ),
              );
              debugPrint(
                'Detected mod loader: $versionName (${modLoader.type.toDisplayString()} ${modLoader.version})',
              );
            } else if (versionName.contains('fabric') ||
                versionName.contains('forge') ||
                versionName.contains('quilt')) {
              ModLoader? fileNameModLoader = ModLoader.fromFileName(
                versionName,
              );

              if (fileNameModLoader != null) {
                localVersions.add(
                  MinecraftVersion.fromLocalVersion(
                    id: versionName,
                    type: versionJson['type'] ?? 'unknown',
                    localPath: jsonFile.path,
                    modLoader: fileNameModLoader,
                  ),
                );
                debugPrint('Detected mod loader from filename: $versionName');
              }
            }
          } catch (e) {
            debugPrint('Failed to load version JSON: $versionName - $e');
          }
        }
      }
    }

    return localVersions;
  } catch (e) {
    debugPrint('Failed to load local versions: $e');
    return [];
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
