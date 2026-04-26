part of 'sign_up_bloc.dart';

enum SignUpStatus { initial, loading, success, failure }

class SignUpState extends Equatable {
  const SignUpState({
    this.firstName = '',
    this.lastName = '',
    this.email = '',
    this.countryCode = '+973',
    this.phoneNumber = '',
    this.password = '',
    this.confirmPassword = '',
    this.signUpType = SignUpType.user,
    this.isPasswordVisible = false,
    this.isConfirmPasswordVisible = false,
    this.status = SignUpStatus.initial,
    this.errorMessage,
  });

  final String firstName;
  final String lastName;
  final String email;
  final String countryCode;
  final String phoneNumber;
  final String password;
  final String confirmPassword;
  final SignUpType signUpType;
  final bool isPasswordVisible;
  final bool isConfirmPasswordVisible;
  final SignUpStatus status;
  final String? errorMessage;

  SignUpState copyWith({
    String? firstName,
    String? lastName,
    String? email,
    String? countryCode,
    String? phoneNumber,
    String? password,
    String? confirmPassword,
    SignUpType? signUpType,
    bool? isPasswordVisible,
    bool? isConfirmPasswordVisible,
    SignUpStatus? status,
    String? errorMessage,
  }) {
    return SignUpState(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      countryCode: countryCode ?? this.countryCode,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      signUpType: signUpType ?? this.signUpType,
      isPasswordVisible: isPasswordVisible ?? this.isPasswordVisible,
      isConfirmPasswordVisible:
          isConfirmPasswordVisible ?? this.isConfirmPasswordVisible,
      status: status ?? this.status,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        firstName,
        lastName,
        email,
        countryCode,
        phoneNumber,
        password,
        confirmPassword,
        signUpType,
        isPasswordVisible,
        isConfirmPasswordVisible,
        status,
        errorMessage,
      ];
}
