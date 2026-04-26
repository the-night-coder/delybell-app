import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error_utils.dart';
import '../../domain/entities/invoice.dart';
import '../../domain/entities/invoice_page.dart';
import '../../domain/repositories/invoices_repository.dart';

part 'invoices_event.dart';
part 'invoices_state.dart';

enum InvoiceTab { paid, unpaid }

class InvoicesBloc extends Bloc<InvoicesEvent, InvoicesState> {
  InvoicesBloc(this._repository, {required this.token})
      : super(const InvoicesState(status: InvoiceStatus.loading)) {
    on<InvoicesRequested>(_onRequested);
    on<InvoicesLoadMore>(_onLoadMore);
    on<InvoicesTabChanged>(_onTabChanged);
    on<InvoicesRefreshed>(_onRefreshed);
  }

  final InvoicesRepository _repository;
  final String token;

  Future<void> _onRequested(
    InvoicesRequested event,
    Emitter<InvoicesState> emit,
  ) async {
    final search = event.search ?? state.searchTerm;
    await _loadPage(
      emit,
      page: 1,
      reset: event.reset,
      search: search,
      tab: state.tab,
    );
  }

  Future<void> _onRefreshed(
    InvoicesRefreshed event,
    Emitter<InvoicesState> emit,
  ) async {
    await _loadPage(
      emit,
      page: 1,
      reset: true,
      search: state.searchTerm,
      tab: state.tab,
    );
  }

  Future<void> _onLoadMore(
    InvoicesLoadMore event,
    Emitter<InvoicesState> emit,
  ) async {
    if (state.isLoadingMore || !state.hasMore) return;
    await _loadPage(
      emit,
      page: state.currentPage + 1,
      append: true,
      search: state.searchTerm,
      tab: state.tab,
    );
  }

  Future<void> _onTabChanged(
    InvoicesTabChanged event,
    Emitter<InvoicesState> emit,
  ) async {
    emit(
      state.copyWith(
        tab: event.tab,
        invoices: const [],
        currentPage: 1,
        lastPage: 1,
        status: InvoiceStatus.loading,
        errorMessage: '',
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

  Future<void> _loadPage(
    Emitter<InvoicesState> emit, {
    required int page,
    bool reset = false,
    bool append = false,
    String search = '',
    InvoiceTab tab = InvoiceTab.unpaid,
  }) async {
    if (!append) {
      emit(
        state.copyWith(
          status: InvoiceStatus.loading,
          errorMessage: '',
          searchTerm: search,
          currentPage: reset ? 1 : state.currentPage,
          lastPage: reset ? 1 : state.lastPage,
        ),
      );
    } else {
      emit(state.copyWith(isLoadingMore: true));
    }

    try {
      final InvoicePage pageData = await _repository.fetchInvoices(
        token: token,
        page: page,
        search: search,
        paymentStatus: _paymentStatusForTab(tab),
      );
      final combined =
          append ? [...state.invoices, ...pageData.invoices] : pageData.invoices;
      emit(
        state.copyWith(
          invoices: combined,
          status: InvoiceStatus.success,
          currentPage: pageData.currentPage,
          lastPage: pageData.lastPage,
          searchTerm: search,
          isLoadingMore: false,
          errorMessage: '',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: append ? state.status : InvoiceStatus.failure,
          errorMessage: ErrorUtils.friendly(e.toString()),
          isLoadingMore: false,
        ),
      );
    }
  }

  int? _paymentStatusForTab(InvoiceTab tab) {
    return tab == InvoiceTab.paid ? 2 : 1;
  }
}
