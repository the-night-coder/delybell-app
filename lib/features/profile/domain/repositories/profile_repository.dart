import 'package:delybell/login/models/login_response.dart';

abstract class ProfileRepository {
  Future<LoginResponse> updateProfile({
    required String token,
    required Map<String, dynamic> payload,
  });
}
