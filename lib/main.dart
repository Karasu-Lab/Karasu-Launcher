import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:karasu_launcher/router/routes.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_i18n/loaders/decoders/json_decode_strategy.dart';
import 'package:karasu_launcher/providers/locale_provider.dart';

const methodChannel = MethodChannel('com.karasu256.karasu_launcher/window');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  runApp(ProviderScope(child: MyApp()));

  doWhenWindowReady(() {
    final win = appWindow;
    win.minSize = const Size(800, 600);
    win.size = const Size(1280, 720);
    win.alignment = Alignment.center;
    win.title = "Karasu Launcher";
    win.show();

    methodChannel.invokeMethod('updateWindowTitle', {
      "title": "Karasu Launcher",
    });
  });
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  Widget build(BuildContext context) {
    final appRouter = ref.watch(routerProvider);
    final currentLocale = ref.watch(localeProvider);
    
    return MaterialApp.router(
      title: 'Karasu Launcher',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
      ),
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,
      locale: currentLocale,
      localizationsDelegates: [
        FlutterI18nDelegate(
          translationLoader: FileTranslationLoader(
            decodeStrategies: [JsonDecodeStrategy()],
            fallbackFile: 'en',
            basePath: 'assets/flutter_i18n',
          ),
          missingTranslationHandler: (key, locale) {
            debugPrint("Missing key: $key, locale: $locale");
          },
        ),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: supportedLocales,
    );
  }
}
