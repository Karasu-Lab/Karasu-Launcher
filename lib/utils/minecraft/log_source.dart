/// LogSourceを定義するクラス
/// ログの出力元を表します。
class LogSource {
  final String source;

  const LogSource(this.source);

  static const LogSource stdout = LogSource('stdout');
  static const LogSource stderr = LogSource('stderr');
}
