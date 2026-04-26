import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../dashboard/models/order_summary.dart';
import '../../domain/repositories/orders_repository.dart';
import 'bluetooth_print_page.dart';
import 'order_tracking_page.dart';

class OrderDetailPage extends StatefulWidget {
  const OrderDetailPage({super.key, required this.order, required this.token});

  final OrderSummary order;
  final String token;

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  static const bool _printingEnabled = true;
  bool _packagesExpanded = false;

  Image? _barcodeImage() {
    if (widget.order.barCode.isEmpty) return null;
    final parts = widget.order.barCode.split(',');
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
    final barcodeWidget = _barcodeImage();
    final order = widget.order;
    final isInternational =
        order.orderType.toLowerCase().contains('international');
    final fromName = _firstNonEmpty([order.pickupName], fallback: 'N/A');
    final fromPhone = _firstNonEmpty(
      [order.pickupPhone, order.pickupAltPhone],
      fallback: 'N/A',
    );
    final fromAddress = _firstNonEmpty(
      [order.pickupAddressLine, order.addressLine, order.senderAddress],
      fallback: 'N/A',
    );
    final toName = _firstNonEmpty([order.receiverName], fallback: 'N/A');
    final toPhone = _firstNonEmpty(
      [order.receiverPhone, order.receiverAltPhone],
      fallback: 'N/A',
    );
    final toAddress = _firstNonEmpty(
      [order.destinationAddress, order.addressLine],
      fallback: 'N/A',
    );
    return Scaffold(
      appBar: AppBar(title: Text(order.generatedOrderId)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _tag(
                    order.serviceType,
                    const Color(0xFFEDE9FE),
                    const Color(0xFF7C3AED),
                  ),
                  _tag(
                    order.orderType,
                    const Color(0xFFE0F2FE),
                    const Color(0xFF0284C7),
                  ),
                  _tag(
                    order.status,
                    const Color(0xFFEFF6FF),
                    const Color(0xFF2563EB),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'AWB No: ${order.generatedOrderId}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              if (isInternational) ...[
                _contactSection(
                  title: 'From',
                  name: fromName,
                  phone: fromPhone,
                  address: fromAddress,
                ),
                const SizedBox(height: 12),
                _contactSection(
                  title: 'To',
                  name: toName,
                  phone: toPhone,
                  address: toAddress,
                ),
                if (barcodeWidget != null) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: barcodeWidget,
                  ),
                ],
              ] else ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (order.receiverName.isNotEmpty)
                            Text(
                              order.receiverName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          const SizedBox(height: 8),
                          if (order.receiverPhone.isNotEmpty)
                            Row(
                              children: [
                                const Icon(
                                  Icons.phone,
                                  size: 16,
                                  color: Color(0xFF6B7280),
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    order.receiverPhone,
                                    style: const TextStyle(
                                      color: Color(0xFF4B5563),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          const SizedBox(height: 6),
                        ],
                      ),
                    ),
                    const SizedBox(width: 5),
                    if (barcodeWidget != null) barcodeWidget,
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.place_outlined,
                      size: 16,
                      color: Color(0xFF6B7280),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        order.addressLine.isEmpty ? 'N/A' : order.addressLine,
                        style: const TextStyle(color: Color(0xFF4B5563)),
                      ),
                    ),
                  ],
                ),
              ],
              const Divider(),
              _rowItem(
                'Shipping Charge',
                'BHD ${order.shippingCharge.isEmpty ? '0.000' : order.shippingCharge}',
                highlight: true,
              ),
              if (order.isCod) _rowItem('COD Amount', 'BHD ${order.codAmount}'),
              Divider(),
              // const SizedBox(height: 8),
              // Text(
              //   'Sender Address',
              //   style: TextStyle(
              //     color: Colors.grey.shade700,
              //     fontWeight: FontWeight.w500,
              //   ),
              // ),
              // const SizedBox(height: 5),
              // Text(order.senderAddress),
              // const SizedBox(height: 6),
              // Divider(),
              _packageListSection(),
              Divider(),
              _rowItem('Total Weight', '${order.totalWeight} KG'),
              _rowItem('Pickup Date', order.pickupDate),
              _rowItem('Pickup Slot', order.pickupSlot),
              const SizedBox(height: 16),
              Center(
                child: Row(
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.travel_explore_outlined, size: 16),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => RepositoryProvider.value(
                              value: context.read<OrdersRepository>(),
                              child: OrderTrackingPage(
                                token: widget.token,
                                orderId: order.id,
                              ),
                            ),
                          ),
                        );
                      },
                      label: const Text('Track now'),
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                      ),
                    ),
                    if (_printingEnabled) ...[
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.print_outlined, size: 16),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => BluetoothPrintPage(order: order),
                            ),
                          );
                        },
                        label: const Text('Print label'),
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                  ],
                ),
              ),
            ],
          ),
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

  String _firstNonEmpty(List<String> values, {String fallback = 'N/A'}) {
    for (final value in values) {
      final trimmed = value.trim();
      if (trimmed.isNotEmpty && trimmed != '-') return trimmed;
    }
    return fallback;
  }

  Widget _contactSection({
    required String title,
    required String name,
    required String phone,
    required String address,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text(
          name.isEmpty ? 'N/A' : name,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        const SizedBox(height: 6),
        _iconLine(Icons.phone, phone.isEmpty ? 'N/A' : phone),
        const SizedBox(height: 6),
        _iconLine(Icons.place_outlined, address.isEmpty ? 'N/A' : address),
      ],
    );
  }

  Widget _iconLine(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF6B7280)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Color(0xFF4B5563)),
          ),
        ),
      ],
    );
  }

  Widget _rowItem(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF6B7280)),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: highlight ? FontWeight.w800 : FontWeight.w600,
              color: highlight
                  ? const Color(0xFFB91C1C)
                  : const Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }

  Widget _packageListSection() {
    final pkgs = widget.order.packages;
    final items = pkgs.isEmpty
        ? [
            OrderPackageSummary(
              generatedPackageId: 'PKG-1',
              weight: widget.order.totalWeight.isEmpty
                  ? '--'
                  : widget.order.totalWeight,
              description: 'Package 1',
              value: widget.order.shippingCharge.isEmpty
                  ? '0.000'
                  : widget.order.shippingCharge,
              status: widget.order.status,
            ),
          ]
        : pkgs;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextButton.icon(
          onPressed: () =>
              setState(() => _packagesExpanded = !_packagesExpanded),
          icon: Icon(_packagesExpanded ? Icons.expand_less : Icons.expand_more),
          label: Text(
            _packagesExpanded
                ? 'Hide packages (${items.length})'
                : 'Show packages (${items.length})',
          ),
        ),
        if (_packagesExpanded)
          ...items.map(
            (pkg) => Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        pkg.generatedPackageId,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0E7FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          pkg.status.isEmpty ? widget.order.status : pkg.status,
                          style: const TextStyle(
                            color: Color(0xFF1D4ED8),
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (pkg.description.isNotEmpty)
                    Text(
                      pkg.description,
                      style: const TextStyle(
                        color: Color(0xFF4B5563),
                        fontSize: 12,
                      ),
                    ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        '${pkg.weight} Kg',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        pkg.value.isEmpty ? '0.000' : pkg.value,
                        style: const TextStyle(
                          color: Color(0xFFB91C1C),
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
