part of 'draft_place_bloc.dart';

class DraftPlaceState extends Equatable {
  const DraftPlaceState({
    this.loading = false,
    this.preview,
    this.errorMessage,
    this.pickupDate,
    this.dateSelection = DraftPickupDateSelection.today,
    this.pickupSlot,
    this.submitting = false,
    this.success = false,
    this.serviceType = '',
    this.primaryAddress = '',
    this.primaryPhone = '',
    this.primaryAddressEntity,
  });

  final bool loading;
  final DraftPlacePreview? preview;
  final String? errorMessage;
  final DateTime? pickupDate;
  final DraftPickupDateSelection dateSelection;
  final int? pickupSlot;
  final bool submitting;
  final bool success;
  final String serviceType;
  final String primaryAddress;
  final String primaryPhone;
  final AddressEntity? primaryAddressEntity;

  DraftPlaceState copyWith({
    bool? loading,
    DraftPlacePreview? preview,
    String? errorMessage,
    DateTime? pickupDate,
    DraftPickupDateSelection? dateSelection,
    int? pickupSlot,
    bool? submitting,
    bool? success,
    String? serviceType,
    String? primaryAddress,
    String? primaryPhone,
    AddressEntity? primaryAddressEntity,
  }) {
    return DraftPlaceState(
      loading: loading ?? this.loading,
      preview: preview ?? this.preview,
      errorMessage: errorMessage,
      pickupDate: pickupDate ?? this.pickupDate,
      dateSelection: dateSelection ?? this.dateSelection,
      pickupSlot: pickupSlot ?? this.pickupSlot,
      submitting: submitting ?? this.submitting,
      success: success ?? this.success,
      serviceType: serviceType ?? this.serviceType,
      primaryAddress: primaryAddress ?? this.primaryAddress,
      primaryPhone: primaryPhone ?? this.primaryPhone,
      primaryAddressEntity: primaryAddressEntity ?? this.primaryAddressEntity,
    );
  }

  @override
  List<Object?> get props => [
        loading,
        preview,
        errorMessage,
        pickupDate,
        dateSelection,
        pickupSlot,
        submitting,
        success,
        serviceType,
        primaryAddress,
        primaryPhone,
        primaryAddressEntity,
      ];
}
