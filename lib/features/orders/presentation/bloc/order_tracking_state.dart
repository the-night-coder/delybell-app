part of 'order_tracking_bloc.dart';

enum OrderTrackingStatus { initial, loading, success, failure }

class OrderTrackingState extends Equatable {
  const OrderTrackingState({
    this.status = OrderTrackingStatus.initial,
    this.tracking,
    this.errorMessage,
  });

  final OrderTrackingStatus status;
  final OrderTracking? tracking;
  final String? errorMessage;

  OrderTrackingState copyWith({
    OrderTrackingStatus? status,
    OrderTracking? tracking,
    String? errorMessage,
  }) {
    return OrderTrackingState(
      status: status ?? this.status,
      tracking: tracking ?? this.tracking,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, tracking, errorMessage];
}
