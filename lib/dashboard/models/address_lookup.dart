class BlockInfo {
  BlockInfo({
    required this.id,
    required this.name,
    required this.code,
  });

  final int id;
  final String name;
  final String code;

  factory BlockInfo.fromJson(Map<String, dynamic> json) {
    return BlockInfo(
      id: json['id'] is String ? int.tryParse(json['id']) ?? 0 : (json['id'] ?? 0) as int,
      name: json['name']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
    );
  }
}

class RoadInfo {
  RoadInfo({
    required this.id,
    required this.name,
    required this.code,
  });

  final int id;
  final String name;
  final String code;

  factory RoadInfo.fromJson(Map<String, dynamic> json) {
    return RoadInfo(
      id: json['id'] is String ? int.tryParse(json['id']) ?? 0 : (json['id'] ?? 0) as int,
      name: json['name']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
    );
  }
}

class BuildingInfo {
  BuildingInfo({
    required this.id,
    required this.name,
    required this.code,
  });

  final int id;
  final String name;
  final String code;

  factory BuildingInfo.fromJson(Map<String, dynamic> json) {
    return BuildingInfo(
      id: json['id'] is String ? int.tryParse(json['id']) ?? 0 : (json['id'] ?? 0) as int,
      name: json['name']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
    );
  }
}
