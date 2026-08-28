import 'package:flutter/material.dart';
import 'package:thunder/thunder.dart';
import 'package:thunder_example/ws.dart';

void main() {
  final _ = Thunder.middleware;

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) => MaterialApp(
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        themeMode: ThemeMode.system,
        home: MyHomePage(),
        builder: (_, child) => Thunder(
          color: Colors.blueGrey,
          child: child ?? SizedBox.shrink(),
        ),
      );
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static const Color _greenDark = Color(0xFF49cc90);

  void _openWebSocketExample() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const WebSocketExamplePage()),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          backgroundColor: _greenDark,
          title: Text(
            'Thunder interceptor example',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Press the button in the bottom to run the requests',
                  style: TextStyle(
                    color: Color(0xFF3b4151),
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _openWebSocketExample,
                  style: FilledButton.styleFrom(
                    backgroundColor: Color(0xFF61affe),
                  ),
                  icon: const Icon(Icons.cable),
                  label: const Text('WebSocket Example'),
                ),
              ],
            ),
          ),
        ),
      );
}
