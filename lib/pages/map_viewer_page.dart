import 'dart:async';
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

/// A full-screen page that displays a map and tracks a robot's position.
class MapViewerPage extends StatefulWidget {
  final String mapImagePartialPath;
  final String robotUuid;
  // These are passed but may not be used directly in the UI anymore.
  final String responseText;
  final List<double> mapOrigin;

  const MapViewerPage({
    Key? key,
    required this.mapImagePartialPath,
    required this.mapOrigin,
    required this.robotUuid,
    required this.responseText,
  }) : super(key: key);

  @override
  _MapViewerPageState createState() => _MapViewerPageState();
}

class _MapViewerPageState extends State<MapViewerPage> {
  final MqttService _mqttService = MqttService();
  final double _resolution = 0.05;
  final String _mapBaseUrl = 'http://64.110.100.118:8001';

  // State variables
  List<double> _dynamicMapOrigin = [];
  ui.Image? _mapImage;
  String _status = 'Initializing...';
  bool _isDataReady = false;

  // Data for drawing
  final List<Offset> _trailPoints = [];
  List<_LabelPoint> _fixedPointsPx = [];

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

  Future<void> _loadImage(String imageUrl) async {
    final imageCompleter = Completer<ui.Image>();
    final imageStream = NetworkImage(imageUrl).resolve(const ImageConfiguration());
    imageStream.addListener(ImageStreamListener((info, _) {
      imageCompleter.complete(info.image);
    }, onError: (exception, stackTrace) {
      imageCompleter.completeError(exception);
    }));
    _mapImage = await imageCompleter.future;
  }

  void _setupMapAndPoints() async {
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

    if (targetMapInfo.mapOrigin.length >= 2) {
      _dynamicMapOrigin = targetMapInfo.mapOrigin;

      String finalPath = targetMapInfo.mapImage.replaceAll(' ', '');
      if (finalPath.startsWith('outputs/')) {
        finalPath = finalPath.substring('outputs/'.length);
      }
      final fullMapUrl = '$_mapBaseUrl/$finalPath';

      try {
        await _loadImage(fullMapUrl);
      } catch(e) {
         setState(() {
            _status = 'Error loading map image: $e';
            _isDataReady = false;
         });
         return;
      }

      final pointsToDisplay = <_LabelPoint>[];
      for (String rLocationName in targetMapInfo.rLocations) {
        if (_allPossiblePoints.containsKey(rLocationName)) {
          final coords = _allPossiblePoints[rLocationName]!;
          final wx = coords[0];
          final wy = coords[1];

          final mapX = (_dynamicMapOrigin[0] - wy) / _resolution;
          final mapY = (_dynamicMapOrigin[1] - wx) / _resolution;
          final px = Offset(mapX, mapY);

          pointsToDisplay.add(_LabelPoint(label: rLocationName, offset: px));
        }
      }

      // --- DEBUG LOGGING ---
      print("--- MAP DEBUG INFO ---");
      print("Map Size (w, h): ${_mapImage?.width}, ${_mapImage?.height}");
      print("Map Origin (ox, oy): $_dynamicMapOrigin");
      print("Map Resolution: $_resolution");
      print("--- CALCULATING FIXED POINTS ---");
      for (var p in pointsToDisplay) {
        final originalPoint = _allPossiblePoints[p.label]!;
        print("Point: ${p.label}, World(x,y): ${originalPoint}, PIXEL(x,y): ${p.offset}");
      }
      print("--- END DEBUG INFO ---");
      // --- END DEBUG LOGGING ---

      setState(() {
        _fixedPointsPx = pointsToDisplay;
        _status = 'Map data loaded. Listening for robot position...';
        _isDataReady = true;
      });
    } else {
      setState(() {
        _status = 'Error: Invalid map origin data for ${targetMapInfo!.mapName}';
        _isDataReady = false;
      });
    }
  }

  void _connectMqtt() {
    _mqttService.positionStream.listen((Point point) {
      if (!mounted || !_isDataReady) {
        return;
      }
      final robotX_m = point.x / 1000.0;
      final robotY_m = point.y / 1000.0;
      final pixelX = (_dynamicMapOrigin[0] - robotY_m) / _resolution;
      final pixelY = (_dynamicMapOrigin[1] - robotX_m) / _resolution;
      final newOffset = Offset(pixelX, pixelY);

      // --- DEBUG LOGGING ---
      print("MQTT: World(x,y): ($robotX_m, $robotY_m) -> PIXEL(x,y): $newOffset");
      // --- END DEBUG LOGGING ---

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

  @override
  Widget build(BuildContext context) {
    Widget bodyContent;
    if (!_isDataReady || _mapImage == null) {
      bodyContent = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(_status),
          ],
        ),
      );
    } else {
      bodyContent = InteractiveViewer(
        maxScale: 5.0,
        child: SizedBox(
          width: _mapImage!.width.toDouble(),
          height: _mapImage!.height.toDouble(),
          child: Stack(
            children: [
              RawImage(image: _mapImage!),
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
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Real-time Map Viewer'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(20.0),
          child: Text(_status, style: const TextStyle(fontSize: 12)),
        ),
      ),
      body: bodyContent,
    );
  }
}

class _RobotAndPointsPainter extends CustomPainter {
  final List<Offset> trailPoints;
  final List<_LabelPoint> fixedPoints;

  _RobotAndPointsPainter({required this.trailPoints, required this.fixedPoints});

  @override
  void paint(Canvas canvas, Size size) {
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
    if (trailPoints.isNotEmpty) {
      final currentPosition = trailPoints.last;
      final paintDot = Paint()
        ..style = PaintingStyle.fill
        ..color = const Color(0xFF2E7D32);
      canvas.drawCircle(currentPosition, 5, paintDot);
      final paintHalo = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0x802E7D32);
      canvas.drawCircle(currentPosition, 9, paintHalo);
    }
  }

  @override
  bool shouldRepaint(covariant _RobotAndPointsPainter oldDelegate) {
    return oldDelegate.trailPoints != trailPoints || oldDelegate.fixedPoints != fixedPoints;
  }
}
