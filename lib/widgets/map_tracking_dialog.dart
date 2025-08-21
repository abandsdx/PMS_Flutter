import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:pms_external_service_flutter/config.dart';
import 'package:pms_external_service_flutter/models/field_data.dart';
import '../utils/mqtt_service.dart';
import 'map_and_robot_painter.dart';

class MapTrackingDialog extends StatefulWidget {
  final String mapImagePartialPath;
  final String robotUuid;
  final String responseText;
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
  final String _mapBaseUrl = 'http://64.110.100.118:8001';

  List<double> _dynamicMapOrigin = [];
  ui.Image? _mapImage;
  String _status = 'Initializing...';
  bool _isDataReady = false;

  Timer? _repaintTimer;
  final List<Offset> _pointBuffer = [];
  List<Offset> _trailPoints = [];

  List<LabelPoint> _fixedPointsPx = [];

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

      final pointsToDisplay = <LabelPoint>[];
      for (String rLocationName in targetMapInfo.rLocations) {
        if (_allPossiblePoints.containsKey(rLocationName)) {
          final coords = _allPossiblePoints[rLocationName]!;
          final wx = coords[0];
          final wy = coords[1];
          final mapX = (_dynamicMapOrigin[0] - wy) / _resolution;
          final mapY = (_dynamicMapOrigin[1] - wx) / _resolution;
          pointsToDisplay.add(LabelPoint(label: rLocationName, offset: Offset(mapX, mapY)));
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
    _repaintTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (_pointBuffer.isNotEmpty && mounted) {
        setState(() {
          _trailPoints = List.from(_trailPoints)..addAll(_pointBuffer);
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

      _pointBuffer.add(Offset(pixelX, pixelY));
    });
    _mqttService.connectAndListen(widget.robotUuid);
  }

  @override
  void dispose() {
    _repaintTimer?.cancel();
    _mqttService.disconnect(widget.robotUuid);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget mapContent;
    if (_mapImage == null) {
        mapContent = Center(child: Text(_status));
    } else {
        mapContent = InteractiveViewer(
            maxScale: 5.0,
            child: CustomPaint(
                size: Size.infinite,
                painter: MapAndRobotPainter(
                mapImage: _mapImage!,
                trailPoints: _trailPoints,
                fixedPoints: _fixedPointsPx,
                ),
            ),
        );
    }

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      title: const Text('Real-time Position Tracking'),
      contentPadding: const EdgeInsets.all(8),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: Column(
          children: [
            Text(_status, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            Expanded(
              flex: 5,
              child: Container(
                decoration: BoxDecoration(border: Border.all(color: Colors.blueGrey)),
                child: mapContent,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              flex: 2,
              child: ExpansionTile(
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
