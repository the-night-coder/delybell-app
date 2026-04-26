import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../data/domestic_order_repository.dart';
import '../models/address_lookup.dart';

part 'domestic_order_event.dart';
part 'domestic_order_state.dart';

class DomesticOrderBloc extends Bloc<DomesticOrderEvent, DomesticOrderState> {
  DomesticOrderBloc(this._repository, {required this.token})
      : super(const DomesticOrderState()) {
    on<DomesticServiceTypeChanged>(_onServiceTypeChanged);
    on<DomesticStepChanged>(_onStepChanged);
    on<DomesticPackageCountChanged>(_onPackageCountChanged);

    on<DomesticBlocksRequested>(_onBlocksRequested);
    on<DomesticBlockSelected>(_onBlockSelected);
    on<DomesticBlockCleared>(_onBlockCleared);

    on<DomesticRoadsRequested>(_onRoadsRequested);
    on<DomesticRoadSelected>(_onRoadSelected);
    on<DomesticRoadCleared>(_onRoadCleared);

    on<DomesticBuildingsRequested>(_onBuildingsRequested);
    on<DomesticBuildingSelected>(_onBuildingSelected);
    on<DomesticBuildingCleared>(_onBuildingCleared);
  }

  final DomesticOrderRepository _repository;
  final String token;

  void _onServiceTypeChanged(
    DomesticServiceTypeChanged event,
    Emitter<DomesticOrderState> emit,
  ) {
    emit(state.copyWith(serviceType: event.serviceType));
  }

  void _onStepChanged(
    DomesticStepChanged event,
    Emitter<DomesticOrderState> emit,
  ) {
    emit(state.copyWith(currentStep: event.step.clamp(0, 2)));
  }

  void _onPackageCountChanged(
    DomesticPackageCountChanged event,
    Emitter<DomesticOrderState> emit,
  ) {
    emit(state.copyWith(packageCount: event.count < 1 ? 1 : event.count));
  }

  Future<void> _onBlocksRequested(
    DomesticBlocksRequested event,
    Emitter<DomesticOrderState> emit,
  ) async {
    emit(state.copyWith(blocksStatus: LookupStatus.loading, blocksError: null));
    try {
      final blocks =
          await _repository.fetchBlocks(token: token, search: event.search ?? '');
      emit(
        state.copyWith(
          blocksStatus: LookupStatus.success,
          blocks: blocks,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          blocksStatus: LookupStatus.failure,
          blocksError: error.toString(),
        ),
      );
    }
  }

  void _onBlockSelected(
    DomesticBlockSelected event,
    Emitter<DomesticOrderState> emit,
  ) {
    emit(
      state.copyWith(
        selectedBlock: event.block,
        selectedRoad: null,
        selectedBuilding: null,
        roads: const [],
        buildings: const [],
      ),
    );
  }

  void _onBlockCleared(
    DomesticBlockCleared event,
    Emitter<DomesticOrderState> emit,
  ) {
    emit(
      state.copyWith(
        selectedBlock: null,
        selectedRoad: null,
        selectedBuilding: null,
        roads: const [],
        buildings: const [],
      ),
    );
  }

  Future<void> _onRoadsRequested(
    DomesticRoadsRequested event,
    Emitter<DomesticOrderState> emit,
  ) async {
    final block = state.selectedBlock;
    if (block == null) return;
    emit(state.copyWith(roadsStatus: LookupStatus.loading, roadsError: null));
    try {
      final roads = await _repository.fetchRoads(
        token: token,
        blockId: block.id,
        search: event.search ?? '',
      );
      emit(
        state.copyWith(
          roadsStatus: LookupStatus.success,
          roads: roads,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          roadsStatus: LookupStatus.failure,
          roadsError: error.toString(),
        ),
      );
    }
  }

  void _onRoadSelected(
    DomesticRoadSelected event,
    Emitter<DomesticOrderState> emit,
  ) {
    emit(
      state.copyWith(
        selectedRoad: event.road,
        selectedBuilding: null,
        buildings: const [],
      ),
    );
  }

  void _onRoadCleared(
    DomesticRoadCleared event,
    Emitter<DomesticOrderState> emit,
  ) {
    emit(
      state.copyWith(
        selectedRoad: null,
        selectedBuilding: null,
        buildings: const [],
      ),
    );
  }

  Future<void> _onBuildingsRequested(
    DomesticBuildingsRequested event,
    Emitter<DomesticOrderState> emit,
  ) async {
    final block = state.selectedBlock;
    final road = state.selectedRoad;
    if (block == null || road == null) return;

    emit(state.copyWith(buildingsStatus: LookupStatus.loading, buildingsError: null));
    try {
      final buildings = await _repository.fetchBuildings(
        token: token,
        blockId: block.id,
        roadId: road.id,
        search: event.search ?? '',
      );
      emit(
        state.copyWith(
          buildingsStatus: LookupStatus.success,
          buildings: buildings,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          buildingsStatus: LookupStatus.failure,
          buildingsError: error.toString(),
        ),
      );
    }
  }

  void _onBuildingSelected(
    DomesticBuildingSelected event,
    Emitter<DomesticOrderState> emit,
  ) {
    emit(state.copyWith(selectedBuilding: event.building));
  }

  void _onBuildingCleared(
    DomesticBuildingCleared event,
    Emitter<DomesticOrderState> emit,
  ) {
    emit(state.copyWith(selectedBuilding: null));
  }
}
