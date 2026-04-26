import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../dashboard/data/domestic_order_repository.dart';
import '../../../../dashboard/models/address_lookup.dart';
import '../../domain/repositories/orders_repository.dart';
import '../../domain/usecases/get_orders.dart';
import '../../../../login/models/login_response.dart';

part 'domestic_create_event.dart';
part 'domestic_create_state.dart';

class DomesticCreateBloc
    extends Bloc<DomesticCreateEvent, DomesticCreateState> {
  DomesticCreateBloc({
    required OrdersRepository ordersRepository,
    required DomesticOrderRepository addressRepository,
    required this.token,
  }) : _ordersRepository = ordersRepository,
       _addressRepository = addressRepository,
       _getOrders = GetOrders(ordersRepository),
       super(const DomesticCreateState()) {
    on<DomesticDraftCheckRequested>(_onDraftCheckRequested);
    on<DomesticServiceTypeChanged>(_onServiceChanged);
    on<DomesticPackageDetailsChanged>(_onPackageChanged);
    on<DomesticDeliveryDetailsChanged>(_onDeliveryChanged);
    on<DomesticDraftNotesChanged>(_onDraftChanged);
    on<DomesticStepChanged>(_onStepChanged);
    on<DomesticNextPressed>(_onNext);
    on<DomesticBackPressed>(_onBack);
    on<DomesticBlocksRequested>(_onBlocksRequested);
    on<DomesticRoadsRequested>(_onRoadsRequested);
    on<DomesticBuildingsRequested>(_onBuildingsRequested);
    on<DomesticBlockSelected>(_onBlockSelected);
    on<DomesticRoadSelected>(_onRoadSelected);
    on<DomesticBuildingSelected>(_onBuildingSelected);
    on<DomesticAcceptanceShown>(_onAcceptanceShown);
    on<DomesticDraftDetailRequested>(_onDraftDetailRequested);
    on<DomesticAddressFormatChanged>(_onAddressFormatChanged);
    on<DomesticUserTypeChanged>(_onUserTypeChanged);
    on<DomesticOrderFlowTypesLoaded>(_onFlowTypesLoaded);
    on<DomesticOrderFlowTypeChanged>(_onFlowTypeChanged);
  }

  final String token;
  final OrdersRepository _ordersRepository;
  final DomesticOrderRepository _addressRepository;
  final GetOrders _getOrders;
  static const Map<String, int> _phoneCodeLengths = {
    '+973': 8, // Bahrain
    '+91': 10, // India
    '+966': 9, // Saudi Arabia
    '+971': 9, // UAE
    '+965': 8, // Kuwait
    '+974': 8, // Qatar
    '+968': 8, // Oman
    '+1': 10, // US/Canada
    '+880': 10, // Bangladesh
    '+92': 10, // Pakistan
    '+44': 10, // UK (without leading zero)
    '+20': 10, // Egypt (mobile, without leading zero)
    '+62': 10, // Indonesia (common length)
    '+60': 9, // Malaysia (common length)
    '+63': 10, // Philippines
    '+234': 10, // Nigeria (without leading zero)
    '+254': 9, // Kenya
    '+255': 9, // Tanzania
    '+256': 9, // Uganda
    '+94': 9, // Sri Lanka
    '+977': 10, // Nepal
  };

  Future<void> _onDraftCheckRequested(
    DomesticDraftCheckRequested event,
    Emitter<DomesticCreateState> emit,
  ) async {
    emit(state.copyWith(isCheckingDraft: true, errorMessage: null));
    try {
      final page = await _getOrders(
        token: token,
        endpoint: 'customer/order/draft/list',
        page: 1,
        limit: 1,
      );
      if (page.orders.isNotEmpty) {
        final draft = page.orders.first;
        final locked = _mapServiceType(draft.serviceType);
        emit(
          state.copyWith(
            isCheckingDraft: false,
            lockedServiceType: locked,
            selectedServiceType: locked ?? state.selectedServiceType,
          ),
        );
      } else {
        emit(state.copyWith(isCheckingDraft: false));
      }
    } catch (error) {
      emit(
        state.copyWith(
          isCheckingDraft: false,
          errorMessage: _friendlyError(error),
        ),
      );
    }
  }

  void _onServiceChanged(
    DomesticServiceTypeChanged event,
    Emitter<DomesticCreateState> emit,
  ) {
    if (state.lockedServiceType != null &&
        state.lockedServiceType != event.serviceType) {
      return;
    }
    final hasDraftContext = state.orderData != null || state.previewData != null;
    emit(
      state.copyWith(
        selectedServiceType: event.serviceType,
        orderData: hasDraftContext ? null : state.orderData,
        previewData: hasDraftContext ? null : state.previewData,
        currentStep: hasDraftContext && state.currentStep > 1 ? 1 : state.currentStep,
      ),
    );
  }

  void _onPackageChanged(
    DomesticPackageDetailsChanged event,
    Emitter<DomesticCreateState> emit,
  ) {
    final previousCommonValue = state.package.commonValue.trim();
    final newCommonValue = event.package.commonValue.trim();
    final previousCommonDescription = state.package.commonDescription.trim();
    final newCommonDescription = event.package.commonDescription.trim();
    final count = event.package.packageCount < 1
        ? 1
        : event.package.packageCount;
    final existing = event.package.items;
    final normalized = existing.take(count).map((item) {
      return item.copyWith(
        weight: (double.tryParse(item.weight) ?? 0) < 1 ? '1' : item.weight,
        value: item.value.isEmpty ? '0' : item.value,
      );
    }).toList();
    final adjusted = [
      ...normalized,
      ...List.generate(
        count - existing.length > 0 ? count - existing.length : 0,
        (_) => const PackageItemData(),
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
          previousCommonDescription.isNotEmpty &&
          descText == previousCommonDescription;
      if (newCommonDescription.isNotEmpty &&
          (descText.isEmpty || matchesPreviousDesc)) {
        updated = updated.copyWith(description: newCommonDescription);
      }
      return updated;
    }).toList();

    emit(
      state.copyWith(
        package: event.package.copyWith(
          packageCount: count,
          items: adjustedWithCommon,
        ),
      ),
    );
  }

  void _onDeliveryChanged(
    DomesticDeliveryDetailsChanged event,
    Emitter<DomesticCreateState> emit,
  ) {
    emit(state.copyWith(delivery: event.delivery));
  }

  Future<void> _onDraftDetailRequested(
    DomesticDraftDetailRequested event,
    Emitter<DomesticCreateState> emit,
  ) async {
    emit(state.copyWith(isCheckingDraft: true, errorMessage: null));
    try {
      final data = await _ordersRepository.fetchDraftDetails(
        token: token,
        draftOrderId: event.draftId,
      );
      bool onlyDraft = false;
      try {
        final page = await _getOrders(
          token: token,
          endpoint: 'customer/order/draft/list',
          page: 1,
          limit: 2,
        );
        onlyDraft = page.orders.length == 1 && page.lastPage == 1;
      } catch (_) {
        // Ignore count errors; default lock rules will apply.
      }
      final serviceTypeId =
          _parseInt(data['serviceTypeId']) ??
          _parseInt(data['service_type_id']) ??
          _parseInt((data['service_type_details'] as Map?)?['id']) ??
          0;
      final serviceType =
          _serviceTypeFromId(serviceTypeId) ??
          _mapServiceType(
            (data['service_type_details'] as Map?)?['name']?.toString() ?? '',
          ) ??
          DomesticServiceType.nextDay;

      // Map delivery
      BlockInfo? block;
      RoadInfo? road;
      BuildingInfo? building;
      if (data['destination_block_details'] is Map<String, dynamic>) {
        block = BlockInfo.fromJson(
          data['destination_block_details'] as Map<String, dynamic>,
        );
      }
      if (data['destination_road_details'] is Map<String, dynamic>) {
        road = RoadInfo.fromJson(
          data['destination_road_details'] as Map<String, dynamic>,
        );
      }
      if (data['destination_building_details'] is Map<String, dynamic>) {
        building = BuildingInfo.fromJson(
          data['destination_building_details'] as Map<String, dynamic>,
        );
      }

      String splitCode(String phone) {
        final digits = phone.replaceAll(' ', '');
        final match = RegExp(r'^\\+?(\\d{1,3})(.*)$').firstMatch(digits);
        if (match != null) {
          return '+${match.group(1)}';
        }
        return '+973';
      }

      String splitNumber(String phone) {
        final digits = phone.replaceAll(' ', '');
        final match = RegExp(r'^\\+?(\\d{1,3})(.*)$').firstMatch(digits);
        if (match != null) {
          return match.group(2) ?? '';
        }
        return phone;
      }

      final delivery = state.delivery.copyWith(
        receiverName:
            data['destinationCustomerName']?.toString() ??
            data['destination_customer_name']?.toString() ??
            '',
        receiverCountryCode: splitCode(
          data['destinationMobileNumber']?.toString() ??
              data['destination_mobile_number']?.toString() ??
              '',
        ),
        receiverPhone: splitNumber(
          data['destinationMobileNumber']?.toString() ??
              data['destination_mobile_number']?.toString() ??
              '',
        ),
        receiverAltCountryCode: splitCode(
          data['destinationAlternateNumber']?.toString() ??
              data['destination_alternate_number']?.toString() ??
              '+973',
        ),
        receiverAltPhone: splitNumber(
          data['destinationAlternateNumber']?.toString() ??
              data['destination_alternate_number']?.toString() ??
              '',
        ),
        block: block,
        road: road,
        building: building,
        flatOrOffice:
            data['destinationFlatOrOfficeNumber']?.toString() ??
            data['destination_flat_or_office_number']?.toString() ??
            '',
        instructions:
            data['deliveryInstructions']?.toString() ??
            data['delivery_instructions']?.toString() ??
            '',
        customerOrderId:
            data['customerInputOrderId']?.toString() ??
            data['customer_input_order_id']?.toString() ??
            '',
      );

      // Map packages
      final pkgList =
          ((data['draft_order_package_list'] as List<dynamic>?) ??
                  (data['draftOrderPackageList'] as List<dynamic>?) ??
                  const [])
              .whereType<Map<String, dynamic>>()
              .toList();
      final pkgCount = pkgList.isEmpty ? 1 : pkgList.length;
      final items = pkgList
          .map(
            (p) => PackageItemData(
              weight: p['weight']?.toString() ?? '1',
              description:
                  p['packageDescription']?.toString() ??
                  p['package_description']?.toString() ??
                  '',
              value:
                  p['customerInputPackageValue']?.toString() ??
                  p['customer_input_package_value']?.toString() ??
                  '0',
              externalPackageId:
                  p['external_package_id']?.toString() ??
                  p['externalPackageId']?.toString() ??
                  '',
            ),
          )
          .toList();
      while (items.length < pkgCount) {
        items.add(const PackageItemData());
      }
      final package = state.package.copyWith(
        packageCount: pkgCount,
        commonDescription:
            data['deliveryInstructions']?.toString() ??
            data['delivery_instructions']?.toString() ??
            '',
        items: items,
      );

      emit(
        state.copyWith(
          isCheckingDraft: false,
          lockedServiceType: onlyDraft ? null : serviceType,
          selectedServiceType: serviceType,
          orderData: {'id': data['id']},
          delivery: delivery,
          package: package,
          currentStep: 0,
        ),
      );
    } catch (e) {
      emit(state.copyWith(isCheckingDraft: false, errorMessage: e.toString()));
    }
  }

  void _onDraftChanged(
    DomesticDraftNotesChanged event,
    Emitter<DomesticCreateState> emit,
  ) {
    emit(state.copyWith(draftNotes: event.notes));
  }

  void _onStepChanged(
    DomesticStepChanged event,
    Emitter<DomesticCreateState> emit,
  ) {
    emit(state.copyWith(currentStep: event.step.clamp(0, 3)));
  }

  Future<void> _onNext(
    DomesticNextPressed event,
    Emitter<DomesticCreateState> emit,
  ) async {
    _logCollectedData(state);
    if (state.currentStep == 3) {
      await _acceptDraft(state, emit);
      return;
    }
    if (state.currentStep == 2) {
      final validationError = _validateDelivery(
        state.delivery,
        state.addressFormatTypeId,
      );
      if (validationError != null) {
        emit(state.copyWith(errorMessage: validationError));
        return;
      }
      emit(state.copyWith(errorMessage: null, isPreviewing: true));
      try {
        final payload = _buildPreviewPayload(state);
        final response = await _ordersRepository.previewDraftOrder(
          token: token,
          payload: payload,
        );
        emit(
          state.copyWith(
            isPreviewing: false,
            previewData: response['data'] as Map<String, dynamic>?,
            currentStep: 3,
          ),
        );
      } catch (error) {
        emit(
          state.copyWith(
            isPreviewing: false,
            errorMessage: _friendlyError(error),
          ),
        );
      }
      return;
    }
    if (state.currentStep == 1) {
      final pkgValidation = _validatePackages(state.package);
      if (pkgValidation != null) {
        emit(state.copyWith(errorMessage: pkgValidation));
        return;
      }
      emit(state.copyWith(isInitiating: true, errorMessage: null));
      try {
        final payload = _buildInitiatePayload(state);
        final response = await _ordersRepository.initiateDraftOrder(
          token: token,
          payload: payload,
        );
        emit(
          state.copyWith(
            isInitiating: false,
            orderData: response['data'] as Map<String, dynamic>?,
            currentStep: 2,
          ),
        );
        return;
      } catch (error) {
        emit(
          state.copyWith(
            isInitiating: false,
            errorMessage: _friendlyError(error),
          ),
        );
        return;
      }
    }

    final next = (state.currentStep + 1).clamp(0, 3);
    emit(state.copyWith(currentStep: next));
  }

  void _onBack(DomesticBackPressed event, Emitter<DomesticCreateState> emit) {
    final prev = (state.currentStep - 1).clamp(0, 3);
    emit(state.copyWith(currentStep: prev));
  }

  DomesticServiceType? _mapServiceType(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('express')) return DomesticServiceType.express;
    if (lower.contains('same')) return DomesticServiceType.sameDay;
    if (lower.contains('next')) return DomesticServiceType.nextDay;
    return null;
  }

  DomesticServiceType? _serviceTypeFromId(int? id) {
    switch (id) {
      case 1:
        return DomesticServiceType.sameDay;
      case 2:
        return DomesticServiceType.nextDay;
      case 3:
        return DomesticServiceType.express;
      default:
        return null;
    }
  }

  void _logCollectedData(DomesticCreateState current) {
    final payload = {
      'service_type': current.selectedServiceType.name,
      'order_flow_type_id': current.selectedOrderFlowTypeId,
      'package_count': current.package.packageCount,
      'common_description': current.package.commonDescription,
      'common_value': current.package.commonValue,
      'packages': current.package.items
          .asMap()
          .entries
          .map(
            (e) => {
              'package_id': e.key + 1,
              'weight': e.value.weight,
              'description': e.value.description,
              'value': e.value.value,
              'external_package_id': e.value.externalPackageId,
            },
          )
          .toList(),
      'delivery': {
        'receiver_name': current.delivery.receiverName,
        'receiver_phone': current.delivery.receiverPhone,
        'receiver_alt_phone': current.delivery.receiverAltPhone,
        // 'address': current.delivery.address,
      },
      'draft_notes': current.draftNotes,
    };
    // Simple console log for review
    // ignore: avoid_print
    print('Domestic create collected data: $payload');
  }

  Map<String, dynamic> _buildInitiatePayload(DomesticCreateState current) {
    final serviceTypeId = _mapServiceTypeId(current.selectedServiceType);
    final draftId = current.orderData?['id'] as int?;
    final packages = current.package.items.asMap().entries.map((e) {
      final weight = double.tryParse(e.value.weight) ?? 1;
      final value = double.tryParse(e.value.value) ?? 0;
      final externalId = e.value.externalPackageId.trim();
      return {
        'package_id': e.key + 1,
        'weight': weight < 1 ? 1 : weight,
        'package_description': e.value.description,
        'customer_input_package_value': value < 0 ? 0 : value,
        if (externalId.isNotEmpty) 'external_package_id': externalId,
      };
    }).toList();

    return {
      'order_type': 1,
      'service_type_id': serviceTypeId,
      'order_flow_type': current.selectedOrderFlowTypeId,
      'package_details': packages,
      'is_cod': current.package.isCod,
      if (current.package.isCod)
        'cod_amount': double.tryParse(current.package.codAmount) ?? 0,
      if (draftId != null) 'draft_order_id': draftId,
    };
  }

  int _mapServiceTypeId(DomesticServiceType type) {
    switch (type) {
      case DomesticServiceType.sameDay:
        return 1;
      case DomesticServiceType.nextDay:
        return 2;
      case DomesticServiceType.express:
        return 3;
    }
  }

  int? _parseInt(Object? raw) {
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    if (raw == null) return null;
    return int.tryParse(raw.toString());
  }

  Map<String, dynamic> _buildPreviewPayload(DomesticCreateState current) {
    final draftId = current.orderData?['id'] as int?;
    if (draftId == null) {
      throw Exception(
        'Draft order is missing. Please complete package step first.',
      );
    }
    final primaryPhone = _formatPhone(
      current.delivery.receiverCountryCode,
      current.delivery.receiverPhone,
    );
    final altPhone = _formatPhone(
      current.delivery.receiverAltCountryCode,
      current.delivery.receiverAltPhone,
    );

    final payload = {
      'draft_order_id': draftId,
      if (current.delivery.customerOrderId.trim().isNotEmpty)
        'customer_input_order_id': current.delivery.customerOrderId.trim(),
      'pickup_flat_or_office_number':
          current.delivery.flatOrOffice.trim().isEmpty
          ? null
          : current.delivery.flatOrOffice.trim(),
      'delivery_instructions': current.delivery.instructions.trim().isEmpty
          ? null
          : current.delivery.instructions.trim(),
      'destination_customer_name': current.delivery.receiverName,
      'destination_mobile_number': primaryPhone,
      if (altPhone.isNotEmpty) 'destination_alternate_number': altPhone,
      'destination_flat_or_office_number':
          current.delivery.flatOrOffice.trim().isEmpty
          ? null
          : current.delivery.flatOrOffice.trim(),
    };
    if (current.addressFormatTypeId == 2) {
      final address = current.delivery.destinationAddress.trim();
      payload['sender_address'] = address;
      payload['destination_address'] = address;
    } else {
      payload.addAll({
        'destination_block_id': current.delivery.block?.id,
        'destination_road_id':
            current.delivery.road?.id ??
            (current.delivery.roadName.isNotEmpty
                ? current.delivery.roadName
                : null),
        'destination_building_id':
            current.delivery.building?.id ??
            (current.delivery.buildingName.isNotEmpty
                ? current.delivery.buildingName
                : null),
        'pickup_block_id': 0,
        'pickup_road_id': 0,
        'pickup_building_id': 0,
      });
    }
    return payload;
  }

  String? _validateDelivery(
    DeliveryFormData delivery,
    int addressFormatTypeId,
  ) {
    if (addressFormatTypeId == 2) {
      if (delivery.destinationAddress.trim().isEmpty) {
        return 'Full address is required';
      }
      if (delivery.receiverName.trim().isEmpty) {
        return 'Receiver name is required';
      }
      if (delivery.receiverPhone.trim().isEmpty) {
        return 'Receiver contact number is required';
      }
      if (!_isValidPhone(
        delivery.receiverCountryCode,
        delivery.receiverPhone,
      )) {
        return 'Enter a valid contact number for ${delivery.receiverCountryCode}';
      }
      return null;
    }
    if (delivery.receiverName.trim().isEmpty) {
      return 'Receiver name is required';
    }
    if (delivery.receiverPhone.trim().isEmpty) {
      return 'Receiver contact number is required';
    }
    if (!_isValidPhone(delivery.receiverCountryCode, delivery.receiverPhone)) {
      return 'Enter a valid contact number for ${delivery.receiverCountryCode}';
    }
    if (delivery.receiverAltPhone.trim().isNotEmpty &&
        !_isValidPhone(
          delivery.receiverAltCountryCode,
          delivery.receiverAltPhone,
        )) {
      return 'Enter a valid alternate number for ${delivery.receiverAltCountryCode}';
    }
    if (delivery.block == null) {
      return 'Please select block';
    }
    final hasRoadSelection = delivery.road != null;
    final hasRoadText = delivery.roadName.trim().isNotEmpty;
    if (!hasRoadSelection && !hasRoadText) {
      return 'Please select or enter road';
    }
    final hasBuildingSelection = delivery.building != null;
    final hasBuildingText = delivery.buildingName.trim().isNotEmpty;
    if (!hasBuildingSelection && !hasBuildingText) {
      return 'Please select or enter building';
    }
    if (delivery.flatOrOffice.trim().isEmpty) {
      return 'Flat/Office number is required';
    }
    return null;
  }

  String? _validatePackages(PackageFormData package) {
    final seen = <String>{};
    for (final item in package.items) {
      final id = item.externalPackageId.trim();
      if (id.isEmpty) continue;
      if (!seen.add(id)) {
        return 'Duplicate custom package ID found: $id';
      }
    }
    return null;
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

  Future<void> _acceptDraft(
    DomesticCreateState current,
    Emitter<DomesticCreateState> emit,
  ) async {
    final draftId = current.orderData?['id'] as int?;
    if (draftId == null) {
      emit(state.copyWith(errorMessage: 'Draft order is missing'));
      return;
    }
    emit(state.copyWith(isAccepting: true, errorMessage: null));
    try {
      await _ordersRepository.acceptDraftOrder(
        token: token,
        draftOrderId: draftId,
      );
      emit(
        state.copyWith(
          isAccepting: false,
          orderAccepted: true,
          acceptedServiceType: state.selectedServiceType,
          currentStep: 0,
          selectedServiceType: DomesticServiceType.nextDay,
          selectedOrderFlowTypeId: state.orderFlowTypes.isNotEmpty
              ? state.orderFlowTypes.first.id
              : 1,
          previewData: null,
          orderData: null,
          package: const PackageFormData(),
          delivery: const DeliveryFormData(),
          draftNotes: '',
          blocks: const [],
          roads: const [],
          buildings: const [],
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(isAccepting: false, errorMessage: _friendlyError(error)),
      );
    }
  }

  void _onAcceptanceShown(
    DomesticAcceptanceShown event,
    Emitter<DomesticCreateState> emit,
  ) {
    emit(
      state.copyWith(
        orderAccepted: false,
        errorMessage: null,
        clearAcceptedServiceType: true,
      ),
    );
  }

  Future<void> _onBlocksRequested(
    DomesticBlocksRequested event,
    Emitter<DomesticCreateState> emit,
  ) async {
    emit(state.copyWith(isLoadingBlocks: true, errorMessage: null));
    try {
      final blocks = await _addressRepository.fetchBlocks(
        token: token,
        search: event.search,
      );
      emit(
        state.copyWith(
          isLoadingBlocks: false,
          blocks: blocks,
          delivery: state.delivery.copyWith(
            block: null,
            road: null,
            building: null,
          ),
          roads: const [],
          buildings: const [],
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          isLoadingBlocks: false,
          errorMessage: _friendlyError(error),
        ),
      );
    }
  }

  Future<void> _onRoadsRequested(
    DomesticRoadsRequested event,
    Emitter<DomesticCreateState> emit,
  ) async {
    emit(state.copyWith(isLoadingRoads: true, errorMessage: null));
    try {
      final roads = await _addressRepository.fetchRoads(
        token: token,
        blockId: event.blockId,
        search: event.search,
      );
      emit(state.copyWith(isLoadingRoads: false, roads: roads));
    } catch (error) {
      emit(
        state.copyWith(
          isLoadingRoads: false,
          errorMessage: _friendlyError(error),
        ),
      );
    }
  }

  Future<void> _onBuildingsRequested(
    DomesticBuildingsRequested event,
    Emitter<DomesticCreateState> emit,
  ) async {
    emit(state.copyWith(isLoadingBuildings: true, errorMessage: null));
    try {
      final buildings = await _addressRepository.fetchBuildings(
        token: token,
        blockId: event.blockId,
        roadId: event.roadId,
        search: event.search,
      );
      emit(state.copyWith(isLoadingBuildings: false, buildings: buildings));
    } catch (error) {
      emit(
        state.copyWith(
          isLoadingBuildings: false,
          errorMessage: _friendlyError(error),
        ),
      );
    }
  }

  void _onBlockSelected(
    DomesticBlockSelected event,
    Emitter<DomesticCreateState> emit,
  ) {
    emit(
      state.copyWith(
        delivery: DeliveryFormData(
          block: event.block,
          road: null,
          building: null,
          roadName: '',
          buildingName: '',
          customerOrderId: state.delivery.customerOrderId,
          receiverCountryCode: state.delivery.receiverCountryCode,
          receiverPhone: state.delivery.receiverPhone,
          receiverAltCountryCode: state.delivery.receiverAltCountryCode,
          receiverAltPhone: state.delivery.receiverAltPhone,
          receiverName: state.delivery.receiverName,
          destinationAddress: state.delivery.destinationAddress,
          flatOrOffice: state.delivery.flatOrOffice,
          instructions: state.delivery.instructions,
        ),
        roads: const [],
        buildings: const [],
      ),
    );
  }

  void _onRoadSelected(
    DomesticRoadSelected event,
    Emitter<DomesticCreateState> emit,
  ) {
    final roadChanged =
        event.road == null || event.road?.id != state.delivery.road?.id;
    final roadName =
        (event.customName ?? event.road?.name ?? state.delivery.roadName)
            .trim();
    emit(
      state.copyWith(
        delivery: DeliveryFormData(
          block: state.delivery.block,
          road: event.road,
          roadName: roadName,
          building: roadChanged ? null : state.delivery.building,
          buildingName: roadChanged ? '' : state.delivery.buildingName,
          customerOrderId: state.delivery.customerOrderId,
          receiverCountryCode: state.delivery.receiverCountryCode,
          receiverPhone: state.delivery.receiverPhone,
          receiverAltCountryCode: state.delivery.receiverAltCountryCode,
          receiverAltPhone: state.delivery.receiverAltPhone,
          receiverName: state.delivery.receiverName,
          destinationAddress: state.delivery.destinationAddress,
          flatOrOffice: state.delivery.flatOrOffice,
          instructions: state.delivery.instructions,
        ),
        buildings: roadChanged ? const [] : state.buildings,
      ),
    );
  }

  void _onBuildingSelected(
    DomesticBuildingSelected event,
    Emitter<DomesticCreateState> emit,
  ) {
    emit(
      state.copyWith(
        delivery: state.delivery.copyWith(
          building: event.building,
          buildingName: event.building == null ? '' : (event.building!.name),
        ),
      ),
    );
  }

  void _onAddressFormatChanged(
    DomesticAddressFormatChanged event,
    Emitter<DomesticCreateState> emit,
  ) {
    emit(state.copyWith(addressFormatTypeId: event.addressFormatTypeId));
  }

  void _onUserTypeChanged(
    DomesticUserTypeChanged event,
    Emitter<DomesticCreateState> emit,
  ) {
    emit(state.copyWith(userTypeId: event.userTypeId));
  }

  void _onFlowTypesLoaded(
    DomesticOrderFlowTypesLoaded event,
    Emitter<DomesticCreateState> emit,
  ) {
    if (event.flowTypes.isEmpty) return;
    final active = event.flowTypes.where((f) => f.isActive).toList();
    final list = active.isNotEmpty ? active : event.flowTypes;
    final selected = list.length == 1
        ? list.first.id
        : (list.any((f) => f.id == state.selectedOrderFlowTypeId)
              ? state.selectedOrderFlowTypeId
              : list.first.id);
    emit(
      state.copyWith(orderFlowTypes: list, selectedOrderFlowTypeId: selected),
    );
  }

  void _onFlowTypeChanged(
    DomesticOrderFlowTypeChanged event,
    Emitter<DomesticCreateState> emit,
  ) {
    if (state.orderFlowTypes.isEmpty) {
      emit(state.copyWith(selectedOrderFlowTypeId: event.flowTypeId));
      return;
    }
    final exists = state.orderFlowTypes.any((f) => f.id == event.flowTypeId);
    if (exists) {
      emit(state.copyWith(selectedOrderFlowTypeId: event.flowTypeId));
    }
  }

  String _friendlyError(Object error) {
    // Log raw error for debugging and return the server/error message to the user.
    // ignore: avoid_print
    print('Domestic create error: $error');
    final message = error.toString().trim();
    if (message.isEmpty) {
      return 'Something went wrong. Please try again.';
    }
    return message;
  }
}
