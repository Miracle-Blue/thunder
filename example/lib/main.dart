import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:thunder/thunder.dart';

void main() {
  final dio = Thunder.addDio(
      Dio(BaseOptions(baseUrl: 'https://jsonplaceholder.typicode.com')));

  dio.get<void>("/posts");

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final Dio _mainDio = Dio();
  final Dio _httpDio =
      Thunder.addDio(Dio(BaseOptions(baseUrl: 'https://httpbin.org')));

  @override
  Widget build(BuildContext context) => MaterialApp(
        builder: (_, child) => Thunder(
          dio: [
            _httpDio,
            _mainDio,
            _httpDio,
          ],
          child: child ?? SizedBox.shrink(),
        ),
        home: MyHomePage(
          httpDio: _httpDio,
          mainDio: _mainDio,
        ),
      );
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.httpDio, required this.mainDio});

  final Dio httpDio;
  final Dio mainDio;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static const Color _greenDark = Color(0xFF49cc90);

  void _runDioRequests() async {
    final Dio jsonPlaceholderDio = Dio(
      BaseOptions(baseUrl: 'https://jsonplaceholder.typicode.com'),
    );

    Thunder.addDio(jsonPlaceholderDio);

    Map<String, Object?> body = <String, Object?>{
      "title": "foo",
      "body": "bar",
      "userId": "1",
      "isFlutterCool": true,
      "socials": null,
      "hobbies": ["Music", "Filmmaking"],
      "score": 7.6,
      "id": 24,
      "name": "John Doe",
      "isJson": true,
    };

    widget.httpDio.get<void>("/redirect-to?url=https%3A%2F%2Fhttpbin.org");
    widget.httpDio.delete<void>(
      "/status/500",
      queryParameters: {"dumb": "data", "Authorization": "Bearer "},
      data: {"data": 0, "ok": true},
      options: Options(headers: {"HEADER": "TEST"}),
    );
    widget.httpDio.delete<void>("/status/400");
    widget.httpDio.delete<void>("/status/300");
    widget.httpDio.delete<void>("/status/200");
    widget.httpDio.delete<void>("/status/100");

    jsonPlaceholderDio.post<void>("/posts", data: body);
    jsonPlaceholderDio.get<void>(
      "/posts",
      queryParameters: <String, Object?>{"test": 1},
    );
    jsonPlaceholderDio.put<void>("/posts/1", data: body);
    jsonPlaceholderDio.put<void>("/posts/1", data: body);
    jsonPlaceholderDio.delete<void>("/posts/1");
    jsonPlaceholderDio.get<void>("/test/test");
    jsonPlaceholderDio.get<void>("/photos");

    widget.mainDio.get<void>(
      "https://icons.iconarchive.com/icons/paomedia/small-n-flat/256/sign-info-icon.png",
    );
    widget.mainDio.get<void>(
      "https://images.unsplash.com/photo-1542736705-53f0131d1e98?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&w=1000&q=80",
    );
    widget.mainDio.get<void>(
      "https://findicons.com/files/icons/1322/world_of_aqua_5/128/bluetooth.png",
    );
    widget.mainDio.get<void>(
      "https://upload.wikimedia.org/wikipedia/commons/4/4e/Pleiades_large.jpg",
    );
    widget.mainDio.get<void>(
      "http://techslides.com/demos/sample-videos/small.mp4",
    );
    widget.mainDio.get<void>(
      "https://www.cse.wustl.edu/~jain/cis677-97/ftp/e_3dlc2.pdf",
    );
    widget.mainDio.get<void>(
      "http://dummy.restapiexample.com/api/v1/employees",
      queryParameters: <String, Object?>{"test": 1},
    );

    log(Thunder.getDiosHash);
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
              FilledButton(
                onPressed: _runDioRequests,
                style: FilledButton.styleFrom(backgroundColor: _greenDark),
                child: const Text('Run requests'),
              ),
            ],
          ),
        ),
      );
}
