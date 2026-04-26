class LoginResponse {
  const LoginResponse({
    required this.status,
    required this.message,
    required this.token,
    required this.user,
  });

  final bool status;
  final String message;
  final String token;
  final LoginUser user;

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      status: json['status'] as bool? ?? false,
      message: json['message']?.toString() ?? '',
      token: json['token']?.toString() ?? '',
      user: LoginUser.fromJson(
        json['data'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'token': token,
      'data': user.toJson(),
    };
  }
}

class LoginUser {
  const LoginUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.companyName,
    required this.companyRegistrationNumber,
    required this.vatNumber,
    required this.addressLineOne,
    required this.addressLineTwo,
    required this.firstNameAr,
    required this.lastNameAr,
    required this.profilePicture,
    required this.nationalityId,
    required this.nationalityName,
    required this.roleName,
    required this.userTypeName,
    required this.userTypeId,
    required this.packageDescription,
    required this.addressFormatTypeId,
    required this.orderFlowTypes,
  });

  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String companyName;
  final String companyRegistrationNumber;
  final String vatNumber;
  final String addressLineOne;
  final String addressLineTwo;
  final String firstNameAr;
  final String lastNameAr;
  final String profilePicture;
  final int nationalityId;
  final String roleName;
  final String userTypeName;
  final String nationalityName;
  final int userTypeId;
  final String packageDescription;
  final int addressFormatTypeId;
  final List<OrderFlowType> orderFlowTypes;

  factory LoginUser.fromJson(Map<String, dynamic> json) {
    String _firstName(Map<String, dynamic> data) {
      return data['firstName']?.toString() ??
          data['first_name']?.toString() ??
          data['name']?.toString() ??
          '';
    }

    String _lastName(Map<String, dynamic> data) {
      return data['lastName']?.toString() ??
          data['last_name']?.toString() ??
          '';
    }

    String _phone(Map<String, dynamic> data) {
      return data['phone']?.toString() ??
          data['mobile']?.toString() ??
          data['mobile_number']?.toString() ??
          '';
    }

    int _intValue(Map<String, dynamic> data, String key) {
      final value = data[key];
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    return LoginUser(
      id: json['id'] as int? ?? 0,
      firstName: _firstName(json),
      lastName: _lastName(json),
      email: json['email']?.toString() ?? '',
      phone: _phone(json),
      companyName: json['companyName']?.toString() ?? '',
      companyRegistrationNumber:
          json['companyRegistrationNumber']?.toString() ?? '',
      vatNumber: json['vatNumber']?.toString() ?? '',
      addressLineOne: json['addressLineOne']?.toString() ?? '',
      addressLineTwo: json['addressLineTwo']?.toString() ?? '',
      firstNameAr: json['firstNameAr']?.toString() ?? '',
      lastNameAr: json['lastNameAr']?.toString() ?? '',
      profilePicture: json['profilePicture']?.toString() ?? '',
      nationalityId: _intValue(json, 'nationalityId'),
      roleName: (json['role'] as Map<String, dynamic>?)?['name']?.toString() ?? '',
      nationalityName: (json['nationalityDetails'] as Map<String, dynamic>?)?['name']?.toString() ?? '',
      userTypeName:
          (json['userType'] as Map<String, dynamic>?)?['name']?.toString() ??
          '',
      userTypeId: (json['userType'] as Map<String, dynamic>?)?['id'] ?? 0,
      packageDescription: json['package_description']?.toString() ??
          json['packageDescription']?.toString() ??
          '',
      addressFormatTypeId:
          _intValue((json['addressFormatType'] as Map<String, dynamic>?) ?? json, 'id') == 0
              ? _intValue(json, 'addressFormatTypeId')
              : _intValue((json['addressFormatType'] as Map<String, dynamic>?) ?? json, 'id'),
      orderFlowTypes: (json['order_flow_types'] as List<dynamic>? ??
              json['orderFlowTypes'] as List<dynamic>? ??
              const [])
          .whereType<Map<String, dynamic>>()
          .map(OrderFlowType.fromJson)
          .toList(),
    );
  }

  String get fullName =>
      [firstName, lastName].where((e) => e.isNotEmpty).join(' ');

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'companyName': companyName,
      'companyRegistrationNumber': companyRegistrationNumber,
      'vatNumber': vatNumber,
      'addressLineOne': addressLineOne,
      'addressLineTwo': addressLineTwo,
      'firstNameAr': firstNameAr,
      'lastNameAr': lastNameAr,
      'profilePicture': profilePicture,
      'nationalityId': nationalityId,
      'nationalityDetails': {'name': nationalityName, 'id': nationalityId},
      'nationalityName': nationalityName,
      'role': {'name': roleName},
      'userType': {'name': userTypeName, 'id': userTypeId},
      'package_description': packageDescription,
      'addressFormatType': {'id': addressFormatTypeId},
      'order_flow_types': orderFlowTypes.map((e) => e.toJson()).toList(),
    };
  }
}

class OrderFlowType {
  const OrderFlowType({
    required this.id,
    required this.name,
    required this.isActive,
  });

  final int id;
  final String name;
  final bool isActive;

  factory OrderFlowType.fromJson(Map<String, dynamic> json) {
    return OrderFlowType(
      id: json['id'] is String ? int.tryParse(json['id']) ?? 0 : (json['id'] ?? 0) as int,
      name: json['name']?.toString() ?? '',
      isActive: (json['isActive'] as num?) == 1 || json['isActive'] == true,
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'isActive': isActive ? 1 : 0};
}
