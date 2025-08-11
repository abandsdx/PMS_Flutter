import 'dart:convert';

List<Field> fieldFromJson(String str) => List<Field>.from(json.decode(str).map((x) => Field.fromJson(x)));

String fieldToJson(List<Field> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class Field {
    final String fieldId;
    final String fieldName;
    final List<MapInfo> maps;

    Field({
        required this.fieldId,
        required this.fieldName,
        required this.maps,
    });

    factory Field.fromJson(Map<String, dynamic> json) => Field(
        fieldId: json["fieldId"] ?? '',
        fieldName: json["fieldName"] ?? '',
        maps: json["maps"] == null ? [] : List<MapInfo>.from(json["maps"].map((x) => MapInfo.fromJson(x))),
    );

    Map<String, dynamic> toJson() => {
        "fieldId": fieldId,
        "fieldName": fieldName,
        "maps": List<dynamic>.from(maps.map((x) => x.toJson())),
    };

    @override
    bool operator ==(Object other) =>
        identical(this, other) ||
        other is Field &&
            runtimeType == other.runtimeType &&
            fieldId == other.fieldId;

    @override
    int get hashCode => fieldId.hashCode;
}

class MapInfo {
    final String mapName;
    final String mapUuid;
    final String floor;
    final List<String> rLocations;
    final String mapImage;
    final List<double> mapOrigin;

    MapInfo({
        required this.mapName,
        required this.mapUuid,
        required this.floor,
        required this.rLocations,
        required this.mapImage,
        required this.mapOrigin,
    });

    factory MapInfo.fromJson(Map<String, dynamic> json) => MapInfo(
        mapName: json["mapName"] ?? '',
        mapUuid: json["mapUuid"] ?? '',
        floor: json["floor"] ?? '',
        rLocations: json["rLocations"] == null ? [] : List<String>.from(json["rLocations"].map((x) => x)),
        mapImage: json["mapImage"] ?? '',
        mapOrigin: json["mapOrigin"] == null ? [] : List<double>.from(json["mapOrigin"].map((x) => x.toDouble())),
    );

    Map<String, dynamic> toJson() => {
        "mapName": mapName,
        "mapUuid": mapUuid,
        "floor": floor,
        "rLocations": List<dynamic>.from(rLocations.map((x) => x)),
        "mapImage": mapImage,
        "mapOrigin": List<dynamic>.from(mapOrigin.map((x) => x)),
    };
}
