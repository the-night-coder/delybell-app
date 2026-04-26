import '../entities/address_entity.dart';

abstract class AddressRepository {
  Future<List<AddressEntity>> fetchAddresses({required String token});
  Future<void> updateAddress({
    required String token,
    required int id,
    required Map<String, dynamic> payload,
  });
  Future<void> createAddress({
    required String token,
    required Map<String, dynamic> payload,
  });
  Future<void> deleteAddress({
    required String token,
    required int id,
  });
  Future<void> markPrimary({
    required String token,
    required int id,
  });
}
