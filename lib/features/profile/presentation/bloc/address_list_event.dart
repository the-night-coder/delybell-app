part of 'address_list_bloc.dart';

abstract class AddressListEvent {
  const AddressListEvent();
}

class AddressListRequested extends AddressListEvent {
  const AddressListRequested();
}

class AddressMarkPrimaryRequested extends AddressListEvent {
  const AddressMarkPrimaryRequested(this.id);
  final int id;
}

class AddressDeleteRequested extends AddressListEvent {
  const AddressDeleteRequested(this.id);
  final int id;
}