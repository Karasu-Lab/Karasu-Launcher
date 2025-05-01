import 'package:json_annotation/json_annotation.dart';

part 'java_runtime.g.dart';

@JsonSerializable()
class JavaRuntime {
  final Gamecore? gamecore;
  final Linux? linux;
  @JsonKey(name: 'linux-i386')
  final LinuxI386? linuxI386;
  @JsonKey(name: 'mac-os')
  final Linux? macOs;
  @JsonKey(name: 'mac-os-arm64')
  final MacOsArm64? macOsArm64;
  @JsonKey(name: 'windows-arm64')
  final MacOsArm64? windowsArm64;
  @JsonKey(name: 'windows-x64')
  final WindowsX64? windowsX64;
  @JsonKey(name: 'windows-x86')
  final WindowsX86? windowsX86;

  JavaRuntime({
    this.gamecore,
    this.linux,
    this.linuxI386,
    this.macOs,
    this.macOsArm64,
    this.windowsArm64,
    this.windowsX64,
    this.windowsX86,
  });

  factory JavaRuntime.fromJson(Map<String, dynamic> json) =>
      _$JavaRuntimeFromJson(json);
  Map<String, dynamic> toJson() => _$JavaRuntimeToJson(this);
}

@JsonSerializable()
class Gamecore {
  @JsonKey(name: 'java-runtime-alpha')
  final List<dynamic>? javaRuntimeAlpha;
  @JsonKey(name: 'java-runtime-beta')
  final List<dynamic>? javaRuntimeBeta;
  @JsonKey(name: 'java-runtime-delta')
  final List<dynamic>? javaRuntimeDelta;
  @JsonKey(name: 'java-runtime-gamma')
  final List<dynamic>? javaRuntimeGamma;
  @JsonKey(name: 'java-runtime-gamma-snapshot')
  final List<dynamic>? javaRuntimeGammaSnapshot;
  @JsonKey(name: 'jre-legacy')
  final List<dynamic>? jreLegacy;
  @JsonKey(name: 'minecraft-java-exe')
  final List<dynamic>? minecraftJavaExe;

  Gamecore({
    this.javaRuntimeAlpha,
    this.javaRuntimeBeta,
    this.javaRuntimeDelta,
    this.javaRuntimeGamma,
    this.javaRuntimeGammaSnapshot,
    this.jreLegacy,
    this.minecraftJavaExe,
  });

  factory Gamecore.fromJson(Map<String, dynamic> json) =>
      _$GamecoreFromJson(json);
  Map<String, dynamic> toJson() => _$GamecoreToJson(this);
}

@JsonSerializable()
class Linux {
  @JsonKey(name: 'java-runtime-alpha')
  final List<JavaRuntimeAlpha>? javaRuntimeAlpha;
  @JsonKey(name: 'java-runtime-beta')
  final List<JavaRuntimeBeta>? javaRuntimeBeta;
  @JsonKey(name: 'java-runtime-delta')
  final List<JavaRuntimeDelta>? javaRuntimeDelta;
  @JsonKey(name: 'java-runtime-gamma')
  final List<JavaRuntimeGamma>? javaRuntimeGamma;
  @JsonKey(name: 'java-runtime-gamma-snapshot')
  final List<JavaRuntimeGammaSnapshot>? javaRuntimeGammaSnapshot;
  @JsonKey(name: 'jre-legacy')
  final List<JreLegacy>? jreLegacy;
  @JsonKey(name: 'minecraft-java-exe')
  final List<dynamic>? minecraftJavaExe;

  Linux({
    this.javaRuntimeAlpha,
    this.javaRuntimeBeta,
    this.javaRuntimeDelta,
    this.javaRuntimeGamma,
    this.javaRuntimeGammaSnapshot,
    this.jreLegacy,
    this.minecraftJavaExe,
  });

  factory Linux.fromJson(Map<String, dynamic> json) => _$LinuxFromJson(json);
  Map<String, dynamic> toJson() => _$LinuxToJson(this);
}

@JsonSerializable()
class JavaRuntimeAlpha {
  final Availability? availability;
  final Manifest? manifest;
  final Version? version;

  JavaRuntimeAlpha({
    this.availability,
    this.manifest,
    this.version,
  });

  factory JavaRuntimeAlpha.fromJson(Map<String, dynamic> json) =>
      _$JavaRuntimeAlphaFromJson(json);
  Map<String, dynamic> toJson() => _$JavaRuntimeAlphaToJson(this);
}

@JsonSerializable()
class Availability {
  final int? group;
  final int? progress;

  Availability({
    this.group,
    this.progress,
  });

