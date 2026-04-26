part of 'orders_bloc.dart';

abstract class OrdersEvent extends Equatable {
  const OrdersEvent();

  @override
  List<Object?> get props => [];
}

class OrdersRequested extends OrdersEvent {
  const OrdersRequested({this.reset = false, this.search});

  final bool reset;
  final String? search;
}

class OrdersRefreshed extends OrdersEvent {
  const OrdersRefreshed();
}

class OrdersLoadMore extends OrdersEvent {
  const OrdersLoadMore();
}

class OrdersTabChanged extends OrdersEvent {
  const OrdersTabChanged(this.tab);

  final OrderTab tab;

  @override
  List<Object?> get props => [tab];
}

class OrdersCountsRequested extends OrdersEvent {
  const OrdersCountsRequested();
}

class OrdersDraftDeleteRequested extends OrdersEvent {
  const OrdersDraftDeleteRequested(this.id);
  final int id;

  @override
  List<Object?> get props => [id];
}

class OrdersDraftClearRequested extends OrdersEvent {
  const OrdersDraftClearRequested();
}

class OrdersDraftPlaceRequested extends OrdersEvent {
  const OrdersDraftPlaceRequested({
    required this.pickupSlotType,
    this.deliverySlotType,
    this.pickupDate,
  });

  final int pickupSlotType;
  final int? deliverySlotType;
  final DateTime? pickupDate;

  @override
  List<Object?> get props => [pickupSlotType, deliverySlotType, pickupDate];
}

class OrdersDraftFuturePickupRequested extends OrdersEvent {
  const OrdersDraftFuturePickupRequested(this.id);
  final int id;

  @override
  List<Object?> get props => [id];
}
