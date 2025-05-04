import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:karasu_launcher/providers/locale_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AboutHomePage extends ConsumerStatefulWidget {
  const AboutHomePage({super.key});

  @override
  ConsumerState<AboutHomePage> createState() => _AboutHomePageState();
}

class _AboutHomePageState extends ConsumerState<AboutHomePage> {
  final String _githubUrl = 'https://github.com/Karasu-Lab/Karasu-Launcher';
  final String _twitterUrl = 'https://twitter.com/Columba_Karasu';

  late Future<PackageInfo> _packageInfoFuture;
  String? _readmeContent;
  bool _isReadmeLoading = true;

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Failed to launch url: $url');
    }
  }

  Future<String> _loadReadmeContent(String languageCode) async {
    try {
      if (languageCode != 'en') {
        try {
          return await rootBundle.loadString('README.$languageCode.md');
        } catch (e) {
          return await rootBundle.loadString('README.md');
        }
      }
      return await rootBundle.loadString('README.md');
    } catch (e) {
      return '';
    }
  }

  @override
  void initState() {
    super.initState();
    _packageInfoFuture = PackageInfo.fromPlatform();
    _loadReadme();
  }

  Future<void> _loadReadme() async {
    setState(() {
      _isReadmeLoading = true;
    });

    final locale = ref.read(localeProvider);
    final languageCode = locale.languageCode;

    try {
      final content = await _loadReadmeContent(languageCode);
      setState(() {
        _readmeContent = content;
        _isReadmeLoading = false;
      });
    } catch (e) {
      setState(() {
        _readmeContent = '';
        _isReadmeLoading = false;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadReadme();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: FutureBuilder<PackageInfo>(
            future: _packageInfoFuture,
            builder: (context, snapshot) {
              String appName = 'Karasu Launcher';
              String version =
                  snapshot.hasData ? snapshot.data!.version : '1.0.0';
              String buildNumber =
                  snapshot.hasData ? snapshot.data!.buildNumber : '';

              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    appName,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    FlutterI18n.translate(
                      context,
                      'aboutPage.version',
                      translationParams: {'version': '$version+$buildNumber'},
                    ),
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 30),
                  Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Text(
                            FlutterI18n.translate(
                              context,
                              'aboutPage.appDescription',
                            ),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _isReadmeLoading
                              ? const CircularProgressIndicator()
                              : Container(
                                constraints: const BoxConstraints(
                                  maxHeight: 300,
                                ),
                                child: Markdown(
                                  listItemCrossAxisAlignment:
                                      MarkdownListItemCrossAxisAlignment.start,
                                  data: _readmeContent ?? '',
                                  shrinkWrap: true,
                                  styleSheet: MarkdownStyleSheet(
                                    p: const TextStyle(fontSize: 16),
                                    textAlign: WrapAlignment.center,
                                  ),
                                ),
                              ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLinkButton(
                        context,
                        icon: BoxIcons.bxl_github,
                        label: FlutterI18n.translate(
                          context,
                          'aboutPage.links.github',
                        ),
                        route: '/about/github',
                        color: Colors.black87,
                      ),
                      const SizedBox(width: 20),
                      _buildLinkButton(
                        context,
                        icon: BoxIcons.bxl_twitter,
                        label: FlutterI18n.translate(
                          context,
                          'aboutPage.links.twitter',
                        ),
                        route: '/about/twitter',
                        color: Colors.blue,
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLinkButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String route,
    required Color color,
  }) {
    return ElevatedButton.icon(
      onPressed: () {
        if (route == '/about/github') {
          _launchUrl(_githubUrl);
        } else if (route == '/about/twitter') {
          _launchUrl(_twitterUrl);
        }
      },
      icon: Icon(icon, color: Colors.white),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        textStyle: const TextStyle(fontSize: 16),
      ),
    );
  }
}
