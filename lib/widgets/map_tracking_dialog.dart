import 'dart:convert';
import 'package:flutter/material.dart';
import '../utils/mqtt_service.dart';

/// A dialog that displays a map and tracks a robot's position in real-time via MQTT.
class MapTrackingDialog extends StatefulWidget {
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
  final MqttService _mqttService = MqttService();
  final double _resolution = 0.05; // As specified by user
  final String _mapBaseUrl = 'http://64.110.100.118:8001';

  Point? _currentPosition;
  Widget? _mapImageWidget; // To hold the cached image widget

  @override
  void initState() {
    super.initState();
    // Create the image widget once to prevent reloading on setState.
    _mapImageWidget = _buildMapImage();
    _connectMqtt();
  }

  /// Initializes the MQTT service, connects, and starts listening to the position stream.
  void _connectMqtt() async {
    await _mqttService.connect(widget.robotUuid);
    _mqttService.positionStream.listen((Point point) {
      if (mounted) {
        setState(() {
          _currentPosition = point;
        });
      }
    });
  }

  @override
  void dispose() {
    _mqttService.disconnect();
    super.dispose();
  }

  Widget _buildMapImage() {
    // Sanitize the path by removing spaces and the "outputs/" prefix.
    String finalPath = widget.mapImagePartialPath.replaceAll(' ', '');
    if (finalPath.startsWith('outputs/')) {
      finalPath = finalPath.substring('outputs/'.length);
    }
    final fullMapUrl = '$_mapBaseUrl/$finalPath';

    return Image.network(
      fullMapUrl,
      fit: BoxFit.contain,
      // Loading and error builders for better UX
      loadingBuilder: (context, child, progress) {
        return progress == null ? child : const Center(child: CircularProgressIndicator());
      },
      errorBuilder: (context, error, stackTrace) {
        // This is the version with the logging fix
        print("🚨 Failed to load map image.");
        print("Error: $error");
        print("StackTrace: $stackTrace");
        return const Center(child: Text("無法載入地圖"));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      // Use a larger dialog size
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      title: const Text('即時位置追蹤'),
      contentPadding: const EdgeInsets.all(8),
      content: SizedBox(
        width: MediaQuery.of(context).size.width, // Occupy full width
        child: Column(
          mainAxisSize: MainAxisSize.min, // Try to be as small as possible vertically
          children: [
            // --- Map View ---
            Expanded(
              child: Container(
                decoration: BoxDecoration(border: Border.all(color: Colors.blueGrey)),
                child: InteractiveViewer( // Allow panning and zooming
                  maxScale: 5.0,
                  child: Stack(
                    children: [
                      // Map Image (using the cached widget)
                      if (_mapImageWidget != null) _mapImageWidget!,

                      // Robot Position Painter
                      if (_currentPosition != null && widget.mapOrigin.length >= 2)
                        Builder(builder: (context) {
                          // Calculate coordinates using the Java formula provided by the user.
                          final robotX_m = _currentPosition!.x / 1000.0;
                          final robotY_m = _currentPosition!.y / 1000.0;

                          // NOTE: The Java formula seems to have a different convention.
                          // mapRobotX uses Y, mapRobotY uses X.
                          final pixelX = widget.mapOrigin[0] - (robotY_m / _resolution);
                          final pixelY = widget.mapOrigin[1] - (robotX_m / _resolution);

                          return CustomPaint(
                            // The painter will paint across the entire stack.
                            size: Size.infinite,
                            painter: _RobotMarkerPainter(
                              position: Offset(pixelX, pixelY),
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // --- API Response ---
            ExpansionTile(
              title: const Text('顯示/隱藏 API 回應'),
              tilePadding: EdgeInsets.zero,
              children: [
                Container(
                  width: double.infinity,
                  height: 100, // Give it a max height
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(widget.responseText),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('關閉'),
        ),
      ],
    );
  }
}


/// A custom painter to draw the robot's marker on the map.
///
/// It draws a small, upward-pointing triangle at the robot's calculated position.
class _RobotMarkerPainter extends CustomPainter {
  final Offset position;

  _RobotMarkerPainter({required this.position});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(position.dx - 6, position.dy + 6); // Bottom-left
    path.lineTo(position.dx + 6, position.dy + 6); // Bottom-right
    path.lineTo(position.dx, position.dy - 6);     // Top-center
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _RobotMarkerPainter oldDelegate) {
    // Repaint only if the position has changed.
    return oldDelegate.position != position;
  }
}
