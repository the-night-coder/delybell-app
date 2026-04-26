part of 'domestic_order_bloc.dart';

abstract class DomesticOrderEvent extends Equatable {
  const DomesticOrderEvent();

  @override
  List<Object?> get props => [];
}

class DomesticServiceTypeChanged extends DomesticOrderEvent {
  const DomesticServiceTypeChanged(this.serviceType);

  final DomesticServiceType serviceType;

  @override
  List<Object?> get props => [serviceType];
}

class DomesticStepChanged extends DomesticOrderEvent {
  const DomesticStepChanged(this.step);

  final int step;

  @override
  List<Object?> get props => [step];
}

class DomesticPackageCountChanged extends DomesticOrderEvent {
  const DomesticPackageCountChanged(this.count);

  final int count;

  @override
  List<Object?> get props => [count];
}

class DomesticBlocksRequested extends DomesticOrderEvent {
  const DomesticBlocksRequested({this.search});

  final String? search;

  @override
  List<Object?> get props => [search];
}

class DomesticBlockSelected extends DomesticOrderEvent {
  const DomesticBlockSelected(this.block);

  final BlockInfo block;

  @override
  List<Object?> get props => [block];
}

class DomesticBlockCleared extends DomesticOrderEvent {
  const DomesticBlockCleared();
}

class DomesticRoadsRequested extends DomesticOrderEvent {
  const DomesticRoadsRequested({this.search});

  final String? search;

  @override
  List<Object?> get props => [search];
}

class DomesticRoadSelected extends DomesticOrderEvent {
  const DomesticRoadSelected(this.road);

  final RoadInfo road;

  @override
  List<Object?> get props => [road];
}

class DomesticRoadCleared extends DomesticOrderEvent {
  const DomesticRoadCleared();
}

class DomesticBuildingsRequested extends DomesticOrderEvent {
  const DomesticBuildingsRequested({this.search});

  final String? search;

  @override
  List<Object?> get props => [search];
}

class DomesticBuildingSelected extends DomesticOrderEvent {
  const DomesticBuildingSelected(this.building);

  final BuildingInfo building;

  @override
  List<Object?> get props => [building];
}

class DomesticBuildingCleared extends DomesticOrderEvent {
  const DomesticBuildingCleared();
}
