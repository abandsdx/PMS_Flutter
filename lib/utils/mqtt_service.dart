import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

/// A simple data class to represent a 2D coordinate point.
class Point {
  final int x;
  final int y;
  Point(this.x, this.y);
}

/// A singleton service class to manage the connection to an MQTT broker,
/// handle subscriptions, and process incoming messages.
class MqttService {
  // --- Singleton Pattern ---
  static final MqttService _instance = MqttService._internal();
  factory MqttService() {
    return _instance;
  }
  MqttService._internal();
  // --- End Singleton ---

  MqttServerClient? _client;
  final String _server = 'log.labqtech.com';
  final int _port = 1883;
  final String _username = 'qoo';
  final String _password = 'qoowater';

  /// A stream controller that broadcasts the robot's position as a [Point].
  /// Widgets can listen to the [positionStream] to get live updates.
  final StreamController<Point> _positionStreamController = StreamController.broadcast();
  Stream<Point> get positionStream => _positionStreamController.stream;

  /// Connects to the MQTT broker if not already connected, and subscribes to the topic.
  ///
  /// [robotUuid] is the unique identifier for the robot, used to build the topic string.
  Future<void> connectAndListen(String robotUuid) async {
    // If client is already connected, just subscribe to the new topic.
    if (_client != null && _client?.connectionStatus?.state == MqttConnectionState.connected) {
      _subscribeToTopic(robotUuid);
      return;
    }

    // A unique client ID for the MQTT connection.
    final clientId = 'pms_flutter_client_${DateTime.now().millisecondsSinceEpoch}';
    _client = MqttServerClient.withPort(_server, clientId, _port);

    // Configure client settings
    _client!.logging(on: false);
    _client!.keepAlivePeriod = 60;
    _client!.onDisconnected = _onDisconnected;
    _client!.onConnected = () => _onConnected(robotUuid); // Pass uuid to subscribe on connect
    _client!.onSubscribed = _onSubscribed;

    // Create and set the connection message
    final connMessage = MqttConnectMessage()
      .withClientIdentifier(clientId)
      .startClean()
      .authenticateAs(_username, _password);
    _client!.connectionMessage = connMessage;

    try {
      print('Connecting to MQTT broker...');
      await _client!.connect();
    } catch (e) {
      print('MQTT Exception: $e');
      disconnect(robotUuid);
    }
  }

  void _onConnected(String robotUuid) {
    print('MQTT client connected.');
    // Set up listener only once on first connect
    _client!.updates!.listen((List<MqttReceivedMessage<MqttMessage>> c) {
        final MqttPublishMessage message = c[0].payload as MqttPublishMessage;
        final payload = MqttPublishPayload.bytesToStringAsString(message.payload.message);
        print("✅ MQTT Message Received: $payload");

        try {
          final jsonData = jsonDecode(payload);
          if (jsonData['Position'] != null) {
            final position = jsonData['Position'];
            if (position['x'] is int && position['y'] is int) {
              final point = Point(position['x'], position['y']);
              _positionStreamController.add(point);
              print("📢 Point added to stream: (${point.x}, ${point.y})");
            }
          }
        } catch (e) {
          print('Error parsing MQTT message: $e');
        }
      });

    _subscribeToTopic(robotUuid);
  }

  void _subscribeToTopic(String robotUuid) {
    if (_client?.connectionStatus?.state == MqttConnectionState.connected) {
      final topic = '/$robotUuid/from_rvc/SLAMPosition';
      print('Subscribing to topic: $topic');
      _client!.subscribe(topic, MqttQos.atMostOnce);
    }
  }

  void _onDisconnected() {
    print('MQTT client disconnected.');
  }

  void _onSubscribed(String topic) {
    print('Subscribed to topic: $topic');
  }

  /// Unsubscribes from a topic.
  void disconnect(String robotUuid) {
    final topic = '/$robotUuid/from_rvc/SLAMPosition';
    print('Unsubscribing from topic: $topic');
    _client?.unsubscribe(topic);
  }

  /// Disposes the client and closes the stream. Should be called when the app closes.
  void dispose() {
    _client?.disconnect();
    _positionStreamController.close();
  }
}
