import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart' hide Action;
import 'package:http/http.dart' as http;
import 'package:karasu_launcher/models/auth/account.dart';
import 'package:karasu_launcher/models/launcher_profiles.dart';
import 'package:karasu_launcher/models/mod_loader.dart';
import 'package:karasu_launcher/models/version_info.dart';
import 'package:karasu_launcher/providers/java_provider.dart';
import 'package:karasu_launcher/providers/log_provider.dart';
import 'package:karasu_launcher/utils/file_utils.dart';
import 'package:karasu_launcher/utils/minecraft/launch/library_builder.dart';
import 'package:karasu_launcher/utils/minecraft/launch/native_library_builder.dart';
import 'package:karasu_launcher/utils/minecraft_utils.dart';
import 'package:karasu_launcher/utils/minecraft/jvm_builder.dart';
import 'package:path/path.dart' as p;
import 'package:pub_semver/pub_semver.dart';

class StandardLauncher extends BaseLauncher<StandardLauncher>
    implements MinecraftLauncherInterface {
  static const String _launcherBrand = 'karasu_launcher';
  static const String _launcherVersion = '1.0.0';
  static const String _defaultMemory = '2G';

  final List<String> _additionalNativeLibraryPaths = [];

  static const String _assetsFolder = 'assets';
  static const String _assetsIndexesFolder = 'indexes';
  static const String _assetsObjectsFolder = 'objects';
  static const String _assetsVirtualFolder = 'virtual';
  static const String _assetsLegacyFolder = 'legacy';

  static const String _defaultClientId = '00000000402b5328';
  static const String _defaultUuid = '00000000-0000-0000-0000-000000000000';
  static const String _defaultAccessToken = '00000000000000000000000000000000';
  Profile? _profile;
  VersionInfo? _versionInfo;
  String? _cachedVersionId;

  /// ライブラリビルダー
  final LibraryBuilder _libraryBuilder = LibraryBuilder();

  /// ネイティブライブラリビルダー
  final NativeLibraryBuilder _nativeLibraryBuilder = NativeLibraryBuilder();

  Future<VersionInfo> _getOrFetchVersionInfo(String versionId) async {
    if (_versionInfo != null && _cachedVersionId == versionId) {
      return _versionInfo!;
    }

    final versionInfo = await fetchVersionInfo(versionId);
    _versionInfo = versionInfo;
    _cachedVersionId = versionId;
    return versionInfo;
  }

  Future<String> getFileSha1(File file) async {
    final bytes = await file.readAsBytes();
    final digest = sha1.convert(bytes);
    return digest.toString();
  }

  Map<String, String> getAssetPaths(String appDir, String assetsIndexName) {
    final assetsRoot = p.join(appDir, _assetsFolder);
    final assetsIndexDir = p.join(assetsRoot, _assetsIndexesFolder);
    final assetsObjectsDir = p.join(assetsRoot, _assetsObjectsFolder);
    final assetsLegacyDir = p.join(
      assetsRoot,
      _assetsVirtualFolder,
      _assetsLegacyFolder,
    );

    return {
      'assetsRoot': assetsRoot,
      'assetsIndexDir': assetsIndexDir,
      'assetsObjectsDir': assetsObjectsDir,
      'assetsLegacyDir': assetsLegacyDir,
      'assetsIndexName': assetsIndexName,
    };
  }

  Map<String, String> buildAuthInfo({
    required String username,
    String? uuid,
    String? accessToken,
    String? userType,
    String? xuid,
    String? clientId,
    String versionType = 'release',
  }) {
    final Map<String, String> authInfo = {
      'username': username,
      'uuid': uuid ?? _defaultUuid,
      'accessToken': accessToken ?? _defaultAccessToken,
      'userType': userType ?? 'mojang',
      'versionType': versionType,
    };

    if (userType == 'msa') {
      if (xuid != null) {
        authInfo['xuid'] = xuid;
      }
      if (clientId != null) {
        authInfo['clientId'] = clientId;
      } else {
        authInfo['clientId'] = _defaultClientId;
      }
    }

    return authInfo;
  }

  @override
  Future<String> findJavaPath(
    Profile profile, [
    JavaProvider? javaProvider,
  ]) async {
    if (javaProvider?.customJavaBinaryPath != null) {
      final customPath = javaProvider!.customJavaBinaryPath!;
      if (await File(customPath).exists()) {
        return customPath;
      }
    }
    if (profile.javaDir != null && profile.javaDir!.isNotEmpty) {
      final javaPath =
          Platform.isWindows
              ? p.join(profile.javaDir!, 'bin', 'javaw.exe')
              : p.join(profile.javaDir!, 'bin', 'java');
      if (await File(javaPath).exists()) {
        return javaPath;
      }
    }

    final appDir = await createAppDirectory();
    final runtimesDir = p.join(appDir.path, 'runtimes');

    final javaDirectories = [
      p.join(runtimesDir, 'jdk-21'),
      p.join(runtimesDir, 'jdk-17'),
      p.join(runtimesDir, 'jdk-16'),
      p.join(runtimesDir, 'jdk-11'),
      p.join(runtimesDir, 'jdk-8'),
    ];

    for (final jdkDir in javaDirectories) {
      final javaPath =
          Platform.isWindows
              ? p.join(jdkDir, 'bin', 'javaw.exe')
              : p.join(jdkDir, 'bin', 'java');
      if (await File(javaPath).exists()) {
        return javaPath;
      }
    }

    final javaHome = Platform.environment['JAVA_HOME'];
    if (javaHome != null && javaHome.isNotEmpty) {
      final javaPath =
          Platform.isWindows
              ? p.join(javaHome, 'bin', 'javaw.exe')
              : p.join(javaHome, 'bin', 'java');
      if (await File(javaPath).exists()) {
        return javaPath;
      }
    }

    return Platform.isWindows ? 'javaw.exe' : 'java';
  }

  @override
  Future<List<String>> constructJvmArguments({
    required VersionInfo versionInfo,
    required String nativeDir,
    required String classpath,
    required String appDir,
    required String gameDir,
  }) async {
    final jvmBuilder = JvmArgsBuilder()
        .withMinecraftPlaceholders(
          nativeDir: nativeDir,
          launcherName: _launcherBrand,
          launcherVersion: _launcherVersion,
          classpath: classpath,
        )
        .withSystemProperty(
          'java.library.path',
          _nativeLibraryBuilder.buildNativeLibraryPath(nativeDir),
        )
        .withSystemProperty('minecraft.launcher.brand', _launcherBrand)
        .withSystemProperty('minecraft.launcher.version', _launcherVersion)
        .withMaxMemory(_defaultMemory);

    jvmBuilder.addClasspath(classpath);

    if (versionInfo.arguments != null && versionInfo.arguments!.jvm != null) {
      jvmBuilder.withRuleBasedArguments(versionInfo.arguments!.jvm!);
    }

    final modLoader = await getModLoaderForVersion(versionInfo.id);
    if (modLoader != null) {
      await _applyModLoaderJvmArgs(jvmBuilder, modLoader);
    }

    jvmBuilder.optimize();

    return jvmBuilder.build();
  }

  Future<void> _applyModLoaderJvmArgs(
    JvmArgsBuilder jvmBuilder,
    ModLoader modLoader,
  ) async {
    if (modLoader.arguments != null &&
        modLoader.arguments!.containsKey('jvm')) {
      final jvmArgs = modLoader.arguments!['jvm'];
      jvmBuilder.withModuleArguments(jvmArgs);
    }
  }

  @override
  String replaceArgumentPlaceholders(
    String arg,
    String username,
    String versionId,
    String gameDir,
    String appDir,
    String assetsIndexName,
    String uuid,
    String accessToken,
    String userType,
    String versionType, [
    String? xuid,
    String? clientId,
  ]) {
    final assetPaths = getAssetPaths(appDir, assetsIndexName);
    final builder = JvmArgsBuilder();
    final placeholders = {
      'auth_player_name': username,
      'version_name': versionId,
      'game_directory': gameDir,
      'assets_root': assetPaths['assetsRoot']!,
      'assets_index_name': assetPaths['assetsIndexName']!,
      'assets_index': assetPaths['assetsIndexName']!,
      'assets_index_dir': assetPaths['assetsIndexDir']!,
      'assets_objects_dir': assetPaths['assetsObjectsDir']!,
      'assets_legacy_dir': assetPaths['assetsLegacyDir']!,
      'auth_uuid': uuid,
      'auth_access_token': accessToken,
      'user_type': userType,
      'version_type': versionType,
      'resolution_width': '854',
      'resolution_height': '480',
    };
    if (xuid != null) {
      placeholders['auth_xuid'] = xuid;
    }
    if (clientId != null) {
      placeholders['clientid'] = clientId;
    }
    return builder.replacePlaceholders(arg);
  }

  @override
  Future<List<String>> constructGameArguments({
    required VersionInfo versionInfo,
    required String appDir,
    required String gameDir,
    required String versionId,
    String? username = 'Player',
    String? uuid = '00000000-0000-0000-0000-000000000000',
    String? accessToken = '00000000000000000000000000000000',
    String? userType = 'mojang',
    String? xuid,
    String? clientId,
  }) async {
    debugPrint('Constructing game arguments...');
    debugPrint('Version info: ${versionInfo.id}');

    var builtargs = await constructJvmArguments(
      versionInfo: versionInfo,
      appDir: appDir,
      classpath: appDir,
      gameDir: appDir,
      nativeDir: appDir,
    );

    return builtargs;
  }

  @override
  void removeAuthRelatedArgs(List<String> args) {
    final authRelatedKeywords = [
      '--accessToken',
      '--uuid',
      '--userType',
      '--xuid',
      '--clientId',
    ];

    for (int i = 0; i < args.length; i++) {
      if (authRelatedKeywords.contains(args[i])) {
        args.removeAt(i);
        if (i < args.length) {
          args.removeAt(i);
        }
        i--;
      }
    }
  }

  Future<ModLoader?> getModLoaderForVersion(String? versionId) async {
    if (versionId == null || versionId.isEmpty) {
      return null;
    }

    try {
      final versionJsonPath = await getVersionJsonPath(versionId);
      final jsonFile = File(versionJsonPath);

      if (await jsonFile.exists()) {
        final content = await jsonFile.readAsString();
        final jsonData = json.decode(content) as Map<String, dynamic>;
        return ModLoader.fromJsonContent(jsonData, versionId);
      }
    } catch (e) {
      debugPrint('Failed to retrieve mod loader information: $e');
    }

    return null;
  }

  @override
  Future<List<String>> constructGameArgumentsWithAuth({
    required VersionInfo versionInfo,
    required String appDir,
    required String gameDir,
    required String versionId,
    Account? account,
    String? offlinePlayerName,
  }) async {
    bool hasGameOwnership = false;
    Map<String, String> authInfo;

    if (account == null) {
      debugPrint('No account information. Launching in offline mode');
      final username = offlinePlayerName ?? 'Player';

      authInfo = buildAuthInfo(
        username: username,
        userType: 'mojang',
        versionType: versionInfo.type ?? 'release',
      );
    } else {
      if (account.minecraftAccessToken != null) {
        try {
          final entitlementResponse = await http.get(
            Uri.parse('https://api.minecraftservices.com/entitlements/mcstore'),
            headers: {
              'Authorization': 'Bearer ${account.minecraftAccessToken}',
            },
          );

          if (entitlementResponse.statusCode == 200) {
            final entitlementJson =
                json.decode(entitlementResponse.body) as Map<String, dynamic>;
            final items = entitlementJson['items'] as List<dynamic>;
            hasGameOwnership = items.any(
              (item) => (item['name'] as String?) == 'game_minecraft',
            );
          }
          debugPrint('Minecraft ownership check result: $hasGameOwnership');
        } catch (e) {
          debugPrint('Failed to check Minecraft ownership: $e');
          hasGameOwnership = false;
        }
      } else {
        debugPrint('No access token available. Assuming no game ownership.');
      }

      authInfo = buildAuthInfo(
        username: account.profile?.name ?? 'Player',
        uuid: account.profile?.id,
        accessToken: account.minecraftAccessToken,
        userType: 'msa',
        xuid: account.xuid,
        clientId: _defaultClientId,
        versionType: versionInfo.type ?? 'release',
      );
    }
    final args = [
      '--username',
      authInfo['username']!,
      '--uuid',
      authInfo['uuid']!,
      '--accessToken',
      authInfo['accessToken']!,
      '--userType',
      authInfo['userType']!,
      '--versionType',
      authInfo['versionType']!,
    ];

    if (authInfo.containsKey('xuid')) {
      args.addAll(['--xuid', authInfo['xuid']!]);
    }
    if (authInfo.containsKey('clientId')) {
      args.addAll(['--clientId', authInfo['clientId']!]);
    }

    if (account == null || !hasGameOwnership) {
      debugPrint(
        account == null
            ? 'Offline mode. Launching in demo mode'
            : 'No ownership of Minecraft: Java Edition. Launching in demo mode',
      );

      if (!args.contains('--demo')) {
        args.add('--demo');
      }

      if (account == null) {
        removeAuthRelatedArgs(args);
      }
    }

    return args;
  }

  @override
  Future<Process> launchMinecraft(
    Profile profile, {
    ProgressCallback? onAssetsProgress,
    ProgressCallback? onLibrariesProgress,
    ProgressCallback? onNativesProgress,
    PrepareCompleteCallback? onPrepareComplete,
    MinecraftExitCallback? onExit,
    MinecraftOutputCallback? onStdout,
    MinecraftOutputCallback? onStderr,
    LaunchMinecraftCallback? onMinecraftLaunch,
    Account? account,
    String? offlinePlayerName,
    JavaProvider? javaProvider,
  }) async {
    _profile = profile;
    try {
      final versionId = profile.lastVersionId;
      if (versionId == null || versionId.isEmpty) {
        throw Exception('No version ID specified in profile');
      }

      final gameDir =
          profile.gameDir != null && profile.gameDir!.isNotEmpty
              ? Directory(profile.gameDir!)
              : await createAppDirectory();

      debugPrint('Launching Minecraft version $versionId...');

      await downloadRequiredMinecraftFiles(
        versionId,
        onAssetsProgress: onAssetsProgress,
        onLibrariesProgress: onLibrariesProgress,
        onNativesProgress: onNativesProgress,
      );
      final versionInfo = await _getOrFetchVersionInfo(versionId);
      final classpath = await buildClasspath(versionInfo, versionId);
      final appDir = await createAppDirectory();
      final nativeDir = p.join(appDir.path, 'natives', versionId);
      final mainClass = await getMainClass();
      if (mainClass.isEmpty) {
        throw Exception('No mainClass specified in version info');
      }

      final jvmBuilder = JvmArgsBuilder()
          .withMaxMemory(_defaultMemory)
          .withMinMemory('1G')
          .withSystemProperty(
            'java.library.path',
            _nativeLibraryBuilder.buildNativeLibraryPath(nativeDir),
          )
          .withSystemProperty('minecraft.launcher.brand', _launcherBrand)
          .withSystemProperty('minecraft.launcher.version', _launcherVersion);

      jvmBuilder.addClasspath(classpath);
      jvmBuilder.withMainClass(mainClass);
      jvmBuilder.withMinecraftPlaceholders(
        nativeDir: nativeDir,
        launcherName: _launcherBrand,
        launcherVersion: _launcherVersion,
        classpath: classpath,
      );
      if (versionInfo.arguments != null && versionInfo.arguments!.jvm != null) {
        jvmBuilder.withRuleBasedArguments(versionInfo.arguments!.jvm!);
      }

      if (profile.javaArgs != null && profile.javaArgs!.isNotEmpty) {
        final customArgs = profile.javaArgs!.split(' ');
        for (final arg in customArgs) {
          if (arg.startsWith('-X') ||
              arg.startsWith('-D') ||
              arg.startsWith('-XX')) {
            jvmBuilder.withRawArgument(arg);
          }
        }
      }
      jvmBuilder
          .withVersion(versionId.toString())
          .withAssetsDir(p.join(appDir.path, _assetsFolder), versionInfo)
          .withSystemProperty(
            'minecraft.assets.index',
            versionInfo.assetIndex?.id ?? 'legacy',
          )
          .withSystemProperty(
            'minecraft.assets.root',
            p.join(appDir.path, _assetsFolder),
          );

      final finalJvmArgs = jvmBuilder.optimize().build();

      final gameArgs = await constructGameArgumentsWithAuth(
        versionInfo: versionInfo,
        appDir: appDir.path,
        gameDir: gameDir.path,
        versionId: versionId,
        account: account,
        offlinePlayerName: offlinePlayerName,
      );

      final javaPath = await findJavaPath(profile, javaProvider);
      final command = [...finalJvmArgs, ...gameArgs];

      debugPrint('Java path: $javaPath');
      debugPrint('Game directory: ${gameDir.path}');
      debugPrint('Launch command: $javaPath ${command.join(' ')}');

      if (onPrepareComplete != null) {
        onPrepareComplete();
      }

      final process = await Process.start(javaPath, [
        ...finalJvmArgs,
        ...gameArgs,
      ], workingDirectory: gameDir.path);

      debugPrint('Minecraft process launched. PID: ${process.pid}');

      if (onMinecraftLaunch != null) {
        onMinecraftLaunch();
      }

      process.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
            (data) {
              debugPrint('[Minecraft] $data');
              if (onStdout != null) {
                onStdout(data, LogSource.javaStdOut);
              }
            },
            onError: (error) {
              debugPrint(
                '[Minecraft] Error processing standard output: $error',
              );
            },
          );

      process.stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
            (data) {
              debugPrint('[Minecraft Error] $data');
              if (onStderr != null) {
                onStderr(data, LogSource.javaStdErr);
              }
            },
            onError: (error) {
              debugPrint(
                '[Minecraft Error] Error processing standard error output: $error',
              );
            },
          );

      process.exitCode.then((exitCode) {
        if (onExit != null) {
          final isNormalExit = exitCode == 0 || exitCode == 143; // 143はSIGTERM
          onExit(exitCode, isNormalExit, account?.id, profile.id);
        }
        debugPrint('Minecraft process exited. Exit code: $exitCode');
      });

      return process;
    } catch (e) {
      throw Exception('Failed to launch Minecraft: $e');
    }
  }

  @override
  Future<void> downloadRequiredMinecraftFiles(
    String versionId, {
    ProgressCallback? onAssetsProgress,
    ProgressCallback? onLibrariesProgress,
    ProgressCallback? onNativesProgress,
  }) async {
    try {
      debugPrint('Downloading required Minecraft files for version $versionId');
      await downloadMinecraftClient(versionId);
      await downloadMinecraftAssets(versionId, onProgress: onAssetsProgress);
      await downloadMinecraftLibraries(
        versionId,
        onProgress: onLibrariesProgress,
      );

      final versionInfo = await fetchVersionInfo(versionId);
      _versionInfo = versionInfo;
      final appDir = await createAppDirectory();
      final nativeDir = p.join(appDir.path, 'natives', versionId);

      await _nativeLibraryBuilder.extractNativeLibraries(
        versionInfo,
        versionId,
        nativeDir,
        onProgress: onNativesProgress,
      );

      debugPrint(
        'All required files for Minecraft version $versionId downloaded and extracted',
      );
    } catch (e) {
      debugPrint('Error downloading required Minecraft files: $e');
      throw Exception('Failed to download required Minecraft files: $e');
    }
  }

  @override
  Future<void> downloadMinecraftClient(String versionId) async {
    if (!isModded && modLoader != ModLoaderType.forge) {
      try {
        final versionInfo = await _getOrFetchVersionInfo(versionId);
        if (versionInfo.downloads?.client?.url == null) {
          throw Exception('No client download URL specified in version info');
        }

        final appDir = await createAppDirectory();
        final versionsDir = p.join(appDir.path, 'versions');
        final versionDir = p.join(versionsDir, versionId);
        await Directory(versionDir).create(recursive: true);

        final clientJarPath = p.join(versionDir, '$versionId.jar');
        final clientJarFile = File(clientJarPath);

        if (await clientJarFile.exists()) {
          if (versionInfo.downloads?.client?.sha1 != null) {
            final sha1 = await getFileSha1(clientJarFile);
            if (sha1 == versionInfo.downloads!.client!.sha1) {
              debugPrint(
                'Client JAR already exists and is valid: $clientJarPath',
              );
              return;
            }
          } else {
            debugPrint('Client JAR already exists: $clientJarPath');
            return;
          }
        }

        debugPrint(
          'Downloading client JAR from ${versionInfo.downloads!.client!.url}',
        );
        await downloadFile(
          versionInfo.downloads!.client!.url!,
          clientJarPath,
          expectedSize: versionInfo.downloads!.client!.size,
        );

        debugPrint('Client download completed: ${clientJarFile.path}');
      } catch (e) {
        debugPrint('Error downloading Minecraft client: $e');
        throw Exception('Failed to download Minecraft client: $e');
      }
    }
  }

  @override
  Future<void> downloadMinecraftComplete(String versionId) async {
    try {
      debugPrint('Starting complete download of Minecraft version $versionId');
      await downloadMinecraftClient(versionId);
      await downloadMinecraftAssets(versionId);
      await downloadMinecraftLibraries(versionId);

      final versionInfo = await fetchVersionInfo(versionId);
      _versionInfo = versionInfo;
      final appDir = await createAppDirectory();
      final nativeDir = p.join(appDir.path, 'natives', versionId);

      await _nativeLibraryBuilder.extractNativeLibraries(
        versionInfo,
        versionId,
        nativeDir,
      );

      debugPrint('Complete download of Minecraft version $versionId finished');
    } catch (e) {
      debugPrint('Error during complete Minecraft download: $e');
      throw Exception('Failed to complete Minecraft download: $e');
    }
  }

  @override
  Future<void> downloadMinecraftAssets(
    String versionId, {
    ProgressCallback? onProgress,
  }) async {
    try {
      final versionInfo = await _getOrFetchVersionInfo(versionId);
      final appDir = await createAppDirectory();
      final assetsDir = p.join(appDir.path, 'assets');
      final indexesDir = p.join(assetsDir, 'indexes');
      final objectsDir = p.join(assetsDir, 'objects');
      final virtualDir = p.join(assetsDir, 'virtual');

      await Directory(indexesDir).create(recursive: true);
      await Directory(objectsDir).create(recursive: true);
      await Directory(virtualDir).create(recursive: true);

      if (versionInfo.assetIndex == null ||
          versionInfo.assetIndex!.url == null) {
        debugPrint('No asset index found for version $versionId');
        return;
      }

      final indexId = versionInfo.assetIndex!.id ?? 'legacy';
      final indexPath = p.join(indexesDir, '$indexId.json');
      final indexFile = File(indexPath);
      if (!await indexFile.exists()) {
        await downloadFile(
          versionInfo.assetIndex!.url!,
          indexPath,
          expectedSize: versionInfo.assetIndex!.size,
        );
        debugPrint('Downloaded asset index: $indexPath');
      }

      final indexContent = await indexFile.readAsString();
      final indexJson = json.decode(indexContent) as Map<String, dynamic>;
      final objects = indexJson['objects'] as Map<String, dynamic>;

      final totalAssets = objects.length;
      int downloadedAssets = 0;
      final isLegacyFormat = indexId == 'legacy' || indexId == 'pre-1.6';
      for (final entry in objects.entries) {
        final object = entry.value as Map<String, dynamic>;
        final hash = object['hash'] as String;
        final hashPrefix = hash.substring(0, 2);
        final size = object['size'] as int;
        final objectPath = p.join(objectsDir, hashPrefix, hash);
        final objectFile = File(objectPath);
        String? virtualPath;
        if (isLegacyFormat) {
          virtualPath = p.join(virtualDir, 'legacy', entry.key);
          await Directory(p.dirname(virtualPath)).create(recursive: true);
        }
        if (await objectFile.exists()) {
          final fileSize = await objectFile.length();
          if (fileSize == size) {
            downloadedAssets++;
            if (isLegacyFormat && virtualPath != null) {
              if (!await File(virtualPath).exists()) {
                await Directory(p.dirname(virtualPath)).create(recursive: true);
                await objectFile.copy(virtualPath);
              }
            }
            continue;
          }
        }

        await Directory(p.dirname(objectPath)).create(recursive: true);
        final assetUrl =
            'https://resources.download.minecraft.net/$hashPrefix/$hash';
        await downloadFile(assetUrl, objectPath, expectedSize: size);

        if (isLegacyFormat && virtualPath != null) {
          await Directory(p.dirname(virtualPath)).create(recursive: true);
          await objectFile.copy(virtualPath);
        }

        downloadedAssets++;
        if (onProgress != null) {
          onProgress(
            downloadedAssets / totalAssets,
            downloadedAssets,
            totalAssets,
          );
        }
      }

      debugPrint('Downloaded $downloadedAssets/$totalAssets assets');
    } catch (e) {
      debugPrint('Error downloading assets: $e');
      throw Exception('Failed to download assets: $e');
    }
  }

  @override
  Future<void> downloadMinecraftLibraries(
    String versionId, {
    ProgressCallback? onProgress,
  }) async {
    try {
      final versionInfo = await _getOrFetchVersionInfo(versionId);
      final appDir = await createAppDirectory();
      final librariesDir = p.join(appDir.path, 'libraries');
      await Directory(librariesDir).create(recursive: true);
      if (versionInfo.libraries == null || versionInfo.libraries!.isEmpty) {
        debugPrint('No libraries found for version $versionId');
        return;
      }

      final validLibraries = _filterValidLibraries(versionInfo.libraries!);
      final totalLibraries = validLibraries.length;
      int downloadedLibraries = 0;
      for (final library in validLibraries) {
        String? libraryPath;
        String? libraryUrl;
        int? librarySize;
        String? librarySha1;
        if (library.downloads?.artifact != null) {
          final artifact = library.downloads!.artifact!;
          if (artifact.path != null) {
            libraryPath = p.join(librariesDir, artifact.path!);
            libraryUrl = artifact.url;
            librarySize = artifact.size;
            librarySha1 = artifact.sha1;
          }
        } else if (library.name != null) {
          final parts = library.name!.split(':');
          if (parts.length >= 3) {
            final group = parts[0].replaceAll('.', '/');
            final artifact = parts[1];
            final version = parts[2];

            String fileName = '$artifact-$version.jar';
            if (parts.length > 3 && parts[3].isNotEmpty) {
              fileName = '$artifact-$version-${parts[3]}.jar';
            }

            final relativePath = p.join(group, artifact, version, fileName);
            libraryPath = p.join(librariesDir, relativePath);

            if (library.url != null) {
              libraryUrl = '${library.url}$relativePath';
            } else {
              libraryUrl = 'https://libraries.minecraft.net/$relativePath';
            }
          }
        }

        if (libraryPath != null && libraryUrl != null) {
          final libraryFile = File(libraryPath);

          if (await libraryFile.exists()) {
            if (librarySha1 != null) {
              final fileSha1 = await getFileSha1(libraryFile);
              if (fileSha1 == librarySha1) {
                downloadedLibraries++;
                continue;
              }
            } else {
              downloadedLibraries++;
              continue;
            }
          }

          await Directory(p.dirname(libraryPath)).create(recursive: true);

          try {
            await downloadFile(
              libraryUrl,
              libraryPath,
              expectedSize: librarySize,
            );
            downloadedLibraries++;
          } catch (e) {
            debugPrint('Failed to download library: $libraryUrl - $e');
          }
        }

        if (onProgress != null) {
          onProgress(
            downloadedLibraries / totalLibraries,
            downloadedLibraries,
            totalLibraries,
          );
        }
      }

      debugPrint('Downloaded $downloadedLibraries/$totalLibraries libraries');
    } catch (e) {
      debugPrint('Error downloading libraries: $e');
      throw Exception('Failed to download libraries: $e');
    }
  }

  List<Libraries> _filterValidLibraries(List<Libraries> libraries) {
    return libraries.where((lib) {
      if (lib.rules == null || lib.rules!.isEmpty) {
        return true;
      }
      bool shouldInclude = false;
      for (final rule in lib.rules!) {
        final action = rule.action;
        final os = rule.os;
        bool osMatch =
            os == null ||
            (os.name == Name.windows && Platform.isWindows) ||
            (os.name == Name.linux && Platform.isLinux) ||
            (os.name == Name.osx && Platform.isMacOS);

        if (osMatch) {
          shouldInclude = action == Action.allow;
        }
      }

      return shouldInclude;
    }).toList();
  }

  @override
  Future<String> buildClasspath(
    VersionInfo versionInfo,
    String versionId,
  ) async {
    try {
      return await _libraryBuilder.buildClasspath(versionInfo, versionId);
    } catch (e) {
      debugPrint('Error building classpath: $e');
      throw Exception('Failed to build classpath: $e');
    }
  }

  String buildFinalClasspathString(List<String> paths) {
    final separator = Platform.isWindows ? ';' : ':';
    final validPaths = paths.where((path) => path.isNotEmpty).toList();
    final uniquePaths = validPaths.toSet().toList();

    // セパレータを含むパスをフィルタリング（ダブルクォートで保護されている場合を除く）
    final cleanPaths =
        uniquePaths.where((path) {
          // ダブルクォートで囲まれているパスは既に保護されているので許可
          if (path.startsWith('"') && path.endsWith('"')) {
            return true;
          }
          // セパレータを含まないパスのみ許可
          return !path.contains(separator);
        }).toList();

    // 最終的なパスリストを生成（空白を含むパスをダブルクォートで囲む）
    final finalPaths =
        cleanPaths.map((path) {
          // 既にダブルクォートで囲まれているパスはそのまま
          if (path.startsWith('"') && path.endsWith('"')) {
            return path;
          }
          // 空白を含むパスをダブルクォートで囲む
          if (path.contains(' ')) {
            return '"$path"';
          }
          return path;
        }).toList();
    if (finalPaths.length < paths.length) {
      debugPrint(
        'Warning: Filtered ${paths.length - finalPaths.length} invalid paths from classpath',
      );
      final excludedPaths =
          paths
              .where(
                (path) =>
                    !finalPaths.contains(path) &&
                    !finalPaths.contains('"$path"'),
              )
              .toList();
      if (excludedPaths.isNotEmpty) {
        debugPrint('Excluded paths: ${excludedPaths.join(', ')}');
      }
    }

    final result = finalPaths.join(separator);
    debugPrint('Final classpath contains ${finalPaths.length} entries');
    return result;
  }

  int compareVersions(String v1, String v2) {
    try {
      final cleanV1 = cleanVersionString(v1);
      final cleanV2 = cleanVersionString(v2);

      final semV1 = Version.parse(cleanV1);
      final semV2 = Version.parse(cleanV2);

      return semV1.compareTo(semV2);
    } catch (e) {
      debugPrint('SemVer parsing failed, using string comparison: $e');
      return v1.compareTo(v2);
    }
  }

  String cleanVersionString(String version) {
    if (version.contains('-')) {
      final parts = version.split('-');
      return '${parts[0]}-${parts.sublist(1).join('.')}';
    }

    final versionParts = version.split('.');
    if (versionParts.length == 1) {
      return '$version.0.0';
    } else if (versionParts.length == 2) {
      return '$version.0';
    }

    return version;
  }

  @override
  StandardLauncher get instance => StandardLauncher();

  bool get isModded => false;
  ModLoaderType? get modLoader => null;

  void addNativeLibrary(String path) {
    if (!_additionalNativeLibraryPaths.contains(path)) {
      _additionalNativeLibraryPaths.add(path);
      debugPrint('Added native library path: $path');
    }
  }

  void clearAdditionalNativeLibraries() {
    _additionalNativeLibraryPaths.clear();
    debugPrint('Cleared additional native library paths');
  }

  List<String> getAdditionalNativeLibraries() {
    return List.unmodifiable(_additionalNativeLibraryPaths);
  }

  @override
  Profile? getProfile() {
    return _profile;
  }

  @override
  Future<VersionInfo?> getVersionInfo() async {
    return _versionInfo;
  }

  @override
  Future<String> getMainClass() async {
    return Future.value(_versionInfo?.mainClass ?? '');
  }

  @override
  Map<String, (String, String)> getClassPathMap() {
    return _libraryBuilder.getLibraryVersionMap();
  }
}
