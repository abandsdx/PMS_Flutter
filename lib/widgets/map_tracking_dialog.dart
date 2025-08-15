import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

// Helper class for fixed points, as provided in the user's example.
class _LabelPoint {
  final String label;
  final Offset offset;
  _LabelPoint({required this.label, required this.offset});
}

// Custom painter from the user's example to draw the trail and marker.
class _TrackPainter extends CustomPainter {
  final List<Offset> trackPx;
  final Offset? currentPx;
  _TrackPainter({required this.trackPx, required this.currentPx});

  @override
  void paint(Canvas canvas, Size size) {
    // Draw the trail (blue line)
    if (trackPx.length > 1) {
      final paintLine = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xFF1565C0); // Blue
      final path = Path()..moveTo(trackPx.first.dx, trackPx.first.dy);
      for (int i = 1; i < trackPx.length; i++) {
        path.lineTo(trackPx[i].dx, trackPx[i].dy);
      }
      canvas.drawPath(path, paintLine);
    }

    // Draw the current position (green circle with halo)
    if (currentPx != null) {
      final paintDot = Paint()
        ..style = PaintingStyle.fill
        ..color = const Color(0xFF2E7D32); // Green
      canvas.drawCircle(currentPx!, 5, paintDot);
      final paintHalo = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0x802E7D32); // Transparent green
      canvas.drawCircle(currentPx!, 9, paintHalo);
    }
  }

  @override
  bool shouldRepaint(covariant _TrackPainter oldDelegate) {
    return oldDelegate.trackPx != trackPx || oldDelegate.currentPx != currentPx;
  }
}

/// A dialog that displays a map and tracks a robot's position in real-time via MQTT.
/// This version is heavily modified to match the user's self-contained example code.
class MapTrackingDialog extends StatefulWidget {
  // These parameters from the original dialog are now unused,
  // as the logic is hardcoded to match the user's example.
  final String mapImagePartialPath;
  final List<double> mapOrigin;
  final String robotUuid;
  final String responseText;

  const MapTrackingDialog({
    Key? key,
    required this.mapImagePartialPath,
    required this.mapOrigin,
    required this.robotUuid,
    required this.responseText,
  }) : super(key: key);

  @override
  _MapTrackingDialogState createState() => _MapTrackingDialogState();
}

class _MapTrackingDialogState extends State<MapTrackingDialog> {
  // --- All logic and variables below are taken directly from the user's example ---

  // Map and coordinate parameters
  final String mapAssetPath = 'assets/map.jpg';
  final double resolution = 0.05; // meter / pixel
  final List<double> origin = [13.00, 13.20]; // World coordinate top-left (ox, oy)

  // Fixed points (world coordinates)
  final Map<String, List<double>> points = {
    "EL0101": [0.17, -0.18], "EL0102": [0.18, -1.18], "MA01": [6.22, -9.53],
    "R0101": [-1.29, -7.71], "R0102": [-1.29, -5.44], "R0103": [0.1, -6.09],
    "R0104": [-8.41, 6.96], "SL0101": [0.19, -2.94], "SL0102": [0.15, -2.44],
    "SL0103": [-8.04, 7.19], "VM0101": [-0.81, 4.08], "WL0101": [5.24, -9.66],
    "XL0101": [5.53, -9.99],
  };

  // Image properties
  ui.Image? _mapImage;
  int get imgW => _mapImage?.width ?? 0;
  int get imgH => _mapImage?.height ?? 0;

  // MQTT connection details
  final String broker = 'log.labqtech.com';
  final int port = 1883;
  final String username = 'qoo';
  final String password = 'qoowater';
  final String topic = '/2b97/from_rvc/SLAMPosition'; // Hardcoded topic

  MqttServerClient? _client;
  StreamSubscription? _subscription;

  // Dynamic data for drawing
  final List<Offset> _trackPx = [];
  Offset? _currentPx;
  List<_LabelPoint> _fixedPointsPx = [];

  // UI Status
  String _status = 'Initializing...';

  @override
  void initState() {
    super.initState();
    _loadImage().then((_) => _connectMqtt());
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _client?.disconnect();
    super.dispose();
  }

