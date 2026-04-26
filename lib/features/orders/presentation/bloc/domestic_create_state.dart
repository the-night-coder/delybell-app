part of 'domestic_create_bloc.dart';

enum DomesticServiceType { express, nextDay, sameDay }
const _unset = Object();

class DomesticCreateState extends Equatable {
  const DomesticCreateState({
    this.currentStep = 0,
    this.selectedServiceType = DomesticServiceType.nextDay,
    this.lockedServiceType,
    this.orderFlowTypes = const [],
    this.selectedOrderFlowTypeId = 1,
    this.isCheckingDraft = false,
    this.isInitiating = false,
    this.isPreviewing = false,
    this.isAccepting = false,
    this.orderAccepted = false,
    this.errorMessage,
    this.orderData,
    this.previewData,
    this.package = const PackageFormData(),
    this.delivery = const DeliveryFormData(),
    this.draftNotes = '',
    this.blocks = const [],
    this.roads = const [],
    this.buildings = const [],
    this.isLoadingBlocks = false,
    this.isLoadingRoads = false,
    this.isLoadingBuildings = false,
    this.acceptedServiceType,
    this.addressFormatTypeId = 1,
    this.userTypeId = 0,
  });

  final int currentStep;
  final DomesticServiceType selectedServiceType;
  final DomesticServiceType? lockedServiceType;
  final List<OrderFlowType> orderFlowTypes;
  final int selectedOrderFlowTypeId;
  final bool isCheckingDraft;
  final bool isInitiating;
  final bool isPreviewing;
  final bool isAccepting;
  final bool orderAccepted;
  final DomesticServiceType? acceptedServiceType;
  final String? errorMessage;
  final Map<String, dynamic>? orderData;
  final Map<String, dynamic>? previewData;
  final PackageFormData package;
  final DeliveryFormData delivery;
  final String draftNotes;
  final List<BlockInfo> blocks;
  final List<RoadInfo> roads;
  final List<BuildingInfo> buildings;
  final bool isLoadingBlocks;
  final bool isLoadingRoads;
  final bool isLoadingBuildings;
  final int addressFormatTypeId;
  final int userTypeId;

  DomesticCreateState copyWith({
    int? currentStep,
    DomesticServiceType? selectedServiceType,
    Object? lockedServiceType = _unset,
    List<OrderFlowType>? orderFlowTypes,
    int? selectedOrderFlowTypeId,
    bool? isCheckingDraft,
    bool? isInitiating,
    bool? isPreviewing,
    bool? isAccepting,
    bool? orderAccepted,
    DomesticServiceType? acceptedServiceType,
    bool clearAcceptedServiceType = false,
    String? errorMessage,
    Object? orderData = _unset,
    Object? previewData = _unset,
    PackageFormData? package,
    DeliveryFormData? delivery,
    String? draftNotes,
    List<BlockInfo>? blocks,
    List<RoadInfo>? roads,
    List<BuildingInfo>? buildings,
    bool? isLoadingBlocks,
    bool? isLoadingRoads,
    bool? isLoadingBuildings,
    int? addressFormatTypeId,
    int? userTypeId,
  }) {
    return DomesticCreateState(
      currentStep: currentStep ?? this.currentStep,
      selectedServiceType: selectedServiceType ?? this.selectedServiceType,
      lockedServiceType: identical(lockedServiceType, _unset)
          ? this.lockedServiceType
          : lockedServiceType as DomesticServiceType?,
      orderFlowTypes: orderFlowTypes ?? this.orderFlowTypes,
      selectedOrderFlowTypeId: selectedOrderFlowTypeId ?? this.selectedOrderFlowTypeId,
      isCheckingDraft: isCheckingDraft ?? this.isCheckingDraft,
      isInitiating: isInitiating ?? this.isInitiating,
      isPreviewing: isPreviewing ?? this.isPreviewing,
      isAccepting: isAccepting ?? this.isAccepting,
      orderAccepted: orderAccepted ?? this.orderAccepted,
      acceptedServiceType:
          clearAcceptedServiceType ? null : (acceptedServiceType ?? this.acceptedServiceType),
      errorMessage: errorMessage,
      orderData: identical(orderData, _unset)
          ? this.orderData
          : orderData as Map<String, dynamic>?,
      previewData: identical(previewData, _unset)
          ? this.previewData
          : previewData as Map<String, dynamic>?,
      package: package ?? this.package,
      delivery: delivery ?? this.delivery,
      draftNotes: draftNotes ?? this.draftNotes,
      blocks: blocks ?? this.blocks,
      roads: roads ?? this.roads,
      buildings: buildings ?? this.buildings,
      isLoadingBlocks: isLoadingBlocks ?? this.isLoadingBlocks,
      isLoadingRoads: isLoadingRoads ?? this.isLoadingRoads,
      isLoadingBuildings: isLoadingBuildings ?? this.isLoadingBuildings,
      addressFormatTypeId: addressFormatTypeId ?? this.addressFormatTypeId,
      userTypeId: userTypeId ?? this.userTypeId,
    );
  }

