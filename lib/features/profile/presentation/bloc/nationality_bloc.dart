import 'package:bloc/bloc.dart';

import '../../../../core/error_utils.dart';
import '../../domain/entities/nationality.dart';
import '../../domain/repositories/nationality_repository.dart';

class NationalityState {
  const NationalityState({
    this.loading = false,
    this.items = const [],
    this.error,
    this.search = '',
  });

  final bool loading;
  final List<Nationality> items;
  final String? error;
  final String search;

  NationalityState copyWith({
    bool? loading,
    List<Nationality>? items,
    String? error,
    String? search,
  }) {
    return NationalityState(
      loading: loading ?? this.loading,
      items: items ?? this.items,
      error: error,
      search: search ?? this.search,
    );
  }
}

abstract class NationalityEvent {
  const NationalityEvent();
}

class NationalitiesRequested extends NationalityEvent {
  const NationalitiesRequested({this.search = ''});
  final String search;
}

class NationalityBloc extends Bloc<NationalityEvent, NationalityState> {
  NationalityBloc({required this.repository, required this.token})
      : super(const NationalityState()) {
    on<NationalitiesRequested>(_onRequested);
  }

  final NationalityRepository repository;
  final String token;

  Future<void> _onRequested(
    NationalitiesRequested event,
    Emitter<NationalityState> emit,
  ) async {
    emit(
      state.copyWith(
        loading: true,
        error: null,
        search: event.search,
      ),
    );
    try {
      final items = await repository.fetchNationalities(
        token: token,
        search: event.search,
      );
      emit(
        state.copyWith(
          loading: false,
          items: items,
          error: null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          loading: false,
          error: ErrorUtils.friendly(
            e.toString(),
            fallback: 'Failed to load nationalities',
          ),
        ),
      );
    }
  }
}
