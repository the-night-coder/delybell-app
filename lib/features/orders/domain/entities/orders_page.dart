import '../../../../dashboard/models/order_summary.dart';

class OrdersPage {
  OrdersPage({
    required this.orders,
    required this.currentPage,
    required this.lastPage,
  });

  final List<OrderSummary> orders;
  final int currentPage;
  final int lastPage;
}
