import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AboutLicensePage extends ConsumerStatefulWidget {
  const AboutLicensePage({super.key});

  @override
  ConsumerState<AboutLicensePage> createState() => _AboutLicensePageState();
}

class _AboutLicensePageState extends ConsumerState<AboutLicensePage> {
  late Future<PackageInfo> _packageInfoFuture;

  @override
  void initState() {
    super.initState();
    _packageInfoFuture = PackageInfo.fromPlatform();
  }

  @override
  Widget build(BuildContext context) {
    return LicensePage();
  }
}
