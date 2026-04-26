import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../dashboard/models/order_tracking.dart';
import '../../domain/repositories/orders_repository.dart';
import '../bloc/order_tracking_bloc.dart';

class OrderTrackingPage extends StatelessWidget {
  const OrderTrackingPage({
    super.key,
    required this.token,
    required this.orderId,
  });

  final String token;
  final int orderId;

  Image? _barcode(String data) {
    if (data.isEmpty) return null;
    final parts = data.split(',');
    final base64Part = parts.length > 1 ? parts.last : parts.first;
    try {
      final bytes = base64Decode(base64Part);
      return Image.memory(bytes, width: 140, height: 80, fit: BoxFit.contain);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          OrderTrackingBloc(context.read<OrdersRepository>(), token: token)
            ..add(OrderTrackingRequested(orderId: orderId)),
      child: Scaffold(
        appBar: AppBar(title: const Text('Order Tracking')),
        body: BlocBuilder<OrderTrackingBloc, OrderTrackingState>(
          builder: (context, state) {
            if (state.status == OrderTrackingStatus.loading ||
                state.status == OrderTrackingStatus.initial) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.status == OrderTrackingStatus.failure ||
                state.tracking == null) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(height: 8),
                    Text(state.errorMessage ?? 'Unable to load tracking'),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () {
                        context.read<OrderTrackingBloc>().add(
                          OrderTrackingRequested(orderId: orderId),
                        );
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            final tracking = state.tracking!;
            final barcodeImg = _barcode(tracking.barCode);
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Column(
                      children: [
                        if (barcodeImg != null) barcodeImg,
                        const SizedBox(height: 8),
                        Text(
                          'AWB No: ${tracking.generatedOrderId}',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          tracking.receiverName.isEmpty
                              ? 'Receiver'
                              : tracking.receiverName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: [
                            _tag(
                              tracking.status,
                              const Color(0xFFE0E7FF),
                              const Color(0xFF1D4ED8),
                            ),
                            _tag(
                              tracking.flowType,
                              const Color(0xFFEDE9FE),
                              const Color(0xFF7C3AED),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.place_outlined,
                              size: 16,
                              color: Color(0xFF6B7280),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                tracking.addressLine.isEmpty
                                    ? 'N/A'
                                    : tracking.addressLine,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Color(0xFF4B5563),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Order Status',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  _StatusTimeline(tracking: tracking),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _tag(String text, Color bg, Color fg) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 12),
      ),
    );
  }
}

class _StatusTimeline extends StatelessWidget {
  const _StatusTimeline({required this.tracking});

  final OrderTracking tracking;

  List<String> get _orderedStatuses => const [
    'OrderPlaced',
    'OrderPicked',
    'AtWarehouse',
    // 'InTransit',
    // 'AtDestinationWarehouse',
    'OutForDelivery',
    'Exception',
    'OutForDeliveryAfterException',
    'Delivered',
  ];

  @override
  Widget build(BuildContext context) {
    final historyTitles = tracking.history
        .map((h) => h.title.replaceAll(' ', ''))
        .toSet();
    final current = tracking.status.replaceAll(' ', '');
    final steps = _orderedStatuses;

    return Column(
      children: steps.asMap().entries.map((entry) {
        final idx = entry.key;
        final raw = entry.value;
        final title = _humanize(raw);
        final isDone = historyTitles.contains(raw);
        final isCurrent =
            current == raw || (!isDone && idx == historyTitles.length);
        final color = isCurrent
            ? const Color(0xFF6366F1)
            : isDone
            ? const Color(0xFF22C55E)
            : Colors.grey.shade400;

        final remarks = tracking.history
            .firstWhere(
              (h) => h.title.replaceAll(' ', '') == raw,
              orElse: () =>
                  OrderHistoryEntry(title: '', remarks: '', date: null),
            )
            .remarks;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Icon(
                  isDone || isCurrent
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: color,
                  size: 16,
                ),
                if (idx != steps.length - 1)
                  Container(width: 2, height: 32, color: Colors.grey.shade300),
              ],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: isCurrent
                            ? FontWeight.w800
                            : FontWeight.w600,
                        color: isCurrent
                            ? Colors.black
                            : const Color(0xFF4B5563),
                      ),
                    ),
                    if (remarks.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        remarks,
                        style: const TextStyle(color: Color(0xFF6B7280)),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  String _humanize(String input) {
    if (input.isEmpty) return input;
    final buffer = StringBuffer();
    for (var i = 0; i < input.length; i++) {
      final c = input[i];
      if (i > 0 && c.toUpperCase() == c && c != ' ') buffer.write(' ');
      buffer.write(c);
    }
    return buffer.toString();
  }
}
