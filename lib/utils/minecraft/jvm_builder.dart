import 'dart:io';
import 'package:flutter/material.dart';
import 'package:karasu_launcher/models/version_info.dart';
import 'package:path/path.dart' as p;

/// 認証関連の引数の編集エラー
class AuthArgumentEditException implements Exception {
  final String message;

  AuthArgumentEditException(this.message);

  @override
  String toString() => 'AuthArgumentEditException: $message';
}

/// JVMの引数を構築するためのクラス
///
/// このクラスはJavaアプリケーションの起動に必要な引数を管理し、最終的な起動コマンドを構築します。
class JvmArgsBuilder {
  /// 起動するjarファイル（メインクラスの代わりに直接jarを実行する場合に使用）
  String? _jarFile;

  /// JVM引数のマップ（例: {'Xmx': '2G', 'Djava.library.path': '/path/to/natives'}）
  /// キーは先頭の'-'を除いた引数名で、値は引数の値
  final Map<String, String> _arguments = {};

  /// 認証関連のシステムプロパティ名のセット
  static const Set<String> _authSystemProperties = {
    'uuid',
    'accessToken',
    'player_name',
    'xuid',
    'type',
    'clientid',
  };

  /// 既に設定された認証関連プロパティを追跡
  final Set<String> _setAuthProperties = {};

  /// クラスパスのセット
  final Set<String> _classpaths = {};

  /// クラスパスセパレータ（Windows: ';', その他: ':'）
  final String _classpathSeparator = Platform.isWindows ? ';' : ':';

  /// 追加の起動引数リスト
  final List<String> _additionalArgs = [];

  /// メインクラス名（jar実行ではなくクラスから起動する場合に使用）
  String? _mainClass;

  /// プレースホルダー置換のためのマップ
  final Map<String, String> _placeholders = {};

  /// 認証関連のプレースホルダー名のセット
  static const Set<String> _authPlaceholders = {
    'auth_player_name',
    'auth_uuid',
    'auth_access_token',
    'auth_xuid',
    'user_type',
    'clientid',
  };

  /// 既に設定された認証関連プレースホルダーを追跡
  final Set<String> _setAuthPlaceholders = {};

  /// コンストラクタ
  JvmArgsBuilder();

  /// jar実行モードを設定
  JvmArgsBuilder withJar(String jarPath) {
    _jarFile = jarPath;
    return this;
  }

  /// メインクラスを設定
  JvmArgsBuilder withMainClass(String mainClass) {
    _mainClass = mainClass;
    return this;
  }

  /// プレースホルダーを設定
  ///
  /// ${placeholder_name} の形式で使われるプレースホルダーの値を設定します
  JvmArgsBuilder withPlaceholder(String name, String value) {
    // 認証関連のプレースホルダーの場合
    if (_authPlaceholders.contains(name)) {
      // 既に設定済みかチェック
      if (_setAuthPlaceholders.contains(name)) {
        throw AuthArgumentEditException(
          '認証関連のプレースホルダー "$name" は既に設定されており変更できません。',
        );
      }
      // まだ設定されていない場合は追跡リストに追加
      _setAuthPlaceholders.add(name);
    }

    _placeholders[name] = value;
    return this;
  }

  /// プレースホルダーを一括設定
  ///
  /// 複数のプレースホルダーを一度に設定します
  JvmArgsBuilder withPlaceholders(Map<String, String> placeholders) {
    // 認証関連のプレースホルダーを事前チェック
    for (final name in placeholders.keys) {
      if (_authPlaceholders.contains(name) &&
          _setAuthPlaceholders.contains(name)) {
        throw AuthArgumentEditException(
          '認証関連のプレースホルダー "$name" は既に設定されており変更できません。',
        );
      }
    }

    // 問題なければ追加
    for (final entry in placeholders.entries) {
      if (_authPlaceholders.contains(entry.key)) {
        _setAuthPlaceholders.add(entry.key);
      }
    }

    _placeholders.addAll(placeholders);
    return this;
  }

