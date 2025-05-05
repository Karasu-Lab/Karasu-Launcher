import 'package:json_annotation/json_annotation.dart';

part 'mod_loader.g.dart';

/// モッドローダーの種類を表す列挙型
enum ModLoaderType {
  fabric,
  forge,
  quilt,
  liteloader,
  other;

  /// 文字列からModLoaderTypeを取得する
  static ModLoaderType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'fabric':
        return ModLoaderType.fabric;
      case 'forge':
        return ModLoaderType.forge;
      case 'quilt':
        return ModLoaderType.quilt;
      case 'liteloader':
        return ModLoaderType.liteloader;
      default:
        return ModLoaderType.other;
    }
  }

  /// ModLoaderTypeを文字列に変換する
  String toDisplayString() {
    switch (this) {
      case ModLoaderType.fabric:
        return 'Fabric';
      case ModLoaderType.forge:
        return 'Forge';
      case ModLoaderType.quilt:
        return 'Quilt';
      case ModLoaderType.liteloader:
        return 'LiteLoader';
      case ModLoaderType.other:
        return 'その他';
    }
  }
}

/// モッドローダー情報を保持するクラス
@JsonSerializable()
class ModLoader {
  @JsonKey(name: 'type')
  final ModLoaderType type;

  @JsonKey(name: 'version')
  final String version;

  @JsonKey(name: 'baseGameVersion')
  final String baseGameVersion;

  @JsonKey(name: 'inheritsFrom')
  final String? inheritsFrom;

  @JsonKey(name: 'mainClass')
  final String? mainClass;

  @JsonKey(name: 'releaseTime')
  final String? releaseTime;

  @JsonKey(name: 'time')
  final String? time;

  @JsonKey(name: 'id')
  final String? id;

  @JsonKey(name: 'arguments')
  final Map<String, dynamic>? arguments;

  @JsonKey(name: 'libraries')
  final List<Map<String, dynamic>>? libraries;

  ModLoader({
    required this.type,
    required this.version,
    required this.baseGameVersion,
    this.inheritsFrom,
    this.mainClass,
    this.releaseTime,
    this.time,
    this.id,
    this.arguments,
    this.libraries,
  });

  factory ModLoader.fromJson(Map<String, dynamic> json) =>
      _$ModLoaderFromJson(json);

  Map<String, dynamic> toJson() => _$ModLoaderToJson(this);

  /// ファイル名からModLoader情報を抽出
  static ModLoader? fromFileName(String fileName) {
    // Fabric Loader: fabric-loader-0.14.24-1.20.2
    RegExp fabricRegex = RegExp(
      r'fabric-loader-(\d+\.\d+\.\d+)-(\d+\.\d+(?:\.\d+)?)',
    );
    // Forge Loader: 1.20.1-forge-47.2.0
    RegExp forgeRegex = RegExp(r'(\d+\.\d+(?:\.\d+)?)-forge-(\d+\.\d+\.\d+)');
    // Quilt Loader: quilt-loader-0.19.2-1.19.4
    RegExp quiltRegex = RegExp(
      r'quilt-loader-(\d+\.\d+\.\d+)-(\d+\.\d+(?:\.\d+)?)',
    );

    if (fabricRegex.hasMatch(fileName)) {
      final match = fabricRegex.firstMatch(fileName)!;
      return ModLoader(
        type: ModLoaderType.fabric,
        version: match.group(1)!,
        baseGameVersion: match.group(2)!,
        inheritsFrom: match.group(2),
      );
    } else if (forgeRegex.hasMatch(fileName)) {
      final match = forgeRegex.firstMatch(fileName)!;
      return ModLoader(
        type: ModLoaderType.forge,
        version: match.group(2)!,
        baseGameVersion: match.group(1)!,
        inheritsFrom: match.group(1),
      );
    } else if (quiltRegex.hasMatch(fileName)) {
      final match = quiltRegex.firstMatch(fileName)!;
      return ModLoader(
        type: ModLoaderType.quilt,
        version: match.group(1)!,
        baseGameVersion: match.group(2)!,
        inheritsFrom: match.group(2),
      );
    }

    return null;
  }

  /// JSONファイルの内容からModLoader情報を抽出
  static ModLoader? fromJsonContent(
    Map<String, dynamic> json,
    String fileName,
  ) {
    // 継承関係が定義されているか確認
    final String? inheritsFrom = json['inheritsFrom'] as String?;
    if (inheritsFrom == null) return null;

    // ファイル名からモッドローダーのタイプを推定
    ModLoaderType type = ModLoaderType.other;
    String version = 'unknown';

    if (fileName.contains('fabric')) {
      type = ModLoaderType.fabric;
      // Fabricバージョンを抽出（librariesからfabric-loaderを検索）
      final libraries = json['libraries'] as List<dynamic>?;
      if (libraries != null) {
        for (final lib in libraries) {
          final name = lib['name'] as String?;
          if (name != null && name.startsWith('net.fabricmc:fabric-loader:')) {
            version = name.split(':').last;
            break;
          }
        }
      }
    } else if (fileName.contains('forge')) {
      type = ModLoaderType.forge;
      // Forgeバージョンを抽出
      if (fileName.contains('-forge-')) {
        version = fileName.split('-forge-').last.replaceAll('.json', '');
      }
    } else if (fileName.contains('quilt')) {
      type = ModLoaderType.quilt;
      // Quiltバージョンを抽出
      final libraries = json['libraries'] as List<dynamic>?;
      if (libraries != null) {
        for (final lib in libraries) {
          final name = lib['name'] as String?;
          if (name != null && name.startsWith('org.quiltmc:quilt-loader:')) {
            version = name.split(':').last;
            break;
          }
        }
      }
    }

    // jsonからライブラリ情報を取得
    final List<Map<String, dynamic>>? librariesData =
        json['libraries'] != null
            ? (json['libraries'] as List).cast<Map<String, dynamic>>()
            : null;

    return ModLoader(
      type: type,
      version: version,
      baseGameVersion: inheritsFrom,
      inheritsFrom: inheritsFrom,
      mainClass: json['mainClass'] as String?,
      releaseTime: json['releaseTime'] as String?,
      time: json['time'] as String?,
      id: json['id'] as String?,
      arguments: json['arguments'] as Map<String, dynamic>?,
      libraries: librariesData,
    );
  }
}
