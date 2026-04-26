import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error_utils.dart';
import '../../../profile/domain/entities/address_entity.dart';
import '../../../profile/domain/repositories/address_repository.dart';
import '../../../profile/data/address_repository_impl.dart';
import '../../domain/entities/draft_place_preview.dart';
import '../../domain/repositories/orders_repository.dart';

part 'draft_place_event.dart';
part 'draft_place_state.dart';

class DraftPlaceBloc extends Bloc<DraftPlaceEvent, DraftPlaceState> {
  DraftPlaceBloc({
    required this.repository,
    required this.token,
    AddressRepository? addressRepository,
  })  : addressRepository = addressRepository ?? AddressRepositoryImpl(),
        super(const DraftPlaceState()) {
    on<DraftPlacePreviewRequested>(_onPreviewRequested);
    on<DraftPlacePickupDateChanged>(_onPickupDateChanged);
    on<DraftPlacePickupSlotChanged>(_onPickupSlotChanged);
    on<DraftPlaceConfirmed>(_onConfirmed);
  }

  final OrdersRepository repository;
  final String token;
  final AddressRepository addressRepository;

  Future<void> _onPreviewRequested(
    DraftPlacePreviewRequested event,
    Emitter<DraftPlaceState> emit,
  ) async {
    emit(state.copyWith(loading: true, errorMessage: null));
    try {
      final data = await repository.previewPlaceDraftOrders(token: token);
      final addresses = await addressRepository.fetchAddresses(token: token);
      final AddressEntity? primary = addresses.isEmpty
          ? null
          : addresses.firstWhere((a) => a.isPrimary, orElse: () => addresses.first);
      final primaryAddress = primary == null
          ? ''
          : [
              primary.buildingCode,
              primary.roadCode,
              primary.blockCode,
              primary.blockName,
            ].where((e) => e.isNotEmpty).join(', ');
      final primaryPhone = primary?.phone ?? '';
      emit(
        state.copyWith(
          loading: false,
          preview: data,
          serviceType: event.serviceType,
          primaryAddress: primaryAddress,
          primaryPhone: primaryPhone,
          primaryAddressEntity: primary,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          loading: false,
          errorMessage: ErrorUtils.friendly(e.toString()),
        ),
      );
    }
  }

  void _onPickupDateChanged(
    DraftPlacePickupDateChanged event,
    Emitter<DraftPlaceState> emit,
  ) {
    emit(
      state.copyWith(
        pickupDate: event.date,
        dateSelection: event.selection,
        pickupSlot: null,
      ),
    );
  }

  void _onPickupSlotChanged(
    DraftPlacePickupSlotChanged event,
    Emitter<DraftPlaceState> emit,
  ) {
    emit(state.copyWith(pickupSlot: event.slot));
  }
  
  Future<void> _onConfirmed(
    DraftPlaceConfirmed event,
    Emitter<DraftPlaceState> emit,
  ) async {
    if (state.pickupSlot == null || state.pickupDate == null) return;
    emit(state.copyWith(submitting: true, errorMessage: null, success: false));
    try {
      final dateStr = state.pickupDate!.toIso8601String().substring(0, 10);
      await repository.placeDraftOrders(
        token: token,
        payload: {
          'pickup_preference_date': dateStr,
          'pickup_slot_type': state.pickupSlot!,
        },
      );
      emit(state.copyWith(submitting: false, success: true));
    } catch (e) {
      emit(
        state.copyWith(
          submitting: false,
          success: false,
          errorMessage: ErrorUtils.friendly(e.toString()),
        ),
      );
    }
  }
}
