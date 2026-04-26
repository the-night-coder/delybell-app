class OrderTracking {
  OrderTracking({
    required this.id,
    required this.generatedOrderId,
    required this.barCode,
    required this.receiverName,
    required this.addressLine,
    required this.status,
    required this.flowType,
    required this.history,
  });

  final int id;
  final String generatedOrderId;
  final String barCode;
  final String receiverName;
  final String addressLine;
  final String status;
  final String flowType;
  final List<OrderHistoryEntry> history;

  factory OrderTracking.fromJson(Map<String, dynamic> json) {
    String _string(dynamic v) => v?.toString() ?? '';
    int _int(dynamic v) => v is int ? v : int.tryParse(v?.toString() ?? '') ?? 0;

    String _address() {
      final dest = _string(json['destinationAddress']);
      if (dest.isNotEmpty) return dest;
      final block = _string(json['destination_block_details']?['name']);
      final road = _string(json['destination_road_details']?['name']);
      final building = _string(json['destination_building_details']?['name']);
      final parts = [block, road, building].where((e) => e.isNotEmpty).toList();
      return parts.isEmpty ? '-' : parts.join(', ');
    }

    final historyList = (json['order_history'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(OrderHistoryEntry.fromJson)
        .toList();

    return OrderTracking(
      id: _int(json['id']),
      generatedOrderId: _string(json['generatedOrderId']),
      barCode: _string(json['barCode']),
      receiverName: _string(json['destinationCustomerName']),
      addressLine: _address(),
      status: _string(json['statusForCustomer']?['name'] ?? json['status']?['name']),
      flowType: _string(json['orderFlowType']?['name']),
      history: historyList,
    );
  }
}

class OrderHistoryEntry {
  OrderHistoryEntry({
    required this.title,
    required this.remarks,
    required this.date,
  });

  final String title;
  final String remarks;
  final DateTime? date;

  factory OrderHistoryEntry.fromJson(Map<String, dynamic> json) {
    String _string(dynamic v) => v?.toString() ?? '';
    DateTime? _date(String input) => DateTime.tryParse(input);

    return OrderHistoryEntry(
      title: _string(json['action']?['name']),
      remarks: _string(json['remarks']),
      date: _date(_string(json['createdAt'])),
    );
  }
}
