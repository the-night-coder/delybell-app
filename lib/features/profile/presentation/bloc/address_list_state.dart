part of 'address_list_bloc.dart';

class AddressListState {
  const AddressListState({
    this.addresses = const [],
    this.loading = false,
    this.error,
    this.message,
  });

  final List<AddressEntity> addresses;
  final bool loading;
  final String? error;
  final String? message;

  AddressListState copyWith({
    List<AddressEntity>? addresses,
    bool? loading,
    String? error,
    String? message,
  }) {
    return AddressListState(
      addresses: addresses ?? this.addresses,
      loading: loading ?? this.loading,
      error: error,
      message: message,
    );
  }
}
