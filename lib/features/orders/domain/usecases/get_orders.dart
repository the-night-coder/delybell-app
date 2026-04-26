import '../repositories/orders_repository.dart';
import '../entities/orders_page.dart';

class GetOrders {
  const GetOrders(this._repository);

  final OrdersRepository _repository;

  Future<OrdersPage> call({
    required String token,
    int page = 1,
    int limit = 10,
    String search = '',
    String? endpoint,
    String? filterByDeliveryStatus,
  }) {
    return _repository.fetchOrders(
      token: token,
      page: page,
      limit: limit,
      search: search,
      endpoint: endpoint,
      filterByDeliveryStatus: filterByDeliveryStatus,
    );
  }
}
