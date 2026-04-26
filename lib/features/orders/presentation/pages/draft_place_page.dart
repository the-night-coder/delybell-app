import 'package:delybell/features/profile/data/address_repository_impl.dart';
import 'package:delybell/features/profile/presentation/pages/address_form_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/app_colors.dart';
import '../../../profile/presentation/pages/address_list_page.dart';
import '../../domain/entities/draft_place_preview.dart';
import '../../domain/repositories/orders_repository.dart';
import '../bloc/draft_place_bloc.dart';
import 'draft_place_success_page.dart';

class DraftPlacePage extends StatelessWidget {
  const DraftPlacePage({
    super.key,
    required this.token,
    required this.serviceType,
  });

  final String token;
  final String serviceType;

  @override
  Widget build(BuildContext context) {
    final repo = context.read<OrdersRepository>();
    return BlocProvider(
      create: (_) =>
          DraftPlaceBloc(repository: repo, token: token)
            ..add(DraftPlacePreviewRequested(serviceType: serviceType)),
      child: const _DraftPlaceView(),
    );
  }
}

class _DraftPlaceView extends StatefulWidget {
  const _DraftPlaceView();

  @override
  State<_DraftPlaceView> createState() => _DraftPlaceViewState();
}

class _DraftPlaceViewState extends State<_DraftPlaceView> {
  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    context.read<DraftPlaceBloc>().add(
      DraftPlacePickupDateChanged(
        date: DateTime(today.year, today.month, today.day),
        selection: DraftPickupDateSelection.today,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Schedule Pickup')),
      body: BlocConsumer<DraftPlaceBloc, DraftPlaceState>(
        listenWhen: (p, c) =>
            p.success != c.success || p.errorMessage != c.errorMessage,
        listener: (context, state) {
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
          }
          if (state.success) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const DraftPlaceSuccessPage()),
            );
          }
        },
        builder: (context, state) {
          if (state.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.errorMessage != null && state.preview == null) {
            return _ErrorView(
              message: state.errorMessage!,
              onRetry: () => context.read<DraftPlaceBloc>().add(
                DraftPlacePreviewRequested(serviceType: state.serviceType),
              ),
            );
          }
          if (state.preview == null) {
            return const Center(child: Text('No preview data found'));
          }
          return _PreviewBody(state: state, colors: colors);
        },
      ),
    );
  }
}

class _PreviewBody extends StatelessWidget {
  const _PreviewBody({required this.state, required this.colors});

  final DraftPlaceState state;
  final AppColors colors;

