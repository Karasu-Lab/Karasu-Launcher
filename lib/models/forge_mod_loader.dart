import 'package:json_annotation/json_annotation.dart';
import 'package:karasu_launcher/models/mod_loader.dart';

part 'forge_mod_loader.g.dart';

@JsonSerializable()
class ForgeModLoader extends ModLoader {
  @JsonKey(name: 'minecraftArguments')
  final String? minecraftArguments;

  @JsonKey(name: 'tweakClass')
  final String? tweakClass;

  @JsonKey(includeFromJson: false, includeToJson: false)
  static const int maxJavaVersion = 8;

  ForgeModLoader({
    required super.type,
    required super.version,
    required super.baseGameVersion,
    super.inheritsFrom,
    super.mainClass,
    super.releaseTime,
    super.time,
    super.id,
    super.arguments,
    super.libraries,
    this.minecraftArguments,
    this.tweakClass,
  });

  factory ForgeModLoader.fromJson(Map<String, dynamic> json) {
    String forgeVersion = '';
    String baseGameVersion = '';

    if (json['id'] != null) {
      final id = json['id'] as String;
      final parts = id.split('-forge-');
      if (parts.length == 2) {
        baseGameVersion = parts[0];
        forgeVersion = parts[1];
      }
    }

    String? tweakClass;
    if (json['minecraftArguments'] != null) {
      final args = json['minecraftArguments'] as String;
      final tweakMatch = RegExp(r'--tweakClass\s+([^\s]+)').firstMatch(args);
      if (tweakMatch != null) {
        tweakClass = tweakMatch.group(1);
      }
    }

    return ForgeModLoader(
      type: ModLoaderType.forge,
      version: forgeVersion,
      baseGameVersion: baseGameVersion,
      inheritsFrom: json['inheritsFrom'] as String?,
      mainClass: json['mainClass'] as String?,
      releaseTime: json['releaseTime'] as String?,
      time: json['time'] as String?,
      id: json['id'] as String?,
      arguments: json['arguments'] as Map<String, dynamic>?,
      libraries:
          json['libraries'] != null
              ? (json['libraries'] as List).cast<Map<String, dynamic>>()
              : null,
      minecraftArguments: json['minecraftArguments'] as String?,
      tweakClass: tweakClass,
    );
  }

  @override
  Map<String, dynamic> toJson() => _$ForgeModLoaderToJson(this);

  static ForgeModLoader? fromJsonContent(
    Map<String, dynamic> json,
    String fileName,
  ) {
    if (!fileName.contains('forge')) return null;

    try {
      return ForgeModLoader.fromJson(json);
    } catch (e) {
      return null;
    }
  }
}
