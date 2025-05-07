import 'package:karasu_launcher/services/auth/auth_events.dart';

/// デバッグログ用のコールバック関数の型定義
typedef LogCallback = void Function(String message, {AuthEventType? eventType});