  String _addressLine(DraftPlacePreview preview, DraftPlaceState state) {
    Map<String, dynamic>? fallbackMap(String code, {String name = ''}) {
      if (code.trim().isEmpty) return null;
      return {'code': code, 'name': name};
    }

    String part(Map<String, dynamic>? data, List<String> codeKeys) {
      final map = data ?? const {};
      final name = map['name']?.toString() ?? '';
      String code = '';
      for (final key in codeKeys) {
        final value = map[key];
        if (value != null && value.toString().isNotEmpty) {
          code = value.toString();
          break;
        }
      }
      if (name.isEmpty && code.isEmpty) return '';
      if (name.isNotEmpty && code.isNotEmpty) return '$name - $code';
      return name.isNotEmpty ? name : code;
    }

    final primary = state.primaryAddressEntity;
    final flat = primary?.line1.trim() ?? '';
    final building = part(
      preview.pickupBuildingDetails.isNotEmpty
          ? preview.pickupBuildingDetails
          : fallbackMap(primary?.buildingCode ?? ''),
      const ['code', 'buildingCode', 'building_code'],
    );
    final road = part(
      preview.pickupRoadDetails.isNotEmpty
          ? preview.pickupRoadDetails
          : fallbackMap(primary?.roadCode ?? ''),
      const ['code', 'roadCode', 'road_code'],
    );
    final block = part(
      preview.pickupBlockDetails.isNotEmpty
          ? preview.pickupBlockDetails
          : fallbackMap(primary?.blockCode ?? '', name: primary?.blockName ?? ''),
      const ['code', 'blockCode', 'block_code'],
    );

    final parts = <String>[];
    if (flat.isNotEmpty) parts.add(flat);
    for (final value in [building, road, block]) {
      if (value.isNotEmpty) parts.add(value);
    }

    if (parts.isEmpty) {
      final fallback = state.primaryAddress.trim();
      return fallback.isEmpty ? 'Not provided' : fallback;
    }
    return parts.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final preview = state.preview!;
    final date = state.pickupDate;
    String dateLabel() {
      if (date == null) return 'Select date';
      final months = [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December',
      ];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    }

    Widget chip({
      required String label,
      required bool selected,
      required VoidCallback onTap,
      IconData? icon,
      bool enabled = true,
    }) {
      return ChoiceChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16),
              const SizedBox(width: 6),
            ],
            Text(label),
          ],
        ),
        selected: selected,
        onSelected: enabled ? (_) => onTap() : null,
        selectedColor: colors.primarySoft,
        labelStyle: TextStyle(
          color: selected ? colors.primary : Colors.black,
          fontWeight: FontWeight.w700,
        ),
      );
    }

    final now = DateTime.now();

    bool isSameDay = state.serviceType.toLowerCase().contains('same');

    bool isTodaySelectable() {
      if (isSameDay) {
        return now.hour < 12;
      }
      // next day / express / others: allow if there is at least one slot left today
      return now.hour < 19;
    }

    List<int> enabledSlotsFor(DateTime? date) {
      if (date == null) return const [];
      final isToday =
          DateTime(now.year, now.month, now.day) ==
          DateTime(date.year, date.month, date.day);
      if (isSameDay) {
        if (isToday && now.hour >= 12) return const [];
        return const [1]; // only morning
      }
      final List<int> slots = [];
      // Morning: 09:00 - 12:00
      if (!isToday || now.hour < 12) slots.add(1);
      // Evening: 16:00 - 19:00
      if (!isToday || now.hour < 19) slots.add(3);
      return slots;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Service Type',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: colors.primarySoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    state.serviceType,
                    style: TextStyle(
                      color: colors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _InfoRow(
              label: 'No. of Orders',
              value: '${preview.numberOfDraftOrders}',
            ),
            _InfoRow(
              label: 'No. of Packages',
              value: '${preview.numberOfPackages}',
            ),
            const SizedBox(height: 8),
            if (preview.codAmount > 0)
              _InfoRow(
                label: 'COD Amount',
                value: 'BHD ${preview.codAmount.toStringAsFixed(3)}',
              ),
            if (preview.totalCodAmount > 0)
              _InfoRow(
                label: 'Total COD Amount',
                value: preview.totalCodAmount.toStringAsFixed(3),
              ),
            if (preview.codAmount > 0) const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Shipping Charge',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                Text(
                  'BHD ${preview.calculatedTotalShippingCharge.toStringAsFixed(3)}',
                  style: TextStyle(
                    color: colors.danger,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            const Text(
              'Pickup Address',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    _addressLine(preview, state),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                TextButton.icon(
                  onPressed: () async {
                    await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (_) => AddressListPage(
                          token: context.read<DraftPlaceBloc>().token,
                        ),
                      ),
                    );
                    if (context.mounted) {
                      context.read<DraftPlaceBloc>().add(
                        DraftPlacePreviewRequested(
                          serviceType: state.serviceType,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.location_on_rounded, size: 16),
                  label: const Text('Change'),
                ),
              ],
            ),
            if ((state.primaryPhone.isNotEmpty) ||
                preview.pickupContactNumber.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    const Icon(
                      Icons.phone_outlined,
                      size: 18,
                      color: Color(0xFF6B7280),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        state.primaryPhone.isNotEmpty
                            ? state.primaryPhone
                            : preview.pickupContactNumber,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () async {
                        final primary = state.primaryAddressEntity;
                        if (primary != null) {
                          await Navigator.of(context).push<bool>(
                            MaterialPageRoute(
                              builder: (_) => AddressFormPage(
                                address: primary,
                                token: context.read<DraftPlaceBloc>().token,
                                repository: AddressRepositoryImpl(),
                              ),
                            ),
                          );
                        } else {
                          await Navigator.of(context).push<bool>(
                            MaterialPageRoute(
                              builder: (_) => AddressListPage(
                                token: context.read<DraftPlaceBloc>().token,
                              ),
                            ),
                          );
                        }
                        if (context.mounted) {
                          context.read<DraftPlaceBloc>().add(
                            DraftPlacePreviewRequested(
                              serviceType: state.serviceType,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Edit'),
                    ),
                  ],
                ),
              ),
            const Divider(),
            const SizedBox(height: 12),
            const Text(
              'Pickup Date',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Builder(
              builder: (ctx) {
                final todayEnabled = isTodaySelectable();
                return Wrap(
                  spacing: 8,
                  children: [
                    chip(
                      label: 'Today',
                      selected:
                          state.dateSelection == DraftPickupDateSelection.today,
                      onTap: () {
                        final now = DateTime.now();
                        ctx.read<DraftPlaceBloc>().add(
                          DraftPlacePickupDateChanged(
                            date: DateTime(now.year, now.month, now.day),
                            selection: DraftPickupDateSelection.today,
                          ),
                        );
                      },
                      icon: Icons.calendar_today_outlined,
                      enabled: todayEnabled,
                    ),
                    chip(
                      label: 'Tomorrow',
                      selected:
                          state.dateSelection ==
                          DraftPickupDateSelection.tomorrow,
                      onTap: () {
                        final now = DateTime.now().add(const Duration(days: 1));
                        ctx.read<DraftPlaceBloc>().add(
                          DraftPlacePickupDateChanged(
                            date: DateTime(now.year, now.month, now.day),
                            selection: DraftPickupDateSelection.tomorrow,
                          ),
                        );
                      },
                      icon: Icons.calendar_view_day,
                    ),
                    chip(
                      label: 'Custom',
                      selected:
                          state.dateSelection ==
                          DraftPickupDateSelection.custom,
                      onTap: () async {
                        final now = DateTime.now();
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: state.pickupDate ?? now,
                          firstDate: now,
                          lastDate: now.add(const Duration(days: 30)),
                        );
                        if (picked != null) {
                          if (!ctx.mounted) return;
                          ctx.read<DraftPlaceBloc>().add(
                            DraftPlacePickupDateChanged(
                              date: DateTime(
                                picked.year,
                                picked.month,
                                picked.day,
                              ),
                              selection: DraftPickupDateSelection.custom,
                            ),
                          );
                        }
                      },
                      icon: Icons.event,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 8),
            Text(
              'Selected Date: ${dateLabel()}',
              style: const TextStyle(color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 16),
            const Text(
              'Pickup Time',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Builder(
              builder: (ctx) {
                final enabledSlots = enabledSlotsFor(state.pickupDate);
                return Wrap(
                  spacing: 8,
                  children: [
                    chip(
                      label: 'Morning',
                      selected: state.pickupSlot == 1,
                      onTap: () {
                        if (enabledSlots.contains(1)) {
                          ctx.read<DraftPlaceBloc>().add(
                            const DraftPlacePickupSlotChanged(1),
                          );
                        }
                      },
                      enabled: enabledSlots.contains(1),
                    ),
                    chip(
                      label: 'Evening',
                      selected: state.pickupSlot == 3,
                      onTap: () {
                        if (enabledSlots.contains(3)) {
                          ctx.read<DraftPlaceBloc>().add(
                            const DraftPlacePickupSlotChanged(3),
                          );
                        }
                      },
                      enabled: enabledSlots.contains(3),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed:
                    state.submitting ||
                        state.pickupSlot == null ||
                        state.pickupDate == null
                    ? null
                    : () => context.read<DraftPlaceBloc>().add(
                        const DraftPlaceConfirmed(),
                      ),
                child: Text(
                  state.submitting ? 'Confirming...' : 'Confirm Order',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
