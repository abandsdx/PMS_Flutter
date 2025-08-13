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

  @override
  void initState() {
    super.initState();
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

  @override
  Widget build(BuildContext context) {
    // Sanitize the path by removing spaces, which can cause 404 errors.
    final sanitizedPath = widget.mapImagePartialPath.replaceAll(' ', '');
    final fullMapUrl = '$_mapBaseUrl/$sanitizedPath';
    print("🗺️ Loading map from URL: $fullMapUrl"); // Log the URL

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
                      // Map Image
                      Image.network(
                        fullMapUrl,
                        fit: BoxFit.contain,
                        // Loading and error builders for better UX
                        loadingBuilder: (context, child, progress) {
                          return progress == null ? child : const Center(child: CircularProgressIndicator());
                        },
                        errorBuilder: (context, error, stackTrace) {
                          print("🚨 Failed to load map image.");
                          print("Error: $error");
                          print("StackTrace: $stackTrace");
                          return const Center(child: Text("無法載入地圖"));
                        },
                      ),
                      // Robot Position Painter
                      if (_currentPosition != null)
                        LayoutBuilder(builder: (context, constraints) {
                          // Guard against incomplete mapOrigin data.
                          if (widget.mapOrigin.length < 2) {
                            return const SizedBox.shrink(); // Don't draw if data is invalid.
                          }

                          // Convert SLAM coordinates (mm) to world coordinates (m)
                          final wx = _currentPosition!.x / 1000.0;
                          final wy = _currentPosition!.y / 1000.0;

                          // Convert world coordinates to pixel coordinates on the map
                          // Using the formula from the user's Python script.
                          final mapX = (widget.mapOrigin[0] - wy) / _resolution;
                          final mapY = (widget.mapOrigin[1] - wx) / _resolution;

                          return Positioned(
                            left: mapY,
                            top: mapX,
                            child: Tooltip(
                              message: '(${_currentPosition!.x}, ${_currentPosition!.y})',
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.8),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                              ),
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
