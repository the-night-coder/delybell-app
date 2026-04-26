part of 'order_tracking_bloc.dart';

abstract class OrderTrackingEvent extends Equatable {
  const OrderTrackingEvent();

  @override
  List<Object?> get props => [];
}

class OrderTrackingRequested extends OrderTrackingEvent {
  const OrderTrackingRequested({required this.orderId});

  final int orderId;

  @override
  List<Object?> get props => [orderId];
}
