import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:pms_external_service_flutter/config.dart';
import 'package:pms_external_service_flutter/models/field_data.dart';
import '../utils/mqtt_service.dart';

// Helper class for rendering fixed points with labels
class _LabelPoint {
  final String label;
  final Offset offset;
  _LabelPoint({required this.label, required this.offset});
}

/// A dialog that displays a map and tracks a robot's position in real-time via MQTT.
class MapTrackingDialog extends StatefulWidget {
  final String mapImagePartialPath;
  final String robotUuid;
  final String responseText;

  // The mapOrigin is now fetched dynamically, so this parameter is no longer used.
  final List<double> mapOrigin;

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
  final double _resolution = 0.05;
  final String _mapBaseUrl = 'http://152.69.194.121:8000';

  // State variables for dynamic data
  List<double> _dynamicMapOrigin = [];
  Widget? _mapImageWidget;
  String _status = 'Initializing...';

  // Data for drawing
  final List<Offset> _trailPoints = [];
  List<_LabelPoint> _fixedPointsPx = [];

  // Master list of all possible named locations and their world coordinates.
  final Map<String, List<double>> _allPossiblePoints = {
    "EL0101": [0.17, -0.18], "EL0102": [0.18, -1.18], "MA01": [6.22, -9.53],
    "R0101": [-1.29, -7.71], "R0102": [-1.29, -5.44], "R0103": [0.1, -6.09],
    "R0104": [-8.41, 6.96], "SL0101": [0.19, -2.94], "SL0102": [0.15, -2.44],
    "SL0103": [-8.04, 7.19], "VM0101": [-0.81, 4.08], "WL0101": [5.24, -9.66],
    "XL0101": [5.53, -9.99],
    "R0301": [-1.3, -2.0], "R0302": [-1.3, -3.0], "R0303": [-1.3, -4.0],
  };

  @override
  void initState() {
    super.initState();
    _setupMapAndPoints();
    _connectMqtt();
  }

  /// Finds the correct map data, sets up the image widget, and calculates fixed point positions.
  void _setupMapAndPoints() {
    setState(() => _status = 'Loading map data...');

    MapInfo? targetMapInfo;
    for (final field in Config.fields) {
      try {
        targetMapInfo = field.maps.firstWhere(
          (mapInfo) => mapInfo.mapImage == widget.mapImagePartialPath,
        );
        break;
      } catch (e) {
        continue;
      }
    }

    if (targetMapInfo == null) {
      setState(() => _status = 'Error: Map data not found for ${widget.mapImagePartialPath}');
      return;
    }

    // **FIX**: Add defensive check for mapOrigin length to prevent RangeError.
    if (targetMapInfo.mapOrigin.length < 2) {
      setState(() => _status = 'Error: Invalid map origin data for ${targetMapInfo.mapName}');
      return;
    }

    _dynamicMapOrigin = targetMapInfo.mapOrigin;
    _mapImageWidget = _buildMapImage(targetMapInfo.mapImage);

    final pointsToDisplay = <_LabelPoint>[];
    for (String rLocationName in targetMapInfo.rLocations) {
      if (_allPossiblePoints.containsKey(rLocationName)) {
        final coords = _allPossiblePoints[rLocationName]!;
        final wx = coords[0];
        final wy = coords[1];

        final mapX = (_dynamicMapOrigin[1] - wy) / _resolution;
        final mapY = (_dynamicMapOrigin[0] - wx) / _resolution;
        final px = Offset(mapX, mapY);

        pointsToDisplay.add(_LabelPoint(label: rLocationName, offset: px));
      }
    }

    setState(() {
      _fixedPointsPx = pointsToDisplay;
      _status = 'Map data loaded. Listening for robot position...';
    });
  }

