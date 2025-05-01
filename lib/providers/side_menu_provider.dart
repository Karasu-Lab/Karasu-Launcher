import 'package:flutter_riverpod/flutter_riverpod.dart';

/// サイドメニューの表示状態を管理するプロバイダー
final sideMenuOpenProvider = StateProvider<bool>((ref) => false);
