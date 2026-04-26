import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error_utils.dart';
import '../../../profile/data/address_repository_impl.dart';
import '../../../profile/domain/entities/address_entity.dart';
import '../../../profile/domain/repositories/address_repository.dart';
import '../../data/international_order_repository.dart';
import '../../domain/entities/international_models.dart';

part 'international_create_event.dart';
part 'international_create_state.dart';

class InternationalCreateBloc
    extends Bloc<InternationalCreateEvent, InternationalCreateState> {
  InternationalCreateBloc({
    required InternationalOrderRepository repository,
    AddressRepository? addressRepository,
    required this.token,
  })  : _repository = repository,
        _addressRepository = addressRepository ?? AddressRepositoryImpl(),
        super(const InternationalCreateState()) {
    on<InternationalShipmentChanged>(_onShipmentChanged);
    on<InternationalAddressChanged>(_onAddressChanged);
    on<InternationalRateSelected>(_onRateSelected);
    on<InternationalStepChanged>(_onStepChanged);
    on<InternationalNextPressed>(_onNextPressed);
    on<InternationalBackPressed>(_onBackPressed);
    on<InternationalPickupDateChanged>(_onPickupDateChanged);
    on<InternationalPickupSlotChanged>(_onPickupSlotChanged);
    on<InternationalPickupAddressRequested>(_onPickupAddressRequested);
    on<InternationalUserLoaded>(_onUserLoaded);
    on<InternationalOriginCountryRequested>(_onOriginCountryRequested);
    on<InternationalOrderPlacedAcknowledged>(_onOrderPlacedAcknowledged);
    on<InternationalFromAddressSelected>(_onFromAddressSelected);
  }

  final String token;
  final InternationalOrderRepository _repository;
  final AddressRepository _addressRepository;

  static const Map<String, int> _phoneCodeLengths = {
    '+973': 8,
    '+91': 10,
    '+966': 9,
    '+971': 9,
    '+965': 8,
    '+974': 8,
    '+968': 8,
    '+1': 10,
    '+880': 10,
    '+92': 10,
    '+44': 10,
    '+20': 10,
    '+62': 10,
    '+60': 9,
    '+63': 10,
    '+234': 10,
    '+254': 9,
    '+255': 9,
    '+256': 9,
    '+94': 9,
    '+977': 10,
  };

  void _onShipmentChanged(
    InternationalShipmentChanged event,
    Emitter<InternationalCreateState> emit,
  ) {
    final previousShipment = state.shipment;
    final shipment = _normalizeShipment(event.shipment);
    final shipper = state.address.shipper;
    final recipient = state.address.recipient;
    final shipperCountryAuto =
        shipper.country == null ||
        _matchesCountry(shipper.country, previousShipment.originCountry);
    final shipperCityAuto =
        shipper.city == null ||
        _matchesCity(shipper.city, previousShipment.originCity);
    final recipientCountryAuto =
        recipient.country == null ||
        _matchesCountry(recipient.country, previousShipment.destinationCountry);
    final recipientCityAuto =
        recipient.city == null ||
        _matchesCity(recipient.city, previousShipment.destinationCity);
    final updatedAddress = state.address.copyWith(
      shipper: shipper.copyWith(
        country: shipperCountryAuto ? shipment.originCountry : shipper.country,
        city: shipperCityAuto ? shipment.originCity : shipper.city,
      ),
      recipient: recipient.copyWith(
        country: recipientCountryAuto
            ? shipment.destinationCountry
            : recipient.country,
        city:
            recipientCityAuto ? shipment.destinationCity : recipient.city,
      ),
    );
    emit(state.copyWith(shipment: shipment, address: updatedAddress));
  }

  void _onAddressChanged(
    InternationalAddressChanged event,
    Emitter<InternationalCreateState> emit,
  ) {
    emit(state.copyWith(address: event.address));
  }

  void _onRateSelected(
    InternationalRateSelected event,
    Emitter<InternationalCreateState> emit,
  ) {
    emit(state.copyWith(selectedRate: event.rate));
  }

  void _onStepChanged(
    InternationalStepChanged event,
    Emitter<InternationalCreateState> emit,
  ) {
    emit(state.copyWith(currentStep: event.step.clamp(0, 5)));
  }

  void _onBackPressed(
    InternationalBackPressed event,
    Emitter<InternationalCreateState> emit,
  ) {
    emit(state.copyWith(currentStep: (state.currentStep - 1).clamp(0, 5)));
  }

  Future<void> _onNextPressed(
    InternationalNextPressed event,
    Emitter<InternationalCreateState> emit,
  ) async {
    if (state.currentStep == 0) {
      final validation = _validateShipmentLocations(state.shipment);
      if (validation != null) {
        emit(state.copyWith(errorMessage: validation));
        return;
      }
      emit(state.copyWith(currentStep: 1, errorMessage: null));
      return;
    }

    if (state.currentStep == 1) {
      final validation = _validatePackages(state.shipment);
      if (validation != null) {
        emit(state.copyWith(errorMessage: validation));
        return;
      }
      emit(state.copyWith(isFetchingRates: true, errorMessage: null));
      try {
        final rates = await _repository.fetchRates(
          token: token,
          payload: _buildRatesPayload(state.shipment),
        );
        emit(
          state.copyWith(
            isFetchingRates: false,
            rates: rates,
            selectedRate: rates.isNotEmpty ? rates.first : null,
            currentStep: 2,
          ),
        );
      } catch (error) {
        emit(
          state.copyWith(
            isFetchingRates: false,
            errorMessage: ErrorUtils.friendly(
              error.toString(),
              fallback: 'Unable to fetch rates',
            ),
          ),
        );
      }
      return;
    }

    if (state.currentStep == 2) {
      if (state.selectedRate == null) {
        emit(state.copyWith(errorMessage: 'Please select a shipping service'));
        return;
      }
      emit(state.copyWith(currentStep: 3, errorMessage: null));
      return;
    }

    if (state.currentStep == 3) {
      final validation = _validateContact(state.address.shipper, label: 'From');
      if (validation != null) {
        emit(state.copyWith(errorMessage: validation));
        return;
      }
      emit(state.copyWith(currentStep: 4, errorMessage: null));
      return;
    }

    if (state.currentStep == 4) {
      final validation = _validateContact(state.address.recipient, label: 'To');
      if (validation != null) {
        emit(state.copyWith(errorMessage: validation));
        return;
      }
      emit(state.copyWith(isInitiating: true, errorMessage: null));
      try {
        final payload = _buildInitiatePayload(state);
        final response = await _repository.initiateDraft(
          token: token,
          payload: payload,
        );
        final data = response['data'] as Map<String, dynamic>? ?? const {};
        final draftId = _parseId(data['id'] ?? data['draft_order_id']);
        final details = draftId == null
            ? <String, dynamic>{}
            : await _repository.fetchDraftDetails(
                token: token,
                draftId: draftId,
              );
        emit(
          state.copyWith(
            isInitiating: false,
            draftId: draftId,
            draftDetails: details,
            currentStep: 5,
          ),
        );
      } catch (error) {
        emit(
          state.copyWith(
            isInitiating: false,
            errorMessage: ErrorUtils.friendly(
              error.toString(),
              fallback: 'Unable to create draft order',
            ),
          ),
        );
      }
      return;
    }

    if (state.currentStep == 5) {
      final validation = _validateConfirmation(state);
      if (validation != null) {
        emit(state.copyWith(errorMessage: validation));
        return;
      }
      final orderId = state.draftId ?? _parseId(state.draftDetails?['id']);
      if (orderId == null) {
        emit(state.copyWith(errorMessage: 'Order id is missing'));
        return;
      }
      emit(state.copyWith(isPlacing: true, errorMessage: null));
      try {
        await _repository.approveAndPlace(token: token);
        emit(state.copyWith(isPlacing: false, orderPlaced: true));
      } catch (error) {
        emit(
          state.copyWith(
            isPlacing: false,
            errorMessage: ErrorUtils.friendly(
              error.toString(),
              fallback: 'Unable to place order',
            ),
          ),
        );
      }
    }
  }

  void _onPickupDateChanged(
    InternationalPickupDateChanged event,
    Emitter<InternationalCreateState> emit,
  ) {
    emit(
      state.copyWith(
        pickupDate: event.date,
        dateSelection: event.selection,
      ),
    );
  }

  void _onPickupSlotChanged(
    InternationalPickupSlotChanged event,
    Emitter<InternationalCreateState> emit,
  ) {
    emit(state.copyWith(pickupSlot: event.slot));
  }

  Future<void> _onPickupAddressRequested(
    InternationalPickupAddressRequested event,
    Emitter<InternationalCreateState> emit,
  ) async {
    emit(state.copyWith(isLoadingPickupAddress: true, errorMessage: null));
    try {
      final addresses = await _addressRepository.fetchAddresses(token: token);
      AddressEntity? selected;
      if (addresses.isNotEmpty) {
        selected = addresses.firstWhere(
          (a) => a.isPrimary,
          orElse: () => addresses.first,
        );
      }
      final selectedFrom = _resolveSelectedFromAddress(
        addresses,
        state.selectedFromAddressId,
      );
      final updatedAddress = selectedFrom == null
          ? state.address
          : _applyFromAddressIfEmpty(
              state.address,
              selectedFrom,
              state.addressFormatTypeId,
            );
      emit(
        state.copyWith(
          isLoadingPickupAddress: false,
          pickupAddress: selected,
          fromAddresses: addresses,
          selectedFromAddressId: selectedFrom?.id,
          clearSelectedFromAddressId: selectedFrom == null,
          address: updatedAddress,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          isLoadingPickupAddress: false,
          errorMessage: ErrorUtils.friendly(
            error.toString(),
            fallback: 'Unable to load pickup address',
          ),
        ),
      );
    }
  }

  void _onUserLoaded(
    InternationalUserLoaded event,
    Emitter<InternationalCreateState> emit,
  ) {
    final defaultDesc = event.defaultPackageDescription?.trim() ?? '';
    final shipment = state.shipment.copyWith(
      description:
          defaultDesc.isNotEmpty ? defaultDesc : state.shipment.description,
      commonDescription:
          defaultDesc.isNotEmpty && state.shipment.commonDescription.isEmpty
              ? defaultDesc
              : state.shipment.commonDescription,
    );
    final formatTypeId =
        event.addressFormatTypeId ?? state.addressFormatTypeId;
    final selectedFrom = _resolveSelectedFromAddress(
      state.fromAddresses,
      state.selectedFromAddressId,
    );
    final updatedAddress = selectedFrom == null
        ? state.address
        : _applyFromAddressIfEmpty(state.address, selectedFrom, formatTypeId);
    emit(
      state.copyWith(
        createdForId: event.userId,
        shipment: shipment,
        addressFormatTypeId: formatTypeId,
        address: updatedAddress,
      ),
    );
  }

  Future<void> _onOriginCountryRequested(
    InternationalOriginCountryRequested event,
    Emitter<InternationalCreateState> emit,
  ) async {
    try {
      final list = await _repository.fetchCountries(
        token: token,
        search: event.searchName,
      );
      final match = list.firstWhere(
        (c) => c.name.toLowerCase() == event.searchName.toLowerCase(),
        orElse: () => list.isNotEmpty ? list.first : const CountryInfo(id: 0, name: '', shortCode: ''),
      );
      if (match.id != 0) {
        emit(
          state.copyWith(
            shipment: state.shipment.copyWith(
              originCountry: match,
              originCity: null,
            ),
          ),
        );
      }
    } catch (_) {
      // Ignore default origin load failure.
    }
  }

  void _onOrderPlacedAcknowledged(
    InternationalOrderPlacedAcknowledged event,
    Emitter<InternationalCreateState> emit,
  ) {
    emit(state.copyWith(orderPlaced: false));
  }

  void _onFromAddressSelected(
    InternationalFromAddressSelected event,
    Emitter<InternationalCreateState> emit,
  ) {
    final addresses = state.fromAddresses;
    final selected = _resolveSelectedFromAddress(addresses, event.addressId);
    if (selected == null) {
      emit(
        state.copyWith(
          selectedFromAddressId: event.addressId,
          clearSelectedFromAddressId: event.addressId == null,
        ),
      );
      return;
    }
    final updatedAddress = _applyFromAddress(
      state.address,
      selected,
      state.addressFormatTypeId,
    );
    emit(
      state.copyWith(
        selectedFromAddressId: selected.id,
        address: updatedAddress,
      ),
    );
  }

  String? _validateShipmentLocations(InternationalShipmentFormData shipment) {
    if (shipment.originCountry == null) {
      return 'Select origin country';
    }
    if (shipment.originCity == null) {
      return 'Select origin city';
    }
    if (shipment.destinationCountry == null) {
      return 'Select destination country';
    }
    if (shipment.destinationCity == null) {
      return 'Select destination city';
    }
    return null;
  }

  String? _validatePackages(InternationalShipmentFormData shipment) {
    if (shipment.packages.isEmpty) {
      return 'Add at least one package';
    }
    for (final item in shipment.packages) {
      if (!_isPositive(item.weight)) {
        return 'Enter a valid weight for all packages';
      }
      if (!_isPositive(item.length) ||
          !_isPositive(item.width) ||
          !_isPositive(item.height)) {
        return 'Enter valid dimensions for all packages';
      }
    }
    return null;
  }

  String? _validateAddress(InternationalAddressFormData address) {
    final shipperError = _validateContact(address.shipper, label: 'Shipper');
    if (shipperError != null) return shipperError;
    final recipientError = _validateContact(address.recipient, label: 'Recipient');
    if (recipientError != null) return recipientError;
    return null;
  }

  String? _validateContact(
    InternationalContactFormData contact, {
    required String label,
  }) {
    if (contact.name.trim().isEmpty) {
      return '$label name is required';
    }
    if (contact.country == null) {
      return '$label country is required';
    }
    if (contact.city == null) {
      return '$label city is required';
    }
    if (contact.addressLine1.trim().isEmpty) {
      return '$label address line 1 is required';
    }
    if (contact.postalCode.trim().isEmpty) {
      return '$label postal code is required';
    }
    if (contact.phone.trim().isEmpty) {
      return '$label mobile number is required';
    }
    if (!_isValidPhone(contact.phoneCode, contact.phone)) {
      return 'Enter a valid ${label.toLowerCase()} mobile number';
    }
    if (contact.altPhone.trim().isNotEmpty &&
        !_isValidPhone(contact.altPhoneCode, contact.altPhone)) {
      return 'Enter a valid ${label.toLowerCase()} alternate number';
    }
    return null;
  }

  String? _validateConfirmation(InternationalCreateState current) {
    if (current.pickupDate == null) {
      return 'Select a pickup date';
    }
    if (current.pickupSlot == null) {
      return 'Select a pickup time slot';
    }
    if (current.pickupAddress == null || current.pickupAddress!.id == 0) {
      return 'Select a pickup address';
    }
    return null;
  }

  Map<String, dynamic> _buildRatesPayload(
    InternationalShipmentFormData shipment,
  ) {
    final maxLength = _maxDimension(
      shipment.packages,
      (p) => double.tryParse(p.length) ?? 0,
    );
    final maxWidth = _maxDimension(
      shipment.packages,
      (p) => double.tryParse(p.width) ?? 0,
    );
    final maxHeight = _maxDimension(
      shipment.packages,
      (p) => double.tryParse(p.height) ?? 0,
    );
    final totalWeight = shipment.totalWeight <= 0 ? 1 : shipment.totalWeight;
    final pieces = shipment.packageCount < 1 ? 1 : shipment.packageCount;
    return {
      'origin_city': shipment.originCity?.name ?? '',
      'origin_country': 'Bahrain',
      'destination_city': shipment.destinationCity?.name ?? '',
      'destination_country': shipment.destinationCountry?.name ?? '',
      'weight': totalWeight,
      'number_of_pieces': pieces,
      'product_group': shipment.productGroup,
      'product_type': shipment.productType,
      'length': maxLength,
      'width': maxWidth,
      'height': maxHeight,
    };
  }

  Map<String, dynamic> _buildInitiatePayload(InternationalCreateState current) {
    final packages = current.shipment.packages.map((item) {
      return {
        'weight': _coercePositive(item.weight, fallback: 1),
        'length': _coercePositive(item.length, fallback: 1),
        'width': _coercePositive(item.width, fallback: 1),
        'height': _coercePositive(item.height, fallback: 1),
        'package_description': item.description.trim(),
        'customer_input_package_value': _coercePositive(item.value, fallback: 0),
      };
    }).toList();

    final shipper = current.address.shipper;
    final recipient = current.address.recipient;
    final pickupAddressId = current.pickupAddress?.id;
    final customValue = current.shipment.totalValue;
    final payload = <String, dynamic>{
      'created_for_id': current.createdForId,
      'package_details': packages,
      if (current.shipment.customerOrderId.trim().isNotEmpty)
        'customer_input_order_id': current.shipment.customerOrderId.trim(),
      'pickup_customer_name': shipper.name.trim(),
      'pickup_mobile_number': _formatPhone(shipper.phoneCode, shipper.phone),
      if (shipper.altPhone.trim().isNotEmpty)
        'pickup_alternate_number':
            _formatPhone(shipper.altPhoneCode, shipper.altPhone),
      if (current.address.deliveryInstructions.trim().isNotEmpty)
        'delivery_instructions': current.address.deliveryInstructions.trim(),
      'destination_customer_name': recipient.name.trim(),
      'destination_mobile_number':
          _formatPhone(recipient.phoneCode, recipient.phone),
      if (recipient.altPhone.trim().isNotEmpty)
        'destination_alternate_number':
            _formatPhone(recipient.altPhoneCode, recipient.altPhone),
      if (current.pickupDate != null)
        'pickup_date': _formatDate(current.pickupDate!),
      if (current.pickupSlot != null) 'pickup_slot_type': current.pickupSlot,
      if (pickupAddressId != null && pickupAddressId > 0)
        'pickup_address_id': pickupAddressId,
      'shipper_company_name': shipper.companyName.trim(),
      'shipper_address': _composeAddress(shipper),
      'shipper_city': shipper.city?.name ?? '',
      'shipper_postal_code': shipper.postalCode.trim(),
      'shipper_country': shipper.country?.name ?? '',
      'shipper_email': shipper.email.trim(),
      'shipper_tax_no': shipper.taxNo.trim(),
      'recipient_company_name': recipient.companyName.trim(),
      'recipient_address': _composeAddress(recipient),
      'recipient_city': recipient.city?.name ?? '',
      'recipient_postal_code': recipient.postalCode.trim(),
      'recipient_country': recipient.country?.name ?? '',
      'recipient_email': recipient.email.trim(),
      'recipient_tax_no': recipient.taxNo.trim(),
      'description': current.shipment.description.trim(),
      'product_group': current.shipment.productGroup,
      'product_type': current.shipment.productType,
      'payment_type': current.shipment.paymentType,
      'customs_value': customValue,
      'currency': current.shipment.currency,
      'carrier': current.selectedRate?.carrier ?? '',
    };
    return payload;
  }

  String _composeAddress(InternationalContactFormData contact) {
    final parts = [
      contact.addressLine1.trim(),
      contact.addressLine2.trim(),
    ].where((p) => p.isNotEmpty).toList();
    return parts.join(', ');
  }

  String _formatPhone(String code, String number) {
    final digits = number.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return '';
    final normalizedCode = code.trim().startsWith('+')
        ? code.trim()
        : '+${code.trim()}';
    final codeDigits = normalizedCode.replaceAll(RegExp(r'\D'), '');
    final stripped = digits.startsWith(codeDigits)
        ? digits.substring(codeDigits.length)
        : digits;
    return '$normalizedCode$stripped';
  }

  String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  bool _isValidPhone(String code, String number) {
    final rawDigits = number.replaceAll(RegExp(r'\D'), '');
    if (rawDigits.isEmpty) return false;
    final codeDigits = code.trim().replaceAll(RegExp(r'\D'), '');
    final digits = rawDigits.startsWith(codeDigits)
        ? rawDigits.substring(codeDigits.length)
        : rawDigits;
    final expected = _phoneCodeLengths[code.trim()];
    if (expected != null) {
      return digits.length == expected;
    }
    return digits.length >= 7 && digits.length <= 12;
  }

  bool _isPositive(String raw) {
    final value = double.tryParse(raw);
    return value != null && value > 0;
  }

  double _coercePositive(String raw, {required double fallback}) {
    final value = double.tryParse(raw);
    if (value == null) return fallback;
    if (value < 0) return fallback;
    return value;
  }

  String _clampPositiveText(String raw, {String fallback = '1'}) {
    final value = double.tryParse(raw);
    if (value == null || value <= 0) return fallback;
    return raw;
  }

  String _clampNonNegativeText(String raw, {String fallback = '0'}) {
    final value = double.tryParse(raw);
    if (value == null || value < 0) return fallback;
    return raw;
  }

  InternationalShipmentFormData _normalizeShipment(
    InternationalShipmentFormData shipment,
  ) {
    final previousCommonValue = state.shipment.commonValue.trim();
    final newCommonValue = shipment.commonValue.trim();
    final previousCommonDesc = state.shipment.commonDescription.trim();
    final newCommonDesc = shipment.commonDescription.trim();
    final count = shipment.packageCount < 1 ? 1 : shipment.packageCount;
    final existing = shipment.packages;

    final normalized = existing.take(count).map((item) {
      return item.copyWith(
        weight: _clampPositiveText(item.weight, fallback: '1'),
        length: _clampPositiveText(item.length, fallback: '1'),
        width: _clampPositiveText(item.width, fallback: '1'),
        height: _clampPositiveText(item.height, fallback: '1'),
        value: _clampNonNegativeText(item.value, fallback: '0'),
      );
    }).toList();

    final adjusted = [
      ...normalized,
      ...List.generate(
        count - existing.length > 0 ? count - existing.length : 0,
        (_) => InternationalPackageItem(
          description: newCommonDesc,
          value: newCommonValue.isEmpty ? '0' : newCommonValue,
        ),
      ),
    ];

    final adjustedWithCommon = adjusted.map((item) {
      var updated = item;
      final valueText = updated.value.trim();
      final isZeroLike =
          valueText.isEmpty ||
          valueText == '0' ||
          double.tryParse(valueText) == 0;
      final matchesPreviousCommon =
          previousCommonValue.isNotEmpty && valueText == previousCommonValue;
      if (newCommonValue.isNotEmpty && (isZeroLike || matchesPreviousCommon)) {
        updated = updated.copyWith(value: newCommonValue);
      }
      final descText = updated.description.trim();
      final matchesPreviousDesc =
          previousCommonDesc.isNotEmpty && descText == previousCommonDesc;
      if (newCommonDesc.isNotEmpty &&
          (descText.isEmpty || matchesPreviousDesc)) {
        updated = updated.copyWith(description: newCommonDesc);
      }
      return updated;
    }).toList();

    return shipment.copyWith(
      packageCount: count,
      packages: adjustedWithCommon,
    );
  }

  double _maxDimension(
    List<InternationalPackageItem> packages,
    double Function(InternationalPackageItem) selector,
  ) {
    double maxValue = 1;
    for (final item in packages) {
      final value = selector(item);
      if (value > maxValue) maxValue = value;
    }
    return maxValue;
  }

  int? _parseId(Object? raw) {
    if (raw == null) return null;
    if (raw is int) return raw;
    return int.tryParse(raw.toString());
  }

  AddressEntity? _resolveSelectedFromAddress(
    List<AddressEntity> addresses,
    int? selectedId,
  ) {
    if (addresses.isEmpty) return null;
    if (selectedId != null) {
      return addresses.firstWhere(
        (address) => address.id == selectedId,
        orElse: () => addresses.first,
      );
    }
    return addresses.firstWhere(
      (address) => address.isPrimary,
      orElse: () => addresses.first,
    );
  }

  InternationalAddressFormData _applyFromAddress(
    InternationalAddressFormData current,
    AddressEntity address,
    int addressFormatTypeId,
  ) {
    final formatted = _formatAddressLines(address, addressFormatTypeId);
    final shipper = current.shipper.copyWith(
      addressLine1: formatted.$1,
      addressLine2: formatted.$2,
      phone: _stripPhoneCode(address.phone, current.shipper.phoneCode),
    );
    return current.copyWith(shipper: shipper);
  }

  InternationalAddressFormData _applyFromAddressIfEmpty(
    InternationalAddressFormData current,
    AddressEntity address,
    int addressFormatTypeId,
  ) {
    final shipper = current.shipper;
    final formatted = _formatAddressLines(address, addressFormatTypeId);
    final hasAddress =
        shipper.addressLine1.trim().isNotEmpty ||
        shipper.addressLine2.trim().isNotEmpty;
    final hasPhone = shipper.phone.trim().isNotEmpty;
    if (hasAddress && hasPhone) return current;
    final updated = shipper.copyWith(
      addressLine1: hasAddress ? shipper.addressLine1 : formatted.$1,
      addressLine2: hasAddress ? shipper.addressLine2 : formatted.$2,
      phone: hasPhone
          ? shipper.phone
          : _stripPhoneCode(address.phone, shipper.phoneCode),
    );
    return current.copyWith(shipper: updated);
  }

  (String, String) _formatAddressLines(
    AddressEntity address,
    int addressFormatTypeId,
  ) {
    String buildStandard() {
      final parts = <String>[];
      if (address.buildingCode.trim().isNotEmpty) {
        parts.add('Building ${address.buildingCode.trim()}');
      }
      if (address.roadCode.trim().isNotEmpty) {
        parts.add('Road ${address.roadCode.trim()}');
      }
      if (address.blockName.trim().isNotEmpty) {
        parts.add(address.blockName.trim());
      }
      return parts.join(', ');
    }

    String buildSingleLine() {
      final parts = <String>[];
      if (address.line1.trim().isNotEmpty) parts.add(address.line1.trim());
      if (address.line2.trim().isNotEmpty) parts.add(address.line2.trim());
      return parts.join(', ');
    }

    if (addressFormatTypeId == 2) {
      final line = buildSingleLine();
      if (line.isNotEmpty) return (line, '');
    }

    final standard = buildStandard();
    if (standard.isNotEmpty) return (standard, '');

    final fallback = buildSingleLine();
    if (fallback.isNotEmpty) return (fallback, '');

    return ('', '');
  }

  String _stripPhoneCode(String raw, String code) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return '';
    final codeDigits = code.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith(codeDigits)) {
      return digits.substring(codeDigits.length);
    }
    return digits;
  }

  bool _matchesCountry(CountryInfo? left, CountryInfo? right) {
    if (left == null || right == null) return false;
    if (left.id != 0 && right.id != 0) return left.id == right.id;
    return left.name == right.name;
  }

  bool _matchesCity(CityInfo? left, CityInfo? right) {
    if (left == null || right == null) return false;
    if (left.id != 0 && right.id != 0) return left.id == right.id;
    return left.name == right.name;
  }
}