  factory Availability.fromJson(Map<String, dynamic> json) =>
      _$AvailabilityFromJson(json);
  Map<String, dynamic> toJson() => _$AvailabilityToJson(this);
}

@JsonSerializable()
class Manifest {
  final String? sha1;
  final int? size;
  final String? url;

  Manifest({
    this.sha1,
    this.size,
    this.url,
  });

  factory Manifest.fromJson(Map<String, dynamic> json) =>
      _$ManifestFromJson(json);
  Map<String, dynamic> toJson() => _$ManifestToJson(this);
}

@JsonSerializable()
class Version {
  final String? name;
  final String? released;

  Version({
    this.name,
    this.released,
  });

  factory Version.fromJson(Map<String, dynamic> json) =>
      _$VersionFromJson(json);
  Map<String, dynamic> toJson() => _$VersionToJson(this);
}

@JsonSerializable()
class LinuxI386 {
  @JsonKey(name: 'java-runtime-alpha')
  final List<dynamic>? javaRuntimeAlpha;
  @JsonKey(name: 'java-runtime-beta')
  final List<dynamic>? javaRuntimeBeta;
  @JsonKey(name: 'java-runtime-delta')
  final List<dynamic>? javaRuntimeDelta;
  @JsonKey(name: 'java-runtime-gamma')
  final List<dynamic>? javaRuntimeGamma;
  @JsonKey(name: 'java-runtime-gamma-snapshot')
  final List<dynamic>? javaRuntimeGammaSnapshot;
  @JsonKey(name: 'jre-legacy')
  final List<JreLegacy>? jreLegacy;
  @JsonKey(name: 'minecraft-java-exe')
  final List<dynamic>? minecraftJavaExe;

  LinuxI386({
    this.javaRuntimeAlpha,
    this.javaRuntimeBeta,
    this.javaRuntimeDelta,
    this.javaRuntimeGamma,
    this.javaRuntimeGammaSnapshot,
    this.jreLegacy,
    this.minecraftJavaExe,
  });

  factory LinuxI386.fromJson(Map<String, dynamic> json) =>
      _$LinuxI386FromJson(json);
  Map<String, dynamic> toJson() => _$LinuxI386ToJson(this);
}

@JsonSerializable()
class MacOsArm64 {
  @JsonKey(name: 'java-runtime-alpha')
  final List<dynamic>? javaRuntimeAlpha;
  @JsonKey(name: 'java-runtime-beta')
  final List<dynamic>? javaRuntimeBeta;
  @JsonKey(name: 'java-runtime-delta')
  final List<JavaRuntimeDelta>? javaRuntimeDelta;
  @JsonKey(name: 'java-runtime-gamma')
  final List<JavaRuntimeGamma>? javaRuntimeGamma;
  @JsonKey(name: 'java-runtime-gamma-snapshot')
  final List<JavaRuntimeGammaSnapshot>? javaRuntimeGammaSnapshot;
  @JsonKey(name: 'jre-legacy')
  final List<dynamic>? jreLegacy;
  @JsonKey(name: 'minecraft-java-exe')
  final List<dynamic>? minecraftJavaExe;

  MacOsArm64({
    this.javaRuntimeAlpha,
    this.javaRuntimeBeta,
    this.javaRuntimeDelta,
    this.javaRuntimeGamma,
    this.javaRuntimeGammaSnapshot,
    this.jreLegacy,
    this.minecraftJavaExe,
  });

  factory MacOsArm64.fromJson(Map<String, dynamic> json) =>
      _$MacOsArm64FromJson(json);
  Map<String, dynamic> toJson() => _$MacOsArm64ToJson(this);
}

@JsonSerializable()
class WindowsX64 {
  @JsonKey(name: 'java-runtime-alpha')
  final List<JavaRuntimeAlpha>? javaRuntimeAlpha;
  @JsonKey(name: 'java-runtime-beta')
  final List<JavaRuntimeBeta>? javaRuntimeBeta;
  @JsonKey(name: 'java-runtime-delta')
  final List<JavaRuntimeDelta>? javaRuntimeDelta;
  @JsonKey(name: 'java-runtime-gamma')
  final List<JavaRuntimeGamma>? javaRuntimeGamma;
  @JsonKey(name: 'java-runtime-gamma-snapshot')
  final List<JavaRuntimeGammaSnapshot>? javaRuntimeGammaSnapshot;
  @JsonKey(name: 'jre-legacy')
  final List<JreLegacy>? jreLegacy;
  @JsonKey(name: 'minecraft-java-exe')
  final List<MinecraftJavaExe>? minecraftJavaExe;