  /// メモリの最大値を設定（例: '2G'）
  JvmArgsBuilder withMaxMemory(String memory) {
    _arguments['Xmx'] = memory;
    return this;
  }

  /// メモリの最小値を設定（例: '1G'）
  JvmArgsBuilder withMinMemory(String memory) {
    _arguments['Xms'] = memory;
    return this;
  }

  JvmArgsBuilder withVersion(String version) {
    _additionalArgs.addAll(['--version', version]);
    return this;
  }

  JvmArgsBuilder withAssetsDir(String dir, VersionInfo info) {
    _additionalArgs.addAll(['--assetsDir', dir]);
    _additionalArgs.addAll(['--assetIndex', info.assetIndex?.id ?? '']);
    return this;
  }

  /// Minecraftの標準プレースホルダーを設定
  ///
  /// Minecraftランチャーに必要な標準的なプレースホルダーを設定します
  JvmArgsBuilder withMinecraftPlaceholders({
    required String nativeDir,
    required String launcherName,
    required String launcherVersion,
    required String classpath,
    Map<String, String>? additional,
  }) {
    withPlaceholders({
      'natives_directory': nativeDir,
      'launcher_name': launcherName,
      'launcher_version': launcherVersion,
      'classpath': classpath,
    });

    if (additional != null) {
      withPlaceholders(additional);
    }

    return this;
  }

  /// 認証情報を設定する
  ///
  /// Minecraftの認証情報を一括で設定します。
  /// この情報は一度設定すると変更できません。
  JvmArgsBuilder withAuthInfo({
    required String username,
    required String uuid,
    required String accessToken,
    required String userType,
    String? xuid,
    String? clientId,
  }) {
    // 認証情報のプレースホルダーを設定
    final authPlaceholders = <String, String>{
      'auth_player_name': username,
      'auth_uuid': uuid,
      'auth_access_token': accessToken,
      'user_type': userType,
    };

    // オプションの認証情報を追加
    if (xuid != null) {
      authPlaceholders['auth_xuid'] = xuid;
    }
    if (clientId != null) {
      authPlaceholders['clientid'] = clientId;
    }

    // 認証情報のプレースホルダーを設定
    withPlaceholders(authPlaceholders);

    // 認証情報のシステムプロパティも設定
    final authProperties = <String, String>{
      'auth.player_name': username,
      'auth.uuid': uuid,
      'auth.accessToken': accessToken,
      'user.type': userType,
    };

    // オプションの認証情報プロパティを追加
    if (xuid != null) {
      authProperties['auth.xuid'] = xuid;
    }
    if (clientId != null) {
      authProperties['clientid'] = clientId;
    }

    // 認証情報のシステムプロパティを設定
    withSystemProperties(authProperties);

    return this;
  }

  /// Java システムプロパティを追加（例: 'java.library.path', '/path/to/natives'）
  JvmArgsBuilder withSystemProperty(String property, String value) {
    final propertyKey = 'D$property';

    // 認証関連のシステムプロパティの場合
    if (_authSystemProperties.contains(propertyKey)) {
      // 既に設定済みかチェック
      if (_setAuthProperties.contains(propertyKey)) {
        throw AuthArgumentEditException(
          '認証関連のシステムプロパティ "$property" は既に設定されており変更できません。',
        );
      }
      // まだ設定されていない場合は追跡リストに追加
      _setAuthProperties.add(propertyKey);
    }

    _arguments[propertyKey] = value;
    return this;
  }

