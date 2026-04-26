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
    this.nationality = '',
    this.city = '',
    this.road = '',
    this.block = '',
    this.building = '',
    this.addressLine1 = '',
    this.addressLine2 = '',
    this.organizationName = '',
    this.organizationRegNo = '',
    this.vatNumber = '',
    this.firstNameAr = '',
    this.lastNameAr = '',
    this.description = '',
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

  final String nationality;
  final String city;
  final String road;
  final String block;
  final String building;
  final String addressLine1;
  final String addressLine2;
  final String organizationName;
  final String organizationRegNo;
  final String vatNumber;
  final String firstNameAr;
  final String lastNameAr;
  final String description;

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
    String? nationality,
    String? city,
    String? road,
    String? block,
    String? building,
    String? addressLine1,
    String? addressLine2,
    String? organizationName,
    String? organizationRegNo,
    String? vatNumber,
    String? firstNameAr,
    String? lastNameAr,
    String? description,
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
      nationality: nationality ?? this.nationality,
      city: city ?? this.city,
      road: road ?? this.road,
      block: block ?? this.block,
      building: building ?? this.building,
      addressLine1: addressLine1 ?? this.addressLine1,
      addressLine2: addressLine2 ?? this.addressLine2,
      organizationName: organizationName ?? this.organizationName,
      organizationRegNo: organizationRegNo ?? this.organizationRegNo,
      vatNumber: vatNumber ?? this.vatNumber,
      firstNameAr: firstNameAr ?? this.firstNameAr,
      lastNameAr: lastNameAr ?? this.lastNameAr,
      description: description ?? this.description,
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
    nationality,
    city,
    road,
    block,
    building,
    addressLine1,
    addressLine2,
    organizationName,
    organizationRegNo,
    vatNumber,
    firstNameAr,
    lastNameAr,
    description,
  ];
}