  WindowsX64({
    this.javaRuntimeAlpha,
    this.javaRuntimeBeta,
    this.javaRuntimeDelta,
    this.javaRuntimeGamma,
    this.javaRuntimeGammaSnapshot,
    this.jreLegacy,
    this.minecraftJavaExe,
  });

  factory WindowsX64.fromJson(Map<String, dynamic> json) =>
      _$WindowsX64FromJson(json);
  Map<String, dynamic> toJson() => _$WindowsX64ToJson(this);
}

@JsonSerializable()
class WindowsX86 {
  @JsonKey(name: 'java-runtime-alpha')
  final List<JavaRuntimeAlpha>? javaRuntimeAlpha;
  @JsonKey(name: 'java-runtime-beta')
  final List<JavaRuntimeBeta>? javaRuntimeBeta;
  @JsonKey(name: 'java-runtime-delta')
  final List<dynamic>? javaRuntimeDelta;
  @JsonKey(name: 'java-runtime-gamma')
  final List<JavaRuntimeGamma>? javaRuntimeGamma;
  @JsonKey(name: 'java-runtime-gamma-snapshot')
  final List<JavaRuntimeGammaSnapshot>? javaRuntimeGammaSnapshot;
  @JsonKey(name: 'jre-legacy')
  final List<JreLegacy>? jreLegacy;
  @JsonKey(name: 'minecraft-java-exe')
  final List<MinecraftJavaExe>? minecraftJavaExe;

  WindowsX86({
    this.javaRuntimeAlpha,
    this.javaRuntimeBeta,
    this.javaRuntimeDelta,
    this.javaRuntimeGamma,
    this.javaRuntimeGammaSnapshot,
    this.jreLegacy,
    this.minecraftJavaExe,
  });

  factory WindowsX86.fromJson(Map<String, dynamic> json) =>
      _$WindowsX86FromJson(json);
  Map<String, dynamic> toJson() => _$WindowsX86ToJson(this);
}

@JsonSerializable()
class JavaRuntimeBeta {
  final Availability? availability;
  final Manifest? manifest;
  final Version? version;

  JavaRuntimeBeta({
    this.availability,
    this.manifest,
    this.version,
  });

  factory JavaRuntimeBeta.fromJson(Map<String, dynamic> json) =>
      _$JavaRuntimeBetaFromJson(json);
  Map<String, dynamic> toJson() => _$JavaRuntimeBetaToJson(this);
}

@JsonSerializable()
class JavaRuntimeDelta {
  final Availability? availability;
  final Manifest? manifest;
  final Version? version;

  JavaRuntimeDelta({
    this.availability,
    this.manifest,
    this.version,
  });

  factory JavaRuntimeDelta.fromJson(Map<String, dynamic> json) =>
      _$JavaRuntimeDeltaFromJson(json);
  Map<String, dynamic> toJson() => _$JavaRuntimeDeltaToJson(this);
}

@JsonSerializable()
class JavaRuntimeGamma {
  final Availability? availability;
  final Manifest? manifest;
  final Version? version;

  JavaRuntimeGamma({
    this.availability,
    this.manifest,
    this.version,
  });

  factory JavaRuntimeGamma.fromJson(Map<String, dynamic> json) =>
      _$JavaRuntimeGammaFromJson(json);
  Map<String, dynamic> toJson() => _$JavaRuntimeGammaToJson(this);
}

@JsonSerializable()
class JavaRuntimeGammaSnapshot {
  final Availability? availability;
  final Manifest? manifest;
  final Version? version;

  JavaRuntimeGammaSnapshot({
    this.availability,
    this.manifest,
    this.version,
  });

  factory JavaRuntimeGammaSnapshot.fromJson(Map<String, dynamic> json) =>
      _$JavaRuntimeGammaSnapshotFromJson(json);
  Map<String, dynamic> toJson() => _$JavaRuntimeGammaSnapshotToJson(this);
}

@JsonSerializable()
class JreLegacy {
  final Availability? availability;
  final Manifest? manifest;
  final Version? version;

  JreLegacy({
    this.availability,
    this.manifest,
    this.version,
  });

  factory JreLegacy.fromJson(Map<String, dynamic> json) =>
      _$JreLegacyFromJson(json);
  Map<String, dynamic> toJson() => _$JreLegacyToJson(this);
}

@JsonSerializable()
class MinecraftJavaExe {
  final Availability? availability;
  final Manifest? manifest;
  final Version? version;

  MinecraftJavaExe({
    this.availability,
    this.manifest,
    this.version,
  });

  factory MinecraftJavaExe.fromJson(Map<String, dynamic> json) =>
      _$MinecraftJavaExeFromJson(json);
  Map<String, dynamic> toJson() => _$MinecraftJavaExeToJson(this);
}
