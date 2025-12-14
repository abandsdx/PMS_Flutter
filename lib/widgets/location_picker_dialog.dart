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

class _LocationPickerDialogState extends State<LocationPickerDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchTerm = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: widget.maps.length, vsync: this);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  List<String> _filterLocations(List<String> locations) {
    if (_searchTerm.isNotEmpty) {
      final term = _searchTerm.trim().toLowerCase();
      return locations
          .where((loc) => loc.trim().toLowerCase().contains(term))
          .toList();
    }
    if (_searchTerm.isEmpty) return locations;
    return locations;
  }

  List<Map<String, dynamic>> _globalSearchResults() {
    final term = _searchTerm.trim().toLowerCase();
    if (term.isEmpty) return [];
    final List<Map<String, dynamic>> results = [];
    for (final map in widget.maps) {
      for (final loc in map.rLocations) {
        if (loc.trim().toLowerCase().contains(term)) {
          results.add({"map": map, "location": loc});
        }
      }
    }
    return results;
  }

  @override
  Widget build(BuildContext context) {
    // --- Adaptive Width Calculation ---
    const double tabEstimatedWidth = 100.0;
    const double minDialogWidth = 320.0;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double maxDialogWidth = screenWidth * 0.9;

    // Add some buffer for padding and the cancel button
    final double calculatedWidth =
        (widget.maps.length * tabEstimatedWidth) + 60.0;

    final dialogWidth = calculatedWidth.clamp(minDialogWidth, maxDialogWidth);
    // --- End Calculation ---
    final bool hasSearch = _searchTerm.trim().isNotEmpty;
    final globalResults = _globalSearchResults();

    return AlertDialog(
      title: Text("選擇地點"),
      contentPadding: const EdgeInsets.fromLTRB(0, 20, 0, 0),
      content: SizedBox(
        width: dialogWidth,
        height:
            MediaQuery.of(context).size.height *
            0.4, // adaptive height, reduced size
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchTerm = value;
                  });
                },
                decoration: const InputDecoration(
                  hintText: "搜尋地點",
                  prefixIcon: Icon(Icons.search),
                  isDense: true,
                ),
              ),
            ),
            if (widget.maps.isNotEmpty && !hasSearch)
              TabBar(
                controller: _tabController,
                isScrollable: true,
                tabs: widget.maps.map((map) {
                  // Use a compact label so all floors/maps stay visible.
                  final shortName = map.mapName.split('_').isNotEmpty
                      ? map.mapName.split('_').last
                      : map.mapName;
                  final label = shortName == map.floor
                      ? map.floor
                      : "${map.floor} ($shortName)";
                  return Tab(text: label);
                }).toList(),
              ),
            Expanded(
              child: widget.maps.isEmpty
                  ? Center(child: Text("此場域無地圖資訊"))
                  : hasSearch
                  ? (globalResults.isEmpty
                        ? Center(child: Text("沒有符合的地點"))
                        : ListView.builder(
                            itemCount: globalResults.length,
                            itemBuilder: (context, index) {
                              final result = globalResults[index];
                              final map = result["map"] as MapInfo;
                              final location = result["location"] as String;
                              final shortName =
                                  map.mapName.split('_').isNotEmpty
                                  ? map.mapName.split('_').last
                                  : map.mapName;
                              return ListTile(
                                title: Text(location),
                                subtitle: Text("${map.floor} ($shortName)"),
                                onTap: () {
                                  Navigator.of(
                                    context,
                                  ).pop({"map": map, "location": location});
                                },
                              );
                            },
                          ))
                  : TabBarView(
                      controller: _tabController,
                      children: widget.maps.map((map) {
                        if (map.rLocations.isEmpty) {
                          return Center(child: Text("此樓層無可用地點"));
                        }
                        final filtered = _filterLocations(map.rLocations);
                        if (filtered.isEmpty) {
                          return Center(child: Text("沒有符合的地點"));
                        }
                        return ListView.builder(
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final location = filtered[index];
                            return ListTile(
                              title: Text(location),
                              onTap: () {
                                // Return both the map and the location
                                final result = {
                                  'map': map,
                                  'location': location,
                                };
                                Navigator.of(context).pop(result);
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
