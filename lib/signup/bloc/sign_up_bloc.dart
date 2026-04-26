import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../data/sign_up_repository.dart';
import '../models/sign_up_type.dart';

part 'sign_up_event.dart';
part 'sign_up_state.dart';

class SignUpBloc extends Bloc<SignUpEvent, SignUpState> {
  SignUpBloc(this._repository) : super(const SignUpState()) {
    on<SignUpFirstNameChanged>(_onFirstNameChanged);
    on<SignUpLastNameChanged>(_onLastNameChanged);
    on<SignUpEmailChanged>(_onEmailChanged);
    on<SignUpCountryCodeChanged>(_onCountryCodeChanged);
    on<SignUpPhoneChanged>(_onPhoneChanged);
    on<SignUpPasswordChanged>(_onPasswordChanged);
    on<SignUpConfirmPasswordChanged>(_onConfirmPasswordChanged);
    on<SignUpTypeChanged>(_onTypeChanged);
    on<SignUpPasswordVisibilityToggled>(_onPasswordVisibilityToggled);
    on<SignUpConfirmPasswordVisibilityToggled>(
      _onConfirmPasswordVisibilityToggled,
    );
    on<SignUpNationalityChanged>(
      (event, emit) => emit(
        state.copyWith(nationality: event.nationality, errorMessage: null),
      ),
    );
    on<SignUpCityChanged>(
      (event, emit) =>
          emit(state.copyWith(city: event.city, errorMessage: null)),
    );
    on<SignUpRoadChanged>(
      (event, emit) =>
          emit(state.copyWith(road: event.road, errorMessage: null)),
    );
    on<SignUpBlockChanged>(
      (event, emit) =>
          emit(state.copyWith(block: event.block, errorMessage: null)),
    );
    on<SignUpBuildingChanged>(
      (event, emit) =>
          emit(state.copyWith(building: event.building, errorMessage: null)),
    );
    on<SignUpAddressLine1Changed>(
      (event, emit) =>
          emit(state.copyWith(addressLine1: event.address, errorMessage: null)),
    );
    on<SignUpAddressLine2Changed>(
      (event, emit) =>
          emit(state.copyWith(addressLine2: event.address, errorMessage: null)),
    );
    on<SignUpOrganizationNameChanged>(
      (event, emit) => emit(
        state.copyWith(organizationName: event.name, errorMessage: null),
      ),
    );
    on<SignUpOrganizationRegNoChanged>(
      (event, emit) => emit(
        state.copyWith(organizationRegNo: event.regNo, errorMessage: null),
      ),
    );
    on<SignUpVatNumberChanged>(
      (event, emit) =>
          emit(state.copyWith(vatNumber: event.vatNumber, errorMessage: null)),
    );
    on<SignUpFirstNameArChanged>(
      (event, emit) =>
          emit(state.copyWith(firstNameAr: event.name, errorMessage: null)),
    );
    on<SignUpLastNameArChanged>(
      (event, emit) =>
          emit(state.copyWith(lastNameAr: event.name, errorMessage: null)),
    );
    on<SignUpDescriptionChanged>(
      (event, emit) => emit(
        state.copyWith(description: event.description, errorMessage: null),
      ),
    );

    on<SignUpSubmitted>(_onSubmitted);
  }

  final SignUpRepository _repository;

  void _onFirstNameChanged(
    SignUpFirstNameChanged event,
    Emitter<SignUpState> emit,
  ) {
    emit(
      state.copyWith(
        firstName: event.firstName,
        status: SignUpStatus.initial,
        errorMessage: null,
      ),
    );
  }

  void _onLastNameChanged(
    SignUpLastNameChanged event,
    Emitter<SignUpState> emit,
  ) {
    emit(
      state.copyWith(
        lastName: event.lastName,
        status: SignUpStatus.initial,
        errorMessage: null,
      ),
    );
  }

  void _onEmailChanged(SignUpEmailChanged event, Emitter<SignUpState> emit) {
    emit(
      state.copyWith(
        email: event.email,
        status: SignUpStatus.initial,
        errorMessage: null,
      ),
    );
  }

  void _onCountryCodeChanged(
    SignUpCountryCodeChanged event,
    Emitter<SignUpState> emit,
  ) {
    emit(state.copyWith(countryCode: event.countryCode));
  }

  void _onPhoneChanged(SignUpPhoneChanged event, Emitter<SignUpState> emit) {
    emit(
      state.copyWith(
        phoneNumber: event.phone,
        status: SignUpStatus.initial,
        errorMessage: null,
      ),
    );
  }

  void _onPasswordChanged(
    SignUpPasswordChanged event,
    Emitter<SignUpState> emit,
  ) {
    emit(
      state.copyWith(
        password: event.password,
        status: SignUpStatus.initial,
        errorMessage: null,
      ),
    );
  }

  void _onConfirmPasswordChanged(
    SignUpConfirmPasswordChanged event,
    Emitter<SignUpState> emit,
  ) {
    emit(
      state.copyWith(
        confirmPassword: event.password,
        status: SignUpStatus.initial,
        errorMessage: null,
      ),
    );
  }

  void _onTypeChanged(SignUpTypeChanged event, Emitter<SignUpState> emit) {
    emit(
      state.copyWith(
        signUpType: event.signUpType,
        status: SignUpStatus.initial,
        errorMessage: null,
      ),
    );
  }

  void _onPasswordVisibilityToggled(
    SignUpPasswordVisibilityToggled event,
    Emitter<SignUpState> emit,
  ) {
    emit(state.copyWith(isPasswordVisible: !state.isPasswordVisible));
  }

  void _onConfirmPasswordVisibilityToggled(
    SignUpConfirmPasswordVisibilityToggled event,
    Emitter<SignUpState> emit,
  ) {
    emit(
      state.copyWith(isConfirmPasswordVisible: !state.isConfirmPasswordVisible),
    );
  }

  Future<void> _onSubmitted(
    SignUpSubmitted event,
    Emitter<SignUpState> emit,
  ) async {
    if (state.firstName.isEmpty ||
        state.lastName.isEmpty ||
        state.email.isEmpty ||
        state.phoneNumber.isEmpty) {
      emit(
        state.copyWith(
          status: SignUpStatus.failure,
          errorMessage: 'Please fill in all fields.',
        ),
      );
      return;
    }

    if (state.signUpType == SignUpType.corporate) {
      if (state.organizationName.isEmpty) {
        emit(
          state.copyWith(
            status: SignUpStatus.failure,
            errorMessage: 'Organization Name is required.',
          ),
        );
        return;
      }
    }

    emit(state.copyWith(status: SignUpStatus.loading, errorMessage: null));

    try {
      await _repository.register(
        firstName: state.firstName,
        lastName: state.lastName,
        email: state.email,
        phoneNumber: state.phoneNumber,
        countryDialCode: state.countryCode,
        password: state.password,
        confirmPassword: state.confirmPassword,
        signUpType: state.signUpType,
        nationality: state.nationality,
        city: state.city,
        road: state.road,
        block: state.block,
        building: state.building,
        addressLine1: state.addressLine1,
        addressLine2: state.addressLine2,
        organizationName: state.organizationName,
        organizationRegNo: state.organizationRegNo,
        vatNumber: state.vatNumber,
        firstNameAr: state.firstNameAr,
        lastNameAr: state.lastNameAr,
        description: state.description,
      );
      emit(state.copyWith(status: SignUpStatus.success));
    } catch (error) {
      emit(
        state.copyWith(
          status: SignUpStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }
}
