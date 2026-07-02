// ---------------------------------------------------------------------------
// WebSocket Example Page
//
// Demonstrates Thunder's WebSocket support: the page talks to an echo server
// through a reconnecting SocketClient created via Thunder.socketClient, so
// every frame, state change and error shows up in Thunder's Socket tab.
// ---------------------------------------------------------------------------

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:thunder/thunder.dart';

class WebSocketExamplePage extends StatefulWidget {
  const WebSocketExamplePage({super.key});

  @override
  State<WebSocketExamplePage> createState() => _WebSocketExamplePageState();
}

class _WebSocketExamplePageState extends State<WebSocketExamplePage> {
  static const _wsUrl = 'wss://echo.websocket.org';

  SocketClient? _client;
  StreamSubscription<Object?>? _messagesSub;
  StreamSubscription<SocketState>? _statesSub;
  SocketState _state = const SocketDisconnected();

  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _messages = <_WsMessage>[];

  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
  }

  // ------ lifecycle ------

  @override
  void dispose() {
    final client = _client;
    _client = null;
    unawaited(_statesSub?.cancel());
    _statesSub = null;
    unawaited(_messagesSub?.cancel());
    _messagesSub = null;
    if (client != null) unawaited(client.close());
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ------ connection ------

  Future<void> _connect() async {
    if (_client != null) return;

    // Thunder.socketClient wires the client into the Socket tab: one call
    // per connection creates one session row.
    final client = Thunder.socketClient(
      uri: Uri.parse(_wsUrl),
      label: 'Echo demo',
      reconnectInterval: const Duration(seconds: 3),
      connectTimeout: const Duration(seconds: 10),
    );
    _client = client;

    _statesSub = client.states.listen(_onSocketState);
    _messagesSub = client.messages.listen((message) {
      if (!mounted) return;
      _addMessage(
        _WsMessage(
          text: message?.toString() ?? '',
          type: _WsMessageType.received,
          timestamp: DateTime.now(),
        ),
      );
    });

    // connect() never throws on connection failure: the client retries on
    // its own and reports progress through the states stream.
    await client.connect();
  }

  Future<void> _disconnect() async {
    final client = _client;
    if (client == null) return;

    // close() is terminal — a fresh client is created per connection,
    // which also creates a fresh session row in Thunder's Socket tab.
    _client = null;
    await client.close();

    await _statesSub?.cancel();
    _statesSub = null;
    await _messagesSub?.cancel();
    _messagesSub = null;

    if (mounted) {
      setState(() => _state = const SocketDisconnected());
    }
  }

  void _onSocketState(SocketState state) {
    if (!mounted) return;

    setState(() => _state = state);

    switch (state) {
      case SocketConnecting():
        _addSystemMessage('Connecting to $_wsUrl…');
      case SocketConnected():
        _addSystemMessage('Connected to $_wsUrl');
      case SocketReconnecting(:final attempt):
        _addSystemMessage('Reconnecting (attempt $attempt)…');
      case SocketDisconnected(
          :final closeCode,
          :final closeReason,
          :final error,
        ):
        final details = <String>[
          if (closeCode != null) 'code: $closeCode',
          if (closeReason != null && closeReason.isNotEmpty)
            'reason: $closeReason',
          if (error != null) 'error: $error',
        ];
        _addSystemMessage(
          details.isEmpty
              ? 'Disconnected'
              : 'Disconnected (${details.join(', ')})',
        );
    }
  }

  // ------ sending ------

  void _sendMessage() {
    final client = _client;
    final text = _messageController.text.trim();
    if (text.isEmpty || client == null || client.state is! SocketConnected) {
      return;
    }

    client.send(text);
    _messageController.clear();
    _addMessage(
      _WsMessage(
        text: text,
        type: _WsMessageType.sent,
        timestamp: DateTime.now(),
      ),
    );
  }

  void _sendJsonSample() {
    final client = _client;
    if (client == null || client.state is! SocketConnected) return;

    final payload = jsonEncode({
      'type': 'greeting',
      'message': 'Hello from Thunder example!',
      'timestamp': DateTime.now().toIso8601String(),
    });
    client.send(payload);
    _addMessage(
      _WsMessage(
        text: payload,
        type: _WsMessageType.sent,
        timestamp: DateTime.now(),
      ),
    );
  }

  // ------ helpers ------

  void _addMessage(_WsMessage msg) {
    setState(() => _messages.add(msg));
    _scrollToBottom();
  }

  void _addSystemMessage(String text) {
    _addMessage(
      _WsMessage(
        text: text,
        type: _WsMessageType.system,
        timestamp: DateTime.now(),
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _clearMessages() => setState(() => _messages.clear());

  // ------ UI ------

  bool get _isConnected => _state is SocketConnected;

  String get _connectionLabel => switch (_state) {
        SocketConnecting() => 'Connecting…',
        SocketConnected() => 'Connected',
        SocketReconnecting(:final attempt) =>
          'Reconnecting (attempt $attempt)…',
        SocketDisconnected() => 'Disconnected',
      };

  Color get _connectionColor => switch (_state) {
        SocketConnected() => Colors.green,
        SocketConnecting() || SocketReconnecting() => Colors.orange,
        SocketDisconnected() => Colors.red,
      };

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF61affe),
        foregroundColor: Colors.white,
        title: const Text(
          'WebSocket Example',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            onPressed: _clearMessages,
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Clear messages',
          ),
        ],
      ),
      body: InkWell(
        onTap: () {
          if (_focusNode.hasFocus) {
            _focusNode.unfocus();
          }
        },
        child: Column(
          children: [
            // ---- connection bar ----
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: colorScheme.surfaceContainerHighest,
              child: Row(
                children: [
                  Icon(Icons.circle, size: 12, color: _connectionColor),
                  const SizedBox(width: 8),
                  Text(
                    _connectionLabel,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const Spacer(),
                  if (_client == null)
                    FilledButton(
                      onPressed: _connect,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF49cc90),
                      ),
                      child: const Text('Connect'),
                    )
                  else
                    OutlinedButton(
                      onPressed: _disconnect,
                      child: const Text('Disconnect'),
                    ),
                ],
              ),
            ),
            const Divider(height: 1),

            // ---- messages list ----
            Expanded(
              child: _messages.isEmpty
                  ? Center(
                      child: Text(
                        _isConnected
                            ? 'Send a message to the echo server'
                            : 'Tap Connect to start',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      itemCount: _messages.length,
                      itemBuilder: (_, i) =>
                          _MessageBubble(message: _messages[i]),
                    ),
            ),

            // ---- input bar ----
            SafeArea(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  border: Border(
                    top: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                child: Row(
                  children: [
                    // Quick JSON button
                    IconButton(
                      onPressed: _isConnected ? _sendJsonSample : null,
                      icon: const Icon(Icons.data_object),
                      tooltip: 'Send sample JSON',
                    ),
                    const SizedBox(width: 4),
                    // Text input
                    Expanded(
                      child: TextField(
                        focusNode: _focusNode,
                        controller: _messageController,
                        enabled: _isConnected,
                        decoration: InputDecoration(
                          hintText: 'Type a message…',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          isDense: true,
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Send button
                    IconButton.filled(
                      onPressed: _isConnected ? _sendMessage : null,
                      icon: const Icon(Icons.send),
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFF61affe),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Message model & bubble widget
// ---------------------------------------------------------------------------

enum _WsMessageType { sent, received, system }

class _WsMessage {
  const _WsMessage({
    required this.text,
    required this.type,
    required this.timestamp,
  });

  final String text;
  final _WsMessageType type;
  final DateTime timestamp;
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final _WsMessage message;

  @override
  Widget build(BuildContext context) {
    if (message.type == _WsMessageType.system) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Center(
          child: Text(
            message.text,
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    final isSent = message.type == _WsMessageType.sent;
    final time = '${message.timestamp.hour.toString().padLeft(2, '0')}:'
        '${message.timestamp.minute.toString().padLeft(2, '0')}:'
        '${message.timestamp.second.toString().padLeft(2, '0')}';

    return Align(
      alignment: isSent ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isSent ? const Color(0xFF61affe) : const Color(0xFFe8e8e8),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isSent ? 16 : 4),
            bottomRight: Radius.circular(isSent ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment:
              isSent ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: TextStyle(
                color: isSent ? Colors.white : Colors.black87,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${isSent ? "Sent" : "Received"} · $time',
              style: TextStyle(
                color: isSent ? Colors.white70 : Colors.grey.shade500,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
