part of 'draft_place_bloc.dart';

abstract class DraftPlaceEvent extends Equatable {
  const DraftPlaceEvent();

  @override
  List<Object?> get props => [];
}

class DraftPlacePreviewRequested extends DraftPlaceEvent {
  const DraftPlacePreviewRequested({required this.serviceType});
  final String serviceType;

  @override
  List<Object?> get props => [serviceType];
}

enum DraftPickupDateSelection { today, tomorrow, custom }

class DraftPlacePickupDateChanged extends DraftPlaceEvent {
  const DraftPlacePickupDateChanged({
    required this.date,
    required this.selection,
  });
  final DateTime date;
  final DraftPickupDateSelection selection;

  @override
  List<Object?> get props => [date, selection];
}

class DraftPlacePickupSlotChanged extends DraftPlaceEvent {
  const DraftPlacePickupSlotChanged(this.slot);
  final int? slot;

  @override
  List<Object?> get props => [slot];
}

class DraftPlaceConfirmed extends DraftPlaceEvent {
  const DraftPlaceConfirmed();
}
