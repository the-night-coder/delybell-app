class AddressEntity {
  const AddressEntity({
    required this.id,
    required this.title,
    required this.line1,
    required this.line2,
    required this.phone,
    required this.isPrimary,
    required this.blockCode,
    required this.blockName,
    required this.roadCode,
    required this.buildingCode,
  });

  final int id;
  final String title;
  final String line1;
  final String line2;
  final String phone;
  final bool isPrimary;
  final String blockCode;
  final String blockName;
  final String roadCode;
  final String buildingCode;

  factory AddressEntity.empty() => const AddressEntity(
        id: 0,
        title: '',
        line1: '',
        line2: '',
        phone: '',
        isPrimary: false,
        blockCode: '',
        blockName: '',
        roadCode: '',
        buildingCode: '',
      );

  factory AddressEntity.fromJson(Map<String, dynamic> json) {
    final block = json['block'] as Map<String, dynamic>? ?? const {};
    final road = json['road'] as Map<String, dynamic>? ?? const {};
    final building = json['building'] as Map<String, dynamic>? ?? const {};

    return AddressEntity(
      id: json['id'] as int? ?? 0,
      title: json['addressTitle']?.toString() ?? '',
      line1: json['addressLineOne']?.toString() ?? '',
      line2: json['addressLineTwo']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      isPrimary: (json['isPrimary'] as num?) == 1,
      blockCode: block['code']?.toString() ?? '',
      blockName: block['name']?.toString() ?? '',
      roadCode: road['code']?.toString() ?? '',
      buildingCode: building['code']?.toString() ?? '',
    );
  }
}
