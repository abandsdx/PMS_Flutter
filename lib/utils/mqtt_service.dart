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

/// A service class to manage the connection to an MQTT broker, handle subscriptions,
/// and process incoming messages.
class MqttService {
  late MqttServerClient _client;
  final String _server = 'log.labqtech.com';
  final int _port = 1883;
  final String _username = 'qoo';
  final String _password = 'qoowater';

  /// A stream controller that broadcasts the robot's position as a [Point].
  /// Widgets can listen to the [positionStream] to get live updates.
  final StreamController<Point> _positionStreamController = StreamController.broadcast();
  Stream<Point> get positionStream => _positionStreamController.stream;

  /// Connects to the MQTT broker and subscribes to the position topic for the given robot.
  ///
  /// [robotUuid] is the unique identifier for the robot, used to build the topic string.
  Future<void> connect(String robotUuid) async {
    // A unique client ID for the MQTT connection.
    final clientId = 'pms_flutter_client_${DateTime.now().millisecondsSinceEpoch}';
    _client = MqttServerClient.withPort(_server, clientId, _port);

    // Configure client settings
    _client.logging(on: false);
    _client.keepAlivePeriod = 60;
    _client.onDisconnected = _onDisconnected;
    _client.onConnected = _onConnected;
    _client.onSubscribed = _onSubscribed;

    // Create and set the connection message
    final connMessage = MqttConnectMessage()
      .withClientIdentifier(clientId)
      .startClean()
      .authenticateAs(_username, _password);
    _client.connectionMessage = connMessage;

    try {
      print('Connecting to MQTT broker...');
      await _client.connect();
    } catch (e) {
      print('MQTT Exception: $e');
      _client.disconnect();
      return;
    }

    // Check connection state and subscribe to the topic
    if (_client.connectionStatus!.state == MqttConnectionState.connected) {
      final topic = '/$robotUuid/from_rvc/SLAMPosition';
      _client.subscribe(topic, MqttQos.atMostOnce);

      // Listen for updates and process incoming messages
      _client.updates?.listen((List<MqttReceivedMessage<MqttMessage>> c) {
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
            }
          }
        } catch (e) {
          print('Error parsing MQTT message: $e');
        }
      });
    }
  }

  void _onConnected() {
    print('MQTT client connected.');
  }

  void _onDisconnected() {
    print('MQTT client disconnected.');
  }

  void _onSubscribed(String topic) {
    print('Subscribed to topic: $topic');
  }

  /// Disconnects from the MQTT broker and closes the stream controller.
  void disconnect() {
    print('Disconnecting MQTT client...');
    _client.disconnect();
    _positionStreamController.close();
  }
}
