import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:pms_external_service_flutter/config.dart';
import 'package:pms_external_service_flutter/models/field_data.dart';
import '../utils/mqtt_service.dart';

/// A data class to hold the label and pixel offset of a fixed point on the map.
/// (一個資料類別，用於儲存地圖上固定點的標籤和像素座標。)
class _LabelPoint {
  final String label;
  final Offset offset;
  _LabelPoint({required this.label, required this.offset});
}

/// A stateful dialog that displays a map and tracks a robot's position in real-time.
/// (一個有狀態的對話框，用於顯示地圖並即時追蹤機器人位置。)
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
  // --- Services and Constants ---
  final MqttService _mqttService = MqttService();
  final double _resolution = 0.05;
  final String _mapBaseUrl = 'http://64.110.100.118:8001';

  // --- State Variables ---
  List<double> _dynamicMapOrigin = [];
  ui.Image? _mapImage;
  String _status = 'Initializing...';
  bool _isDataReady = false;

  // -- State for real-time drawing with performance optimization --
  Timer? _repaintTimer;
  final List<Offset> _pointBuffer = [];
  List<Offset> _trailPoints = [];

  // --- Data for Display ---
  List<_LabelPoint> _fixedPointsPx = [];
  final Map<String, List<double>> _allPossiblePoints = {
    "EL0101": [0.17, -0.18], "EL0102": [0.18, -1.18], "MA01": [6.22, -9.53],
    "R0101": [-1.29, -7.71], "R0102": [-1.29, -5.44], "R0103": [0.1, -6.09],
    "R0104": [-8.41, 6.96], "SL0101": [0.19, -2.94], "SL0102": [0.15, -2.44],
    "SL0103": [-8.04, 7.19], "VM0101": [-0.81, 4.08], "WL0101": [5.24, -9.66],
    "XL0101": [5.53, -9.99], "R0301": [-1.3, -2.0], "R0302": [-1.3, -3.0],
    "R0303": [-1.3, -4.0],
  };

  @override
  void initState() {
    super.initState();
    _setupMapAndPoints();
  }

  @override
  void dispose() {
    _repaintTimer?.cancel();
    _mqttService.disconnect(widget.robotUuid);
    super.dispose();
  }

  /// Loads a network image and returns it as a `ui.Image` object.
  /// (載入網路圖片並將其作為 `ui.Image` 物件返回。)
  Future<ui.Image> _loadImage(String imageUrl) {
    final completer = Completer<ui.Image>();
    NetworkImage(imageUrl).resolve(const ImageConfiguration()).addListener(
      ImageStreamListener((info, _) => completer.complete(info.image),
      onError: (e, s) => completer.completeError(e),
    ));
    return completer.future;
  }

  /// Sets up all necessary data for the map display.
  /// Fetches map info, loads the image, calculates fixed point positions, and connects to MQTT.
  /// (設定所有地圖顯示所需的資料。獲取地圖資訊、載入圖片、計算固定點位置並連接到 MQTT。)
  void _setupMapAndPoints() async {
    setState(() => _status = 'Loading map data...');

    MapInfo? targetMapInfo;
    try {
      targetMapInfo = Config.fields.expand((f) => f.maps).firstWhere((m) => m.mapImage == widget.mapImagePartialPath);
    } catch (e) {
      targetMapInfo = null;
    }

    if (targetMapInfo == null) {
      setState(() => _status = 'Error: Map data not found in Config');
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
          pointsToDisplay.add(_transformPoint(coords[0], coords[1], rLocationName, loadedImage));
        }
      }

      setState(() {
        _mapImage = loadedImage;
        _fixedPointsPx = pointsToDisplay;
        _status = 'Map loaded. Listening for robot position...';
        _isDataReady = true;
      });
      _connectMqtt();
    } else {
      setState(() => _status = 'Error: Invalid map origin data for ${targetMapInfo!.mapName}');
    }
  }

  /// Transforms world coordinates to pixel coordinates for drawing on the canvas.
  /// (將世界座標轉換為用於在畫布上繪圖的像素座標。)
  _LabelPoint _transformPoint(double wx, double wy, String label, ui.Image image) {
      // This is the final, correct transformation formula based on extensive debugging.
      // (這是經過大量除錯後最終確定的正確轉換公式。)
      final mapX = (_dynamicMapOrigin[0] - wy) / _resolution;
      final mapY = (_dynamicMapOrigin[1] - wx) / _resolution;
      return _LabelPoint(label: label, offset: Offset(mapX, mapY));
  }

  /// Connects to MQTT and sets up listeners for real-time position updates.
  /// (連接到 MQTT 並設定監聽器以獲取即時位置更新。)
  void _connectMqtt() {
    // This timer batches UI updates to prevent jank from high-frequency messages.
    // (這個計時器批次處理 UI 更新，以防止高頻訊息導致的卡頓。)
    _repaintTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (_pointBuffer.isNotEmpty && mounted) {
        setState(() {
          // Create a new list to ensure Flutter's state management detects the change.
          // (建立一個新列表以確保 Flutter 的狀態管理能夠偵測到變化。)
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

      // Add to a temporary buffer instead of calling setState directly on every message.
      // (新增到暫存緩衝區，而不是在每條訊息上都直接呼叫 setState。)
      _pointBuffer.add(Offset(pixelX, pixelY));
    });
    _mqttService.connectAndListen(widget.robotUuid);
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
      title: const Text('即時位置追蹤'),
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
            // New expandable tile to show the raw API response.
            // (新的可展開組件，用於顯示原始 API 回應。)
            Expanded(
              flex: 2,
              child: ExpansionTile(
                title: const Text('顯示/隱藏 API 回應'),
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
          child: const Text('關閉'),
        ),
      ],
    );
  }
}

/// A custom painter that draws the map, fixed points, and the robot's trail.
/// (一個自訂畫家，負責繪製地圖、固定點和機器人軌跡。)
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

    // Calculate scaling factors to draw points on the resized canvas.
    // (計算縮放因子以在調整大小後的畫布上繪製點。)
    final scaleX = size.width / mapImage.width;
    final scaleY = size.height / mapImage.height;

    // Draw fixed points
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

    // Draw robot trail and current position
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
