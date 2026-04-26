import 'package:flutter/material.dart';

import '../../../../dashboard/models/order_summary.dart';
import '../../../../core/app_colors.dart';

class DraftDetailPage extends StatelessWidget {
  const DraftDetailPage({super.key, required this.order});

  final OrderSummary order;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>();
    final isInternational =
        order.orderType.toLowerCase().contains('international');
    return Scaffold(
      appBar: AppBar(title: const Text('Draft Order')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _headerCard(context, colors, isInternational),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Column(
                children: [
                  _infoTile('Service Type', order.serviceType),
                  _infoTile(
                    'Order Type',
                    order.orderType.isNotEmpty
                        ? order.orderType
                        : order.orderFlowType,
                  ),
                  if (order.orderFlowType.isNotEmpty)
                    _infoTile('Order Flow', order.orderFlowType),
                  _infoTile('Packages', '${order.packageCount}'),
                  _infoTile('Total Weight', '${order.totalWeight} KG'),
                  _infoTile('Shipping Charge', order.shippingCharge),
                  if (order.isCod) _infoTile('COD Amount', order.codAmount),
                  if (!isInternational) ...[
                    _infoTile('Receiver', order.receiverName),
                    _infoTile('Contact', order.receiverPhone),
                    if (order.receiverAltPhone.isNotEmpty)
                      _infoTile('Alt Contact', order.receiverAltPhone),
                  ] else ...[
                    const SizedBox(height: 10),
                    _contactSection(
                      title: 'From',
                      name: _firstNonEmpty(
                        [order.pickupName],
                        fallback: 'N/A',
                      ),
                      phone: _firstNonEmpty(
                        [order.pickupPhone, order.pickupAltPhone],
                        fallback: 'N/A',
                      ),
                      address: _firstNonEmpty(
                        [
                          order.pickupAddressLine,
                          order.addressLine,
                          order.senderAddress,
                        ],
                        fallback: 'N/A',
                      ),
                    ),
                    const SizedBox(height: 12),
                    _contactSection(
                      title: 'To',
                      name: _firstNonEmpty(
                        [order.receiverName],
                        fallback: 'N/A',
                      ),
                      phone: _firstNonEmpty(
                        [order.receiverPhone, order.receiverAltPhone],
                        fallback: 'N/A',
                      ),
                      address: _firstNonEmpty(
                        [order.destinationAddress, order.addressLine],
                        fallback: 'N/A',
                      ),
                    ),
                  ],
                  _infoTile(
                    'Instructions',
                    order.deliveryInstructions.isEmpty
                        ? '---'
                        : order.deliveryInstructions,
                  ),
                  const SizedBox(height: 16),
                  _packagesSection(colors),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _headerCard(
    BuildContext context,
    AppColors? colors,
    bool isInternational,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors?.border ?? const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: (colors?.primary ?? const Color(0xFF66258E))
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Draft',
                  style: TextStyle(
                    color: colors?.primary ?? const Color(0xFF66258E),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              if (isInternational)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'International',
                    style: TextStyle(
                      color: Color(0xFF0284C7),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              if (isInternational) const SizedBox(width: 8),
              Text(
                order.generatedOrderId,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            order.receiverName,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            _displayAddress(),
            style: const TextStyle(color: Color(0xFF6B7280)),
          ),
        ],
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

  String _displayAddress() {
    final primary = order.destinationAddress.trim();
    final secondary = order.addressLine.trim();
    final sender = order.senderAddress.trim();
    if (primary.isNotEmpty && primary != '-') return primary;
    if (secondary.isNotEmpty && secondary != '-') return secondary;
    if (sender.isNotEmpty && sender != '-') return sender;
    return '-';
  }

  Widget _infoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            value.isEmpty ? '---' : value,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _contactSection({
    required String title,
    required String name,
    required String phone,
    required String address,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(
            name.isEmpty ? 'N/A' : name,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(
                Icons.phone,
                size: 16,
                color: Color(0xFF6B7280),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  phone.isEmpty ? 'N/A' : phone,
                  style: const TextStyle(color: Color(0xFF4B5563)),
                ),
              ),
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
                  address.isEmpty ? 'N/A' : address,
                  style: const TextStyle(color: Color(0xFF4B5563)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _packagesSection(AppColors? colors) {
    if (order.packages.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Packages',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        ...order.packages.map(
          (p) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colors?.border ?? const Color(0xFFE5E7EB),
              ),
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.generatedPackageId.isEmpty
                          ? 'Package'
                          : p.generatedPackageId,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      p.description.isEmpty ? 'No description' : p.description,
                      style: const TextStyle(color: Color(0xFF6B7280)),
                    ),
                  ],
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [Text('${p.weight} KG'), Text('Value ${p.value}')],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
