import '../entities/orders_page.dart';
import '../../../../dashboard/models/order_tracking.dart';
import '../entities/draft_place_preview.dart';

abstract class OrdersRepository {
  Future<OrdersPage> fetchOrders({
    required String token,
    int page,
    int limit,
    String search,
    String? endpoint,
    String? filterByDeliveryStatus,
  });

  Future<OrderTracking> fetchOrderTracking({
    required String token,
    required int orderId,
  });

  Future<Map<String, dynamic>> initiateDraftOrder({
    required String token,
    required Map<String, dynamic> payload,
  });

  Future<Map<String, dynamic>> previewDraftOrder({
    required String token,
    required Map<String, dynamic> payload,
  });

  Future<void> acceptDraftOrder({
    required String token,
    required int draftOrderId,
  });

  Future<void> deleteDraftOrder({
    required String token,
    required int draftOrderId,
  });

  Future<void> clearDraftOrders({
    required String token,
  });

  Future<void> placeDraftOrders({
    required String token,
    required Map<String, dynamic> payload,
  });

  Future<DraftPlacePreview> previewPlaceDraftOrders({
    required String token,
  });

  Future<void> markDraftFuturePickup({
    required String token,
    required int draftOrderId,
  });

  Future<void> cancelOrder({
    required String token,
    required int orderId,
    String? reason,
  });

  Future<Map<String, dynamic>> fetchDraftDetails({
    required String token,
    required int draftOrderId,
  });
}
