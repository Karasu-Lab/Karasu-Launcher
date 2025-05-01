// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'java_runtime.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

JavaRuntime _$JavaRuntimeFromJson(Map<String, dynamic> json) => JavaRuntime(
  gamecore:
      json['gamecore'] == null
          ? null
          : Gamecore.fromJson(json['gamecore'] as Map<String, dynamic>),
  linux:
      json['linux'] == null
          ? null
          : Linux.fromJson(json['linux'] as Map<String, dynamic>),
  linuxI386:
      json['linux-i386'] == null
          ? null
          : LinuxI386.fromJson(json['linux-i386'] as Map<String, dynamic>),
  macOs:
      json['mac-os'] == null
          ? null
          : Linux.fromJson(json['mac-os'] as Map<String, dynamic>),
  macOsArm64:
      json['mac-os-arm64'] == null
          ? null
          : MacOsArm64.fromJson(json['mac-os-arm64'] as Map<String, dynamic>),
  windowsArm64:
      json['windows-arm64'] == null
          ? null
          : MacOsArm64.fromJson(json['windows-arm64'] as Map<String, dynamic>),
  windowsX64:
      json['windows-x64'] == null
          ? null
          : WindowsX64.fromJson(json['windows-x64'] as Map<String, dynamic>),
  windowsX86:
      json['windows-x86'] == null
          ? null
          : WindowsX86.fromJson(json['windows-x86'] as Map<String, dynamic>),
);

Map<String, dynamic> _$JavaRuntimeToJson(JavaRuntime instance) =>
    <String, dynamic>{
      'gamecore': instance.gamecore,
      'linux': instance.linux,
      'linux-i386': instance.linuxI386,
      'mac-os': instance.macOs,
      'mac-os-arm64': instance.macOsArm64,
      'windows-arm64': instance.windowsArm64,
      'windows-x64': instance.windowsX64,
      'windows-x86': instance.windowsX86,
    };

Gamecore _$GamecoreFromJson(Map<String, dynamic> json) => Gamecore(
  javaRuntimeAlpha: json['java-runtime-alpha'] as List<dynamic>?,
  javaRuntimeBeta: json['java-runtime-beta'] as List<dynamic>?,
  javaRuntimeDelta: json['java-runtime-delta'] as List<dynamic>?,
  javaRuntimeGamma: json['java-runtime-gamma'] as List<dynamic>?,
  javaRuntimeGammaSnapshot:
      json['java-runtime-gamma-snapshot'] as List<dynamic>?,
  jreLegacy: json['jre-legacy'] as List<dynamic>?,
  minecraftJavaExe: json['minecraft-java-exe'] as List<dynamic>?,
);

Map<String, dynamic> _$GamecoreToJson(Gamecore instance) => <String, dynamic>{
  'java-runtime-alpha': instance.javaRuntimeAlpha,
  'java-runtime-beta': instance.javaRuntimeBeta,
  'java-runtime-delta': instance.javaRuntimeDelta,
  'java-runtime-gamma': instance.javaRuntimeGamma,
  'java-runtime-gamma-snapshot': instance.javaRuntimeGammaSnapshot,
  'jre-legacy': instance.jreLegacy,
  'minecraft-java-exe': instance.minecraftJavaExe,
};

