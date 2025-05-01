import 'package:json_annotation/json_annotation.dart';

part 'assets_indexes.g.dart';

@JsonSerializable()
class AssetsIndexes {
  final Map<String, AssetObject> objects;

  AssetsIndexes({required this.objects});

  factory AssetsIndexes.fromJson(Map<String, dynamic> json) =>
      _$AssetsIndexesFromJson(json);

  Map<String, dynamic> toJson() => _$AssetsIndexesToJson(this);
}

@JsonSerializable()
class AssetObject {
  final String hash;
  final int size;

  AssetObject({required this.hash, required this.size});

  factory AssetObject.fromJson(Map<String, dynamic> json) =>
      _$AssetObjectFromJson(json);

  Map<String, dynamic> toJson() => _$AssetObjectToJson(this);
}
