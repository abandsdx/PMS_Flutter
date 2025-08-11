import 'package:flutter/material.dart';
import '../models/field_data.dart';

class LocationPickerDialog extends StatefulWidget {
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
    return AlertDialog(
      title: Text("選擇地點"),
      contentPadding: const EdgeInsets.fromLTRB(0, 20, 0, 0),
      content: Container(
        width: double.maxFinite,
        height: 400, // Give it a fixed height
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