  /// Initializes the MQTT service and listens to the position stream.
  void _connectMqtt() {
    _mqttService.positionStream.listen((Point point) {
      if (!mounted || _dynamicMapOrigin.length < 2) return;

      final robotX_m = point.x / 1000.0;
      final robotY_m = point.y / 1000.0;
      final pixelX = (_dynamicMapOrigin[1] - robotX_m) / _resolution;
      final pixelY = (_dynamicMapOrigin[0] - robotY_m) / _resolution;
      final newOffset = Offset(pixelX, pixelY);

      setState(() {
        _trailPoints.add(newOffset);
      });
    });
    _mqttService.connectAndListen(widget.robotUuid);
  }

  @override
  void dispose() {
    _mqttService.disconnect(widget.robotUuid);
    super.dispose();
  }

  Widget _buildMapImage(String imagePath) {
    String finalPath = imagePath.replaceAll(' ', '');
    if (finalPath.startsWith('outputs/')) {
      finalPath = finalPath.substring('outputs/'.length);
    }
    final fullMapUrl = '$_mapBaseUrl/$finalPath';

    return Image.network(
      fullMapUrl,
      fit: BoxFit.contain,
      loadingBuilder: (context, child, progress) {
        return progress == null ? child : const Center(child: CircularProgressIndicator());
      },
      errorBuilder: (context, error, stackTrace) {
        return Center(child: Text("Failed to load map: $error"));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Real-time Position Tracking'),
            Text(_status, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10)),
          ],
        ),
      contentPadding: const EdgeInsets.all(8),
      content: SizedBox(
        width: MediaQuery.of(context).size.width,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(border: Border.all(color: Colors.blueGrey)),
                child: InteractiveViewer(
                  maxScale: 5.0,
                  child: Stack(
                    children: [
                      if (_mapImageWidget != null) _mapImageWidget!,
                      CustomPaint(
                        size: Size.infinite,
                        painter: _RobotAndPointsPainter(
                          trailPoints: _trailPoints,
                          fixedPoints: _fixedPointsPx,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            ExpansionTile(
              title: const Text('Show/Hide API Response'),
              tilePadding: EdgeInsets.zero,
              children: [
                Container(
                  width: double.infinity,
                  height: 100,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: SingleChildScrollView(child: SelectableText(widget.responseText)),
                ),
              ],
            ),
          ],
        ),
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

/// Custom painter for both the robot's trail and the fixed points.
class _RobotAndPointsPainter extends CustomPainter {
  final List<Offset> trailPoints;
  final List<_LabelPoint> fixedPoints;

  _RobotAndPointsPainter({required this.trailPoints, required this.fixedPoints});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Paint the fixed points
    for (final point in fixedPoints) {
      final paintDot = Paint()..color = Colors.red;
      canvas.drawCircle(point.offset, 4, paintDot);

      final textPainter = TextPainter(
        text: TextSpan(
          text: point.label,
          style: const TextStyle(fontSize: 10, color: Colors.red, backgroundColor: Color(0x99FFFFFF)),
        ),
        textDirection: ui.TextDirection.ltr,
      );
      textPainter.layout(minWidth: 0, maxWidth: size.width);
      textPainter.paint(canvas, point.offset + const Offset(5, -18));
    }

    // 2. Paint the robot's trail
    if (trailPoints.length > 1) {
      final trailPaint = Paint()
        ..color = Colors.blue.withOpacity(0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      final path = Path()..moveTo(trailPoints.first.dx, trailPoints.first.dy);
      for (int i = 1; i < trailPoints.length; i++) {
        path.lineTo(trailPoints[i].dx, trailPoints[i].dy);
      }
      canvas.drawPath(path, trailPaint);
    }

    // 3. Paint the robot's current position
    if (trailPoints.isNotEmpty) {
      final currentPosition = trailPoints.last;
      final paintDot = Paint()
        ..style = PaintingStyle.fill
        ..color = const Color(0xFF2E7D32); // Green
      canvas.drawCircle(currentPosition, 5, paintDot);
      final paintHalo = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0x802E7D32); // Transparent green
      canvas.drawCircle(currentPosition, 9, paintHalo);
    }
  }

  @override
  bool shouldRepaint(covariant _RobotAndPointsPainter oldDelegate) {
    return oldDelegate.trailPoints != trailPoints || oldDelegate.fixedPoints != fixedPoints;
  }
}
