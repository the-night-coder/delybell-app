part of 'invoices_bloc.dart';

enum InvoiceStatus { initial, loading, success, failure }

class InvoicesState extends Equatable {
  const InvoicesState({
    this.invoices = const [],
    this.status = InvoiceStatus.initial,
    this.currentPage = 1,
    this.lastPage = 1,
    this.searchTerm = '',
    this.tab = InvoiceTab.unpaid,
    this.errorMessage = '',
    this.isLoadingMore = false,
  });

  final List<Invoice> invoices;
  final InvoiceStatus status;
  final int currentPage;
  final int lastPage;
  final String searchTerm;
  final InvoiceTab tab;
  final String errorMessage;
  final bool isLoadingMore;

  bool get hasMore => currentPage < lastPage;

  InvoicesState copyWith({
    List<Invoice>? invoices,
    InvoiceStatus? status,
    int? currentPage,
    int? lastPage,
    String? searchTerm,
    InvoiceTab? tab,
    String? errorMessage,
    bool? isLoadingMore,
  }) {
    return InvoicesState(
      invoices: invoices ?? this.invoices,
      status: status ?? this.status,
      currentPage: currentPage ?? this.currentPage,
      lastPage: lastPage ?? this.lastPage,
      searchTerm: searchTerm ?? this.searchTerm,
      tab: tab ?? this.tab,
      errorMessage: errorMessage ?? this.errorMessage,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object?> get props => [
        invoices,
        status,
        currentPage,
        lastPage,
        searchTerm,
        tab,
        errorMessage,
        isLoadingMore,
      ];
}
