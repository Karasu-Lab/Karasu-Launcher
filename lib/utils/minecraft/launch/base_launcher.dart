import 'dart:io';
import 'package:karasu_launcher/models/auth/account.dart';
import 'package:karasu_launcher/models/launcher_profiles.dart';
import 'package:karasu_launcher/models/version_info.dart';
import 'package:karasu_launcher/utils/minecraft_utils.dart';

/// ベースランチャークラス
///
/// `T`は具体的な実装クラスの型を表し、ファクトリーメソッドでの返却型を指定するために使用します。
abstract class BaseLauncher<T extends BaseLauncher<T>>
    implements MinecraftLauncherInterface {
  /// ラッパーの対象となるローンチャー実装を指定する必要があります
  /// サブクラスでは通常、`this as T`を返します
  T get instance;

  /// Minecraftをローンチする
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
  });

  /// 必要なMinecraftファイルをダウンロードする
  Future<void> downloadRequiredMinecraftFiles(
    String versionId, {
    ProgressCallback? onAssetsProgress,
    ProgressCallback? onLibrariesProgress,
    ProgressCallback? onNativesProgress,
  });

  /// Minecraftクライアントをダウンロードする
  @override
  Future<void> downloadMinecraftClient(String versionId);

  /// Minecraftアセットをダウンロードする
  Future<void> downloadMinecraftAssets(
    String versionId, {
    ProgressCallback? onProgress,
  });

  /// Minecraftライブラリをダウンロードする
  Future<void> downloadMinecraftLibraries(
    String versionId, {
    ProgressCallback? onProgress,
  });

  /// Minecraftの全てのファイルをダウンロードする
  @override
  Future<void> downloadMinecraftComplete(String versionId);

  /// Javaパスを検索する
  @override
  Future<String> findJavaPath(Profile profile);

  /// JVM引数を構築する
  @override
  Future<List<String>> constructJvmArguments({
    required VersionInfo versionInfo,
    required String nativeDir,
    required String classpath,
    required String appDir,
    required String gameDir,
  });

  /// ゲーム引数を構築する
  @override
  Future<List<String>> constructGameArguments({
    required VersionInfo versionInfo,
    required String appDir,
    required String gameDir,
    required String versionId,
    String? username,
    String? uuid,
    String? accessToken,
    String? userType,
    String? xuid,
    String? clientId,
  });

  /// 認証情報を使用してゲーム引数を構築する
  @override
  Future<List<String>> constructGameArgumentsWithAuth({
    required VersionInfo versionInfo,
    required String appDir,
    required String gameDir,
    required String versionId,
    Account? account,
    String? offlinePlayerName,
  });
}
