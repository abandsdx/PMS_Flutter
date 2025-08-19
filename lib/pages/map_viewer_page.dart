import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:pms_external_service_flutter/config.dart';
import 'package:pms_external_service_flutter/models/field_data.dart';
import '../utils/mqtt_service.dart';

enum FlipOption { noFlip, yFlip, xFlip, xyFlip }

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

  ui.Image? _mapImage;
  String _status = 'Initializing...';
  bool _isDataReady = false;

  // Store points for each flip option
  final Map<FlipOption, List<Offset>> _trailPoints = {
    for (var option in FlipOption.values) option: []
  };
  final Map<FlipOption, List<_LabelPoint>> _fixedPoints = {
    for (var option in FlipOption.values) option: []
  };

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
      final dynamicMapOrigin = targetMapInfo.mapOrigin;
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

      // Calculate points for all 4 flip options
      for (var option in FlipOption.values) {
        final pointsToDisplay = <_LabelPoint>[];
        for (String rLocationName in targetMapInfo.rLocations) {
          if (_allPossiblePoints.containsKey(rLocationName)) {
            final coords = _allPossiblePoints[rLocationName]!;
            pointsToDisplay.add(_transformPoint(coords[0], coords[1], rLocationName, dynamicMapOrigin, loadedImage, option));
          }
        }
        _fixedPoints[option] = pointsToDisplay;
      }

      setState(() {
        _mapImage = loadedImage;
        _status = 'Map data loaded. Listening...';
        _isDataReady = true;
      });
      _connectMqtt(dynamicMapOrigin, loadedImage);
    } else {
      setState(() => _status = 'Error: Invalid map origin data for ${targetMapInfo!.mapName}');
    }
  }

  _LabelPoint _transformPoint(double wx, double wy, String label, List<double> origin, ui.Image image, FlipOption option) {
      final mapX = (origin[0] - wy) / _resolution;
      final mapY = (origin[1] - wx) / _resolution;

      double finalX, finalY;
      switch (option) {
        case FlipOption.noFlip:
          finalX = mapX;
          finalY = mapY;
          break;
        case FlipOption.yFlip:
          finalX = mapX;
          finalY = image.height - mapY;
          break;
        case FlipOption.xFlip:
          finalX = image.width - mapX;
          finalY = mapY;
          break;
        case FlipOption.xyFlip:
          finalX = image.width - mapX;
          finalY = image.height - mapY;
          break;
      }
      return _LabelPoint(label: label, offset: Offset(finalX, finalY));
  }

  void _connectMqtt(List<double> origin, ui.Image image) {
    _mqttService.positionStream.listen((Point point) {
      if (!mounted || !_isDataReady) return;

      final robotX_m = point.x / 1000.0;
      final robotY_m = point.y / 1000.0;

      final mapX = (origin[0] - robotY_m) / _resolution;
      final mapY = (origin[1] - robotX_m) / _resolution;

      setState(() {
        for (var option in FlipOption.values) {
          double finalX, finalY;
          switch (option) {
            case FlipOption.noFlip:
              finalX = mapX;
              finalY = mapY;
              break;
            case FlipOption.yFlip:
              finalX = mapX;
              finalY = image.height - mapY;
              break;
            case FlipOption.xFlip:
              finalX = image.width - mapX;
              finalY = mapY;
              break;
            case FlipOption.xyFlip:
              finalX = image.width - mapX;
              finalY = image.height - mapY;
              break;
          }
          _trailPoints[option]!.add(Offset(finalX, finalY));
        }
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
    return Scaffold(
      appBar: AppBar(title: const Text('Map Transformation Debugger')),
      body: _mapImage == null
          ? Center(child: Text(_status))
          : GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1.0,
              ),
              itemCount: FlipOption.values.length,
              itemBuilder: (context, index) {
                final option = FlipOption.values[index];
                return Card(
                  elevation: 2,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Text(option.toString(), style: Theme.of(context).textTheme.titleSmall),
                      ),
                      Expanded(
                        child: InteractiveViewer(
                          maxScale: 5.0,
                          child: CustomPaint(
                            size: Size.infinite,
                            painter: MapAndRobotPainter(
                              mapImage: _mapImage!,
                              trailPoints: _trailPoints[option]!,
                              fixedPoints: _fixedPoints[option]!,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
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
    }
  }

  @override
  bool shouldRepaint(covariant MapAndRobotPainter oldDelegate) {
    return oldDelegate.mapImage != mapImage ||
           oldDelegate.trailPoints != trailPoints ||
           oldDelegate.fixedPoints != fixedPoints;
  }
}
