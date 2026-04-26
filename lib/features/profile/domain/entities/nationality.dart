class Nationality {
  const Nationality({
    required this.id,
    required this.name,
    required this.shortCode,
  });

  final int id;
  final String name;
  final String shortCode;

  factory Nationality.fromJson(Map<String, dynamic> json) {
    int _intValue(dynamic value) {
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    return Nationality(
      id: _intValue(json['id']),
      name: json['name']?.toString() ?? '',
      shortCode: json['shortCode']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'shortCode': shortCode,
    };
  }
}