  @override
  List<Object?> get props => [
        currentStep,
        selectedServiceType,
        lockedServiceType,
        orderFlowTypes,
        selectedOrderFlowTypeId,
        isCheckingDraft,
        isInitiating,
        isPreviewing,
        isAccepting,
        orderAccepted,
        acceptedServiceType,
        errorMessage,
        orderData,
        previewData,
        package,
        delivery,
        draftNotes,
        blocks,
        roads,
        buildings,
        isLoadingBlocks,
        isLoadingRoads,
        isLoadingBuildings,
        addressFormatTypeId,
        userTypeId,
      ];
}

class PackageFormData extends Equatable {
  const PackageFormData({
    this.packageCount = 1,
    this.commonDescription = '',
    this.commonValue = '',
    this.items = const [PackageItemData()],
    this.isCod = false,
    this.codAmount = '0',
  });

  final int packageCount;
  final String commonDescription;
  final String commonValue;
  final List<PackageItemData> items;
  final bool isCod;
  final String codAmount;

  PackageFormData copyWith({
    int? packageCount,
    String? commonDescription,
    String? commonValue,
    List<PackageItemData>? items,
    bool? isCod,
    String? codAmount,
  }) {
    return PackageFormData(
      packageCount: packageCount ?? this.packageCount,
      commonDescription: commonDescription ?? this.commonDescription,
      commonValue: commonValue ?? this.commonValue,
      items: items ?? this.items,
      isCod: isCod ?? this.isCod,
      codAmount: codAmount ?? this.codAmount,
    );
  }

  @override
  List<Object?> get props => [packageCount, commonDescription, commonValue, items, isCod, codAmount];
}

class DeliveryFormData extends Equatable {
  const DeliveryFormData({
    this.customerOrderId = '',
    this.receiverCountryCode = '+973',
    this.receiverPhone = '',
    this.receiverAltCountryCode = '+973',
    this.receiverAltPhone = '',
    this.receiverName = '',
    this.block,
    this.road,
    this.building,
    this.roadName = '',
    this.buildingName = '',
    this.destinationAddress = '',
    this.flatOrOffice = '',
    this.instructions = '',
  });

  final String customerOrderId;
  final String receiverCountryCode;
  final String receiverName;
  final String receiverAltCountryCode;
  final String receiverPhone;
  final String receiverAltPhone;
  final BlockInfo? block;
  final RoadInfo? road;
  final BuildingInfo? building;
  final String roadName;
  final String buildingName;
  final String destinationAddress;
  final String flatOrOffice;
  final String instructions;

  DeliveryFormData copyWith({
    String? customerOrderId,
    String? receiverCountryCode,
    String? receiverName,
    String? receiverAltCountryCode,
    String? receiverPhone,
    String? receiverAltPhone,
    BlockInfo? block,
    RoadInfo? road,
    BuildingInfo? building,
    String? roadName,
    String? buildingName,
    String? destinationAddress,
    String? flatOrOffice,
    String? instructions,
  }) {
    return DeliveryFormData(
      customerOrderId: customerOrderId ?? this.customerOrderId,
      receiverCountryCode: receiverCountryCode ?? this.receiverCountryCode,
      receiverName: receiverName ?? this.receiverName,
      receiverAltCountryCode: receiverAltCountryCode ?? this.receiverAltCountryCode,
      receiverPhone: receiverPhone ?? this.receiverPhone,
      receiverAltPhone: receiverAltPhone ?? this.receiverAltPhone,
      block: block ?? this.block,
      road: road ?? this.road,
      building: building ?? this.building,
      roadName: roadName ?? this.roadName,
      buildingName: buildingName ?? this.buildingName,
      destinationAddress: destinationAddress ?? this.destinationAddress,
      flatOrOffice: flatOrOffice ?? this.flatOrOffice,
      instructions: instructions ?? this.instructions,
    );
  }

  @override
  List<Object?> get props => [
        customerOrderId,
        receiverCountryCode,
        receiverName,
        receiverAltCountryCode,
        receiverPhone,
        receiverAltPhone,
        block,
        road,
        building,
        roadName,
        buildingName,
        destinationAddress,
        flatOrOffice,
        instructions,
      ];
}

class PackageItemData extends Equatable {
  const PackageItemData({
    this.weight = '1',
    this.description = '',
    this.value = '0',
    this.externalPackageId = '',
  });

  final String weight;
  final String description;
  final String value;
  final String externalPackageId;

  PackageItemData copyWith({
    String? weight,
    String? description,
    String? value,
    String? externalPackageId,
  }) {
    return PackageItemData(
      weight: weight ?? this.weight,
      description: description ?? this.description,
      value: value ?? this.value,
      externalPackageId: externalPackageId ?? this.externalPackageId,
    );
  }

  @override
  List<Object?> get props => [weight, description, value, externalPackageId];
}
