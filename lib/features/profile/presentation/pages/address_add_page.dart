import 'package:flutter/material.dart';
import '../../domain/entities/address_entity.dart';
import '../../domain/repositories/address_repository.dart';
import 'address_form_page.dart';

class AddressAddPage extends StatelessWidget {
  const AddressAddPage({
    super.key,
    required this.token,
    required this.repository,
    this.forcePrimary = false,
  });

  final String token;
  final AddressRepository repository;
  final bool forcePrimary;

  @override
  Widget build(BuildContext context) {
    return AddressFormPage(
      address: AddressEntity.empty(),
      token: token,
      isCreate: true,
      repository: repository,
      forcePrimary: forcePrimary,
    );
  }
}