  /// Java システムプロパティを一括追加
  JvmArgsBuilder withSystemProperties(Map<String, String> properties) {
    // 認証関連のプロパティを事前チェック
    for (final property in properties.keys) {
      final propertyKey = 'D$property';
      if (_authSystemProperties.contains(propertyKey) &&
          _setAuthProperties.contains(propertyKey)) {
        throw AuthArgumentEditException(
          '認証関連のシステムプロパティ "$property" は既に設定されており変更できません。',
        );
      }
    }

    // 問題なければ追加
    properties.forEach((key, value) {
      final propertyKey = 'D$key';
      if (_authSystemProperties.contains(propertyKey)) {
        _setAuthProperties.add(propertyKey);
      }
      _arguments[propertyKey] = value;
    });

    return this;
  }

  /// 生のJVM引数を追加
  ///
  /// プレースホルダーを含む可能性のあるJVM引数を追加します
  JvmArgsBuilder withRawArgument(String argument) {
    final processedArg = replacePlaceholders(argument);
    _additionalArgs.add(processedArg);
    return this;
  }
  /// クラスパスにディレクトリまたはjarファイルを追加
  JvmArgsBuilder addClasspath(String path) {
    // 空または無効なパスの場合は追加しない
    if (path.isEmpty) {
      debugPrint('空のパスはクラスパスに追加しません');
      return this;
    }

    // 環境変数の内容が誤って含まれていないか確認
    // PATHセパレータが複数含まれている場合は環境変数の可能性がある
    final pathSeparator = Platform.isWindows ? ';' : ':';
    if (path.contains(pathSeparator)) {
      debugPrint('警告: クラスパスに複数のパスセパレータが含まれています。個別のパスに分割します。');
      // パスセパレータで分割する前に、引用符で囲まれた部分を一時的に置換して保護
      final protectedPath = _protectQuotedPaths(path);
      // 個別のパスに分割して再帰的に追加
      final paths = _splitPreservingQuotedPaths(protectedPath, pathSeparator);
      return addClasspaths(paths.where((p) => p.isNotEmpty));
    }
    
    // パスに引用符が含まれている場合、引用符を削除
    String cleanPath = path;
    if (path.startsWith('"') && path.endsWith('"')) {
      cleanPath = path.substring(1, path.length - 1);
    }
    
    // Windowsの場合、パスをノーマライズする
    if (Platform.isWindows) {
      // バックスラッシュをスラッシュに変換し、重複するスラッシュを削除
      final normalizedPath = cleanPath.replaceAll('\\', '/').replaceAll('//', '/');
      _classpaths.add(normalizedPath);
    } else {
      _classpaths.add(cleanPath);
    }
    return this;
  }

  /// 引用符で囲まれたパスを一時的に保護するためのメソッド
  String _protectQuotedPaths(String originalPath) {
    // 引用符で囲まれた部分を一時的なプレースホルダーに置換
    RegExp regex = RegExp(r'"([^"]*)"');
    String result = originalPath;
    int count = 0;

    // 引用符で囲まれた各パスを特殊なプレースホルダーに置き換え
    result = result.replaceAllMapped(regex, (Match match) {
      final quotedPath = match.group(1)!;
      final placeholder = '##QUOTED_PATH_${count++}##';
      _placeholders[placeholder] = quotedPath;
      return placeholder;
    });

    return result;
  }

  /// パスセパレータで分割する際に引用符で囲まれたパスを保護する
  List<String> _splitPreservingQuotedPaths(
    String protectedPath,
    String separator,
  ) {
    // セパレータで分割
    List<String> parts = protectedPath.split(separator);

    // 各部分のプレースホルダーを元の引用符付きパスに戻す
    for (int i = 0; i < parts.length; i++) {
      String part = parts[i];
      // プレースホルダーパターンを検出
      RegExp placeholderPattern = RegExp(r'##QUOTED_PATH_(\d+)##');

      if (placeholderPattern.hasMatch(part)) {
        parts[i] = part.replaceAllMapped(placeholderPattern, (Match match) {
          final placeholder = match.group(0)!;
          // プレースホルダーから元のパスを取得
          final originalPath = _placeholders[placeholder];
          // プレースホルダーをクリーンアップ
          _placeholders.remove(placeholder);
          // 引用符で囲まれたパスを返す
          return '"$originalPath"';
        });
      }
    }

    return parts;
  }

