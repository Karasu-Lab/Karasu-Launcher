import 'package:karasu_launcher/utils/minecraft/default_launcher.dart';
import 'package:karasu_launcher/utils/minecraft/launch/base_launcher.dart';
import 'package:karasu_launcher/utils/minecraft/launch/standard_launcher.dart';

/// Minecraftランチャーのファクトリークラス
class LauncherFactory {
  /// シングルトンインスタンス
  static final LauncherFactory _instance = LauncherFactory._internal();
  
  /// 現在のランチャー実装
  BaseLauncher? _currentLauncher;
  
  /// Minecraftランチャーインターフェースの実装
  StandardLauncher? _standardLauncher;

  /// プライベートコンストラクタ
  LauncherFactory._internal();
  
  /// ファクトリーインスタンスを取得
  factory LauncherFactory() {
    return _instance;
  }

  /// デフォルトのランチャーを取得
  T getLauncher<T extends BaseLauncher<T>>() {
    if (_currentLauncher != null) {
      return _currentLauncher as T;
    }
    
    // デフォルトのランチャー実装を返す
    _currentLauncher = DefaultLauncher();
    return _currentLauncher as T;
  }
  
  /// 標準ランチャーを取得
  StandardLauncher getStandardLauncher() {
    _standardLauncher ??= StandardLauncher();
    return _standardLauncher!;
  }
  
  /// カスタムランチャーをセット
  void setLauncher<T extends BaseLauncher<T>>(T launcher) {
    _currentLauncher = launcher;
  }
}
