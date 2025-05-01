import 'package:json_annotation/json_annotation.dart';

part 'java_patch_note.g.dart';

@JsonSerializable()
class JavaPatchNote {
  final int version;
  final List<JavaPatchNoteEntry> entries;

  JavaPatchNote({required this.version, required this.entries});

  factory JavaPatchNote.fromJson(Map<String, dynamic> json) {
    List<dynamic> entriesJson = json['entries'] ?? [];
    List<JavaPatchNoteEntry> entriesList =
        entriesJson
            .map((entryJson) => JavaPatchNoteEntry.fromJson(entryJson))
            .toList();

    return JavaPatchNote(version: json['version'] ?? 1, entries: entriesList);
  }

  Map<String, dynamic> toJson() => _$JavaPatchNoteToJson(this);
}

@JsonSerializable()
class JavaPatchNoteEntry {
  final String title;
  final String version;
  final String body;
  final String? type;
  final String? id;
  final String? contentPath;
  final JavaPatchNoteImage? image;

  JavaPatchNoteEntry({
    required this.title,
    required this.version,
    required this.body,
    this.type,
    this.id,
    this.contentPath,
    this.image,
  });

  factory JavaPatchNoteEntry.fromJson(Map<String, dynamic> json) {
    return JavaPatchNoteEntry(
      title: json['title'] ?? '',
      version: json['version'] ?? '',
      body: json['body'] ?? '',
      type: json['type'],
      id: json['id'],
      contentPath: json['contentPath'],
      image:
          json['image'] != null
              ? JavaPatchNoteImage.fromJson(json['image'])
              : null,
    );
  }

  Map<String, dynamic> toJson() => _$JavaPatchNoteEntryToJson(this);
}

@JsonSerializable()
class JavaPatchNoteImage {
  final String url;
  final String title;

  JavaPatchNoteImage({required this.url, required this.title});

  factory JavaPatchNoteImage.fromJson(Map<String, dynamic> json) {
    return JavaPatchNoteImage(
      url: json['url'] ?? '',
      title: json['title'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => _$JavaPatchNoteImageToJson(this);
}