  /// 認証情報が設定されているかどうかを確認する
  bool hasAuthInfo() {
    // 主要な認証情報プレースホルダーの存在を確認
    return _setAuthPlaceholders.contains('auth_player_name') &&
        _setAuthPlaceholders.contains('auth_uuid') &&
        _setAuthPlaceholders.contains('auth_access_token') &&
        _setAuthPlaceholders.contains('user_type');
  }

  /// 認証情報の設定状態を取得する
  Map<String, bool> getAuthInfoStatus() {
    final status = <String, bool>{};

    // 各認証情報プレースホルダーの設定状態を確認
    for (final placeholder in _authPlaceholders) {
      status[placeholder] = _setAuthPlaceholders.contains(placeholder);
    }

    // 各認証情報システムプロパティの設定状態を確認
    for (final property in _authSystemProperties) {
      // プロパティ名からDを取り除いて表示用にする
      final displayName =
          property.startsWith('D') ? property.substring(1) : property;
      status['property_$displayName'] = _setAuthProperties.contains(property);
    }

    return status;
  }

  /// クラスパスに複数のパスを一括追加
  JvmArgsBuilder addClasspaths(Iterable<String> paths) {
    for (var path in paths) {
      addClasspath(path); // ノーマライズ処理はaddClasspathメソッドに委譲
    }
    return this;
  }

  /// ディレクトリ内のすべてのjarファイルをクラスパスに追加
  Future<JvmArgsBuilder> addClasspathsFromDirectory(String directory) async {
    final dir = Directory(directory);
    if (await dir.exists()) {
      await for (final entity in dir.list(recursive: true)) {
        if (entity is File && p.extension(entity.path) == '.jar') {
          addClasspath(entity.path); // ノーマライズ処理はaddClasspathメソッドに委譲
        }
      }
    }
    return this;
  }

  /// 追加の引数を設定
  JvmArgsBuilder withAdditionalArgs(List<String> args) {
    for (final arg in args) {
      withAdditionalArg(arg);
    }
    return this;
  }

  /// 追加の引数を1つ追加
  JvmArgsBuilder withAdditionalArg(String arg) {
    final processedArg = replacePlaceholders(arg);
    _additionalArgs.add(processedArg);
    return this;
  }

  /// モジュールのJVM引数をバッチで追加
  ///
  /// 特定のモジュール（Forgeなど）が必要とするJVM引数をバッチで追加します
  JvmArgsBuilder withModuleArguments(List<dynamic> arguments) {
    for (final arg in arguments) {
      if (arg is String) {
        withAdditionalArg(arg);
      } else if (arg is Map<String, dynamic> && arg.containsKey('value')) {
        final value = arg['value'];
        if (value is String) {
          withAdditionalArg(value);
        } else if (value is List) {
          for (final item in value) {
            if (item is String) {
              withAdditionalArg(item);
            }
          }
        }
      }
    }
    return this;
  }

  /// クラスパス文字列を構築
  String _buildClasspath() {
    return _classpaths.join(_classpathSeparator);
  }

  /// 文字列内のプレースホルダーを置換
  ///
  /// "${placeholder}" 形式のプレースホルダーを設定された値で置換します
  String replacePlaceholders(String input) {
    String result = input;
    _placeholders.forEach((key, value) {
      result = result.replaceAll('\${$key}', value);
    });
    return result;
  }

