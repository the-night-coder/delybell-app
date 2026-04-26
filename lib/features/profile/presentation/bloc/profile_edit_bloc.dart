import 'package:bloc/bloc.dart';

import 'package:delybell/core/error_utils.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../../../login/models/login_response.dart';

class ProfileEditState {
  const ProfileEditState({
    this.submitting = false,
    this.success = false,
    this.error,
    this.loginResponse,
  });

  final bool submitting;
  final bool success;
  final String? error;
  final LoginResponse? loginResponse;

  ProfileEditState copyWith({
    bool? submitting,
    bool? success,
    String? error,
    LoginResponse? loginResponse,
  }) {
    return ProfileEditState(
      submitting: submitting ?? this.submitting,
      success: success ?? this.success,
      error: error,
      loginResponse: loginResponse ?? this.loginResponse,
    );
  }
}

class ProfileEditEvent {
  const ProfileEditEvent({required this.payload});
  final Map<String, dynamic> payload;
}

class ProfileEditBloc extends Bloc<ProfileEditEvent, ProfileEditState> {
  ProfileEditBloc({required this.repository, required this.token})
      : super(const ProfileEditState()) {
    on<ProfileEditEvent>(_onSubmit);
  }

  final ProfileRepository repository;
  final String token;

  Future<void> _onSubmit(
    ProfileEditEvent event,
    Emitter<ProfileEditState> emit,
  ) async {
    emit(state.copyWith(submitting: true, error: null, success: false));
    try {
      final response = await repository.updateProfile(token: token, payload: event.payload);
      emit(
        state.copyWith(
          submitting: false,
          success: true,
          loginResponse: response,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          submitting: false,
          error: ErrorUtils.friendly(e.toString()),
        ),
      );
    }
  }
}
