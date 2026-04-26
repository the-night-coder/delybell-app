class DraftPlacePreview {
  const DraftPlacePreview({
    required this.numberOfDraftOrders,
    required this.numberOfPackages,
    required this.calculatedTotalShippingCharge,
    this.pickupBlockDetails = const {},
    this.pickupRoadDetails = const {},
    this.pickupBuildingDetails = const {},
    this.pickupContactNumber = '',
    this.codAmount = 0,
    this.totalCodAmount = 0,
  });

  final int numberOfDraftOrders;
  final int numberOfPackages;
  final num calculatedTotalShippingCharge;
  final Map<String, dynamic> pickupBlockDetails;
  final Map<String, dynamic> pickupRoadDetails;
  final Map<String, dynamic> pickupBuildingDetails;
  final String pickupContactNumber;
  final num codAmount;
  final num totalCodAmount;

  factory DraftPlacePreview.fromJson(Map<String, dynamic> json) {
    int _intValue(String key) {
      final value = json[key];
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    num _numValue(String key) {
      final value = json[key];
      if (value is num) return value;
      if (value is String) return num.tryParse(value) ?? 0;
      return 0;
    }

    return DraftPlacePreview(
      numberOfDraftOrders: _intValue('numberOfDraftOrders'),
      numberOfPackages: _intValue('numberOfPackages'),
      calculatedTotalShippingCharge: _numValue('calculatedTotalShippingCharge'),
      pickupBlockDetails:
          (json['pickupBlockDetails'] as Map<String, dynamic>? ?? const {}),
      pickupRoadDetails: (json['pickupRoadDetails'] as Map<String, dynamic>? ?? const {}),
      pickupBuildingDetails:
          (json['pickupBuildingDetails'] as Map<String, dynamic>? ?? const {}),
      pickupContactNumber:
          json['pickupContactNumber']?.toString() ?? json['pickup_contact_number']?.toString() ?? '',
      codAmount: _numValue('codAmount'),
      totalCodAmount: _numValue('totalCodAmount'),
    );
  }
}
