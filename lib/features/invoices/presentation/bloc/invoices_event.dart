part of 'invoices_bloc.dart';

abstract class InvoicesEvent extends Equatable {
  const InvoicesEvent();

  @override
  List<Object?> get props => [];
}

class InvoicesRequested extends InvoicesEvent {
  const InvoicesRequested({this.search, this.reset = false});

  final String? search;
  final bool reset;

  @override
  List<Object?> get props => [search, reset];
}

class InvoicesLoadMore extends InvoicesEvent {
  const InvoicesLoadMore();
}

class InvoicesTabChanged extends InvoicesEvent {
  const InvoicesTabChanged(this.tab);

  final InvoiceTab tab;

  @override
  List<Object?> get props => [tab];
}

class InvoicesRefreshed extends InvoicesEvent {
  const InvoicesRefreshed();
}
