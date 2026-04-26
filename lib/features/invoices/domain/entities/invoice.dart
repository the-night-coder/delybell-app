class Invoice {
  const Invoice({
    required this.id,
    required this.generatedId,
    required this.payableAmount,
    required this.paymentStatusId,
    required this.paymentStatus,
    required this.dueDate,
    required this.customerName,
    required this.orderId,
  });

  final int id;
  final String generatedId;
  final String payableAmount;
  final int paymentStatusId;
  final String paymentStatus;
  final String dueDate;
  final String customerName;
  final int orderId;

  factory Invoice.fromJson(Map<String, dynamic> json) {
    final orderDetails = json['order_details'] as Map<String, dynamic>? ?? const {};
    final createdFor = orderDetails['created_for_details'] as Map<String, dynamic>? ?? const {};
    final paymentStatus = json['paymentStatus'] as Map<String, dynamic>? ?? const {};
    return Invoice(
      id: json['id'] as int? ?? 0,
      generatedId: json['generatedInvoiceId']?.toString() ?? '',
      payableAmount: json['payableAmount']?.toString() ?? '0.000',
      paymentStatusId: paymentStatus['id'] as int? ?? 0,
      paymentStatus: paymentStatus['name']?.toString() ?? '',
      dueDate: json['dueDate']?.toString() ?? '',
      customerName: _composeName(
        createdFor['firstName']?.toString() ?? '',
        createdFor['lastName']?.toString() ?? '',
        createdFor['companyName']?.toString() ?? '',
      ),
      orderId: json['orderId'] as int? ?? 0,
    );
  }

  static String _composeName(String first, String last, String company) {
    final name = [first, last].where((e) => e.isNotEmpty).join(' ').trim();
    if (name.isNotEmpty) return name;
    return company;
  }
}
