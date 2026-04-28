class OrderSummary {
  OrderSummary({
    required this.id,
    required this.generatedOrderId,
    required this.orderType,
    required this.status,
    required this.serviceType,
    required this.orderFlowType,
    required this.totalWeight,
    required this.shippingCharge,
    required this.packageCount,
    required this.addressLine,
    required this.barCode,
    required this.receiverName,
    required this.receiverPhone,
    required this.receiverAltPhone,
    required this.pickupName,
    required this.pickupPhone,
    required this.pickupAltPhone,
    required this.pickupAddressLine,
    required this.pickupDate,
    required this.pickupSlot,
    required this.senderAddress,
    required this.destinationAddress,
    required this.deliveryInstructions,
    required this.codAmount,
    required this.packages,
    required this.createdAt,
    required this.customerOrderId,
    this.isFuturePickup = false,
    this.isCod = false,
  });

  final int id;
  final String generatedOrderId;
  final String orderType;
  final String status;
  final String serviceType;
  final String orderFlowType;
  final String totalWeight;
  final String shippingCharge;
  final int packageCount;
  final String addressLine;
  final String barCode;
  final String receiverName;
  final String receiverPhone;
  final String receiverAltPhone;
  final String pickupName;
  final String pickupPhone;
  final String pickupAltPhone;
  final String pickupAddressLine;
  final String pickupDate;
  final String pickupSlot;
  final String senderAddress;
  final String destinationAddress;
  final String deliveryInstructions;
  final String codAmount;
  final List<OrderPackageSummary> packages;
  final DateTime createdAt;
  final String customerOrderId;
  final bool isFuturePickup;
  final bool isCod;

  factory OrderSummary.fromJson(Map<String, dynamic> json) {
    String toStr(dynamic v) => v?.toString() ?? '';
    int toInt(dynamic v) => v is int ? v : int.tryParse(v?.toString() ?? '') ?? 0;
    Map<String, dynamic>? toMap(dynamic v) => v is Map<String, dynamic> ? v : null;

    String formatAddress({
      required String flat,
      required Map<String, dynamic>? building,
      required Map<String, dynamic>? road,
      required Map<String, dynamic>? block,
      required String fallback,
    }) {
      String part(Map<String, dynamic>? data, List<String> codeKeys) {
        if (data == null) return '';
        final name = toStr(data['name']);
        String code = '';
        for (final key in codeKeys) {
          final value = data[key];
          if (value != null && value.toString().isNotEmpty) {
            code = value.toString();
            break;
          }
        }
        if (name.isEmpty && code.isEmpty) return '';
        if (name.isNotEmpty && code.isNotEmpty) return '$name - $code';
        return name.isNotEmpty ? name : code;
      }

      final parts = <String>[];
      final flatClean = flat.trim();
      if (flatClean.isNotEmpty) parts.add(flatClean);
      final buildingPart = part(building, const ['code', 'buildingCode', 'building_code']);
      if (buildingPart.isNotEmpty) parts.add(buildingPart);
      final roadPart = part(road, const ['code', 'roadCode', 'road_code']);
      if (roadPart.isNotEmpty) parts.add(roadPart);
      final blockPart = part(block, const ['code', 'blockCode', 'block_code']);
      if (blockPart.isNotEmpty) parts.add(blockPart);

      if (parts.isEmpty) {
        final fallbackClean = fallback.trim();
        return fallbackClean.isEmpty ? '-' : fallbackClean;
      }
      return parts.join(', ');
    }

    final pickupAddress = formatAddress(
      flat: toStr(json['pickup_flat_or_office_number'] ?? json['pickupFlatOrOfficeNumber']),
      building: toMap(json['pickup_building_details']),
      road: toMap(json['pickup_road_details']),
      block: toMap(json['pickup_block_details']),
      fallback: toStr(json['senderAddress']).ifEmpty(toStr(json['destinationAddress'])),
    );

    final destinationAddressLine = formatAddress(
      flat: toStr(json['destination_flat_or_office_number'] ?? json['destinationFlatOrOfficeNumber']),
      building: toMap(json['destination_building_details']),
      road: toMap(json['destination_road_details']),
      block: toMap(json['destination_block_details']),
      fallback: toStr(json['destinationAddress']),
    );

    final packages = (json['order_package_list'] as List<dynamic>? ??
            json['draft_order_package_list'] as List<dynamic>? ??
            const [])
        .whereType<Map<String, dynamic>>()
        .map(OrderPackageSummary.fromJson)
        .toList();
    String codAmount() {
      final codRaw = json['codAmount'] ?? json['cod_amount'];
      final val = codRaw?.toString() ?? '';
      if (val.isEmpty) return '0';
      return val;
    }

    return OrderSummary(
      id: json['id'] is String ? int.tryParse(json['id']) ?? 0 : (json['id'] ?? 0) as int,
      generatedOrderId: toStr(json['generatedOrderId']).isNotEmpty
          ? toStr(json['generatedOrderId'])
          : toStr(json['destinationCustomerName']),
      orderType: toStr(json['orderType']?['name']),
      status: toStr(json['statusForCustomer']?['name'] ?? json['status']?['name'])
          .ifEmpty('Draft'),
      serviceType: toStr(json['service_type_details']?['name']),
      orderFlowType: toStr(json['orderFlowType']?['name']),
      totalWeight: toStr(json['totalWeight']).ifEmpty('0.0'),
      shippingCharge: toStr(json['calculatedTotalShippingCharge']).ifEmpty('0'),
      packageCount: toInt(json['totalNoOfPackages']),
      addressLine: pickupAddress,
      barCode: toStr(json['barCode']),
      receiverName: toStr(json['destinationCustomerName']),
      receiverPhone: toStr(json['destinationMobileNumber']),
      receiverAltPhone: toStr(json['destinationAlternateNumber']),
      pickupName: toStr(json['pickupCustomerName']),
      pickupPhone: toStr(json['pickupMobileNumber']),
      pickupAltPhone: toStr(json['pickupAlternateNumber']),
      pickupAddressLine: pickupAddress,
      pickupDate: toStr(json['pickupPreferenceDate']),
      pickupSlot: toStr(json['pickupPreferenceSlotType']?['name']),
      senderAddress: toStr(json['senderAddress']),
      destinationAddress: destinationAddressLine.ifEmpty('-'),
      deliveryInstructions: toStr(json['deliveryInstructions']),
      codAmount: codAmount(),
      isCod: json['isCod'] == true,
      packages: packages,
      createdAt: DateTime.tryParse(toStr(json['createdAt'])) ?? DateTime.now(),
      isFuturePickup: json['isFuturePickup'] == true ||
          toStr(json['isFuturePickup']).toLowerCase() == 'true',
      customerOrderId: toStr(
        json['customerInputOrderId'] ?? json['customer_input_order_id'],
      ),
    );
  }
}

extension _StringHelpers on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}

class OrderPackageSummary {
  OrderPackageSummary({
    required this.generatedPackageId,
    required this.weight,
    required this.description,
    required this.value,
    required this.status,
  });

  final String generatedPackageId;
  final String weight;
  final String description;
  final String value;
  final String status;

  factory OrderPackageSummary.fromJson(Map<String, dynamic> json) {
    String toStr(dynamic v) => v?.toString() ?? '';
    return OrderPackageSummary(
      generatedPackageId: toStr(json['generatedOrderPackageId']),
      weight: toStr(json['weight']),
      description: toStr(json['packageDescription']),
      value: toStr(json['customerInputPackageValue']),
      status: toStr(json['status']?['name']),
    );
  }
}
