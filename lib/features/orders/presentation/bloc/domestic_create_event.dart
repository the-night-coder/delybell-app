part of 'domestic_create_bloc.dart';

abstract class DomesticCreateEvent extends Equatable {
  const DomesticCreateEvent();

  @override
  List<Object?> get props => [];
}

class DomesticDraftCheckRequested extends DomesticCreateEvent {
  const DomesticDraftCheckRequested();
}

class DomesticServiceTypeChanged extends DomesticCreateEvent {
  const DomesticServiceTypeChanged(this.serviceType);

  final DomesticServiceType serviceType;

  @override
  List<Object?> get props => [serviceType];
}

class DomesticPackageDetailsChanged extends DomesticCreateEvent {
  const DomesticPackageDetailsChanged(this.package);

  final PackageFormData package;

  @override
  List<Object?> get props => [package];
}

class DomesticDeliveryDetailsChanged extends DomesticCreateEvent {
  const DomesticDeliveryDetailsChanged(this.delivery);

  final DeliveryFormData delivery;

  @override
  List<Object?> get props => [delivery];
}

class DomesticBlocksRequested extends DomesticCreateEvent {
  const DomesticBlocksRequested({this.search = ''});

  final String search;

  @override
  List<Object?> get props => [search];
}

class DomesticRoadsRequested extends DomesticCreateEvent {
  const DomesticRoadsRequested({required this.blockId, this.search = ''});

  final int blockId;
  final String search;

  @override
  List<Object?> get props => [blockId, search];
}

class DomesticBuildingsRequested extends DomesticCreateEvent {
  const DomesticBuildingsRequested({
    required this.blockId,
    required this.roadId,
    this.search = '',
  });

  final int blockId;
  final int roadId;
  final String search;

  @override
  List<Object?> get props => [blockId, roadId, search];
}

class DomesticBlockSelected extends DomesticCreateEvent {
  const DomesticBlockSelected(this.block);

  final BlockInfo? block;

  @override
  List<Object?> get props => [block];
}

class DomesticRoadSelected extends DomesticCreateEvent {
  const DomesticRoadSelected(this.road, {this.customName});

  final RoadInfo? road;
  final String? customName;

  @override
  List<Object?> get props => [road, customName];
}

class DomesticBuildingSelected extends DomesticCreateEvent {
  const DomesticBuildingSelected(this.building);

  final BuildingInfo? building;

  @override
  List<Object?> get props => [building];
}

class DomesticAddressFormatChanged extends DomesticCreateEvent {
  const DomesticAddressFormatChanged(this.addressFormatTypeId);

  final int addressFormatTypeId;

  @override
  List<Object?> get props => [addressFormatTypeId];
}

class DomesticOrderFlowTypesLoaded extends DomesticCreateEvent {
  const DomesticOrderFlowTypesLoaded(this.flowTypes);

  final List<OrderFlowType> flowTypes;

  @override
  List<Object?> get props => [flowTypes];
}

class DomesticOrderFlowTypeChanged extends DomesticCreateEvent {
  const DomesticOrderFlowTypeChanged(this.flowTypeId);

  final int flowTypeId;

  @override
  List<Object?> get props => [flowTypeId];
}

class DomesticUserTypeChanged extends DomesticCreateEvent {
  const DomesticUserTypeChanged(this.userTypeId);

  final int userTypeId;

  @override
  List<Object?> get props => [userTypeId];
}

class DomesticDraftNotesChanged extends DomesticCreateEvent {
  const DomesticDraftNotesChanged(this.notes);

  final String notes;

  @override
  List<Object?> get props => [notes];
}

class DomesticStepChanged extends DomesticCreateEvent {
  const DomesticStepChanged(this.step);

  final int step;

  @override
  List<Object?> get props => [step];
}

class DomesticNextPressed extends DomesticCreateEvent {
  const DomesticNextPressed();
}

class DomesticBackPressed extends DomesticCreateEvent {
  const DomesticBackPressed();
}

class DomesticAcceptanceShown extends DomesticCreateEvent {
  const DomesticAcceptanceShown();
}

class DomesticDraftDetailRequested extends DomesticCreateEvent {
  const DomesticDraftDetailRequested(this.draftId);
  final int draftId;

  @override
  List<Object?> get props => [draftId];
}
