part of 'domestic_order_bloc.dart';

enum DomesticServiceType { express, nextDay, sameDay }

enum LookupStatus { initial, loading, success, failure }

const _unset = Object();

class DomesticOrderState extends Equatable {
  const DomesticOrderState({
    this.currentStep = 0,
    this.serviceType = DomesticServiceType.nextDay,
    this.packageCount = 1,
    this.blocks = const [],
    this.blocksStatus = LookupStatus.initial,
    this.blocksError,
    this.selectedBlock,
    this.roads = const [],
    this.roadsStatus = LookupStatus.initial,
    this.roadsError,
    this.selectedRoad,
    this.buildings = const [],
    this.buildingsStatus = LookupStatus.initial,
    this.buildingsError,
    this.selectedBuilding,
  });

  final int currentStep;
  final DomesticServiceType serviceType;
  final int packageCount;

  final List<BlockInfo> blocks;
  final LookupStatus blocksStatus;
  final String? blocksError;
  final BlockInfo? selectedBlock;

  final List<RoadInfo> roads;
  final LookupStatus roadsStatus;
  final String? roadsError;
  final RoadInfo? selectedRoad;

  final List<BuildingInfo> buildings;
  final LookupStatus buildingsStatus;
  final String? buildingsError;
  final BuildingInfo? selectedBuilding;

  DomesticOrderState copyWith({
    int? currentStep,
    DomesticServiceType? serviceType,
    int? packageCount,
    List<BlockInfo>? blocks,
    LookupStatus? blocksStatus,
    Object? blocksError = _unset,
    Object? selectedBlock = _unset,
    List<RoadInfo>? roads,
    LookupStatus? roadsStatus,
    Object? roadsError = _unset,
    Object? selectedRoad = _unset,
    List<BuildingInfo>? buildings,
    LookupStatus? buildingsStatus,
    Object? buildingsError = _unset,
    Object? selectedBuilding = _unset,
  }) {
    return DomesticOrderState(
      currentStep: currentStep ?? this.currentStep,
      serviceType: serviceType ?? this.serviceType,
      packageCount: packageCount ?? this.packageCount,
      blocks: blocks ?? this.blocks,
      blocksStatus: blocksStatus ?? this.blocksStatus,
      blocksError: identical(blocksError, _unset)
          ? this.blocksError
          : blocksError as String?,
      selectedBlock: identical(selectedBlock, _unset)
          ? this.selectedBlock
          : selectedBlock as BlockInfo?,
      roads: roads ?? this.roads,
      roadsStatus: roadsStatus ?? this.roadsStatus,
      roadsError:
          identical(roadsError, _unset) ? this.roadsError : roadsError as String?,
      selectedRoad: identical(selectedRoad, _unset)
          ? this.selectedRoad
          : selectedRoad as RoadInfo?,
      buildings: buildings ?? this.buildings,
      buildingsStatus: buildingsStatus ?? this.buildingsStatus,
      buildingsError: identical(buildingsError, _unset)
          ? this.buildingsError
          : buildingsError as String?,
      selectedBuilding: identical(selectedBuilding, _unset)
          ? this.selectedBuilding
          : selectedBuilding as BuildingInfo?,
    );
  }

  @override
  List<Object?> get props => [
        currentStep,
        serviceType,
        packageCount,
        blocks,
        blocksStatus,
        blocksError,
        selectedBlock,
        roads,
        roadsStatus,
        roadsError,
        selectedRoad,
        buildings,
        buildingsStatus,
        buildingsError,
        selectedBuilding,
      ];
}
