import 'package:flutter/material.dart';
import 'package:thunder/thunder.dart';

import 'api_client.dart';

void main() {
  final mw = Thunder.middleware;

  final apiClient = ApiClient(
    uri: Uri.parse('https://jsonplaceholder.typicode.com'),
    middlewares: <ApiClientMiddleware>[
      mw,
    ],
  );

  apiClient.get("/posts");

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _mainDio = ApiClient(
    uri: Uri(),
    middlewares: <ApiClientMiddleware>[
      Thunder.middleware,
    ],
  );
  final _httpDio = ApiClient(
      uri: Uri.parse('https://httpbin.org'),
      middlewares: <ApiClientMiddleware>[Thunder.middleware]);

  @override
  Widget build(BuildContext context) => MaterialApp(
        builder: (_, child) => Thunder(
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

  final ApiClient httpDio;
  final ApiClient mainDio;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static const Color _greenDark = Color(0xFF49cc90);

  void _runDioRequests() async {
    final ApiClient jsonPlaceholderDio = ApiClient(
      uri: Uri.parse('https://jsonplaceholder.typicode.com'),
      middlewares: <ApiClientMiddleware>[
        Thunder.middleware,
      ],
    );

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

    widget.httpDio.get("/redirect-to?url=https%3A%2F%2Fhttpbin.org");
    widget.httpDio.delete(
      "/status/500?dumb=data&Authorization=Bearer ",
      body: {"data": 0, "ok": true},
      headers: {"HEADER": "TEST"},
    );
    widget.httpDio.delete("/status/400");
    widget.httpDio.delete("/status/300");
    widget.httpDio.delete("/status/200");
    widget.httpDio.delete("/status/100");

    jsonPlaceholderDio.post("/posts", body: body);
    jsonPlaceholderDio.get(
      "/posts?test=1",
    );
    jsonPlaceholderDio.put("/posts/1", body: body);
    jsonPlaceholderDio.put("/posts/1", body: body);
    jsonPlaceholderDio.delete("/posts/1");
    jsonPlaceholderDio.get("/test/test");
    jsonPlaceholderDio.get("/photos");

    widget.mainDio.get(
      "https://icons.iconarchive.com/icons/paomedia/small-n-flat/256/sign-info-icon.png",
    );
    widget.mainDio.get(
      "https://images.unsplash.com/photo-1542736705-53f0131d1e98?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&w=1000&q=80",
    );
    widget.mainDio.get(
      "https://findicons.com/files/icons/1322/world_of_aqua_5/128/bluetooth.png",
    );
    widget.mainDio.get(
      "https://upload.wikimedia.org/wikipedia/commons/4/4e/Pleiades_large.jpg",
    );
    widget.mainDio.get(
      "http://techslides.com/demos/sample-videos/small.mp4",
    );
    widget.mainDio.get(
      "https://www.cse.wustl.edu/~jain/cis677-97/ftp/e_3dlc2.pdf",
    );
    widget.mainDio.get(
      "http://dummy.restapiexample.com/api/v1/employees?test=1",
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