  /// JVM引数リストを構築（標準的な順序で）
  List<String> build() {
    final args = <String>[];

    // メモリ設定（Xで始まる引数）を最初に追加
    for (final entry in _arguments.entries.where(
      (e) => e.key.startsWith('X'),
    )) {
      args.add('-${entry.key}${entry.value}');
    }

    // システムプロパティ（Dで始まる引数）を追加
    for (final entry in _arguments.entries.where(
      (e) => e.key.startsWith('D'),
    )) {
      args.add('-${entry.key}=${entry.value}');
    }

    // その他のJVM引数を追加
    for (final entry in _arguments.entries.where(
      (e) => !e.key.startsWith('X') && !e.key.startsWith('D'),
    )) {
      args.add('-${entry.key}=${entry.value}');
    }

    // クラスパスを追加
    if (_classpaths.isNotEmpty) {
      args.add('-cp');
      args.add(_buildClasspath());
    }

    // jarファイルが指定されている場合は-jarオプションを追加
    if (_jarFile != null) {
      args.add('-jar');
      args.add(_jarFile!);
    }

    if (_mainClass != null) {
      // メインクラスを追加
      args.add(_mainClass!);
    }

    // 追加の引数を追加
    args.addAll(_additionalArgs);

    return args;
  }

  /// Java実行コマンドを構築（javaパスを含む完全な実行コマンド）
  List<String> buildCommand(String javaPath) {
    return [javaPath, ...build()];
  }

  /// ルールベースの引数を追加
  ///
  /// 条件付きの引数を追加します。主にMinecraftのバージョンJSONからの引数に使用されます。
  JvmArgsBuilder withRuleBasedArguments(dynamic arguments) {
    if (arguments is List) {
      for (final arg in arguments) {
        try {
          bool shouldAdd = true;

          // ルールがある場合は評価
          if (arg is Map<String, dynamic> && arg.containsKey('rules')) {
            final rules = arg['rules'] as List;
            if (rules.isNotEmpty) {
              shouldAdd = false;
              for (final rule in rules) {
                final action = rule['action'];
                final os = rule.containsKey('os') ? rule['os'] : null;

                bool osMatch =
                    os == null ||
                    (os['name'] == 'windows' && Platform.isWindows) ||
                    (os['name'] == 'linux' && Platform.isLinux) ||
                    (os['name'] == 'osx' && Platform.isMacOS);

                if (osMatch) {
                  shouldAdd = action == 'allow';
                }
              }
            }
          }
          debugPrint('Arg type:${arg.runtimeType.toString()}');

          if (arg is Map<String, dynamic>) {
            if (shouldAdd && arg.containsKey('value')) {
              final value = arg['value'];
              if (value is String) {
                withAdditionalArg(value);
              } else if (value is List) {
                for (final item in value) {
                  if (item is String) {
                    withAdditionalArg(item);
                  }
                }
              }
            }
          }
        } catch (e) {
          // エラーが発生した場合はスキップ
          debugPrint('ルールベース引数の処理中にエラーが発生しました: $e');
        }
      }
    }
    return this;
  }

  /// 重複する引数を削除し最適化する
  JvmArgsBuilder optimize() {
    // メモリ設定や同じシステムプロパティの重複を排除するロジック
    final uniqueProperties = <String, String>{};

    // 既存の引数をユニークなプロパティに変換
    _arguments.forEach((key, value) {
      uniqueProperties[key] = value;
    });

    // 一度クリアして、ユニークな値だけを設定し直す
    _arguments.clear();
    _arguments.addAll(uniqueProperties);

    return this;
  }

  /// 認証関連の引数をクリアする
  ///
  /// この操作は認証情報の保護を解除し、新しい認証情報の設定を可能にします。
  /// 主にオフラインモードへの切り替えや認証情報の再設定が必要な場合に使用します。
  JvmArgsBuilder clearAuthInfo() {
    // 認証関連のプレースホルダーを削除
    for (final placeholder in _authPlaceholders) {
      _placeholders.remove(placeholder);
    }
    _setAuthPlaceholders.clear();

    // 認証関連のシステムプロパティを削除
    for (final property in _authSystemProperties) {
      _arguments.remove(property);
    }
    _setAuthProperties.clear();

    return this;
  }

  @override
  String toString() {
    return build().join(' ');
  }
}
