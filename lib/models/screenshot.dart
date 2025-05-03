import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';

part 'screenshot.g.dart';

@JsonSerializable()
class Screenshot {
  final String id;
  final String filePath;
  final String profileId;
  final String? comment;
  final DateTime createdAt;
  final Map<String, dynamic>? metadata;

  Screenshot({
    String? id,
    required this.filePath,
    required this.profileId,
    this.comment,
    DateTime? createdAt,
    this.metadata,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  factory Screenshot.fromJson(Map<String, dynamic> json) =>
      _$ScreenshotFromJson(json);

  Map<String, dynamic> toJson() => _$ScreenshotToJson(this);

  Screenshot copyWith({
    String? filePath,
    String? profileId,
    String? comment,
    DateTime? createdAt,
    Map<String, dynamic>? metadata,
  }) {
    return Screenshot(
      id: id,
      filePath: filePath ?? this.filePath,
      profileId: profileId ?? this.profileId,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Screenshot &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