  // Load image from assets and calculate fixed point positions
  Future<void> _loadImage() async {
    try {
      final data = await rootBundle.load(mapAssetPath);
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      final image = frame.image;

      final pointsPx = <_LabelPoint>[];
      points.forEach((label, coords) {
        final wx = coords[0];
        final wy = coords[1];
        final px = worldToMapPx(wx, wy);
        if (px.dx >= 0 && px.dy >= 0 && px.dx <= image.width && px.dy <= image.height) {
          pointsPx.add(_LabelPoint(label: label, offset: px));
        }
      });

      setState(() {
        _mapImage = image;
        _fixedPointsPx = pointsPx;
        _status = 'Map loaded (${image.width}x${image.height})';
      });
    } catch (e) {
      setState(() {
        _status = 'Error loading map: $e';
      });
    }
  }

  // Convert world coordinates to map pixel coordinates
  Offset worldToMapPx(double wx, double wy) {
    final mapX = (origin[0] - wy) / resolution;
    final mapY = (origin[1] - wx) / resolution;
    return Offset(mapX, mapY);
  }

  // Connect to MQTT and subscribe to the topic
  Future<void> _connectMqtt() async {
    if (_mapImage == null) {
      if (!_status.contains('Error')) {
        setState(() => _status = 'Waiting for map...');
      }
      return;
    }

    final clientId = 'flutter_map_dialog_${DateTime.now().millisecondsSinceEpoch}';
    _client = MqttServerClient.withPort(broker, clientId, port);
    _client!.logging(on: false);
    _client!.keepAlivePeriod = 30;
    _client!.onConnected = () => setState(() => _status = '✅ Connected to MQTT');
    _client!.onDisconnected = () => setState(() => _status = '⚠️ Disconnected');
    _client!.onSubscribed = (t) => setState(() => _status = '📡 Subscribed: $t');
    _client!.connectionMessage = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .startClean()
        .authenticateAs(username, password); // Added authentication

    try {
      setState(() => _status = 'Connecting...');
      await _client!.connect();
    } catch (e) {
      setState(() => _status = '❌ Connection failed: $e');
      _client!.disconnect();
      return;
    }

    if (_client!.connectionStatus?.state == MqttConnectionState.connected) {
      _client!.subscribe(topic, MqttQos.atMostOnce);
      _subscription = _client!.updates!.listen((events) {
        for (final evt in events) {
          final recMess = evt.payload as MqttPublishMessage;
          final payload = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);

          try {
            final map = json.decode(payload) as Map<String, dynamic>;
            final pos = map['Position'] as Map<String, dynamic>?;

            if (pos == null) continue;
            final xMm = (pos['x'] as num?)?.toDouble();
            final yMm = (pos['y'] as num?)?.toDouble();
            if (xMm == null || yMm == null) continue;

            final wx = xMm / 1000.0;
            final wy = yMm / 1000.0;
            final px = worldToMapPx(wx, wy);

            if (px.dx >= 0 && px.dy >= 0 && px.dx < imgW && px.dy < imgH) {
              setState(() {
                _currentPx = px;
                _trackPx.add(px);
              });
            }
          } catch (e) {
            // Silently ignore JSON parsing errors for single messages
          }
        }
      });
    } else {
      setState(() => _status = '❌ Connection not established: ${_client!.connectionStatus}');
      _client!.disconnect();
    }
  }

  @override
  Widget build(BuildContext context) {
    final mapImg = _mapImage;

    // Build the main content widget for the dialog body
    Widget mapContent;
    if (mapImg == null) {
      mapContent = Center(
        child: _status.contains('Error')
            ? Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(_status, textAlign: TextAlign.center),
              )
            : const CircularProgressIndicator(),
      );
    } else {
      mapContent = InteractiveViewer(
        minScale: 0.2,
        maxScale: 6.0,
        child: SizedBox(
          width: mapImg.width.toDouble(),
          height: mapImg.height.toDouble(),
          child: Stack(
            children: [
              // 1. Base map image
              RawImage(image: mapImg),
              // 2. Trail and current position painter
              CustomPaint(
                painter: _TrackPainter(trackPx: _trackPx, currentPx: _currentPx),
                size: Size(mapImg.width.toDouble(), mapImg.height.toDouble()),
              ),
              // 3. Fixed points and labels
              ..._fixedPointsPx.map((lp) {
                return Positioned(
                  left: lp.offset.dx,
                  top: lp.offset.dy,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 6, height: 6,
                        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      ),
                      const SizedBox(height: 2),
                      Transform.translate(
                        offset: const Offset(5, -12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            lp.label,
                            style: const TextStyle(fontSize: 10, color: Colors.red),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      );
    }

    // Return the AlertDialog with the constructed content
    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Real-time Position Tracking'),
          Text(_status, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10)),
        ],
      ),
      contentPadding: const EdgeInsets.all(4),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.7,
        child: mapContent,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
