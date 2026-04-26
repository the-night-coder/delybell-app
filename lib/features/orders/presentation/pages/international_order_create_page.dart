import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/app_colors.dart';
import '../../../../core/session_manager.dart';
import '../../../profile/domain/entities/address_entity.dart';
import '../../data/international_order_repository.dart';
import '../../domain/entities/international_models.dart';
import '../bloc/international_create_bloc.dart';
import 'international_city_picker_page.dart';
import 'international_country_picker_page.dart';
import 'international_order_success_page.dart';
import '_shimmer_overlay.dart';

class InternationalOrderCreatePage extends StatefulWidget {
  const InternationalOrderCreatePage({super.key, required this.token});

  final String token;

  @override
  State<InternationalOrderCreatePage> createState() =>
      _InternationalOrderCreatePageState();
}

class _InternationalOrderCreatePageState
    extends State<InternationalOrderCreatePage> {
  late final PageController _pageController;
  String? _lastErrorMessage;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadDefaults();
    context.read<InternationalCreateBloc>().add(
          const InternationalOriginCountryRequested(),
        );
    context
        .read<InternationalCreateBloc>()
        .add(const InternationalPickupAddressRequested());
  }

  Future<void> _loadDefaults() async {
    final login = await SessionManager().loadLogin();
    if (!mounted) return;
    context.read<InternationalCreateBloc>().add(
          InternationalUserLoaded(
            userId: login?.user.id ?? 0,
            defaultPackageDescription: login?.user.packageDescription,
            addressFormatTypeId: login?.user.addressFormatTypeId,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    const stepTitles = [
      'Shipment',
      'Package Details',
      'Shipper',
      'From Address',
      'To Address',
      'Confirmation',
    ];

    return WillPopScope(
      onWillPop: () async {
        final bloc = context.read<InternationalCreateBloc>();
        if (bloc.state.currentStep > 0) {
          bloc.add(const InternationalBackPressed());
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: BlocBuilder<InternationalCreateBloc, InternationalCreateState>(
            builder: (context, state) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Create International Order'),
                  Text(
                    stepTitles[state.currentStep],
                    style: TextStyle(fontSize: 14, color: colors.primary),
                  ),
                ],
              );
            },
          ),
        ),
        body: BlocListener<InternationalCreateBloc, InternationalCreateState>(
          listenWhen: (p, c) =>
              p.currentStep != c.currentStep ||
              p.errorMessage != c.errorMessage ||
              p.orderPlaced != c.orderPlaced,
          listener: (context, state) async {
            if (_pageController.hasClients &&
                _pageController.page?.round() != state.currentStep) {
              _pageController.animateToPage(
                state.currentStep,
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
              );
            }
            if (state.currentStep == 5 &&
                !state.isLoadingPickupAddress &&
                state.pickupAddress == null) {
              context
                  .read<InternationalCreateBloc>()
                  .add(const InternationalPickupAddressRequested());
            }
            final errorMessage = state.errorMessage;
            if (errorMessage == null || errorMessage.isEmpty) {
              _lastErrorMessage = null;
            } else if (errorMessage != _lastErrorMessage) {
              _lastErrorMessage = errorMessage;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(errorMessage),
                  backgroundColor: colors.danger,
                ),
              );
            }
            if (state.orderPlaced) {
              await Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const InternationalOrderSuccessPage(),
                ),
              );
              if (!mounted) return;
              context
                  .read<InternationalCreateBloc>()
                  .add(const InternationalOrderPlacedAcknowledged());
            }
          },
          child: BlocBuilder<InternationalCreateBloc, InternationalCreateState>(
            builder: (context, state) {
              final bloc = context.read<InternationalCreateBloc>();
              final checking =
                  state.isFetchingRates || state.isInitiating || state.isPlacing;
              return Column(
                children: [
                  const SizedBox(height: 12),
                  AbsorbPointer(
                    absorbing: checking,
                    child: _StepHeader(
                      current: state.currentStep,
                      labels: stepTitles,
                      onStepTap: (idx) => bloc.add(InternationalStepChanged(idx)),
                    ),
                  ),
                  Expanded(
                    child: Stack(
                      children: [
                        AbsorbPointer(
                          absorbing: checking,
                          child: PageView(
                            controller: _pageController,
                            physics: const NeverScrollableScrollPhysics(),
                            children: [
                              _ShipmentStep(
                                token: widget.token,
                                shipment: state.shipment,
                                onChanged: (data) =>
                                    bloc.add(InternationalShipmentChanged(data)),
                              ),
                              _PackageDetailsStep(
                                shipment: state.shipment,
                                onChanged: (data) =>
                                    bloc.add(InternationalShipmentChanged(data)),
                              ),
                              _ShipperStep(
                                rates: state.rates,
                                selected: state.selectedRate,
                                onSelect: (rate) =>
                                    bloc.add(InternationalRateSelected(rate)),
                              ),
                              _AddressContactStep(
                                token: widget.token,
                                title: 'From Address',
                                contact: state.address.shipper,
                                addressOptions: state.fromAddresses,
                                selectedAddressId: state.selectedFromAddressId,
                                addressFormatTypeId: state.addressFormatTypeId,
                                onAddressSelected: (id) => bloc.add(
                                  InternationalFromAddressSelected(id),
                                ),
                                onChanged: (contact) => bloc.add(
                                  InternationalAddressChanged(
                                    state.address.copyWith(shipper: contact),
                                  ),
                                ),
                              ),
                              _AddressContactStep(
                                token: widget.token,
                                title: 'To Address',
                                contact: state.address.recipient,
                                instructions: state.address.deliveryInstructions,
                                onChanged: (contact) => bloc.add(
                                  InternationalAddressChanged(
                                    state.address.copyWith(recipient: contact),
                                  ),
                                ),
                                onInstructionsChanged: (value) => bloc.add(
                                  InternationalAddressChanged(
                                    state.address.copyWith(
                                      deliveryInstructions: value,
                                    ),
                                  ),
                                ),
                              ),
                              _ConfirmationStep(
                                state: state,
                                onPickupDateChanged: (date, selection) =>
                                    bloc.add(
                                  InternationalPickupDateChanged(
                                    date: date,
                                    selection: selection,
                                  ),
                                ),
                                onPickupSlotChanged: (slot) =>
                                    bloc.add(InternationalPickupSlotChanged(slot)),
                              ),
                            ],
                          ),
                        ),
                        if (checking) const ShimmerOverlay(),
                      ],
                    ),
                  ),
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: AbsorbPointer(
                        absorbing: checking,
                        child: Row(
                          children: [
                            if (state.currentStep > 0)
                              OutlinedButton(
                                onPressed: () =>
                                    bloc.add(const InternationalBackPressed()),
                                child: const Text('Back'),
                              ),
                            if (state.currentStep > 0)
                              const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  elevation: 0,
                                  backgroundColor: colors.primary,
                                ),
                                onPressed: () =>
                                    bloc.add(const InternationalNextPressed()),
                                child: Text(
                                  state.currentStep == 5 ? 'Place Order' : 'Next',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

class InternationalOrderCreatePageWrapper extends StatelessWidget {
  const InternationalOrderCreatePageWrapper({
    super.key,
    required this.token,
  });

  final String token;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => InternationalCreateBloc(
        repository: InternationalOrderRepository(),
        token: token,
      ),
      child: InternationalOrderCreatePage(token: token),
    );
  }
}

class _StepHeader extends StatelessWidget {
  const _StepHeader({
    required this.current,
    required this.labels,
    required this.onStepTap,
  });

  final int current;
  final List<String> labels;
  final ValueChanged<int> onStepTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: List.generate(labels.length, (index) {
          final isActive = index == current;
          final isDone = index < current;
          final color = isActive
              ? const Color(0xFF66258E)
              : isDone
                  ? const Color(0xFF16A34A)
                  : Colors.grey.shade400;
          return Expanded(
            child: InkWell(
              onTap: () => onStepTap(index),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: isActive
                        ? color.withValues(alpha: 0.15)
                        : Colors.grey.shade200,
                    child: Icon(
                      isDone ? Icons.check : Icons.circle,
                      size: 16,
                      color: color,
                    ),
                  ),
                  if (index != labels.length - 1)
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        height: 2,
                        color: index < current ? color : Colors.grey.shade300,
                      ),
                    ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _ShipmentStep extends StatelessWidget {
  const _ShipmentStep({
    required this.token,
    required this.shipment,
    required this.onChanged,
  });

  final String token;
  final InternationalShipmentFormData shipment;
  final ValueChanged<InternationalShipmentFormData> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    Future<void> pickCountry({
      required CountryInfo? selected,
      required ValueChanged<CountryInfo> onSelect,
    }) async {
      final result = await Navigator.of(context).push<CountryInfo>(
        MaterialPageRoute(
          builder: (_) => InternationalCountryPickerPage(
            token: token,
            selectedCountryId: selected?.id,
            initialQuery: selected?.name ?? '',
          ),
        ),
      );
      if (result != null) onSelect(result);
    }

    Future<void> pickCity({
      required CountryInfo? country,
      required CityInfo? selected,
      required ValueChanged<CityInfo> onSelect,
    }) async {
      if (country == null) return;
      final result = await Navigator.of(context).push<CityInfo>(
        MaterialPageRoute(
          builder: (_) => InternationalCityPickerPage(
            token: token,
            country: country,
            selectedCityId: selected?.id,
            initialQuery: selected?.name ?? '',
          ),
        ),
      );
      if (result != null) onSelect(result);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Shipment',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          _ShipmentLocationCard(
            title: 'From',
            countryLabel: shipment.originCountry?.name ?? 'Select Country',
            cityLabel: shipment.originCity?.name ?? 'Select City',
            cityEnabled: shipment.originCountry != null,
            onCountryTap: () async {
              if (shipment.originCountry?.name == 'Bahrain') return;
              await pickCountry(
                selected: shipment.originCountry,
                onSelect: (country) {
                  onChanged(
                    shipment.copyWith(
                      originCountry: country,
                      clearOriginCity: true,
                    ),
                  );
                },
              );
            },
            onCityTap: () async {
              await pickCity(
                country: shipment.originCountry,
                selected: shipment.originCity,
                onSelect: (city) {
                  onChanged(shipment.copyWith(originCity: city));
                },
              );
            },
          ),
          const SizedBox(height: 12),
          Center(
            child: InkWell(
              onTap: () {
                onChanged(
                  shipment.copyWith(
                    originCountry: shipment.destinationCountry,
                    originCity: shipment.destinationCity,
                    destinationCountry: shipment.originCountry,
                    destinationCity: shipment.originCity,
                  ),
                );
              },
              borderRadius: BorderRadius.circular(999),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colors.primarySoft,
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.border),
                ),
                child: Icon(Icons.swap_vert, color: colors.primary),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _ShipmentLocationCard(
            title: 'To',
            countryLabel: shipment.destinationCountry?.name ?? 'Select Country',
            cityLabel: shipment.destinationCity?.name ?? 'Select Country First',
            cityEnabled: shipment.destinationCountry != null,
            onCountryTap: () async {
              await pickCountry(
                selected: shipment.destinationCountry,
                onSelect: (country) {
                  onChanged(
                    shipment.copyWith(
                      destinationCountry: country,
                      clearDestinationCity: true,
                    ),
                  );
                },
              );
            },
            onCityTap: () async {
              await pickCity(
                country: shipment.destinationCountry,
                selected: shipment.destinationCity,
                onSelect: (city) {
                  onChanged(shipment.copyWith(destinationCity: city));
                },
              );
            },
          ),
          const SizedBox(height: 18),
          const Text(
            'Shipment Content',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Text('Document'),
                  selected: shipment.contentType ==
                      InternationalContentType.document,
                  onSelected: (_) => onChanged(
                    shipment.copyWith(
                      contentType: InternationalContentType.document,
                    ),
                  ),
                  selectedColor: colors.primarySoft,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ChoiceChip(
                  label: const Text('Parcel'),
                  selected:
                      shipment.contentType == InternationalContentType.parcel,
                  onSelected: (_) => onChanged(
                    shipment.copyWith(
                      contentType: InternationalContentType.parcel,
                    ),
                  ),
                  selectedColor: colors.primarySoft,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

}

class _PackageDetailsStep extends StatelessWidget {
  const _PackageDetailsStep({
    required this.shipment,
    required this.onChanged,
  });

  final InternationalShipmentFormData shipment;
  final ValueChanged<InternationalShipmentFormData> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    void updatePackageCount(int count) {
      final clamped = count < 1 ? 1 : count;
      final items = List<InternationalPackageItem>.from(shipment.packages);
      if (items.length > clamped) {
        items.removeRange(clamped, items.length);
      } else {
        items.addAll(
          List.generate(
            clamped - items.length,
            (_) => InternationalPackageItem(
              description: shipment.commonDescription,
              value: shipment.commonValue.isEmpty ? '0' : shipment.commonValue,
            ),
          ),
        );
      }
      onChanged(
        shipment.copyWith(packageCount: clamped, packages: items),
      );
    }

    void updateItem(int index, InternationalPackageItem item) {
      final items = List<InternationalPackageItem>.from(shipment.packages);
      if (index >= 0 && index < items.length) {
        items[index] = item;
        onChanged(shipment.copyWith(packages: items));
      }
    }

    final totalWeight = shipment.totalWeight.toStringAsFixed(2);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Package Details',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          _rectField(
            label: 'Customer Order ID (optional)',
            initial: shipment.customerOrderId,
            onChanged: (value) =>
                onChanged(shipment.copyWith(customerOrderId: value)),
          ),
          _rectField(
            label: 'Shipment Description',
            initial: shipment.description,
            onChanged: (value) =>
                onChanged(shipment.copyWith(description: value)),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              children: [
                const Text(
                  'No. of Packages',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                _CountButton(
                  icon: Icons.remove,
                  onTap: shipment.packageCount > 1
                      ? () => updatePackageCount(shipment.packageCount - 1)
                      : null,
                ),
                const SizedBox(width: 5),
                SizedBox(
                  width: 80,
                  child: TextFormField(
                    key: ValueKey('intl-pkg-count-${shipment.packageCount}'),
                    initialValue: '${shipment.packageCount}',
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 6),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) {
                      final count = int.tryParse(v) ?? shipment.packageCount;
                      updatePackageCount(count);
                    },
                  ),
                ),
                const SizedBox(width: 5),
                _CountButton(
                  icon: Icons.add,
                  onTap: () => updatePackageCount(shipment.packageCount + 1),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: colors.primary,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.monitor_weight, color: Colors.white, size: 18),
                const SizedBox(width: 6),
                Text(
                  '$totalWeight KG',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (shipment.packageCount > 1) ...[
            const SizedBox(height: 14),
            const Text(
              'Common fields for all packages',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            _rectField(
              label: 'Common description',
              initial: shipment.commonDescription,
              onChanged: (value) =>
                  onChanged(shipment.copyWith(commonDescription: value)),
            ),
            _rectField(
              label: 'Common value',
              initial: shipment.commonValue,
              keyboard: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (value) =>
                  onChanged(shipment.copyWith(commonValue: value)),
            ),
          ],
          const SizedBox(height: 12),
          ...shipment.packages.asMap().entries.map((entry) {
            final idx = entry.key;
            final item = entry.value;
            return _PackageItemCard(
              index: idx,
              item: item,
              onChanged: (updated) => updateItem(idx, updated),
            );
          }),
        ],
      ),
    );
  }

  Widget _rectField({
    required String label,
    required String initial,
    TextInputType keyboard = TextInputType.text,
    required ValueChanged<String> onChanged,
    double bottomPadding = 10,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: TextFormField(
        initialValue: initial,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF66258E), width: 1.5),
          ),
        ),
        keyboardType: keyboard,
        onChanged: onChanged,
      ),
    );
  }
}

class _ShipmentLocationCard extends StatelessWidget {
  const _ShipmentLocationCard({
    required this.title,
    required this.countryLabel,
    required this.cityLabel,
    required this.cityEnabled,
    required this.onCountryTap,
    required this.onCityTap,
  });

  final String title;
  final String countryLabel;
  final String cityLabel;
  final bool cityEnabled;
  final VoidCallback? onCountryTap;
  final VoidCallback? onCityTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Column(
              children: [
                _SelectionField(
                  label: 'Country *',
                  value: countryLabel,
                  onTap: onCountryTap,
                ),
                const SizedBox(height: 10),
                _SelectionField(
                  label: 'City *',
                  value: cityLabel,
                  onTap: cityEnabled ? onCityTap : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectionField extends StatelessWidget {
  const _SelectionField({
    required this.label,
    required this.value,
    this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colors.primary),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  color: onTap == null ? colors.mutedText : Colors.black,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(Icons.expand_more, color: colors.mutedText),
          ],
        ),
      ),
    );
  }
}

class _CountButton extends StatelessWidget {
  const _CountButton({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: enabled ? const Color(0xFF66258E) : Colors.grey.shade300,
        ),
        child: Icon(icon, size: 18, color: Colors.white),
      ),
    );
  }
}

class _PackageItemCard extends StatefulWidget {
  const _PackageItemCard({
    required this.index,
    required this.item,
    required this.onChanged,
  });

  final int index;
  final InternationalPackageItem item;
  final ValueChanged<InternationalPackageItem> onChanged;

  @override
  State<_PackageItemCard> createState() => _PackageItemCardState();
}

class _PackageItemCardState extends State<_PackageItemCard> {
  bool _expanded = false;
  late InternationalPackageItem _item;

  @override
  void initState() {
    super.initState();
    _item = widget.item;
  }

  @override
  void didUpdateWidget(covariant _PackageItemCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item != widget.item) {
      _item = widget.item;
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = 'Package ${widget.index + 1}';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          ListTile(
            title: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: _subtitleText(),
            trailing: IconButton(
              icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
              onPressed: () => setState(() => _expanded = !_expanded),
            ),
            onTap: () => setState(() => _expanded = !_expanded),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: _field(
                            label: 'Weight (KG) *',
                            initial: _item.weight,
                            keyboard:
                                const TextInputType.numberWithOptions(decimal: true),
                            bottomPadding: 0,
                            onChanged: (value) {
                              final updated = _item.copyWith(weight: value);
                              setState(() => _item = updated);
                              widget.onChanged(updated);
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _field(
                            label: 'Length *',
                            initial: _item.length,
                            keyboard:
                                const TextInputType.numberWithOptions(decimal: true),
                            bottomPadding: 0,
                            onChanged: (value) {
                              final updated = _item.copyWith(length: value);
                              setState(() => _item = updated);
                              widget.onChanged(updated);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: _field(
                            label: 'Width *',
                            initial: _item.width,
                            keyboard:
                                const TextInputType.numberWithOptions(decimal: true),
                            bottomPadding: 0,
                            onChanged: (value) {
                              final updated = _item.copyWith(width: value);
                              setState(() => _item = updated);
                              widget.onChanged(updated);
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _field(
                            label: 'Height *',
                            initial: _item.height,
                            keyboard:
                                const TextInputType.numberWithOptions(decimal: true),
                            bottomPadding: 0,
                            onChanged: (value) {
                              final updated = _item.copyWith(height: value);
                              setState(() => _item = updated);
                              widget.onChanged(updated);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  _field(
                    label: 'Description',
                    initial: _item.description,
                    onChanged: (value) {
                      final updated = _item.copyWith(description: value);
                      setState(() => _item = updated);
                      widget.onChanged(updated);
                    },
                  ),
                  _field(
                    label: 'Package Value',
                    initial: _item.value,
                    keyboard: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (value) {
                      final updated = _item.copyWith(value: value);
                      setState(() => _item = updated);
                      widget.onChanged(updated);
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _field({
    required String label,
    required String initial,
    TextInputType keyboard = TextInputType.text,
    required ValueChanged<String> onChanged,
    double bottomPadding = 10,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: TextFormField(
        initialValue: initial,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF66258E), width: 1.5),
          ),
        ),
        keyboardType: keyboard,
        onChanged: onChanged,
      ),
    );
  }

  Widget? _subtitleText() {
    final parts = <String>[];
    if (_item.weight.isNotEmpty) parts.add('${_item.weight} kg');
    if (_item.length.isNotEmpty &&
        _item.width.isNotEmpty &&
        _item.height.isNotEmpty) {
      parts.add('${_item.length}x${_item.width}x${_item.height}');
    }
    if (_item.value.isNotEmpty) parts.add('Value ${_item.value}');
    if (_item.description.isNotEmpty) parts.add(_item.description);
    if (parts.isEmpty) return const Text('Tap to add details');
    return Text(parts.join(' • '));
  }
}

class _ShipperStep extends StatelessWidget {
  const _ShipperStep({
    required this.rates,
    required this.selected,
    required this.onSelect,
  });

  final List<InternationalRateOption> rates;
  final InternationalRateOption? selected;
  final ValueChanged<InternationalRateOption> onSelect;

  @override
  Widget build(BuildContext context) {
    if (rates.isEmpty) {
      return const Center(
        child: Text('No shipping services available.'),
      );
    }

    final groups = <String, List<InternationalRateOption>>{};
    for (final rate in rates) {
      groups.putIfAbsent(rate.carrier, () => []).add(rate);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Select Shipment Service',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        const Text(
          '* Final charges may slightly vary based on courier rates.',
          style: TextStyle(color: Color(0xFF6B7280)),
        ),
        const SizedBox(height: 12),
        ...groups.entries.map((entry) {
          return _CarrierCard(
            carrier: entry.key,
            rates: entry.value,
            selected: selected,
            onSelect: onSelect,
          );
        }),
      ],
    );
  }
}

class _CarrierCard extends StatelessWidget {
  const _CarrierCard({
    required this.carrier,
    required this.rates,
    required this.selected,
    required this.onSelect,
  });

  final String carrier;
  final List<InternationalRateOption> rates;
  final InternationalRateOption? selected;
  final ValueChanged<InternationalRateOption> onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Card(
      elevation: 0,
      color: const Color(0xFFF8FAFF),
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              carrier.isEmpty ? 'Carrier' : carrier,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 10),
            ...rates.map((rate) {
              final isSelected = selected != null &&
                  selected!.carrier == rate.carrier &&
                  selected!.serviceCode == rate.serviceCode;
              final disabled = rate.amount <= 0 ||
                  rate.serviceName.toLowerCase().contains('unauthorized');
              return InkWell(
                onTap: disabled ? null : () => onSelect(rate),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFD1FAE5) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF16A34A)
                          : Colors.grey.shade200,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              rate.serviceName,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: disabled ? colors.mutedText : Colors.black,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              rate.deliveryDate.isEmpty
                                  ? 'Delivery date unavailable'
                                  : rate.deliveryDate,
                              style: TextStyle(color: colors.mutedText),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${rate.amount.toStringAsFixed(3)} ${rate.currency}',
                        style: TextStyle(
                          color: disabled ? colors.mutedText : colors.danger,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        isSelected ? Icons.check_circle : Icons.circle_outlined,
                        color: isSelected ? colors.success : colors.mutedText,
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _AddressContactStep extends StatelessWidget {
  const _AddressContactStep({
    required this.token,
    required this.title,
    required this.contact,
    required this.onChanged,
    this.addressOptions = const [],
    this.selectedAddressId,
    this.addressFormatTypeId = 1,
    this.onAddressSelected,
    this.instructions,
    this.onInstructionsChanged,
  });

  final String token;
  final String title;
  final InternationalContactFormData contact;
  final ValueChanged<InternationalContactFormData> onChanged;
  final List<AddressEntity> addressOptions;
  final int? selectedAddressId;
  final int addressFormatTypeId;
  final ValueChanged<int?>? onAddressSelected;
  final String? instructions;
  final ValueChanged<String>? onInstructionsChanged;

  static const List<String> _phoneCodes = [
    '+973',
    '+966',
    '+971',
    '+965',
    '+974',
    '+968',
    '+91',
    '+1',
    '+44',
    '+880',
    '+92',
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _ContactSection(
            token: token,
            title: title,
            contact: contact,
            phoneCodes: _phoneCodes,
            onChanged: onChanged,
            addressOptions: addressOptions,
            selectedAddressId: selectedAddressId,
            addressFormatTypeId: addressFormatTypeId,
            onAddressSelected: onAddressSelected,
          ),
          if (onInstructionsChanged != null) ...[
            const SizedBox(height: 12),
            TextFormField(
              initialValue: instructions ?? '',
              decoration: InputDecoration(
                labelText: 'Delivery Instructions (optional)',
                filled: true,
                fillColor: Colors.white,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: Color(0xFF66258E), width: 1.5),
                ),
              ),
              maxLines: 2,
              onChanged: onInstructionsChanged,
            ),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _ContactSection extends StatelessWidget {
  const _ContactSection({
    required this.token,
    required this.title,
    required this.contact,
    required this.phoneCodes,
    required this.onChanged,
    this.addressOptions = const [],
    this.selectedAddressId,
    this.addressFormatTypeId = 1,
    this.onAddressSelected,
  });

  final String token;
  final String title;
  final InternationalContactFormData contact;
  final List<String> phoneCodes;
  final ValueChanged<InternationalContactFormData> onChanged;
  final List<AddressEntity> addressOptions;
  final int? selectedAddressId;
  final int addressFormatTypeId;
  final ValueChanged<int?>? onAddressSelected;

  @override
  Widget build(BuildContext context) {
    Future<void> pickCountry({
      required CountryInfo? selected,
      required ValueChanged<CountryInfo> onSelect,
    }) async {
      final result = await Navigator.of(context).push<CountryInfo>(
        MaterialPageRoute(
          builder: (_) => InternationalCountryPickerPage(
            token: token,
            selectedCountryId: selected?.id,
            initialQuery: selected?.name ?? '',
          ),
        ),
      );
      if (result != null) onSelect(result);
    }

    Future<void> pickCity({
      required CountryInfo? country,
      required CityInfo? selected,
      required ValueChanged<CityInfo> onSelect,
    }) async {
      if (country == null) return;
      final result = await Navigator.of(context).push<CityInfo>(
        MaterialPageRoute(
          builder: (_) => InternationalCityPickerPage(
            token: token,
            country: country,
            selectedCityId: selected?.id,
            initialQuery: selected?.name ?? '',
          ),
        ),
      );
      if (result != null) onSelect(result);
    }

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            if (addressOptions.isNotEmpty && onAddressSelected != null) ...[
              const SizedBox(height: 10),
              _AddressDropdown(
                label: 'Saved Address',
                addresses: addressOptions,
                selectedId: selectedAddressId,
                addressFormatTypeId: addressFormatTypeId,
                onChanged: onAddressSelected!,
              ),
            ],
            const SizedBox(height: 12),
            _rectField(
              label: 'Name *',
              initial: contact.name,
              onChanged: (value) => onChanged(contact.copyWith(name: value)),
            ),
            _rectField(
              label: 'Company Name',
              initial: contact.companyName,
              onChanged: (value) =>
                  onChanged(contact.copyWith(companyName: value)),
            ),
            _rectField(
              label: 'Tax ID/VAT/EIN Number',
              initial: contact.taxNo,
              onChanged: (value) => onChanged(contact.copyWith(taxNo: value)),
            ),
            Column(
              children: [
                _SelectionField(
                  label: 'Country *',
                  value: contact.country?.name ?? 'Select Country',
                  onTap: () async {
                    await pickCountry(
                      selected: contact.country,
                      onSelect: (country) => onChanged(
                        contact.copyWith(
                          country: country,
                          clearCity: true,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                _SelectionField(
                  label: 'City *',
                  value: contact.city?.name ?? 'Select Country First',
                  onTap: contact.country == null
                      ? null
                      : () async {
                          await pickCity(
                            country: contact.country,
                            selected: contact.city,
                            onSelect: (city) =>
                                onChanged(contact.copyWith(city: city)),
                          );
                        },
                ),
              ],
            ),
            const SizedBox(height: 10),
            _rectField(
              label: 'Postal Code *',
              initial: contact.postalCode,
              onChanged: (value) =>
                  onChanged(contact.copyWith(postalCode: value)),
            ),
            const SizedBox(height: 10),
            _phoneRow(
              title: 'Mobile Number *',
              countryCode: contact.phoneCode,
              number: contact.phone,
              codes: phoneCodes,
              onCodeChanged: (value) =>
                  onChanged(contact.copyWith(phoneCode: value)),
              onNumberChanged: (value) =>
                  onChanged(contact.copyWith(phone: value)),
              numberFieldKey: selectedAddressId == null
                  ? null
                  : ValueKey('shipper-phone-$selectedAddressId'),
            ),
            const SizedBox(height: 8),
            _phoneRow(
              title: 'Alternate Mobile Number',
              countryCode: contact.altPhoneCode,
              number: contact.altPhone,
              codes: phoneCodes,
              onCodeChanged: (value) =>
                  onChanged(contact.copyWith(altPhoneCode: value)),
              onNumberChanged: (value) =>
                  onChanged(contact.copyWith(altPhone: value)),
            ),
            const SizedBox(height: 8),
            _rectField(
              label: 'Email Address',
              initial: contact.email,
              keyboard: TextInputType.emailAddress,
              onChanged: (value) => onChanged(contact.copyWith(email: value)),
            ),
            _rectField(
              label: 'Address Line 1 *',
              initial: contact.addressLine1,
              fieldKey: selectedAddressId == null
                  ? null
                  : ValueKey('shipper-address-$selectedAddressId'),
              onChanged: (value) =>
                  onChanged(contact.copyWith(addressLine1: value)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _rectField({
    required String label,
    required String initial,
    TextInputType keyboard = TextInputType.text,
    required ValueChanged<String> onChanged,
    Key? fieldKey,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        key: fieldKey,
        initialValue: initial,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: Color(0xFF66258E), width: 1.5),
          ),
        ),
        keyboardType: keyboard,
        onChanged: onChanged,
      ),
    );
  }

  Widget _phoneRow({
    required String title,
    required String countryCode,
    required String number,
    required List<String> codes,
    required ValueChanged<String> onCodeChanged,
    required ValueChanged<String> onNumberChanged,
    Key? numberFieldKey,
  }) {
    String sanitizeNumber(String raw, String code) {
      final digits = raw.replaceAll(RegExp(r'\D'), '');
      final codeDigits = code.replaceAll(RegExp(r'\D'), '');
      if (digits.startsWith(codeDigits)) {
        return digits.substring(codeDigits.length);
      }
      return digits;
    }

    final displayNumber = sanitizeNumber(number, countryCode);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: countryCode,
                    items: codes
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) => v == null ? null : onCodeChanged(v),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 5,
              child: _rectField(
                label: '',
                initial: displayNumber,
                keyboard: TextInputType.number,
                fieldKey: numberFieldKey,
                onChanged: (v) => onNumberChanged(
                  sanitizeNumber(v, countryCode),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AddressDropdown extends StatelessWidget {
  const _AddressDropdown({
    required this.label,
    required this.addresses,
    required this.selectedId,
    required this.addressFormatTypeId,
    required this.onChanged,
  });

  final String label;
  final List<AddressEntity> addresses;
  final int? selectedId;
  final int addressFormatTypeId;
  final ValueChanged<int?> onChanged;

  String _formatAddress(AddressEntity address) {
    String buildStandard() {
      final parts = <String>[];
      if (address.buildingCode.trim().isNotEmpty) {
        parts.add('Building ${address.buildingCode.trim()}');
      }
      if (address.roadCode.trim().isNotEmpty) {
        parts.add('Road ${address.roadCode.trim()}');
      }
      if (address.blockName.trim().isNotEmpty) {
        parts.add(address.blockName.trim());
      }
      return parts.join(', ');
    }

    String buildSingleLine() {
      final parts = <String>[];
      if (address.line1.trim().isNotEmpty) parts.add(address.line1.trim());
      if (address.line2.trim().isNotEmpty) parts.add(address.line2.trim());
      return parts.join(', ');
    }

    if (addressFormatTypeId == 2) {
      final line = buildSingleLine();
      if (line.isNotEmpty) return line;
    }

    final standard = buildStandard();
    if (standard.isNotEmpty) return standard;

    final fallback = buildSingleLine();
    if (fallback.isNotEmpty) return fallback;

    return address.title.isEmpty ? 'Saved Address' : address.title;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final hint = addresses.isEmpty ? 'No saved address' : 'Select Address';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colors.primary),
          ),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<int>(
            isExpanded: true,
            value: selectedId,
            hint: Text(hint),
            items: addresses
                .map(
                  (address) => DropdownMenuItem<int>(
                    value: address.id,
                    child: Text(
                      _formatAddress(address),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }
}

class _ConfirmationStep extends StatelessWidget {
  const _ConfirmationStep({
    required this.state,
    required this.onPickupDateChanged,
    required this.onPickupSlotChanged,
  });

  final InternationalCreateState state;
  final void Function(DateTime, InternationalPickupDateSelection)
      onPickupDateChanged;
  final ValueChanged<int> onPickupSlotChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final shipper = state.address.shipper;
    final recipient = state.address.recipient;
    final rate = state.selectedRate;

    String addressLine(InternationalContactFormData contact) {
      final parts = [
        contact.addressLine1.trim(),
        contact.addressLine2.trim(),
        contact.city?.name ?? '',
        contact.country?.name ?? '',
      ].where((p) => p.isNotEmpty).toList();
      return parts.join(', ');
    }

    String dateLabel() {
      final date = state.pickupDate;
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
        disabledColor: Colors.grey.shade200,
        labelStyle: TextStyle(
          color: selected
              ? colors.primary
              : enabled
                  ? Colors.black
                  : colors.mutedText,
          fontWeight: FontWeight.w700,
        ),
      );
    }

    final now = DateTime.now();

    bool isTodaySelectable() {
      return now.hour < 19;
    }

    List<int> enabledSlotsFor(DateTime? date) {
      if (date == null) return const [];
      final isToday =
          DateTime(now.year, now.month, now.day) ==
          DateTime(date.year, date.month, date.day);
      if (!isToday) return const [1, 3];
      final List<int> slots = [];
      if (now.hour < 12) slots.add(1);
      if (now.hour < 19) slots.add(3);
      return slots;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: colors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Order Summary',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  _SummaryRow(label: 'From', value: shipper.name),
                  _SummaryRow(label: 'Contact', value: shipper.phone),
                  _SummaryRow(
                    label: 'Address',
                    value: addressLine(shipper),
                    stacked: true,
                  ),
                  const Divider(height: 24),
                  _SummaryRow(label: 'To', value: recipient.name),
                  _SummaryRow(label: 'Contact', value: recipient.phone),
                  _SummaryRow(
                    label: 'Address',
                    value: addressLine(recipient),
                    stacked: true,
                  ),
                  const Divider(height: 24),
                  _SummaryRow(
                    label: 'Packages',
                    value: state.shipment.packageCount.toString(),
                  ),
                  _SummaryRow(
                    label: 'Total Weight',
                    value: '${state.shipment.totalWeight.toStringAsFixed(2)} KG',
                  ),
                  if (rate != null)
                    _SummaryRow(
                      label: 'Shipping Charge',
                      value:
                          '${rate.amount.toStringAsFixed(3)} ${rate.currency}',
                      valueColor: colors.danger,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Schedule Pickup',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const Divider(height: 24),
          const Text(
            'Pickup Date *',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              chip(
                label: 'Today',
                icon: Icons.calendar_today_outlined,
                selected:
                    state.dateSelection == InternationalPickupDateSelection.today,
                onTap: () {
                  final now = DateTime.now();
                  onPickupDateChanged(
                    DateTime(now.year, now.month, now.day),
                    InternationalPickupDateSelection.today,
                  );
                },
                enabled: isTodaySelectable(),
              ),
              chip(
                label: 'Tomorrow',
                icon: Icons.calendar_view_day,
                selected: state.dateSelection ==
                    InternationalPickupDateSelection.tomorrow,
                onTap: () {
                  final now = DateTime.now().add(const Duration(days: 1));
                  onPickupDateChanged(
                    DateTime(now.year, now.month, now.day),
                    InternationalPickupDateSelection.tomorrow,
                  );
                },
              ),
              chip(
                label: 'Custom',
                icon: Icons.event,
                selected:
                    state.dateSelection == InternationalPickupDateSelection.custom,
                onTap: () async {
                  final now = DateTime.now();
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: state.pickupDate ?? now,
                    firstDate: now,
                    lastDate: now.add(const Duration(days: 30)),
                  );
                  if (picked != null) {
                    onPickupDateChanged(
                      DateTime(picked.year, picked.month, picked.day),
                      InternationalPickupDateSelection.custom,
                    );
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Selected Date: ${dateLabel()}',
            style: const TextStyle(color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 16),
          const Text(
            'Pickup Time *',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              chip(
                label: 'Morning',
                selected: state.pickupSlot == 1,
                onTap: () => onPickupSlotChanged(1),
                enabled: enabledSlotsFor(state.pickupDate).contains(1),
              ),
              chip(
                label: 'Evening',
                selected: state.pickupSlot == 3,
                onTap: () => onPickupSlotChanged(3),
                enabled: enabledSlotsFor(state.pickupDate).contains(3),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.stacked = false,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final bool stacked;

  @override
  Widget build(BuildContext context) {
    if (stacked) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text(
              value.isEmpty ? '---' : value,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: valueColor ?? const Color(0xFF374151),
              ),
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            value.isEmpty ? '---' : value,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: valueColor ?? const Color(0xFF374151),
            ),
          ),
        ],
      ),
    );
  }
}
