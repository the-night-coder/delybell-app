import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/static.dart';
import '../models/sign_up_type.dart';

class SignUpRepository {
  SignUpRepository({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<void> register({
    required String firstName,
    required String lastName,
    required String email,
    required String phoneNumber,
    required String countryDialCode,
    required String password,
    required String confirmPassword,
    required SignUpType signUpType,
    String nationality = '',
    String city = '',
    String road = '',
    String block = '',
    String building = '',
    String addressLine1 = '',
    String addressLine2 = '',
    String organizationName = '',
    String organizationRegNo = '',
    String vatNumber = '',
    String firstNameAr = '',
    String lastNameAr = '',
    String description = '',
  }) async {
    final uri = Uri.parse('${Static.baseUrl}initiate_registration');

    final Map<String, dynamic> body = {
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'phone': '$countryDialCode$phoneNumber',
      'password': password, // Usually empty string per requirements
      'confirm_password': confirmPassword,
      'user_type': 3,
      'user_type_id': signUpType == SignUpType.corporate ? "4" : "",
      'nationality': nationality,
      'city': city,
      'road': road,
      'block': block,
      'building': building,
      'address_line1': addressLine1,
      'address_line2': addressLine2,
      'organization_name': organizationName,
      'organization_reg_no': organizationRegNo,
      'vat_number': vatNumber,
      'first_name_ar': firstNameAr,
      'last_name_ar': lastNameAr,
      'description': description,
    };

    final response = await _client.post(
      uri,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_parseError(response.body));
    }
  }

  String _parseError(String body) {
    try {
      final decoded = jsonDecode(body) as Map<String, dynamic>;
      return decoded['message']?.toString() ?? 'Unable to create account';
    } catch (_) {
      return 'Unable to create account';
    }
  }
}
