import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:karasu_launcher/providers/locale_provider.dart';

class AboutHomePage extends ConsumerWidget {
  const AboutHomePage({super.key});

  final String _githubUrl = 'https://github.com/Karasu-Lab/Karasu-Launcher';
  final String _twitterUrl = 'https://twitter.com/Columba_Karasu';

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
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final languageCode = locale.languageCode;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Karasu Launcher',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                FlutterI18n.translate(
                  context,
                  'aboutPage.version',
                  translationParams: {'version': '1.0.0'},
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
                      FutureBuilder<String>(
                        future: _loadReadmeContent(languageCode),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const CircularProgressIndicator();
                          } else if (snapshot.hasError) {
                            return Text('エラー: ${snapshot.error}');
                          } else {
                            return Container(
                              constraints: const BoxConstraints(maxHeight: 300),
                              child: Markdown(
                                listItemCrossAxisAlignment:
                                    MarkdownListItemCrossAxisAlignment.start,
                                data: snapshot.data ?? '',
                                shrinkWrap: true,
                                styleSheet: MarkdownStyleSheet(
                                  p: const TextStyle(fontSize: 16),
                                  textAlign: WrapAlignment.center,
                                ),
                              ),
                            );
                          }
                        },
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