Linux _$LinuxFromJson(Map<String, dynamic> json) => Linux(
  javaRuntimeAlpha:
      (json['java-runtime-alpha'] as List<dynamic>?)
          ?.map((e) => JavaRuntimeAlpha.fromJson(e as Map<String, dynamic>))
          .toList(),
  javaRuntimeBeta:
      (json['java-runtime-beta'] as List<dynamic>?)
          ?.map((e) => JavaRuntimeBeta.fromJson(e as Map<String, dynamic>))
          .toList(),
  javaRuntimeDelta:
      (json['java-runtime-delta'] as List<dynamic>?)
          ?.map((e) => JavaRuntimeDelta.fromJson(e as Map<String, dynamic>))
          .toList(),
  javaRuntimeGamma:
      (json['java-runtime-gamma'] as List<dynamic>?)
          ?.map((e) => JavaRuntimeGamma.fromJson(e as Map<String, dynamic>))
          .toList(),
  javaRuntimeGammaSnapshot:
      (json['java-runtime-gamma-snapshot'] as List<dynamic>?)
          ?.map(
            (e) => JavaRuntimeGammaSnapshot.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
  jreLegacy:
      (json['jre-legacy'] as List<dynamic>?)
          ?.map((e) => JreLegacy.fromJson(e as Map<String, dynamic>))
          .toList(),
  minecraftJavaExe: json['minecraft-java-exe'] as List<dynamic>?,
);

Map<String, dynamic> _$LinuxToJson(Linux instance) => <String, dynamic>{
  'java-runtime-alpha': instance.javaRuntimeAlpha,
  'java-runtime-beta': instance.javaRuntimeBeta,
  'java-runtime-delta': instance.javaRuntimeDelta,
  'java-runtime-gamma': instance.javaRuntimeGamma,
  'java-runtime-gamma-snapshot': instance.javaRuntimeGammaSnapshot,
  'jre-legacy': instance.jreLegacy,
  'minecraft-java-exe': instance.minecraftJavaExe,
};

JavaRuntimeAlpha _$JavaRuntimeAlphaFromJson(Map<String, dynamic> json) =>
    JavaRuntimeAlpha(
      availability:
          json['availability'] == null
              ? null
              : Availability.fromJson(
                json['availability'] as Map<String, dynamic>,
              ),
      manifest:
          json['manifest'] == null
              ? null
              : Manifest.fromJson(json['manifest'] as Map<String, dynamic>),
      version:
          json['version'] == null
              ? null
              : Version.fromJson(json['version'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$JavaRuntimeAlphaToJson(JavaRuntimeAlpha instance) =>
    <String, dynamic>{
      'availability': instance.availability,
      'manifest': instance.manifest,
      'version': instance.version,
    };

Availability _$AvailabilityFromJson(Map<String, dynamic> json) => Availability(
  group: (json['group'] as num?)?.toInt(),
  progress: (json['progress'] as num?)?.toInt(),
);

Map<String, dynamic> _$AvailabilityToJson(Availability instance) =>
    <String, dynamic>{'group': instance.group, 'progress': instance.progress};

Manifest _$ManifestFromJson(Map<String, dynamic> json) => Manifest(
  sha1: json['sha1'] as String?,
  size: (json['size'] as num?)?.toInt(),
  url: json['url'] as String?,
);

Map<String, dynamic> _$ManifestToJson(Manifest instance) => <String, dynamic>{
  'sha1': instance.sha1,
  'size': instance.size,
  'url': instance.url,
};

Version _$VersionFromJson(Map<String, dynamic> json) => Version(
  name: json['name'] as String?,
  released: json['released'] as String?,
);

Map<String, dynamic> _$VersionToJson(Version instance) => <String, dynamic>{
  'name': instance.name,
  'released': instance.released,
};

LinuxI386 _$LinuxI386FromJson(Map<String, dynamic> json) => LinuxI386(
  javaRuntimeAlpha: json['java-runtime-alpha'] as List<dynamic>?,
  javaRuntimeBeta: json['java-runtime-beta'] as List<dynamic>?,
  javaRuntimeDelta: json['java-runtime-delta'] as List<dynamic>?,
  javaRuntimeGamma: json['java-runtime-gamma'] as List<dynamic>?,
  javaRuntimeGammaSnapshot:
      json['java-runtime-gamma-snapshot'] as List<dynamic>?,
  jreLegacy:
      (json['jre-legacy'] as List<dynamic>?)
          ?.map((e) => JreLegacy.fromJson(e as Map<String, dynamic>))
          .toList(),
  minecraftJavaExe: json['minecraft-java-exe'] as List<dynamic>?,
);

Map<String, dynamic> _$LinuxI386ToJson(LinuxI386 instance) => <String, dynamic>{
  'java-runtime-alpha': instance.javaRuntimeAlpha,
  'java-runtime-beta': instance.javaRuntimeBeta,
  'java-runtime-delta': instance.javaRuntimeDelta,
  'java-runtime-gamma': instance.javaRuntimeGamma,
  'java-runtime-gamma-snapshot': instance.javaRuntimeGammaSnapshot,
  'jre-legacy': instance.jreLegacy,
  'minecraft-java-exe': instance.minecraftJavaExe,
};

MacOsArm64 _$MacOsArm64FromJson(Map<String, dynamic> json) => MacOsArm64(
  javaRuntimeAlpha: json['java-runtime-alpha'] as List<dynamic>?,
  javaRuntimeBeta: json['java-runtime-beta'] as List<dynamic>?,
  javaRuntimeDelta:
      (json['java-runtime-delta'] as List<dynamic>?)
          ?.map((e) => JavaRuntimeDelta.fromJson(e as Map<String, dynamic>))
          .toList(),
  javaRuntimeGamma:
      (json['java-runtime-gamma'] as List<dynamic>?)
          ?.map((e) => JavaRuntimeGamma.fromJson(e as Map<String, dynamic>))
          .toList(),
  javaRuntimeGammaSnapshot:
      (json['java-runtime-gamma-snapshot'] as List<dynamic>?)
          ?.map(
            (e) => JavaRuntimeGammaSnapshot.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
  jreLegacy: json['jre-legacy'] as List<dynamic>?,
  minecraftJavaExe: json['minecraft-java-exe'] as List<dynamic>?,
);

Map<String, dynamic> _$MacOsArm64ToJson(MacOsArm64 instance) =>
    <String, dynamic>{
      'java-runtime-alpha': instance.javaRuntimeAlpha,
      'java-runtime-beta': instance.javaRuntimeBeta,
      'java-runtime-delta': instance.javaRuntimeDelta,
      'java-runtime-gamma': instance.javaRuntimeGamma,
      'java-runtime-gamma-snapshot': instance.javaRuntimeGammaSnapshot,
      'jre-legacy': instance.jreLegacy,
      'minecraft-java-exe': instance.minecraftJavaExe,
    };

WindowsX64 _$WindowsX64FromJson(Map<String, dynamic> json) => WindowsX64(
  javaRuntimeAlpha:
      (json['java-runtime-alpha'] as List<dynamic>?)
          ?.map((e) => JavaRuntimeAlpha.fromJson(e as Map<String, dynamic>))
          .toList(),
  javaRuntimeBeta:
      (json['java-runtime-beta'] as List<dynamic>?)
          ?.map((e) => JavaRuntimeBeta.fromJson(e as Map<String, dynamic>))
          .toList(),
  javaRuntimeDelta:
      (json['java-runtime-delta'] as List<dynamic>?)
          ?.map((e) => JavaRuntimeDelta.fromJson(e as Map<String, dynamic>))
          .toList(),
  javaRuntimeGamma:
      (json['java-runtime-gamma'] as List<dynamic>?)
          ?.map((e) => JavaRuntimeGamma.fromJson(e as Map<String, dynamic>))
          .toList(),
  javaRuntimeGammaSnapshot:
      (json['java-runtime-gamma-snapshot'] as List<dynamic>?)
          ?.map(
            (e) => JavaRuntimeGammaSnapshot.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
  jreLegacy:
      (json['jre-legacy'] as List<dynamic>?)
          ?.map((e) => JreLegacy.fromJson(e as Map<String, dynamic>))
          .toList(),
  minecraftJavaExe:
      (json['minecraft-java-exe'] as List<dynamic>?)
          ?.map((e) => MinecraftJavaExe.fromJson(e as Map<String, dynamic>))
          .toList(),
);

Map<String, dynamic> _$WindowsX64ToJson(WindowsX64 instance) =>
    <String, dynamic>{
      'java-runtime-alpha': instance.javaRuntimeAlpha,
      'java-runtime-beta': instance.javaRuntimeBeta,
      'java-runtime-delta': instance.javaRuntimeDelta,
      'java-runtime-gamma': instance.javaRuntimeGamma,
      'java-runtime-gamma-snapshot': instance.javaRuntimeGammaSnapshot,
      'jre-legacy': instance.jreLegacy,
      'minecraft-java-exe': instance.minecraftJavaExe,
    };

WindowsX86 _$WindowsX86FromJson(Map<String, dynamic> json) => WindowsX86(
  javaRuntimeAlpha:
      (json['java-runtime-alpha'] as List<dynamic>?)
          ?.map((e) => JavaRuntimeAlpha.fromJson(e as Map<String, dynamic>))
          .toList(),
  javaRuntimeBeta:
      (json['java-runtime-beta'] as List<dynamic>?)
          ?.map((e) => JavaRuntimeBeta.fromJson(e as Map<String, dynamic>))
          .toList(),
  javaRuntimeDelta: json['java-runtime-delta'] as List<dynamic>?,
  javaRuntimeGamma:
      (json['java-runtime-gamma'] as List<dynamic>?)
          ?.map((e) => JavaRuntimeGamma.fromJson(e as Map<String, dynamic>))
          .toList(),
  javaRuntimeGammaSnapshot:
      (json['java-runtime-gamma-snapshot'] as List<dynamic>?)
          ?.map(
            (e) => JavaRuntimeGammaSnapshot.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
  jreLegacy:
      (json['jre-legacy'] as List<dynamic>?)
          ?.map((e) => JreLegacy.fromJson(e as Map<String, dynamic>))
          .toList(),
  minecraftJavaExe:
      (json['minecraft-java-exe'] as List<dynamic>?)
          ?.map((e) => MinecraftJavaExe.fromJson(e as Map<String, dynamic>))
          .toList(),
);

Map<String, dynamic> _$WindowsX86ToJson(WindowsX86 instance) =>
    <String, dynamic>{
      'java-runtime-alpha': instance.javaRuntimeAlpha,
      'java-runtime-beta': instance.javaRuntimeBeta,
      'java-runtime-delta': instance.javaRuntimeDelta,
      'java-runtime-gamma': instance.javaRuntimeGamma,
      'java-runtime-gamma-snapshot': instance.javaRuntimeGammaSnapshot,
      'jre-legacy': instance.jreLegacy,
      'minecraft-java-exe': instance.minecraftJavaExe,
    };

JavaRuntimeBeta _$JavaRuntimeBetaFromJson(Map<String, dynamic> json) =>
    JavaRuntimeBeta(
      availability:
          json['availability'] == null
              ? null
              : Availability.fromJson(
                json['availability'] as Map<String, dynamic>,
              ),
      manifest:
          json['manifest'] == null
              ? null
              : Manifest.fromJson(json['manifest'] as Map<String, dynamic>),
      version:
          json['version'] == null
              ? null
              : Version.fromJson(json['version'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$JavaRuntimeBetaToJson(JavaRuntimeBeta instance) =>
    <String, dynamic>{
      'availability': instance.availability,
      'manifest': instance.manifest,
      'version': instance.version,
    };

JavaRuntimeDelta _$JavaRuntimeDeltaFromJson(Map<String, dynamic> json) =>
    JavaRuntimeDelta(
      availability:
          json['availability'] == null
              ? null
              : Availability.fromJson(
                json['availability'] as Map<String, dynamic>,
              ),
      manifest:
          json['manifest'] == null
              ? null
              : Manifest.fromJson(json['manifest'] as Map<String, dynamic>),
      version:
          json['version'] == null
              ? null
              : Version.fromJson(json['version'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$JavaRuntimeDeltaToJson(JavaRuntimeDelta instance) =>
    <String, dynamic>{
      'availability': instance.availability,
      'manifest': instance.manifest,
      'version': instance.version,
    };

JavaRuntimeGamma _$JavaRuntimeGammaFromJson(Map<String, dynamic> json) =>
    JavaRuntimeGamma(
      availability:
          json['availability'] == null
              ? null
              : Availability.fromJson(
                json['availability'] as Map<String, dynamic>,
              ),
      manifest:
          json['manifest'] == null
              ? null
              : Manifest.fromJson(json['manifest'] as Map<String, dynamic>),
      version:
          json['version'] == null
              ? null
              : Version.fromJson(json['version'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$JavaRuntimeGammaToJson(JavaRuntimeGamma instance) =>
    <String, dynamic>{
      'availability': instance.availability,
      'manifest': instance.manifest,
      'version': instance.version,
    };

JavaRuntimeGammaSnapshot _$JavaRuntimeGammaSnapshotFromJson(
  Map<String, dynamic> json,
) => JavaRuntimeGammaSnapshot(
  availability:
      json['availability'] == null
          ? null
          : Availability.fromJson(json['availability'] as Map<String, dynamic>),
  manifest:
      json['manifest'] == null
          ? null
          : Manifest.fromJson(json['manifest'] as Map<String, dynamic>),
  version:
      json['version'] == null
          ? null
          : Version.fromJson(json['version'] as Map<String, dynamic>),
);

Map<String, dynamic> _$JavaRuntimeGammaSnapshotToJson(
  JavaRuntimeGammaSnapshot instance,
) => <String, dynamic>{
  'availability': instance.availability,
  'manifest': instance.manifest,
  'version': instance.version,
};

JreLegacy _$JreLegacyFromJson(Map<String, dynamic> json) => JreLegacy(
  availability:
      json['availability'] == null
          ? null
          : Availability.fromJson(json['availability'] as Map<String, dynamic>),
  manifest:
      json['manifest'] == null
          ? null
          : Manifest.fromJson(json['manifest'] as Map<String, dynamic>),
  version:
      json['version'] == null
          ? null
          : Version.fromJson(json['version'] as Map<String, dynamic>),
);

Map<String, dynamic> _$JreLegacyToJson(JreLegacy instance) => <String, dynamic>{
  'availability': instance.availability,
  'manifest': instance.manifest,
  'version': instance.version,
};

MinecraftJavaExe _$MinecraftJavaExeFromJson(Map<String, dynamic> json) =>
    MinecraftJavaExe(
      availability:
          json['availability'] == null
              ? null
              : Availability.fromJson(
                json['availability'] as Map<String, dynamic>,
              ),
      manifest:
          json['manifest'] == null
              ? null
              : Manifest.fromJson(json['manifest'] as Map<String, dynamic>),
      version:
          json['version'] == null
              ? null
              : Version.fromJson(json['version'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$MinecraftJavaExeToJson(MinecraftJavaExe instance) =>
    <String, dynamic>{
      'availability': instance.availability,
      'manifest': instance.manifest,
      'version': instance.version,
    };
