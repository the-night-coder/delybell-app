import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../domain/repositories/orders_repository.dart';
import '../../domain/usecases/get_order_tracking.dart';
import '../../../../dashboard/models/order_tracking.dart';

part 'order_tracking_event.dart';
part 'order_tracking_state.dart';

class OrderTrackingBloc extends Bloc<OrderTrackingEvent, OrderTrackingState> {
  OrderTrackingBloc(OrdersRepository ordersRepository, {required this.token})
      : _getOrderTracking = GetOrderTracking(ordersRepository),
        super(const OrderTrackingState()) {
    on<OrderTrackingRequested>(_onRequested);
  }

  final String token;
  final GetOrderTracking _getOrderTracking;

  Future<void> _onRequested(
    OrderTrackingRequested event,
    Emitter<OrderTrackingState> emit,
  ) async {
    emit(state.copyWith(status: OrderTrackingStatus.loading, errorMessage: null));
    try {
      final tracking = await _getOrderTracking(token: token, orderId: event.orderId);
      emit(
        state.copyWith(
          status: OrderTrackingStatus.success,
          tracking: tracking,
          errorMessage: null,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: OrderTrackingStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }
}
