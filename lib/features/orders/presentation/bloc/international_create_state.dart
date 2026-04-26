part of 'international_create_bloc.dart';

enum InternationalContentType { document, parcel }

enum InternationalPickupDateSelection { today, tomorrow, custom }

class InternationalCreateState extends Equatable {
  const InternationalCreateState({
    this.currentStep = 0,
    this.shipment = const InternationalShipmentFormData(),
    this.address = const InternationalAddressFormData(),
    this.rates = const [],
    this.selectedRate,
    this.isFetchingRates = false,
    this.isInitiating = false,
    this.isPlacing = false,
    this.isLoadingPickupAddress = false,
    this.pickupAddress,
    this.pickupDate,
    this.pickupSlot,
    this.dateSelection = InternationalPickupDateSelection.today,
    this.errorMessage,
    this.draftId,
    this.draftDetails,
    this.orderPlaced = false,
    this.createdForId = 0,
    this.addressFormatTypeId = 1,
    this.fromAddresses = const [],
    this.selectedFromAddressId,
  });

  final int currentStep;
  final InternationalShipmentFormData shipment;
  final InternationalAddressFormData address;
  final List<InternationalRateOption> rates;
  final InternationalRateOption? selectedRate;
  final bool isFetchingRates;
  final bool isInitiating;
  final bool isPlacing;
  final bool isLoadingPickupAddress;
  final AddressEntity? pickupAddress;
  final DateTime? pickupDate;
  final int? pickupSlot;
  final InternationalPickupDateSelection dateSelection;
  final String? errorMessage;
  final int? draftId;
  final Map<String, dynamic>? draftDetails;
  final bool orderPlaced;
  final int createdForId;
  final int addressFormatTypeId;
  final List<AddressEntity> fromAddresses;
  final int? selectedFromAddressId;

  InternationalCreateState copyWith({
    int? currentStep,
    InternationalShipmentFormData? shipment,
    InternationalAddressFormData? address,
    List<InternationalRateOption>? rates,
    InternationalRateOption? selectedRate,
    bool clearSelectedRate = false,
    bool? isFetchingRates,
    bool? isInitiating,
    bool? isPlacing,
    bool? isLoadingPickupAddress,
    AddressEntity? pickupAddress,
    bool clearPickupAddress = false,
    DateTime? pickupDate,
    int? pickupSlot,
    InternationalPickupDateSelection? dateSelection,
    String? errorMessage,
    int? draftId,
    Map<String, dynamic>? draftDetails,
    bool? orderPlaced,
    int? createdForId,
    int? addressFormatTypeId,
    List<AddressEntity>? fromAddresses,
    int? selectedFromAddressId,
    bool clearSelectedFromAddressId = false,
  }) {
    return InternationalCreateState(
      currentStep: currentStep ?? this.currentStep,
      shipment: shipment ?? this.shipment,
      address: address ?? this.address,
      rates: rates ?? this.rates,
      selectedRate: clearSelectedRate ? null : (selectedRate ?? this.selectedRate),
      isFetchingRates: isFetchingRates ?? this.isFetchingRates,
      isInitiating: isInitiating ?? this.isInitiating,
      isPlacing: isPlacing ?? this.isPlacing,
      isLoadingPickupAddress: isLoadingPickupAddress ?? this.isLoadingPickupAddress,
      pickupAddress: clearPickupAddress ? null : (pickupAddress ?? this.pickupAddress),
      pickupDate: pickupDate ?? this.pickupDate,
      pickupSlot: pickupSlot ?? this.pickupSlot,
      dateSelection: dateSelection ?? this.dateSelection,
      errorMessage: errorMessage,
      draftId: draftId ?? this.draftId,
      draftDetails: draftDetails ?? this.draftDetails,
      orderPlaced: orderPlaced ?? this.orderPlaced,
      createdForId: createdForId ?? this.createdForId,
      addressFormatTypeId: addressFormatTypeId ?? this.addressFormatTypeId,
      fromAddresses: fromAddresses ?? this.fromAddresses,
      selectedFromAddressId: clearSelectedFromAddressId
          ? null
          : (selectedFromAddressId ?? this.selectedFromAddressId),
    );
  }

  @override
  List<Object?> get props => [
        currentStep,
        shipment,
        address,
        rates,
        selectedRate,
        isFetchingRates,
        isInitiating,
        isPlacing,
        isLoadingPickupAddress,
        pickupAddress,
        pickupDate,
        pickupSlot,
        dateSelection,
        errorMessage,
        draftId,
        draftDetails,
        orderPlaced,
        createdForId,
        addressFormatTypeId,
        fromAddresses,
        selectedFromAddressId,
      ];
}

class InternationalShipmentFormData extends Equatable {
  const InternationalShipmentFormData({
    this.originCountry,
    this.originCity,
    this.destinationCountry,
    this.destinationCity,
    this.contentType = InternationalContentType.parcel,
    this.packageCount = 1,
    this.packages = const [InternationalPackageItem()],
    this.commonDescription = '',
    this.commonValue = '',
    this.customerOrderId = '',
    this.description = '',
    this.productGroup = 'EXP',
    this.productType = 'P',
    this.paymentType = 'Prepaid',
    this.currency = 'BHD',
  });

  final CountryInfo? originCountry;
  final CityInfo? originCity;
  final CountryInfo? destinationCountry;
  final CityInfo? destinationCity;
  final InternationalContentType contentType;
  final int packageCount;
  final List<InternationalPackageItem> packages;
  final String commonDescription;
  final String commonValue;
  final String customerOrderId;
  final String description;
  final String productGroup;
  final String productType;
  final String paymentType;
  final String currency;

