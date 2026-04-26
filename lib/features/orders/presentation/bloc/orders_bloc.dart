import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../domain/repositories/orders_repository.dart';
import '../../../../features/dashboard/domain/repositories/dashboard_repository.dart';
import '../../../../dashboard/models/order_summary.dart';
import '../../domain/usecases/get_orders.dart';
import 'package:delybell/core/error_utils.dart';

part 'orders_event.dart';
part 'orders_state.dart';

class OrdersBloc extends Bloc<OrdersEvent, OrdersState> {
  OrdersBloc(
    OrdersRepository ordersRepository, {
    required this.token,
    required DashboardRepository dashboardRepository,
  })  : _dashboardRepository = dashboardRepository,
        _getOrders = GetOrders(ordersRepository),
        _ordersRepository = ordersRepository,
        super(const OrdersState()) {
    on<OrdersRequested>(_onRequested);
    on<OrdersLoadMore>(_onLoadMore);
    on<OrdersRefreshed>(_onRefreshed);
    on<OrdersTabChanged>(_onTabChanged);
    on<OrdersCountsRequested>(_onCountsRequested);
    on<OrdersDraftDeleteRequested>(_onDraftDelete);
    on<OrdersDraftClearRequested>(_onDraftClear);
    on<OrdersDraftPlaceRequested>(_onDraftPlace);
    on<OrdersDraftFuturePickupRequested>(_onDraftFuturePickup);
  }

  final String token;
  final DashboardRepository _dashboardRepository;
  final GetOrders _getOrders;
  final OrdersRepository _ordersRepository;

  Future<void> _onRequested(OrdersRequested event, Emitter<OrdersState> emit) async {
    final search = event.search ?? state.searchTerm;
    add(const OrdersCountsRequested());
    await _loadPage(emit, page: 1, reset: event.reset, search: search, tab: state.tab);
  }

  Future<void> _onRefreshed(OrdersRefreshed event, Emitter<OrdersState> emit) async {
    add(const OrdersCountsRequested());
    await _loadPage(
      emit,
      page: 1,
      reset: true,
      search: state.searchTerm,
      tab: state.tab,
    );
  }

  Future<void> _onLoadMore(OrdersLoadMore event, Emitter<OrdersState> emit) async {
    if (state.isLoadingMore || !state.hasMore) return;
    await _loadPage(
      emit,
      page: state.currentPage + 1,
      append: true,
      search: state.searchTerm,
      tab: state.tab,
    );
  }

  Future<void> _onTabChanged(OrdersTabChanged event, Emitter<OrdersState> emit) async {
    emit(
      state.copyWith(
        tab: event.tab,
        orders: const [],
        currentPage: 1,
        lastPage: 1,
        status: OrdersStatus.loading,
      ),
    );
    await _loadPage(
      emit,
      page: 1,
      reset: true,
      search: state.searchTerm,
      tab: event.tab,
    );
  }

  Future<void> _onCountsRequested(
    OrdersCountsRequested event,
    Emitter<OrdersState> emit,
  ) async {
    final cached = await _dashboardRepository.loadCachedSummary();
    if (cached != null) {
      emit(
        state.copyWith(
          draftCount: cached.draftOrders,
          inProgressCount: cached.liveOrders,
          completedCount: cached.deliveredOrders,
          canceledCount: cached.cancelledOrders,
        ),
      );
    }
    try {
      final fresh = await _dashboardRepository.fetchDashboard(token: token);
      emit(
        state.copyWith(
          draftCount: fresh.draftOrders,
          inProgressCount: fresh.liveOrders,
          completedCount: fresh.deliveredOrders,
          canceledCount: fresh.cancelledOrders,
        ),
      );
    } catch (_) {}
  }

  Future<void> _loadPage(
    Emitter<OrdersState> emit, {
    required int page,
    bool reset = false,
    bool append = false,
    String search = '',
    OrderTab tab = OrderTab.inprogress,
  }) async {
    final loadId = state.requestId + 1;
    final initialOrders = append || reset ? state.orders : <OrderSummary>[];
    emit(
      state.copyWith(
        status: append ? OrdersStatus.success : OrdersStatus.loading,
        errorMessage: null,
        isLoadingMore: append,
        orders: append ? state.orders : initialOrders,
        currentPage: append ? state.currentPage : 1,
        searchTerm: search,
        tab: tab,
        requestId: loadId,
      ),
    );

    try {
      String? endpoint;
      String? filter;
      switch (tab) {
        case OrderTab.draft:
          endpoint = 'customer/order/draft/list';
          break;
        case OrderTab.completed:
          filter = '10';
          break;
        case OrderTab.canceled:
          filter = '12';
          break;
        case OrderTab.inprogress:
          break;
      }

      final result = await _getOrders(
        token: token,
        page: page,
        search: search,
        endpoint: endpoint,
        filterByDeliveryStatus: filter,
      );
      final merged = append ? [...state.orders, ...result.orders] : result.orders;

      if (state.requestId == loadId) {
        emit(
          state.copyWith(
            status: OrdersStatus.success,
            orders: merged,
            currentPage: result.currentPage,
            lastPage: result.lastPage,
            isLoadingMore: false,
          ),
        );
      }
    } catch (error) {
      if (state.requestId == loadId) {
        emit(
          state.copyWith(
            status: OrdersStatus.failure,
            errorMessage: ErrorUtils.friendly(error.toString()),
            isLoadingMore: false,
          ),
        );
      }
    }
  }

  Future<void> _onDraftDelete(
    OrdersDraftDeleteRequested event,
    Emitter<OrdersState> emit,
  ) async {
    try {
      await _ordersRepository.deleteDraftOrder(token: token, draftOrderId: event.id);
      add(const OrdersRefreshed());
    } catch (error) {
      emit(state.copyWith(errorMessage: ErrorUtils.friendly(error.toString())));
    }
  }

  Future<void> _onDraftClear(
    OrdersDraftClearRequested event,
    Emitter<OrdersState> emit,
  ) async {
    try {
      await _ordersRepository.clearDraftOrders(token: token);
      add(const OrdersRefreshed());
    } catch (error) {
      emit(state.copyWith(errorMessage: ErrorUtils.friendly(error.toString())));
    }
  }

  Future<void> _onDraftPlace(
    OrdersDraftPlaceRequested event,
    Emitter<OrdersState> emit,
  ) async {
    emit(state.copyWith(isPlacingDraft: true, errorMessage: null));
    try {
      final dateStr = (event.pickupDate ?? DateTime.now())
          .toIso8601String()
          .substring(0, 10);
      await _ordersRepository.placeDraftOrders(
        token: token,
        payload: {
          'pickup_preference_date': dateStr,
          'pickup_slot_type': event.pickupSlotType,
          if (event.deliverySlotType != null)
            'delivery_slot_type': event.deliverySlotType,
        },
      );
      emit(state.copyWith(isPlacingDraft: false));
      add(const OrdersRefreshed());
    } catch (error) {
      emit(state.copyWith(
        isPlacingDraft: false,
        errorMessage: ErrorUtils.friendly(error.toString()),
      ));
    }
  }

  Future<void> _onDraftFuturePickup(
    OrdersDraftFuturePickupRequested event,
    Emitter<OrdersState> emit,
  ) async {
    try {
      await _ordersRepository.markDraftFuturePickup(
        token: token,
        draftOrderId: event.id,
      );
      emit(state.copyWith(errorMessage: null));
      add(const OrdersRefreshed());
    } catch (error) {
      emit(state.copyWith(errorMessage: ErrorUtils.friendly(error.toString())));
    }
  }
}
