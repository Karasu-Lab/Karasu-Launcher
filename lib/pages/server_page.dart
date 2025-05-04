import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

class ServerPage extends StatelessWidget {
  const ServerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            FlutterI18n.translate(context, 'serverPage.title'),
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              // サーバー起動などの操作
            },
            child: Text(
              FlutterI18n.translate(context, 'serverPage.startServer'),
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              // サーバー設定などの操作
            },
            child: Text(
              FlutterI18n.translate(context, 'serverPage.serverSettings'),
            ),
          ),
        ],
      ),
    );
  }
}
