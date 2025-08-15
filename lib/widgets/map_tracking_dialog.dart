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
  // Get the singleton instance of the MqttService.
  final MqttService _mqttService = MqttService();
  final double _resolution = 0.05; // As specified by user
  final String _mapBaseUrl = 'http://64.110.100.118:8001';

  Point? _currentPosition;
  Widget? _mapImageWidget; // To hold the cached image widget
  final List<Offset> _trailPoints = []; // To store the robot's path

  @override
  void initState() {
    super.initState();
    // Create the image widget once to prevent reloading on setState.
    _mapImageWidget = _buildMapImage();
    _connectMqtt();
  }

  /// Initializes the MQTT service, connects, and starts listening to the position stream.
  void _connectMqtt() {
    // Set up the listener for this dialog instance.
    _mqttService.positionStream.listen((Point point) {
      if (!mounted || widget.mapOrigin.length < 2) return;

      // Calculate the pixel offset for the new point using the Python formula.
      final robotX_m = point.x / 1000.0;
      final robotY_m = point.y / 1000.0;

      // map_y from python script corresponds to the 'left'/'dx' pixel coordinate
      final pixelX = (widget.mapOrigin[1] - robotX_m) / _resolution;
      // map_x from python script corresponds to the 'top'/'dy' pixel coordinate
      final pixelY = (widget.mapOrigin[0] - robotY_m) / _resolution;

      final newOffset = Offset(pixelX, pixelY);

      setState(() {
        _currentPosition = point;
        _trailPoints.add(newOffset);
      });
    });

    // Connect after setting up the listener to avoid race conditions.
    _mqttService.connectAndListen(widget.robotUuid);
  }

  @override
  void dispose() {
    // Unsubscribe from the topic when the dialog is closed.
    _mqttService.disconnect(widget.robotUuid);
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

                      // Robot Position and Trail Painter
                      if (_trailPoints.isNotEmpty)
                        CustomPaint(
                          size: Size.infinite,
                          painter: _RobotMarkerPainter(
                            trailPoints: _trailPoints,
                            currentPosition: _trailPoints.last,
                          ),
                        ),
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


/// A custom painter to draw the robot's marker and its trail on the map.
class _RobotMarkerPainter extends CustomPainter {
  final List<Offset> trailPoints;
  final Offset currentPosition;

  _RobotMarkerPainter({required this.trailPoints, required this.currentPosition});

  @override
  void paint(Canvas canvas, Size size) {
    // Paint for the trail
    final trailPaint = Paint()
      ..color = Colors.blue.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Draw the trail if there are enough points
    if (trailPoints.length > 1) {
      final path = Path();
      path.moveTo(trailPoints.first.dx, trailPoints.first.dy);
      for (int i = 1; i < trailPoints.length; i++) {
        path.lineTo(trailPoints[i].dx, trailPoints[i].dy);
      }
      canvas.drawPath(path, trailPaint);
    }

    // Paint for the current position marker (triangle)
    final markerPaint = Paint()
      ..color = Colors.green // Changed to green to match python example
      ..style = PaintingStyle.fill;

    final markerPath = Path();
    markerPath.moveTo(currentPosition.dx - 6, currentPosition.dy + 6); // Bottom-left
    markerPath.lineTo(currentPosition.dx + 6, currentPosition.dy + 6); // Bottom-right
    markerPath.lineTo(currentPosition.dx, currentPosition.dy - 6);     // Top-center
    markerPath.close();

    canvas.drawPath(markerPath, markerPaint);
  }

  @override
  bool shouldRepaint(covariant _RobotMarkerPainter oldDelegate) {
    // Repaint if the trail or the current position has changed.
    return oldDelegate.trailPoints != trailPoints || oldDelegate.currentPosition != currentPosition;
  }
}
