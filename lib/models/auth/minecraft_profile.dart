import 'package:json_annotation/json_annotation.dart';

part 'minecraft_profile.g.dart';

@JsonSerializable()
class MinecraftProfile {
  final String id;
  final String name;
  final List<Skin>? skins;
  final List<Cape>? capes;

  MinecraftProfile({
    required this.id,
    required this.name,
    this.skins,
    this.capes,
  });

  /// スキンのURLを取得するゲッター
  String? get skinUrl {
    // スキンがある場合は最初のスキンのURLを返す
    if (skins != null && skins!.isNotEmpty) {
      return skins![0].url;
    }
    return null;
  }

  /// ケープのURLを取得するゲッター
  String? get capeUrl {
    // ケープがある場合は最初のケープのURLを返す
    if (capes != null && capes!.isNotEmpty) {
      return capes![0].url;
    }
    return null;
  }

  factory MinecraftProfile.fromJson(Map<String, dynamic> json) =>
      _$MinecraftProfileFromJson(json);

  Map<String, dynamic> toJson() => _$MinecraftProfileToJson(this);
}

@JsonSerializable()
class Skin {
  final String id;
  final String state;
  final String url;
  final String variant;
  final String? alias;

  Skin({
    required this.id,
    required this.state,
    required this.url,
    required this.variant,
    this.alias,
  });

  factory Skin.fromJson(Map<String, dynamic> json) => _$SkinFromJson(json);

  Map<String, dynamic> toJson() => _$SkinToJson(this);
}

@JsonSerializable()
class Cape {
  final String id;
  final String state;
  final String url;
  final String alias;

  Cape({
    required this.id,
    required this.state,
    required this.url,
    required this.alias,
  });

  factory Cape.fromJson(Map<String, dynamic> json) => _$CapeFromJson(json);

  Map<String, dynamic> toJson() => _$CapeToJson(this);
}
