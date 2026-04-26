import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../data/login_repository.dart';
import '../models/login_response.dart';
import '../models/login_type.dart';

part 'login_event.dart';
part 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  LoginBloc(this._repository) : super(const LoginState()) {
    on<LoginEmailChanged>(_onEmailChanged);
    on<LoginPasswordChanged>(_onPasswordChanged);
    on<LoginTypeChanged>(_onLoginTypeChanged);
    on<LoginPasswordVisibilityToggled>(_onPasswordVisibilityToggled);
    on<LoginSubmitted>(_onLoginSubmitted);
  }

  final LoginRepository _repository;

  void _onEmailChanged(LoginEmailChanged event, Emitter<LoginState> emit) {
    emit(
      state.copyWith(
        email: event.email,
        status: LoginStatus.initial,
        errorMessage: null,
        loginResult: null,
      ),
    );
  }

  void _onPasswordChanged(
    LoginPasswordChanged event,
    Emitter<LoginState> emit,
  ) {
    emit(
      state.copyWith(
        password: event.password,
        status: LoginStatus.initial,
        errorMessage: null,
        loginResult: null,
      ),
    );
  }

  void _onLoginTypeChanged(
    LoginTypeChanged event,
    Emitter<LoginState> emit,
  ) {
    emit(
      state.copyWith(
        loginType: event.loginType,
        status: LoginStatus.initial,
        errorMessage: null,
        loginResult: null,
      ),
    );
  }

  void _onPasswordVisibilityToggled(
    LoginPasswordVisibilityToggled event,
    Emitter<LoginState> emit,
  ) {
    emit(
      state.copyWith(
        isPasswordVisible: !state.isPasswordVisible,
      ),
    );
  }

  Future<void> _onLoginSubmitted(
    LoginSubmitted event,
    Emitter<LoginState> emit,
  ) async {
    if (state.email.isEmpty || state.password.isEmpty) {
      emit(
        state.copyWith(
          status: LoginStatus.failure,
          errorMessage: 'Please fill in both email and password.',
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        status: LoginStatus.loading,
        errorMessage: null,
        loginResult: null,
      ),
    );

    try {
      final loginResult = await _repository.login(
        loginType: state.loginType,
        email: state.email,
        password: state.password,
      );
      emit(
        state.copyWith(
          status: LoginStatus.success,
          errorMessage: null,
          loginResult: loginResult,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: LoginStatus.failure,
          errorMessage: error.toString(),
          loginResult: null,
        ),
      );
    }
  }
}
