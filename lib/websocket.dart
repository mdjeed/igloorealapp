import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter/material.dart';

class WebSocketService {
  final WebSocketChannel _channel = WebSocketChannel.connect(
    Uri.parse('wss://igloodepotserver-production.up.railway.app'),
  );

  Stream<dynamic> get stream =>
      _channel.stream.map((event) => json.decode(event)).asBroadcastStream();

  void sendMessage(Map<String, dynamic> message) {
    _channel.sink.add(json.encode(message));
  }

  void close() {
    _channel.sink.close();
  }

  Future<bool> checkConnection() async {
    try {
      // محاولة إرسال طلب ping
      _channel.sink.add(json.encode({'action': 'ping'}));
      return true; // إذا نجح الاتصال
    } catch (e) {
      return false; // إذا فشل الاتصال
    }
  }
}
