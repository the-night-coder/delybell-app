part of 'sign_up_bloc.dart';

abstract class SignUpEvent extends Equatable {
  const SignUpEvent();

  @override
  List<Object?> get props => [];
}

class SignUpFirstNameChanged extends SignUpEvent {
  const SignUpFirstNameChanged(this.firstName);
  final String firstName;

  @override
  List<Object?> get props => [firstName];
}

class SignUpLastNameChanged extends SignUpEvent {
  const SignUpLastNameChanged(this.lastName);
  final String lastName;

  @override
  List<Object?> get props => [lastName];
}

class SignUpEmailChanged extends SignUpEvent {
  const SignUpEmailChanged(this.email);
  final String email;

  @override
  List<Object?> get props => [email];
}

class SignUpCountryCodeChanged extends SignUpEvent {
  const SignUpCountryCodeChanged(this.countryCode);
  final String countryCode;

  @override
  List<Object?> get props => [countryCode];
}

class SignUpPhoneChanged extends SignUpEvent {
  const SignUpPhoneChanged(this.phone);
  final String phone;

  @override
  List<Object?> get props => [phone];
}

class SignUpPasswordChanged extends SignUpEvent {
  const SignUpPasswordChanged(this.password);
  final String password;

  @override
  List<Object?> get props => [password];
}

class SignUpConfirmPasswordChanged extends SignUpEvent {
  const SignUpConfirmPasswordChanged(this.password);
  final String password;

  @override
  List<Object?> get props => [password];
}

class SignUpTypeChanged extends SignUpEvent {
  const SignUpTypeChanged(this.signUpType);
  final SignUpType signUpType;

  @override
  List<Object?> get props => [signUpType];
}

class SignUpPasswordVisibilityToggled extends SignUpEvent {
  const SignUpPasswordVisibilityToggled();
}

class SignUpConfirmPasswordVisibilityToggled extends SignUpEvent {
  const SignUpConfirmPasswordVisibilityToggled();
}

class SignUpSubmitted extends SignUpEvent {
  const SignUpSubmitted();
}
