part of 'login_bloc.dart';

enum LoginStatus { initial, loading, success, failure }

class LoginState extends Equatable {
  const LoginState({
    this.email = '',
    this.password = '',
    this.loginType = LoginType.user,
    this.isPasswordVisible = false,
    this.status = LoginStatus.initial,
    this.errorMessage,
    this.loginResult,
  });

  final String email;
  final String password;
  final LoginType loginType;
  final bool isPasswordVisible;
  final LoginStatus status;
  final String? errorMessage;
  final LoginResponse? loginResult;

  LoginState copyWith({
    String? email,
    String? password,
    LoginType? loginType,
    bool? isPasswordVisible,
    LoginStatus? status,
    String? errorMessage,
    LoginResponse? loginResult,
  }) {
    return LoginState(
      email: email ?? this.email,
      password: password ?? this.password,
      loginType: loginType ?? this.loginType,
      isPasswordVisible: isPasswordVisible ?? this.isPasswordVisible,
      status: status ?? this.status,
      errorMessage: errorMessage,
      loginResult: loginResult ?? this.loginResult,
    );
  }

  @override
  List<Object?> get props => [
        email,
        password,
        loginType,
        isPasswordVisible,
        status,
        errorMessage,
        loginResult,
      ];
}
