import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:karasu_launcher/router/routes.dart';

const methodChannel = MethodChannel('com.karasu256.karasu_launcher/window');

void main() {
  runApp(ProviderScope(child: const MyApp()));

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

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appRouter = ref.watch(routerProvider);
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
    );
  }
}
