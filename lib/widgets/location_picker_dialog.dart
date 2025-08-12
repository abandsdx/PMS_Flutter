import 'package:flutter/material.dart';
import '../models/field_data.dart';

/// A dialog widget that allows the user to select a location (`rLocation`).
///
/// It displays a tabbed interface where each tab represents a floor.
/// The content of each tab is a list of available locations on that floor.
class LocationPickerDialog extends StatefulWidget {
  /// The list of map information for a specific field, containing floors and locations.
  final List<MapInfo> maps;

  const LocationPickerDialog({Key? key, required this.maps}) : super(key: key);

  @override
  _LocationPickerDialogState createState() => _LocationPickerDialogState();
}

class _LocationPickerDialogState extends State<LocationPickerDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: widget.maps.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // --- Adaptive Width Calculation ---
    const double tabEstimatedWidth = 100.0;
    const double minDialogWidth = 320.0;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double maxDialogWidth = screenWidth * 0.9;

    // Add some buffer for padding and the cancel button
    final double calculatedWidth = (widget.maps.length * tabEstimatedWidth) + 60.0;

    final dialogWidth = calculatedWidth.clamp(minDialogWidth, maxDialogWidth);
    // --- End Calculation ---

    return AlertDialog(
      title: Text("選擇地點"),
      contentPadding: const EdgeInsets.fromLTRB(0, 20, 0, 0),
      content: SizedBox(
        width: dialogWidth,
        height: MediaQuery.of(context).size.height * 0.4, // adaptive height, reduced size
        child: Column(
          children: [
            if (widget.maps.isNotEmpty)
              TabBar(
                controller: _tabController,
                isScrollable: true,
                tabs: widget.maps.map((map) => Tab(text: "${map.floor} (${map.mapName})")).toList(),
              ),
            Expanded(
              child: widget.maps.isEmpty
                  ? Center(child: Text("此場域無地圖資訊"))
                  : TabBarView(
                      controller: _tabController,
                      children: widget.maps.map((map) {
                        if (map.rLocations.isEmpty) {
                          return Center(child: Text("此樓層無可用地點"));
                        }
                        return ListView.builder(
                          itemCount: map.rLocations.length,
                          itemBuilder: (context, index) {
                            final location = map.rLocations[index];
                            return ListTile(
                              title: Text(location),
                              onTap: () {
                                Navigator.of(context).pop(location);
                              },
                            );
                          },
                        );
                      }).toList(),
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text("取消"),
        ),
      ],
    );
  }
}
