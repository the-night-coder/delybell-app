import '../repositories/orders_repository.dart';
import '../../../../dashboard/models/order_tracking.dart';

class GetOrderTracking {
  const GetOrderTracking(this._repository);

  final OrdersRepository _repository;

  Future<OrderTracking> call({
    required String token,
    required int orderId,
  }) {
    return _repository.fetchOrderTracking(token: token, orderId: orderId);
  }
}
