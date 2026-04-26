import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:delybell/core/error_utils.dart';
import '../../domain/entities/address_entity.dart';
import '../../domain/repositories/address_repository.dart';

part 'address_list_event.dart';
part 'address_list_state.dart';

class AddressListBloc extends Bloc<AddressListEvent, AddressListState> {
  AddressListBloc({required this.repository, required this.token})
      : super(const AddressListState()) {
    on<AddressListRequested>(_onFetch);
    on<AddressMarkPrimaryRequested>(_onMarkPrimary);
    on<AddressDeleteRequested>(_onDelete);
  }

  final AddressRepository repository;
  final String token;

  Future<void> _onFetch(
    AddressListRequested event,
    Emitter<AddressListState> emit,
  ) async {
    emit(state.copyWith(loading: true, error: null, message: null));
    try {
      final addresses = await repository.fetchAddresses(token: token);
      emit(state.copyWith(addresses: addresses, loading: false));
    } catch (e) {
      emit(
        state.copyWith(
          loading: false,
          error: ErrorUtils.friendly(e.toString()),
        ),
      );
    }
  }

  Future<void> _onMarkPrimary(
    AddressMarkPrimaryRequested event,
    Emitter<AddressListState> emit,
  ) async {
    emit(state.copyWith(loading: true, error: null, message: null));
    try {
      await repository.markPrimary(token: token, id: event.id);
      final updated = state.addresses
          .map((a) => a.id == event.id
              ? AddressEntity(
                  id: a.id,
                  title: a.title,
                  line1: a.line1,
                  line2: a.line2,
                  phone: a.phone,
                  isPrimary: true,
                  blockCode: a.blockCode,
                  blockName: a.blockName,
                  roadCode: a.roadCode,
                  buildingCode: a.buildingCode,
                )
              : AddressEntity(
                  id: a.id,
                  title: a.title,
                  line1: a.line1,
                  line2: a.line2,
                  phone: a.phone,
                  isPrimary: false,
                  blockCode: a.blockCode,
                  blockName: a.blockName,
                  roadCode: a.roadCode,
                  buildingCode: a.buildingCode,
                ))
          .toList();
      emit(state.copyWith(
        addresses: updated,
        loading: false,
        message: 'Marked as primary',
      ));
    } catch (e) {
      emit(
        state.copyWith(
          loading: false,
          error: ErrorUtils.friendly(e.toString()),
        ),
      );
    }
  }

  Future<void> _onDelete(
    AddressDeleteRequested event,
    Emitter<AddressListState> emit,
  ) async {
    emit(state.copyWith(loading: true, error: null, message: null));
    try {
      await repository.deleteAddress(token: token, id: event.id);
      final updated = state.addresses.where((a) => a.id != event.id).toList();
      emit(state.copyWith(
        addresses: updated,
        loading: false,
        message: 'Address deleted',
      ));
    } catch (e) {
      emit(
        state.copyWith(
          loading: false,
          error: ErrorUtils.friendly(e.toString()),
        ),
      );
    }
  }
}
