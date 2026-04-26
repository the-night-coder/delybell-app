part of 'dashboard_bloc.dart';

sealed class DashboardEvent extends Equatable {
  const DashboardEvent();

  @override
  List<Object?> get props => [];
}

class DashboardRequested extends DashboardEvent {
  const DashboardRequested({this.resetData = false});

  final bool resetData;

  @override
  List<Object?> get props => [resetData];
}

class DashboardRefreshed extends DashboardEvent {
  const DashboardRefreshed();
}
