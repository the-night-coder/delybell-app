import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../data/login_repository.dart';

part 'forgot_password_event.dart';
part 'forgot_password_state.dart';

class ForgotPasswordBloc
    extends Bloc<ForgotPasswordEvent, ForgotPasswordState> {
  ForgotPasswordBloc(this._repository) : super(const ForgotPasswordState()) {
    on<ForgotPasswordEmailChanged>(_onEmailChanged);
    on<ForgotPasswordSubmitted>(_onSubmitted);
  }

  final LoginRepository _repository;

  void _onEmailChanged(
    ForgotPasswordEmailChanged event,
    Emitter<ForgotPasswordState> emit,
  ) {
    emit(state.copyWith(email: event.email));
  }

  Future<void> _onSubmitted(
    ForgotPasswordSubmitted event,
    Emitter<ForgotPasswordState> emit,
  ) async {
    final email = state.email.trim();
    if (email.isEmpty) {
      emit(
        state.copyWith(
          status: ForgotPasswordStatus.failure,
          errorMessage: 'Email is required',
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        status: ForgotPasswordStatus.loading,
        errorMessage: null,
        successMessage: null,
      ),
    );

    try {
      final message = await _repository.forgotPassword(email: email);
      emit(
        state.copyWith(
          status: ForgotPasswordStatus.success,
          successMessage: message,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ForgotPasswordStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }
}
