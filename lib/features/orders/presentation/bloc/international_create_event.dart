part of 'international_create_bloc.dart';

abstract class InternationalCreateEvent extends Equatable {
  const InternationalCreateEvent();

  @override
  List<Object?> get props => [];
}

class InternationalShipmentChanged extends InternationalCreateEvent {
  const InternationalShipmentChanged(this.shipment);

  final InternationalShipmentFormData shipment;

  @override
  List<Object?> get props => [shipment];
}

class InternationalAddressChanged extends InternationalCreateEvent {
  const InternationalAddressChanged(this.address);

  final InternationalAddressFormData address;

  @override
  List<Object?> get props => [address];
}

class InternationalRateSelected extends InternationalCreateEvent {
  const InternationalRateSelected(this.rate);

  final InternationalRateOption rate;

  @override
  List<Object?> get props => [rate];
}

class InternationalStepChanged extends InternationalCreateEvent {
  const InternationalStepChanged(this.step);

  final int step;

  @override
  List<Object?> get props => [step];
}

class InternationalNextPressed extends InternationalCreateEvent {
  const InternationalNextPressed();
}

class InternationalBackPressed extends InternationalCreateEvent {
  const InternationalBackPressed();
}

class InternationalPickupDateChanged extends InternationalCreateEvent {
  const InternationalPickupDateChanged({
    required this.date,
    required this.selection,
  });

  final DateTime date;
  final InternationalPickupDateSelection selection;

  @override
  List<Object?> get props => [date, selection];
}

class InternationalPickupSlotChanged extends InternationalCreateEvent {
  const InternationalPickupSlotChanged(this.slot);

  final int slot;

  @override
  List<Object?> get props => [slot];
}

class InternationalPickupAddressRequested extends InternationalCreateEvent {
  const InternationalPickupAddressRequested();
}

class InternationalUserLoaded extends InternationalCreateEvent {
  const InternationalUserLoaded({
    required this.userId,
    this.defaultPackageDescription,
    this.addressFormatTypeId,
  });

  final int userId;
  final String? defaultPackageDescription;
  final int? addressFormatTypeId;

  @override
  List<Object?> get props => [
    userId,
    defaultPackageDescription,
    addressFormatTypeId,
  ];
}

class InternationalOriginCountryRequested extends InternationalCreateEvent {
  const InternationalOriginCountryRequested({this.searchName = 'Bahrain'});

  final String searchName;

  @override
  List<Object?> get props => [searchName];
}

class InternationalOrderPlacedAcknowledged extends InternationalCreateEvent {
  const InternationalOrderPlacedAcknowledged();
}

class InternationalFromAddressSelected extends InternationalCreateEvent {
  const InternationalFromAddressSelected(this.addressId);

  final int? addressId;

  @override
  List<Object?> get props => [addressId];
}
