part of 'orders_bloc.dart';

enum OrdersStatus { initial, loading, success, failure }
enum OrderTab { draft, inprogress, completed, canceled }

class OrdersState extends Equatable {
  const OrdersState({
    this.status = OrdersStatus.initial,
    this.orders = const [],
    this.errorMessage,
    this.currentPage = 1,
    this.lastPage = 1,
    this.isLoadingMore = false,
    this.searchTerm = '',
    this.tab = OrderTab.draft,
    this.draftCount = 0,
    this.inProgressCount = 0,
    this.completedCount = 0,
    this.canceledCount = 0,
    this.isPlacingDraft = false,
    this.requestId = 0,
  });

  final OrdersStatus status;
  final List<OrderSummary> orders;
  final String? errorMessage;
  final int currentPage;
  final int lastPage;
  final bool isLoadingMore;
  final String searchTerm;
  final OrderTab tab;
  final int draftCount;
  final int inProgressCount;
  final int completedCount;
  final int canceledCount;
  final bool isPlacingDraft;
  final int requestId;

  bool get hasMore => currentPage < lastPage;

  OrdersState copyWith({
    OrdersStatus? status,
    List<OrderSummary>? orders,
    String? errorMessage,
    int? currentPage,
    int? lastPage,
    bool? isLoadingMore,
    String? searchTerm,
    OrderTab? tab,
    int? draftCount,
    int? inProgressCount,
    int? completedCount,
    int? canceledCount,
    bool? isPlacingDraft,
    int? requestId,
  }) {
    return OrdersState(
      status: status ?? this.status,
      orders: orders ?? this.orders,
      errorMessage: errorMessage,
      currentPage: currentPage ?? this.currentPage,
      lastPage: lastPage ?? this.lastPage,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      searchTerm: searchTerm ?? this.searchTerm,
      tab: tab ?? this.tab,
      draftCount: draftCount ?? this.draftCount,
      inProgressCount: inProgressCount ?? this.inProgressCount,
      completedCount: completedCount ?? this.completedCount,
      canceledCount: canceledCount ?? this.canceledCount,
      isPlacingDraft: isPlacingDraft ?? this.isPlacingDraft,
      requestId: requestId ?? this.requestId,
    );
  }

  @override
  List<Object?> get props => [
        status,
        orders,
        errorMessage,
        currentPage,
        lastPage,
        isLoadingMore,
        searchTerm,
        tab,
        draftCount,
        inProgressCount,
        completedCount,
        canceledCount,
        isPlacingDraft,
        requestId,
      ];
}
