import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:async';

class WebSocketService {

  static final WebSocketService _instance = WebSocketService._internal();

  factory WebSocketService() {
    return _instance;
  }

  WebSocketService._internal() {
    connect();
  }

  WebSocketChannel? _channel;

  final String url =
      "wss://igloodepotserver-production.up.railway.app";

  final StreamController<dynamic> _controller =
      StreamController.broadcast();

  Stream<dynamic> get stream => _controller.stream;

  bool _connected = false;

  void connect() {

    if (_connected) return;

    print("connecting websocket...");

    try {

      _channel = WebSocketChannel.connect(Uri.parse(url));

      _connected = true;

      _channel!.stream.listen(

        (event) {

          var data = json.decode(event);

          _controller.add(data);

        },

        onDone: () {

          print("connection closed");

          _connected = false;

          reconnect();

        },

        onError: (error) {

          print("connection error");

          _connected = false;

          reconnect();

        },

      );

    } catch (e) {

      reconnect();

    }

  }

  void reconnect() {

    Future.delayed(const Duration(seconds: 3), () {

      connect();

    });

  }

  void sendMessage(Map<String, dynamic> message) {

    try {

      _channel?.sink.add(json.encode(message));

    } catch (e) {

      reconnect();

    }

  }

}