import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;

import '../../../../core/error_utils.dart';
import '../../../../core/static.dart';
import '../../domain/repositories/address_repository.dart';

class AddressFormState {
  const AddressFormState({
    this.submitting = false,
    this.error,
    this.success = false,
    this.blockOptions = const [],
    this.roadOptions = const [],
    this.buildingOptions = const [],
    this.blockLoading = false,
    this.roadLoading = false,
    this.buildingLoading = false,
  });

  final bool submitting;
  final String? error;
  final bool success;
  final List<Map<String, dynamic>> blockOptions;
  final List<Map<String, dynamic>> roadOptions;
  final List<Map<String, dynamic>> buildingOptions;
  final bool blockLoading;
  final bool roadLoading;
  final bool buildingLoading;

  AddressFormState copyWith({
    bool? submitting,
    String? error,
    bool? success,
    List<Map<String, dynamic>>? blockOptions,
    List<Map<String, dynamic>>? roadOptions,
    List<Map<String, dynamic>>? buildingOptions,
    bool? blockLoading,
    bool? roadLoading,
    bool? buildingLoading,
  }) {
    return AddressFormState(
      submitting: submitting ?? this.submitting,
      error: error,
      success: success ?? this.success,
      blockOptions: blockOptions ?? this.blockOptions,
      roadOptions: roadOptions ?? this.roadOptions,
      buildingOptions: buildingOptions ?? this.buildingOptions,
      blockLoading: blockLoading ?? this.blockLoading,
      roadLoading: roadLoading ?? this.roadLoading,
      buildingLoading: buildingLoading ?? this.buildingLoading,
    );
  }
}

abstract class AddressFormEvent {
  const AddressFormEvent();
}

class AddressFormSubmit extends AddressFormEvent {
  const AddressFormSubmit({required this.id, required this.payload});
  final int id;
  final Map<String, dynamic> payload;
}

class AddressFormCreate extends AddressFormEvent {
  const AddressFormCreate({required this.payload});
  final Map<String, dynamic> payload;
}

class AddressFormLoadBlocks extends AddressFormEvent {
  const AddressFormLoadBlocks();
}

class AddressFormLoadRoads extends AddressFormEvent {
  const AddressFormLoadRoads(this.blockId);
  final int blockId;
}

class AddressFormLoadBuildings extends AddressFormEvent {
  const AddressFormLoadBuildings(this.blockId, this.roadId);
  final int blockId;
  final int roadId;
}

class AddressFormClearRoads extends AddressFormEvent {
  const AddressFormClearRoads();
}

class AddressFormClearBuildings extends AddressFormEvent {
  const AddressFormClearBuildings();
}

class AddressFormBloc extends Bloc<AddressFormEvent, AddressFormState> {
  AddressFormBloc({
    required this.repository,
    required this.token,
    http.Client? client,
  })  : _client = client ?? http.Client(),
        super(const AddressFormState()) {
    on<AddressFormSubmit>(_onSubmit);
    on<AddressFormCreate>(_onCreate);
    on<AddressFormLoadBlocks>(_onLoadBlocks);
    on<AddressFormLoadRoads>(_onLoadRoads);
    on<AddressFormLoadBuildings>(_onLoadBuildings);
    on<AddressFormClearRoads>(_onClearRoads);
    on<AddressFormClearBuildings>(_onClearBuildings);
  }

  final AddressRepository repository;
  final String token;
  final http.Client _client;

  Future<void> _onSubmit(
    AddressFormSubmit event,
    Emitter<AddressFormState> emit,
  ) async {
    emit(state.copyWith(submitting: true, error: null, success: false));
    try {
      await repository.updateAddress(
        token: token,
        id: event.id,
        payload: event.payload,
      );
      emit(state.copyWith(submitting: false, success: true));
    } catch (e) {
      emit(state.copyWith(
        submitting: false,
        error: ErrorUtils.friendly(e.toString()),
      ));
    }
  }

  Future<void> _onCreate(
    AddressFormCreate event,
    Emitter<AddressFormState> emit,
  ) async {
    emit(state.copyWith(submitting: true, error: null, success: false));
    try {
      await repository.createAddress(
        token: token,
        payload: event.payload,
      );
      emit(state.copyWith(submitting: false, success: true));
    } catch (e) {
      emit(state.copyWith(
        submitting: false,
        error: ErrorUtils.friendly(e.toString()),
      ));
    }
  }

  Future<void> _onLoadBlocks(
    AddressFormLoadBlocks event,
    Emitter<AddressFormState> emit,
  ) async {
    emit(state.copyWith(blockLoading: true, error: null));
    try {
      final items = await _fetch('user/master/block/list?search=');
      emit(state.copyWith(blockOptions: items, blockLoading: false));
    } catch (e) {
      emit(state.copyWith(
        blockLoading: false,
        error: ErrorUtils.friendly(e.toString()),
      ));
    }
  }

  Future<void> _onLoadRoads(
    AddressFormLoadRoads event,
    Emitter<AddressFormState> emit,
  ) async {
    emit(state.copyWith(roadLoading: true, error: null));
    try {
      final items =
          await _fetch('user/master/road/list?block_id=${event.blockId}&search=');
      emit(state.copyWith(roadOptions: items, roadLoading: false));
    } catch (e) {
      emit(state.copyWith(
        roadLoading: false,
        error: ErrorUtils.friendly(e.toString()),
      ));
    }
  }

  Future<void> _onLoadBuildings(
    AddressFormLoadBuildings event,
    Emitter<AddressFormState> emit,
  ) async {
    emit(state.copyWith(buildingLoading: true, error: null));
    try {
      final items = await _fetch(
        'user/master/building/list?block_id=${event.blockId}&road_id=${event.roadId}&search=',
      );
      emit(state.copyWith(buildingOptions: items, buildingLoading: false));
    } catch (e) {
      emit(state.copyWith(
        buildingLoading: false,
        error: ErrorUtils.friendly(e.toString()),
      ));
    }
  }

  void _onClearRoads(
    AddressFormClearRoads event,
    Emitter<AddressFormState> emit,
  ) {
    emit(
      state.copyWith(
        roadOptions: const [],
        buildingOptions: const [],
        roadLoading: false,
        buildingLoading: false,
      ),
    );
  }

  void _onClearBuildings(
    AddressFormClearBuildings event,
    Emitter<AddressFormState> emit,
  ) {
    emit(
      state.copyWith(
        buildingOptions: const [],
        buildingLoading: false,
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _fetch(String path) async {
    final uri = Uri.parse('${Static.baseUrl}$path');
    final res = await _client.get(uri, headers: {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    });
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final body = jsonDecode(res.body) as Map<String, dynamic>? ?? {};
      final data = body['data'] as List<dynamic>? ?? const [];
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('Failed to load data. Please retry.');
  }
}
