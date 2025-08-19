import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:pms_external_service_flutter/config.dart';
import 'package:pms_external_service_flutter/models/field_data.dart';
import '../utils/mqtt_service.dart';

class _LabelPoint {
  final String label;
  final Offset offset;
  _LabelPoint({required this.label, required this.offset});
}

class MapViewerPage extends StatefulWidget {
  final String mapImagePartialPath;
  final String robotUuid;
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

  List<double> _dynamicMapOrigin = [];
  ui.Image? _mapImage;
  String _status = 'Initializing...';
  bool _isDataReady = false;

  // -- Performance Optimization --
  Timer? _repaintTimer;
  final List<Offset> _pointBuffer = [];
  final List<Offset> _trailPoints = [];
  // -- End Optimization --

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
  }

  Future<ui.Image> _loadImage(String imageUrl) {
    final completer = Completer<ui.Image>();
    NetworkImage(imageUrl).resolve(const ImageConfiguration()).addListener(
      ImageStreamListener((info, _) => completer.complete(info.image),
      onError: (e, s) => completer.completeError(e),
    ));
    return completer.future;
  }

  void _setupMapAndPoints() async {
    setState(() => _status = 'Loading map data...');

    MapInfo? targetMapInfo;
    try {
      targetMapInfo = Config.fields.expand((f) => f.maps).firstWhere((m) => m.mapImage == widget.mapImagePartialPath);
    } catch (e) {
      targetMapInfo = null;
    }

    if (targetMapInfo == null) {
      setState(() => _status = 'Error: Map data not found');
      return;
    }

    if (targetMapInfo.mapOrigin.length >= 2) {
      _dynamicMapOrigin = targetMapInfo.mapOrigin;
      String finalPath = targetMapInfo.mapImage.replaceAll(' ', '');
      if (finalPath.startsWith('outputs/')) {
        finalPath = finalPath.substring('outputs/'.length);
      }
      final fullMapUrl = '$_mapBaseUrl/$finalPath';

      ui.Image loadedImage;
      try {
        loadedImage = await _loadImage(fullMapUrl);
      } catch(e) {
         setState(() => _status = 'Error loading map image: $e');
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
          pointsToDisplay.add(_LabelPoint(label: rLocationName, offset: Offset(mapX, mapY)));
        }
      }

      setState(() {
        _mapImage = loadedImage;
        _fixedPointsPx = pointsToDisplay;
        _status = 'Map data loaded. Listening for robot position...';
        _isDataReady = true;
      });
      _connectMqtt();
    } else {
      setState(() => _status = 'Error: Invalid map origin data for ${targetMapInfo!.mapName}');
    }
  }

  void _connectMqtt() {
    // Start a timer to update the UI at a fixed rate (e.g., 10fps)
    _repaintTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (_pointBuffer.isNotEmpty) {
        setState(() {
          _trailPoints.addAll(_pointBuffer);
          _pointBuffer.clear();
        });
      }
    });

    _mqttService.positionStream.listen((Point point) {
      if (!mounted || !_isDataReady) return;

      final robotX_m = point.x / 1000.0;
      final robotY_m = point.y / 1000.0;

      final pixelX = (_dynamicMapOrigin[0] - robotY_m) / _resolution;
      final pixelY = (_dynamicMapOrigin[1] - robotX_m) / _resolution;

      // Add to buffer instead of calling setState directly
      _pointBuffer.add(Offset(pixelX, pixelY));
    });
    _mqttService.connectAndListen(widget.robotUuid);
  }

  @override
  void dispose() {
    _repaintTimer?.cancel(); // Cancel the timer
    _mqttService.disconnect(widget.robotUuid);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Real-time Map Viewer'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(20.0),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: Text(_status, style: const TextStyle(fontSize: 12)),
          ),
        ),
      ),
      body: _mapImage == null
          ? Center(child: Text(_status))
          : InteractiveViewer(
              maxScale: 5.0,
              child: CustomPaint(
                size: Size.infinite,
                painter: MapAndRobotPainter(
                  mapImage: _mapImage!,
                  trailPoints: _trailPoints,
                  fixedPoints: _fixedPointsPx,
                ),
              ),
            ),
    );
  }
}

class MapAndRobotPainter extends CustomPainter {
  final ui.Image mapImage;
  final List<Offset> trailPoints;
  final List<_LabelPoint> fixedPoints;

  MapAndRobotPainter({
    required this.mapImage,
    required this.trailPoints,
    required this.fixedPoints,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final mapSourceRect = Rect.fromLTWH(0, 0, mapImage.width.toDouble(), mapImage.height.toDouble());
    final canvasDestRect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawImageRect(mapImage, mapSourceRect, canvasDestRect, paint);

    final scaleX = size.width / mapImage.width;
    final scaleY = size.height / mapImage.height;

    for (final point in fixedPoints) {
      final scaledPosition = Offset(point.offset.dx * scaleX, point.offset.dy * scaleY);
      final paintDot = Paint()..color = Colors.red;
      canvas.drawCircle(scaledPosition, 5, paintDot);
      final textPainter = TextPainter(
        text: TextSpan(text: point.label, style: const TextStyle(fontSize: 10, color: Colors.red, backgroundColor: Color(0x99FFFFFF))),
        textDirection: ui.TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, scaledPosition + const Offset(8, -18));
    }

    if (trailPoints.isNotEmpty) {
        final path = Path();
        final firstPoint = trailPoints.first;
        path.moveTo(firstPoint.dx * scaleX, firstPoint.dy * scaleY);
        for (int i = 1; i < trailPoints.length; i++) {
            path.lineTo(trailPoints[i].dx * scaleX, trailPoints[i].dy * scaleY);
        }
        final trailPaint = Paint()..color = Colors.blue.withOpacity(0.8)..style = PaintingStyle.stroke..strokeWidth = 2.0;
        canvas.drawPath(path, trailPaint);

        final currentPosition = Offset(trailPoints.last.dx * scaleX, trailPoints.last.dy * scaleY);
        final paintDot = Paint()..style = PaintingStyle.fill..color = const Color(0xFF2E7D32);
        canvas.drawCircle(currentPosition, 6, paintDot);
        final paintHalo = Paint()..style = PaintingStyle.stroke..strokeWidth = 2..color = const Color(0x802E7D32);
        canvas.drawCircle(currentPosition, 10, paintHalo);
    }
  }

  @override
  bool shouldRepaint(covariant MapAndRobotPainter oldDelegate) {
    return oldDelegate.mapImage != mapImage ||
           oldDelegate.trailPoints != trailPoints ||
           oldDelegate.fixedPoints != fixedPoints;
  }
}