  InternationalShipmentFormData copyWith({
    CountryInfo? originCountry,
    CityInfo? originCity,
    bool clearOriginCity = false,
    CountryInfo? destinationCountry,
    CityInfo? destinationCity,
    bool clearDestinationCity = false,
    InternationalContentType? contentType,
    int? packageCount,
    List<InternationalPackageItem>? packages,
    String? commonDescription,
    String? commonValue,
    String? customerOrderId,
    String? description,
    String? productGroup,
    String? productType,
    String? paymentType,
    String? currency,
  }) {
    return InternationalShipmentFormData(
      originCountry: originCountry ?? this.originCountry,
      originCity: clearOriginCity ? null : (originCity ?? this.originCity),
      destinationCountry: destinationCountry ?? this.destinationCountry,
      destinationCity:
          clearDestinationCity ? null : (destinationCity ?? this.destinationCity),
      contentType: contentType ?? this.contentType,
      packageCount: packageCount ?? this.packageCount,
      packages: packages ?? this.packages,
      commonDescription: commonDescription ?? this.commonDescription,
      commonValue: commonValue ?? this.commonValue,
      customerOrderId: customerOrderId ?? this.customerOrderId,
      description: description ?? this.description,
      productGroup: productGroup ?? this.productGroup,
      productType: productType ?? this.productType,
      paymentType: paymentType ?? this.paymentType,
      currency: currency ?? this.currency,
    );
  }

  double get totalWeight {
    double total = 0;
    for (final item in packages) {
      total += double.tryParse(item.weight) ?? 0;
    }
    return total;
  }

  double get totalValue {
    double total = 0;
    for (final item in packages) {
      total += double.tryParse(item.value) ?? 0;
    }
    return total;
  }

  @override
  List<Object?> get props => [
        originCountry,
        originCity,
        destinationCountry,
        destinationCity,
        contentType,
        packageCount,
        packages,
        commonDescription,
        commonValue,
        customerOrderId,
        description,
        productGroup,
        productType,
        paymentType,
        currency,
      ];
}

class InternationalPackageItem extends Equatable {
  const InternationalPackageItem({
    this.weight = '1',
    this.length = '1',
    this.width = '1',
    this.height = '1',
    this.description = '',
    this.value = '0',
  });

  final String weight;
  final String length;
  final String width;
  final String height;
  final String description;
  final String value;

  InternationalPackageItem copyWith({
    String? weight,
    String? length,
    String? width,
    String? height,
    String? description,
    String? value,
  }) {
    return InternationalPackageItem(
      weight: weight ?? this.weight,
      length: length ?? this.length,
      width: width ?? this.width,
      height: height ?? this.height,
      description: description ?? this.description,
      value: value ?? this.value,
    );
  }

  @override
  List<Object?> get props => [weight, length, width, height, description, value];
}

class InternationalAddressFormData extends Equatable {
  const InternationalAddressFormData({
    this.shipper = const InternationalContactFormData(),
    this.recipient = const InternationalContactFormData(),
    this.deliveryInstructions = '',
  });

  final InternationalContactFormData shipper;
  final InternationalContactFormData recipient;
  final String deliveryInstructions;

  InternationalAddressFormData copyWith({
    InternationalContactFormData? shipper,
    InternationalContactFormData? recipient,
    String? deliveryInstructions,
  }) {
    return InternationalAddressFormData(
      shipper: shipper ?? this.shipper,
      recipient: recipient ?? this.recipient,
      deliveryInstructions: deliveryInstructions ?? this.deliveryInstructions,
    );
  }

  @override
  List<Object?> get props => [shipper, recipient, deliveryInstructions];
}

class InternationalContactFormData extends Equatable {
  const InternationalContactFormData({
    this.name = '',
    this.companyName = '',
    this.taxNo = '',
    this.country,
    this.city,
    this.postalCode = '',
    this.state = '',
    this.phoneCode = '+973',
    this.phone = '',
    this.altPhoneCode = '+973',
    this.altPhone = '',
    this.email = '',
    this.addressLine1 = '',
    this.addressLine2 = '',
  });

  final String name;
  final String companyName;
  final String taxNo;
  final CountryInfo? country;
  final CityInfo? city;
  final String postalCode;
  final String state;
  final String phoneCode;
  final String phone;
  final String altPhoneCode;
  final String altPhone;
  final String email;
  final String addressLine1;
  final String addressLine2;

  InternationalContactFormData copyWith({
    String? name,
    String? companyName,
    String? taxNo,
    CountryInfo? country,
    bool clearCountry = false,
    CityInfo? city,
    bool clearCity = false,
    String? postalCode,
    String? state,
    String? phoneCode,
    String? phone,
    String? altPhoneCode,
    String? altPhone,
    String? email,
    String? addressLine1,
    String? addressLine2,
  }) {
    return InternationalContactFormData(
      name: name ?? this.name,
      companyName: companyName ?? this.companyName,
      taxNo: taxNo ?? this.taxNo,
      country: clearCountry ? null : (country ?? this.country),
      city: clearCity ? null : (city ?? this.city),
      postalCode: postalCode ?? this.postalCode,
      state: state ?? this.state,
      phoneCode: phoneCode ?? this.phoneCode,
      phone: phone ?? this.phone,
      altPhoneCode: altPhoneCode ?? this.altPhoneCode,
      altPhone: altPhone ?? this.altPhone,
      email: email ?? this.email,
      addressLine1: addressLine1 ?? this.addressLine1,
      addressLine2: addressLine2 ?? this.addressLine2,
    );
  }

  @override
  List<Object?> get props => [
        name,
        companyName,
        taxNo,
        country,
        city,
        postalCode,
        state,
        phoneCode,
        phone,
        altPhoneCode,
        altPhone,
        email,
        addressLine1,
        addressLine2,
      ];
}
