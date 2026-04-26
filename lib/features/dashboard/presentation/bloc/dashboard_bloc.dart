import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../domain/usecases/get_dashboard_summary.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../../../../dashboard/models/dashboard_summary.dart';

part 'dashboard_event.dart';
part 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  DashboardBloc(
    DashboardRepository repository, {
    required this.token,
  })  : _repository = repository,
        _getDashboardSummary = GetDashboardSummary(repository),
        super(const DashboardState()) {
    on<DashboardRequested>(_onRequested);
    on<DashboardRefreshed>(_onRefreshed);
  }

  final DashboardRepository _repository;
  final String token;
  final GetDashboardSummary _getDashboardSummary;

  Future<void> _onRequested(
    DashboardRequested event,
    Emitter<DashboardState> emit,
  ) async {
    await _fetchDashboard(emit, resetData: event.resetData);
  }

  Future<void> _onRefreshed(
    DashboardRefreshed event,
    Emitter<DashboardState> emit,
  ) async {
    await _fetchDashboard(emit);
  }

  Future<void> _fetchDashboard(
    Emitter<DashboardState> emit, {
    bool resetData = false,
  }) async {
    final hasExisting = !resetData && state.summary != null;
    bool emittedCached = false;

    if (!hasExisting) {
      final cached = await _repository.loadCachedSummary();
      if (cached != null) {
        emittedCached = true;
        emit(
          state.copyWith(
            status: DashboardStatus.success,
            errorMessage: null,
            summary: cached,
          ),
        );
      } else {
        emit(
          state.copyWith(
            status: DashboardStatus.loading,
            errorMessage: null,
            summary: resetData ? null : state.summary,
          ),
        );
      }
    } else {
      emit(
        state.copyWith(
          status: DashboardStatus.success,
          errorMessage: null,
        ),
      );
    }

    try {
      final summary = await _getDashboardSummary(token: token);
      emit(
        state.copyWith(
          status: DashboardStatus.success,
          errorMessage: null,
          summary: summary,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: emittedCached || hasExisting ? DashboardStatus.success : DashboardStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }
}
