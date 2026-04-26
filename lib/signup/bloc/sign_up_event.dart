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

class SignUpNationalityChanged extends SignUpEvent {
  const SignUpNationalityChanged(this.nationality);
  final String nationality;
  @override
  List<Object?> get props => [nationality];
}

class SignUpCityChanged extends SignUpEvent {
  const SignUpCityChanged(this.city);
  final String city;
  @override
  List<Object?> get props => [city];
}

class SignUpRoadChanged extends SignUpEvent {
  const SignUpRoadChanged(this.road);
  final String road;
  @override
  List<Object?> get props => [road];
}

class SignUpBlockChanged extends SignUpEvent {
  const SignUpBlockChanged(this.block);
  final String block;
  @override
  List<Object?> get props => [block];
}

class SignUpBuildingChanged extends SignUpEvent {
  const SignUpBuildingChanged(this.building);
  final String building;
  @override
  List<Object?> get props => [building];
}

class SignUpAddressLine1Changed extends SignUpEvent {
  const SignUpAddressLine1Changed(this.address);
  final String address;
  @override
  List<Object?> get props => [address];
}

class SignUpAddressLine2Changed extends SignUpEvent {
  const SignUpAddressLine2Changed(this.address);
  final String address;
  @override
  List<Object?> get props => [address];
}

class SignUpOrganizationNameChanged extends SignUpEvent {
  const SignUpOrganizationNameChanged(this.name);
  final String name;
  @override
  List<Object?> get props => [name];
}

class SignUpOrganizationRegNoChanged extends SignUpEvent {
  const SignUpOrganizationRegNoChanged(this.regNo);
  final String regNo;
  @override
  List<Object?> get props => [regNo];
}

class SignUpVatNumberChanged extends SignUpEvent {
  const SignUpVatNumberChanged(this.vatNumber);
  final String vatNumber;
  @override
  List<Object?> get props => [vatNumber];
}

class SignUpFirstNameArChanged extends SignUpEvent {
  const SignUpFirstNameArChanged(this.name);
  final String name;
  @override
  List<Object?> get props => [name];
}

class SignUpLastNameArChanged extends SignUpEvent {
  const SignUpLastNameArChanged(this.name);
  final String name;
  @override
  List<Object?> get props => [name];
}

class SignUpDescriptionChanged extends SignUpEvent {
  const SignUpDescriptionChanged(this.description);
  final String description;
  @override
  List<Object?> get props => [description];
}
