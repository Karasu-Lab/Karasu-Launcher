import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart' hide Action;
import 'package:http/http.dart' as http;
import 'package:karasu_launcher/models/auth/account.dart';
import 'package:karasu_launcher/models/launcher_profiles.dart';
import 'package:karasu_launcher/models/mod_loader.dart';
import 'package:karasu_launcher/models/version_info.dart';
import 'package:karasu_launcher/providers/log_provider.dart';
import 'package:karasu_launcher/utils/file_utils.dart';
import 'package:karasu_launcher/utils/minecraft_utils.dart';
import 'package:karasu_launcher/utils/minecraft/jvm_builder.dart';
import 'package:path/path.dart' as p;

/// 標準的なMinecraftランチャーの実装
class StandardLauncher extends BaseLauncher<StandardLauncher>
    implements MinecraftLauncherInterface {
  // ランチャーの設定
  static const String _launcherBrand = 'karasu_launcher';
  static const String _launcherVersion = '1.0.0';
  static const String _defaultMemory = '2G'; // Xmxプレフィックスなしで定義

  // アセットディレクトリの定数
  static const String _assetsFolder = 'assets';
  static const String _assetsIndexesFolder = 'indexes';
  static const String _assetsObjectsFolder = 'objects';
  static const String _assetsVirtualFolder = 'virtual';
  static const String _assetsLegacyFolder = 'legacy';

  // 認証関連の定数
  static const String _defaultClientId = '00000000402b5328';
  static const String _defaultUuid = '00000000-0000-0000-0000-000000000000';
  static const String _defaultAccessToken = '00000000000000000000000000000000';

  /// ファイルのSHA1ハッシュを計算する
  Future<String> getFileSha1(File file) async {
    final bytes = await file.readAsBytes();
    final digest = sha1.convert(bytes);
    return digest.toString();
  }

  /// アセットディレクトリ関連のパスを取得する
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

  /// 認証情報のマップを構築する
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

    // Microsoftアカウント（MSA）の場合は追加の認証情報を設定
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

  /// Javaパスを検索する
  @override
  Future<String> findJavaPath(Profile profile) async {
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

    // バージョンに応じたJavaランタイムを検索
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

  /// JVM引数を構築する
  @override
  Future<List<String>> constructJvmArguments({
    required VersionInfo versionInfo,
    required String nativeDir,
    required String classpath,
    required String appDir,
    required String gameDir,
  }) async {
    // JvmArgsBuilderを使用して引数を構築
    final jvmBuilder = JvmArgsBuilder()
        // 標準のプレースホルダーを設定
        .withMinecraftPlaceholders(
          nativeDir: nativeDir,
          launcherName: _launcherBrand,
          launcherVersion: _launcherVersion,
          classpath: classpath,
        )
        // システムプロパティを設定
        .withSystemProperty('java.library.path', nativeDir)
        .withSystemProperty('minecraft.launcher.brand', _launcherBrand)
        .withSystemProperty('minecraft.launcher.version', _launcherVersion)
        // メモリ設定
        .withMaxMemory(_defaultMemory);

    // クラスパスを追加
    jvmBuilder.addClasspath(classpath);

    // バージョン情報からJVM引数を追加（バニラ引数）
    if (versionInfo.arguments != null && versionInfo.arguments!.jvm != null) {
      // ルールベースの引数処理を使用
      jvmBuilder.withRuleBasedArguments(versionInfo.arguments!.jvm!);
    }

    // ※MODローダーによる引数の追加は最後に行う
    // MODローダー情報を取得
    final modLoader = await getModLoaderForVersion(versionInfo.id);
    if (modLoader != null) {
      // MODローダー固有の引数を追加
      await _applyModLoaderJvmArgs(jvmBuilder, modLoader);
    }

    // 重複を除去して最適化
    jvmBuilder.optimize();

    // 構築された引数を返す
    return jvmBuilder.build();
  }

  /// MODローダー固有のJVM引数を適用する
  Future<void> _applyModLoaderJvmArgs(
    JvmArgsBuilder jvmBuilder,
    ModLoader modLoader,
  ) async {
    // MODローダータイプ別の固有設定
    if (modLoader.type == ModLoaderType.fabric) {
      jvmBuilder.withSystemProperty(
        'FabricMcEmu',
        'net.minecraft.client.main.Main',
      );
    } else if (modLoader.type == ModLoaderType.forge) {
      // Forge特有のJVM引数を追加
      jvmBuilder
          .withSystemProperty('forge.logging.console.level', 'info')
          .withSystemProperty(
            'forge.logging.markers',
            'SCAN,REGISTRIES,REGISTRYDUMP',
          );
    } else if (modLoader.type == ModLoaderType.quilt) {
      jvmBuilder.withSystemProperty(
        'QuiltMcEmu',
        'net.minecraft.client.main.Main',
      );
    }

    // MODローダーからJVM引数を取得して追加（arguments.jvmが存在する場合）
    if (modLoader.arguments != null &&
        modLoader.arguments!.containsKey('jvm')) {
      final jvmArgs = modLoader.arguments!['jvm'];
      // MODローダーのJVM引数を追加 (新しいモジュール引数ハンドラーを使用)
      jvmBuilder.withModuleArguments(jvmArgs);
    }
  }

  /// ゲーム引数のプレースホルダーを置き換える
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
    // アセットパスを取得
    final assetPaths = getAssetPaths(appDir, assetsIndexName);

    // JvmArgsBuilderのプレースホルダー機能を活用
    final builder = JvmArgsBuilder();

    // プレースホルダーマップを構築
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

    // オプションのプレースホルダーを設定（MSAアカウントの場合）
    if (xuid != null) {
      placeholders['auth_xuid'] = xuid;
    }
    if (clientId != null) {
      placeholders['clientid'] = clientId;
    }

    // プレースホルダーをビルダーに設定
    builder.withPlaceholders(placeholders);

    // プレースホルダーを置換して返す
    return builder.replacePlaceholders(arg);
  }

  /// ゲーム引数を構築する
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
    final parsedUuid = uuid ?? _defaultUuid;
    final args = <String>[];

    final assetPaths = getAssetPaths(
      appDir,
      versionInfo.assetIndex?.id ?? 'legacy',
    );

    var builtargs = await constructJvmArguments(
      versionInfo: versionInfo,
      appDir: appDir,
      classpath: appDir,
      gameDir: appDir,
      nativeDir: appDir,
    );

    return builtargs;
  }

  /// 認証関連の引数を削除する
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
        // キーワードとその値を削除
        args.removeAt(i);
        if (i < args.length) {
          args.removeAt(i);
        }
        i--; // インデックスを調整
      }
    }
  }

  /// バージョンからMODローダー情報を取得する
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
      debugPrint('MODローダー情報の取得に失敗しました: $e');
    }

    return null;
  }

  /// 認証情報を使用してゲーム引数を構築する
  @override
  Future<List<String>> constructGameArgumentsWithAuth({
    required VersionInfo versionInfo,
    required String appDir,
    required String gameDir,
    required String versionId,
    Account? account,
    String? offlinePlayerName,
  }) async {
    // ゲームの所有権フラグ
    bool hasGameOwnership = false;
    Map<String, String> authInfo;

    // オフラインモードの場合
    if (account == null) {
      debugPrint('No account information. Launching in offline mode');
      final username = offlinePlayerName ?? 'Player';

      // オフラインモード用の認証情報を構築
      authInfo = buildAuthInfo(
        username: username,
        userType: 'mojang', // オフラインモードではmojangタイプを使用
        versionType: versionInfo.type ?? 'release',
      );
    } else {
      // アカウントがある場合は、所有権チェックを行う
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
            // 所有製品リストにMinecraft: Java Editionが含まれているか確認
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

      // アカウントありの認証情報を構築
      authInfo = buildAuthInfo(
        username: account.profile?.name ?? 'Player',
        uuid: account.profile?.id,
        accessToken: account.minecraftAccessToken,
        userType: 'msa', // Microsoft認証の場合はmsa
        xuid: account.xuid,
        clientId: _defaultClientId, // Minecraftのclientidは固定値（公開情報）
        versionType: versionInfo.type ?? 'release',
      );
    } // 認証情報の引数を構築（プレフィックスなし）
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

    // XUIDとクライアントIDをオプションで追加（MSAアカウントの場合）
    if (authInfo.containsKey('xuid')) {
      args.addAll(['--xuid', authInfo['xuid']!]);
    }
    if (authInfo.containsKey('clientId')) {
      args.addAll(['--clientId', authInfo['clientId']!]);
    }

    // オフラインモードまたは所有権がない場合はデモモードで起動
    if (account == null || !hasGameOwnership) {
      debugPrint(
        account == null
            ? 'Offline mode. Launching in demo mode'
            : 'No ownership of Minecraft: Java Edition. Launching in demo mode',
      );

      // --demoフラグが含まれていなければ追加（重複防止）
      if (!args.contains('--demo')) {
        args.add('--demo');
      }

      // オフラインモードの場合は認証関連の引数を削除
      if (account == null) {
        removeAuthRelatedArgs(args);
      }
    }

    return args;
  }

  /// Minecraftを起動する
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
  }) async {
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
      final versionInfo = await fetchVersionInfo(versionId);
      final classpath = await buildClasspath(versionInfo, versionId);
      final appDir = await createAppDirectory();
      final nativeDir = p.join(
        appDir.path,
        'natives',
        versionId,
      ); // JvmArgsBuilderベースでJVM引数を構築

      final mainClass = versionInfo.mainClass;
      if (mainClass == null || mainClass.isEmpty) {
        throw Exception('No mainClass specified in version info');
      } // JvmArgsBuilderを初期化して基本的なJVM引数を設定
      final jvmBuilder = JvmArgsBuilder()
          .withMaxMemory(_defaultMemory)
          .withMinMemory('1G')
          .withSystemProperty('java.library.path', nativeDir)
          .withSystemProperty('minecraft.launcher.brand', _launcherBrand)
          .withSystemProperty('minecraft.launcher.version', _launcherVersion);

      // クラスパスを設定
      jvmBuilder.addClasspath(classpath);

      // メインクラスを設定
      jvmBuilder.withMainClass(mainClass);

      // プレースホルダーを設定
      jvmBuilder.withMinecraftPlaceholders(
        nativeDir: nativeDir,
        launcherName: _launcherBrand,
        launcherVersion: _launcherVersion,
        classpath: classpath,
      ); // バージョン情報からの追加のJVM引数を適用
      if (versionInfo.arguments != null && versionInfo.arguments!.jvm != null) {
        jvmBuilder.withRuleBasedArguments(versionInfo.arguments!.jvm!);
      }

      // プロファイルからのカスタムJava引数を上書き適用
      if (profile.javaArgs != null && profile.javaArgs!.isNotEmpty) {
        final customArgs = profile.javaArgs!.split(' ');
        for (final arg in customArgs) {
          if (arg.startsWith('-X') ||
              arg.startsWith('-D') ||
              arg.startsWith('-XX')) {
            jvmBuilder.withRawArgument(arg);
          }
        }
      } // バージョンとアセット関連の設定を追加
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

      final javaPath = await findJavaPath(profile);
      final command = [...finalJvmArgs, ...gameArgs];

      debugPrint('Java path: $javaPath');
      debugPrint('Game directory: ${gameDir.path}');
      debugPrint('Launch command: $javaPath ${command.join(' ')}');

      if (onPrepareComplete != null) {
        onPrepareComplete();
      }

      // JvmArgsBuilderが生成した引数をそのまま使用（JVMオプション、クラスパス、メインクラスの順序は自動的に正しくなる）
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

  /// 必要なMinecraftファイルをダウンロードする
  @override
  Future<void> downloadRequiredMinecraftFiles(
    String versionId, {
    ProgressCallback? onAssetsProgress,
    ProgressCallback? onLibrariesProgress,
    ProgressCallback? onNativesProgress,
  }) async {
    try {
      debugPrint('Downloading required Minecraft files for version $versionId');

      // クライアントJARをダウンロード
      await downloadMinecraftClient(versionId);

      // アセットをダウンロード
      await downloadMinecraftAssets(versionId, onProgress: onAssetsProgress);

      // ライブラリをダウンロード
      await downloadMinecraftLibraries(
        versionId,
        onProgress: onLibrariesProgress,
      );

      // ネイティブライブラリを展開
      final versionInfo = await fetchVersionInfo(versionId);
      final appDir = await createAppDirectory();
      final nativeDir = p.join(appDir.path, 'natives', versionId);

      await extractNativeLibraries(
        // extractNativesからextractNativeLibrariesに変更
        versionInfo,
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

  /// Minecraftクライアントをダウンロードする
  @override
  Future<void> downloadMinecraftClient(String versionId) async {
    try {
      final versionInfo = await fetchVersionInfo(versionId);
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

  /// Minecraftの全てのファイルをダウンロードする
  @override
  Future<void> downloadMinecraftComplete(String versionId) async {
    try {
      debugPrint('Starting complete download of Minecraft version $versionId');

      // クライアントJARをダウンロード
      await downloadMinecraftClient(versionId);

      // アセットとライブラリをダウンロード
      await downloadMinecraftAssets(versionId);
      await downloadMinecraftLibraries(versionId);

      // ネイティブライブラリを展開
      final versionInfo = await fetchVersionInfo(versionId);
      final appDir = await createAppDirectory();
      final nativeDir = p.join(appDir.path, 'natives', versionId);

      await extractNativeLibraries(
        // extractNativesからextractNativeLibrariesに変更
        versionInfo,
        nativeDir,
      );

      debugPrint('Complete download of Minecraft version $versionId finished');
    } catch (e) {
      debugPrint('Error during complete Minecraft download: $e');
      throw Exception('Failed to complete Minecraft download: $e');
    }
  }

  /// Minecraftアセットをダウンロードする
  @override
  Future<void> downloadMinecraftAssets(
    String versionId, {
    ProgressCallback? onProgress,
  }) async {
    try {
      final versionInfo = await fetchVersionInfo(versionId);
      final appDir = await createAppDirectory();
      final assetsDir = p.join(appDir.path, 'assets');
      final indexesDir = p.join(assetsDir, 'indexes');
      final objectsDir = p.join(assetsDir, 'objects');
      final virtualDir = p.join(assetsDir, 'virtual');

      // ディレクトリを作成
      await Directory(indexesDir).create(recursive: true);
      await Directory(objectsDir).create(recursive: true);
      await Directory(virtualDir).create(recursive: true);

      // アセットインデックスが存在しない場合
      if (versionInfo.assetIndex == null ||
          versionInfo.assetIndex!.url == null) {
        debugPrint('No asset index found for version $versionId');
        return;
      }

      final indexId = versionInfo.assetIndex!.id ?? 'legacy';
      final indexPath = p.join(indexesDir, '$indexId.json');
      final indexFile = File(indexPath);

      // インデックスファイルが存在しない場合、ダウンロード
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

      // レガシーフォーマットのチェック（assets versionが1.7.3以前の場合）
      final isLegacyFormat = indexId == 'legacy' || indexId == 'pre-1.6';

      // すべてのアセットをダウンロード
      for (final entry in objects.entries) {
        final object = entry.value as Map<String, dynamic>;
        final hash = object['hash'] as String;
        final hashPrefix = hash.substring(0, 2);
        final size = object['size'] as int;

        // オブジェクトディレクトリ内のパス
        final objectPath = p.join(objectsDir, hashPrefix, hash);
        final objectFile = File(objectPath);

        // レガシーフォーマットの場合、virtualディレクトリにもコピー
        String? virtualPath;
        if (isLegacyFormat) {
          virtualPath = p.join(virtualDir, 'legacy', entry.key);
          await Directory(p.dirname(virtualPath)).create(recursive: true);
        }

        // ファイルが存在し、サイズが一致する場合はスキップ
        if (await objectFile.exists()) {
          final fileSize = await objectFile.length();
          if (fileSize == size) {
            downloadedAssets++;
            if (isLegacyFormat && virtualPath != null) {
              // レガシー形式の場合、virtualディレクトリにコピー
              if (!await File(virtualPath).exists()) {
                await Directory(p.dirname(virtualPath)).create(recursive: true);
                await objectFile.copy(virtualPath);
              }
            }
            continue;
          }
        }

        // ファイルディレクトリを作成
        await Directory(p.dirname(objectPath)).create(recursive: true);

        // アセットをダウンロード
        final assetUrl =
            'https://resources.download.minecraft.net/$hashPrefix/$hash';
        await downloadFile(assetUrl, objectPath, expectedSize: size);

        // レガシーフォーマットの場合、virtualディレクトリにコピー
        if (isLegacyFormat && virtualPath != null) {
          await Directory(p.dirname(virtualPath)).create(recursive: true);
          await objectFile.copy(virtualPath);
        }

        downloadedAssets++;

        // 進捗を報告
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

  /// Minecraftライブラリをダウンロードする
  @override
  Future<void> downloadMinecraftLibraries(
    String versionId, {
    ProgressCallback? onProgress,
  }) async {
    try {
      final versionInfo = await fetchVersionInfo(versionId);
      final appDir = await createAppDirectory();
      final librariesDir = p.join(appDir.path, 'libraries');

      // ライブラリディレクトリを作成
      await Directory(librariesDir).create(recursive: true);

      // ライブラリがない場合
      if (versionInfo.libraries == null || versionInfo.libraries!.isEmpty) {
        debugPrint('No libraries found for version $versionId');
        return;
      }

      final validLibraries = _filterValidLibraries(versionInfo.libraries!);
      final totalLibraries = validLibraries.length;
      int downloadedLibraries = 0;

      // すべてのライブラリをダウンロード
      for (final library in validLibraries) {
        String? libraryPath;
        String? libraryUrl;
        int? librarySize;
        String? librarySha1;

        // モダンフォーマット（downloadsフィールドがある場合）
        if (library.downloads?.artifact != null) {
          final artifact = library.downloads!.artifact!;
          if (artifact.path != null) {
            libraryPath = p.join(librariesDir, artifact.path!);
            libraryUrl = artifact.url;
            librarySize = artifact.size;
            librarySha1 = artifact.sha1;
          }
        }
        // レガシーフォーマット（nameフィールドから解析）
        else if (library.name != null) {
          final parts = library.name!.split(':');
          if (parts.length >= 3) {
            final group = parts[0].replaceAll('.', '/');
            final artifact = parts[1];
            final version = parts[2];

            String fileName = '$artifact-$version.jar';
            // 特定のフォーマットを持つライブラリ名の処理
            if (parts.length > 3 && parts[3].isNotEmpty) {
              fileName = '$artifact-$version-${parts[3]}.jar';
            }

            final relativePath = p.join(group, artifact, version, fileName);
            libraryPath = p.join(librariesDir, relativePath);

            // カスタムURLがある場合はそれを使用、なければMavenリポジトリから
            if (library.url != null) {
              libraryUrl = '${library.url}$relativePath';
            } else {
              libraryUrl = 'https://libraries.minecraft.net/$relativePath';
            }
          }
        }

        // パスとURLの両方が存在する場合のみダウンロードを試みる
        if (libraryPath != null && libraryUrl != null) {
          final libraryFile = File(libraryPath);

          // ファイルが存在し、SHA1が一致する場合はスキップ
          if (await libraryFile.exists()) {
            if (librarySha1 != null) {
              final fileSha1 = await getFileSha1(libraryFile);
              if (fileSha1 == librarySha1) {
                downloadedLibraries++;
                continue;
              }
            } else {
              // SHA1のチェックができない場合は既存ファイルを使用
              downloadedLibraries++;
              continue;
            }
          }

          // ディレクトリを作成
          await Directory(p.dirname(libraryPath)).create(recursive: true);

          // ライブラリをダウンロード
          try {
            await downloadFile(
              libraryUrl,
              libraryPath,
              expectedSize: librarySize,
            );
            downloadedLibraries++;
          } catch (e) {
            debugPrint('Failed to download library: $libraryUrl - $e');
            // エラーが発生しても続行（一部のライブラリはオプショナル）
          }
        }

        // 進捗を報告
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

  /// 現在のシステムで有効なライブラリをフィルタリングする
  List<Libraries> _filterValidLibraries(List<Libraries> libraries) {
    return libraries.where((lib) {
      // ルールがない場合は常に含める
      if (lib.rules == null || lib.rules!.isEmpty) {
        return true;
      }

      // ルールを評価
      bool shouldInclude = false;
      for (final rule in lib.rules!) {
        final action = rule.action;
        final os = rule.os;

        // OSの一致を確認
        bool osMatch =
            os == null ||
            (os.name == Name.windows && Platform.isWindows) ||
            (os.name == Name.linux && Platform.isLinux) ||
            (os.name == Name.osx && Platform.isMacOS);

        // ルールのアクションに基づいて含めるかどうかを決定
        if (osMatch) {
          shouldInclude = action == Action.allow;
        }
      }

      return shouldInclude;
    }).toList();
  }

  @override
  StandardLauncher get instance => StandardLauncher();
}
