import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../dashboard/data/domestic_order_repository.dart';
import '../../../../dashboard/models/address_lookup.dart';
import '../../../../core/app_colors.dart';
import '../../../../core/session_manager.dart';
import '../../../../login/models/login_response.dart';
import '../../domain/repositories/orders_repository.dart';
import '../bloc/domestic_create_bloc.dart';
import 'draft_order_success_page.dart';
import '_shimmer_overlay.dart';
import 'road_picker_page.dart';
import 'building_picker_page.dart';
import 'block_picker_page.dart';
import 'barcode_scanner_page.dart';

class DomesticOrderCreatePage extends StatefulWidget {
  const DomesticOrderCreatePage({super.key, required this.token, this.draftId});

  final String token;
  final int? draftId;

  @override
  State<DomesticOrderCreatePage> createState() =>
      _DomesticOrderCreatePageState();
}

class _DomesticOrderCreatePageState extends State<DomesticOrderCreatePage> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadAddressFormat();
    if (widget.draftId != null) {
      context.read<DomesticCreateBloc>().add(
        DomesticDraftDetailRequested(widget.draftId!),
      );
    } else {
      context.read<DomesticCreateBloc>().add(
        const DomesticDraftCheckRequested(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isReturn(DomesticCreateState state) {
      final flow = state.orderFlowTypes
          .firstWhere(
            (f) => f.id == state.selectedOrderFlowTypeId,
            orElse: () => state.orderFlowTypes.isNotEmpty
                ? state.orderFlowTypes.first
                : OrderFlowType(id: 0, name: '', isActive: true),
          )
          .name
          .toLowerCase();
      return flow.contains('return');
    }

    return WillPopScope(
      onWillPop: () async {
        _clearFocus();
        final bloc = context.read<DomesticCreateBloc>();
        if (bloc.state.currentStep > 0) {
          bloc.add(const DomesticBackPressed());
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: BlocBuilder<DomesticCreateBloc, DomesticCreateState>(
            builder: (context, state) {
              final colors = Theme.of(context).extension<AppColors>()!;
              final stepTitles = [
                'Service Type',
                'Package Details',
                isReturn(state) ? 'Pickup Details' : 'Delivery Details',
                'Draft Orders',
              ];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Create Domestic Order'),
                  Text(
                    stepTitles[state.currentStep],
                    style: TextStyle(fontSize: 14, color: colors.primary),
                  ),
                ],
              );
            },
          ),
        ),
        body: BlocListener<DomesticCreateBloc, DomesticCreateState>(
          listenWhen: (previous, current) =>
              previous.currentStep != current.currentStep ||
              previous.errorMessage != current.errorMessage ||
              previous.orderAccepted != current.orderAccepted,
          listener: (context, state) {
            if (_pageController.hasClients &&
                _pageController.page?.round() != state.currentStep) {
              _pageController.animateToPage(
                state.currentStep,
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
              );
            }
            if (state.currentStep == 2 && state.blocks.isEmpty) {
              context.read<DomesticCreateBloc>().add(
                const DomesticBlocksRequested(),
              );
            }
            if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.errorMessage!),
                  backgroundColor: Colors.red.shade700,
                ),
              );
            }
            if (state.orderAccepted) {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => DraftOrderSuccessPage(
                    token: widget.token,
                    serviceType: _serviceLabel(
                      state.acceptedServiceType ?? state.selectedServiceType,
                    ),
                  ),
                ),
              );
              context.read<DomesticCreateBloc>().add(
                const DomesticAcceptanceShown(),
              );
            }
          },
          child: BlocBuilder<DomesticCreateBloc, DomesticCreateState>(
            builder: (context, state) {
              final bloc = context.read<DomesticCreateBloc>();
              final checking =
                  state.isCheckingDraft ||
                  state.isInitiating ||
                  state.isPreviewing ||
                  state.isAccepting;
              final stepLabels = [
                'Service Type',
                'Package Details',
                isReturn(state) ? 'Pickup Details' : 'Delivery Details',
                'Draft',
              ];
              return Column(
                children: [
                  const SizedBox(height: 12),
                  AbsorbPointer(
                    absorbing: checking,
                    child: _StepHeader(
                      current: state.currentStep,
                      onStepTap: (idx) {
                        _clearFocus();
                        bloc.add(DomesticStepChanged(idx));
                      },
                      labels: stepLabels,
                    ),
                  ),
                  if (state.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        state.errorMessage!,
                        style: const TextStyle(color: Colors.red),
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
                              _PackageDetails(
                                selected: state.selectedServiceType,
                                locked: state.lockedServiceType,
                                flowTypes: state.orderFlowTypes,
                                selectedFlowTypeId: state.selectedOrderFlowTypeId,
                                onSelect: (type) =>
                                    bloc.add(DomesticServiceTypeChanged(type)),
                                onFlowTypeSelect: (flow) => bloc.add(
                                  DomesticOrderFlowTypeChanged(flow.id),
                                ),
                              ),
                              _PackageFormStep(
                                data: state.package,
                                userTypeId: state.userTypeId,
                                onChanged: (data) => bloc.add(
                                  DomesticPackageDetailsChanged(data),
                                ),
                              ),
                            _DeliveryFormStep(
                              state: state,
                              isReturnFlow: isReturn(state),
                              onChanged: (delivery) => bloc.add(
                                DomesticDeliveryDetailsChanged(delivery),
                              ),
                              token: widget.token,
                              addressFormatTypeId: state.addressFormatTypeId,
                              onSelectBlock: (block) {
                                bloc.add(DomesticBlockSelected(block));
                                if (block != null) {
                                  bloc.add(
                                    DomesticRoadsRequested(blockId: block.id),
                                  );
                                }
                              },
                              onSelectRoad: (road, customName) {
                                bloc.add(
                                  DomesticRoadSelected(
                                    road,
                                    customName: customName,
                                  ),
                                );
                                final blockId = state.delivery.block?.id;
                                if (blockId != null && road != null) {
                                  bloc.add(
                                    DomesticBuildingsRequested(
                                      blockId: blockId,
                                      roadId: road.id,
                                    ),
                                  );
                                }
                              },
                              onSelectBuilding: (building) => bloc.add(
                                DomesticBuildingSelected(building),
                              ),
                              onFetchBuildings: (blockId, roadId) => bloc.add(
                                DomesticBuildingsRequested(
                                  blockId: blockId,
                                  roadId: roadId,
                                ),
                              ),
                            ),
                              _DraftPreviewStep(
                                state: state,
                                isReturnFlow: isReturn(state),
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
                                onPressed: () {
                                  _clearFocus();
                                  bloc.add(const DomesticBackPressed());
                                },
                                child: const Text('Back'),
                              ),
                            if (state.currentStep > 0)
                              const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  elevation: 0,
                                  backgroundColor: Color(0xFF66258E),
                                ),
                                onPressed: () {
                                  _clearFocus();
                                  bloc.add(const DomesticNextPressed());
                                },
                                child: Text(
                                  state.currentStep == 3 ? 'Finish' : 'Next',
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

  Future<void> _loadAddressFormat() async {
    final login = await SessionManager().loadLogin();
    final id = login?.user.addressFormatTypeId ?? 1;
    final userTypeId = login?.user.userTypeId ?? 0;
    final packageDesc = login?.user.packageDescription ?? '';
    final flowTypes = login?.user.orderFlowTypes ?? const [];
    if (mounted) {
      context.read<DomesticCreateBloc>().add(
            DomesticAddressFormatChanged(id),
          );
      context.read<DomesticCreateBloc>().add(
            DomesticUserTypeChanged(userTypeId),
          );
      if (flowTypes.isNotEmpty) {
        context.read<DomesticCreateBloc>().add(
              DomesticOrderFlowTypesLoaded(flowTypes),
            );
      }
      if (packageDesc.isNotEmpty) {
        final pkg = context.read<DomesticCreateBloc>().state.package;
        if (pkg.commonDescription.isEmpty) {
          context.read<DomesticCreateBloc>().add(
                DomesticPackageDetailsChanged(
                  pkg.copyWith(commonDescription: packageDesc),
                ),
              );
        }
      }
    }
  }

  String _serviceLabel(DomesticServiceType type) {
    switch (type) {
      case DomesticServiceType.express:
        return 'Express';
      case DomesticServiceType.sameDay:
        return 'Same Day';
      case DomesticServiceType.nextDay:
        return 'Next Day';
    }
  }

  void _clearFocus() {
    FocusScope.of(context).unfocus();
    FocusManager.instance.primaryFocus?.unfocus();
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

class _PackageDetails extends StatelessWidget {
  const _PackageDetails({
    required this.selected,
    required this.locked,
    required this.onSelect,
    required this.flowTypes,
    required this.selectedFlowTypeId,
    required this.onFlowTypeSelect,
  });

  final DomesticServiceType selected;
  final DomesticServiceType? locked;
  final ValueChanged<DomesticServiceType> onSelect;
  final List<OrderFlowType> flowTypes;
  final int selectedFlowTypeId;
  final ValueChanged<OrderFlowType> onFlowTypeSelect;

  @override
  Widget build(BuildContext context) {
    flowTypes
        .firstWhere(
          (f) => f.id == selectedFlowTypeId,
          orElse: () => flowTypes.isNotEmpty
              ? flowTypes.first
              : OrderFlowType(id: 0, name: '', isActive: true),
        )
        .name
        .toLowerCase()
        .contains('return');

    Widget card(DomesticServiceType type, String label, String desc) {
      final isLocked = locked != null && locked != type;
      final isSelected = selected == type;
      return GestureDetector(
        onTap: isLocked ? null : () => onSelect(type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFEDE9FE) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isLocked
                  ? Colors.grey.shade300
                  : isSelected
                  ? const Color(0xFF66258E)
                  : Colors.grey.shade200,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: isLocked ? Colors.grey : const Color(0xFF111827),
                    ),
                  ),
                  const Spacer(),
                  if (isLocked)
                    const Icon(Icons.lock, size: 16, color: Colors.grey),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                desc,
                style: TextStyle(
                  color: isLocked ? Colors.grey : const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Service Type',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            card(
              DomesticServiceType.express,
              'Express',
              'Fast delivery on the same day',
            ),
            const SizedBox(height: 10),
            card(
              DomesticServiceType.nextDay,
              'Next Day',
              'Delivery by the next working day',
            ),
            const SizedBox(height: 10),
            card(
              DomesticServiceType.sameDay,
              'Same Day',
              'Deliver within the same day',
            ),
            const SizedBox(height: 18),
            if (flowTypes.length > 1)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Order Type',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  ...flowTypes.map((flow) {
                    final isSelected = flow.id == selectedFlowTypeId;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: GestureDetector(
                        onTap: () => onFlowTypeSelect(flow),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFFEDE9FE) : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF66258E)
                                  : Colors.grey.shade200,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  flow.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF111827),
                                  ),
                                ),
                              ),
                              Icon(
                                isSelected
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_unchecked,
                                color: isSelected
                                    ? const Color(0xFF66258E)
                                    : Colors.grey,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            if (flowTypes.length == 1)
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 12),
                child: Row(
                  children: [
                    const Text(
                      'Order Type:',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      flowTypes.first.name,
                      style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF66258E)),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PackageFormStep extends StatelessWidget {
  const _PackageFormStep({
    required this.data,
    required this.onChanged,
    required this.userTypeId,
  });

  final PackageFormData data;
  final ValueChanged<PackageFormData> onChanged;
  final int userTypeId;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Package Details',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          if (userTypeId == 5 || userTypeId == 14) ...[
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Is this a COD Order?', style: TextStyle(fontWeight: FontWeight.bold),),
              value: data.isCod,
              onChanged: (value) {
                onChanged(
                  data.copyWith(
                    isCod: value,
                    codAmount: value ? data.codAmount : '0',
                  ),
                );
              },
            ),
            if (data.isCod)
              _rectField(
                label: 'COD Amount',
                keyboard: const TextInputType.numberWithOptions(decimal: true),
                initial: data.codAmount,
                onChanged: (v) => onChanged(data.copyWith(codAmount: v)),
              ),
            const SizedBox(height: 12),
          ],
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
                  'No.of Packages',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                _CircleIconButton(
                  icon: Icons.remove,
                  onTap: data.packageCount > 1
                      ? () => onChanged(
                          data.copyWith(packageCount: data.packageCount - 1),
                        )
                      : null,
                ),
                SizedBox(width: 5),
                SizedBox(
                  width: 80,
                  child: TextFormField(
                    key: ValueKey('pkg-count-${data.packageCount}'),
                    initialValue: '${data.packageCount}',
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 6),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) {
                      final count = int.tryParse(v) ?? data.packageCount;
                      onChanged(
                        data.copyWith(packageCount: count < 1 ? 1 : count),
                      );
                    },
                  ),
                ),
                SizedBox(width: 5),
                _CircleIconButton(
                  icon: Icons.add,
                  onTap: () => onChanged(
                    data.copyWith(packageCount: data.packageCount + 1),
                  ),
                ),
              ],
            ),
          ),
          if (data.packageCount > 1) ...[
            const SizedBox(height: 12),
            const Text(
              'Common fields for all packages',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 10),
            _rectField(
              label: 'Common description',
              initial: data.commonDescription,
              onChanged: (v) => onChanged(data.copyWith(commonDescription: v)),
            ),
            _rectField(
              label: 'Common value',
              initial: data.commonValue,
              keyboard: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (v) => onChanged(data.copyWith(commonValue: v)),
            ),
          ],
          const SizedBox(height: 12),
          ...List.generate(data.items.length, (index) {
            final item = data.items[index];
            return _PackageItemCard(
              index: index,
              item: item,
              commonDescription: data.commonDescription,
              commonValue: data.commonValue,
              onChanged: (updated) => _updateItem(index, updated),
            );
          }),
        ],
      ),
    );
  }

  void _updateItem(int index, PackageItemData item) {
    final updated = List<PackageItemData>.from(data.items);
    updated[index] = item;
    onChanged(data.copyWith(items: updated));
  }

  Widget _rectField({
    required String label,
    TextInputType? keyboard,
    String initial = '',
    required ValueChanged<String> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
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

class _DeliveryFormStep extends StatelessWidget {
  const _DeliveryFormStep({
    required this.state,
    required this.onChanged,
    required this.onSelectBlock,
    required this.onSelectRoad,
    required this.onSelectBuilding,
    required this.token,
    required this.onFetchBuildings,
    required this.addressFormatTypeId,
    required this.isReturnFlow,
  });

  final DomesticCreateState state;
  final ValueChanged<DeliveryFormData> onChanged;
  final ValueChanged<BlockInfo?> onSelectBlock;
  final void Function(RoadInfo?, String? customName) onSelectRoad;
  final ValueChanged<BuildingInfo?> onSelectBuilding;
  final String token;
  final void Function(int blockId, int roadId)? onFetchBuildings;
  final int addressFormatTypeId;
  final bool isReturnFlow;

  static const Map<String, int> _phoneCodeLengths = {
    '+973': 8, // Bahrain
    '+91': 10, // India
    '+966': 9, // Saudi Arabia
    '+971': 9, // UAE
    '+965': 8, // Kuwait
    '+974': 8, // Qatar
    '+968': 8, // Oman
    '+1': 10, // US/Canada
    '+880': 10, // Bangladesh
    '+92': 10, // Pakistan
    '+44': 10, // UK (without leading zero)
    '+20': 10, // Egypt (mobile, without leading zero)
    '+62': 10, // Indonesia (common length)
    '+60': 9, // Malaysia (common length)
    '+63': 10, // Philippines
    '+234': 10, // Nigeria (without leading zero)
    '+254': 9, // Kenya
    '+255': 9, // Tanzania
    '+256': 9, // Uganda
    '+94': 9, // Sri Lanka
    '+977': 10, // Nepal
  };

  @override
  Widget build(BuildContext context) {
    final delivery = state.delivery;
    final isSingleLine = addressFormatTypeId == 2;
    final colors =
        Theme.of(context).extension<AppColors>() ??
        const AppColors(
          primary: Color(0xFF66258E),
          primarySoft: Color(0xFFEDE7F6),
          border: Color(0xFFE5E7EB),
          surface: Colors.white,
          mutedText: Color(0xFF6B7280),
          danger: Colors.red,
          success: Colors.green,
        );
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isReturnFlow ? 'Pickup Details' : 'Delivery Details',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          _rectField(
            label: 'Customer Order ID',
            initial: delivery.customerOrderId,
            keyboard: TextInputType.text,
            onChanged: (v) => _update(delivery.copyWith(customerOrderId: v)),
          ),
          const SizedBox(height: 8),
          _phoneRow(
            title: isReturnFlow ? 'Pickup Contact Number' : 'Receiver Contact Number',
            countryCode: delivery.receiverCountryCode,
            number: delivery.receiverPhone,
            onCodeChanged: (v) =>
                _update(delivery.copyWith(receiverCountryCode: v)),
            onNumberChanged: (v) =>
                _update(delivery.copyWith(receiverPhone: v)),
            keyboard: TextInputType.phone,
          ),
          const SizedBox(height: 8),
          _rectField(
            label: isReturnFlow ? 'Pickup Name' : 'Receiver Name',
            initial: delivery.receiverName,
            keyboard: TextInputType.name,
            onChanged: (v) => _update(delivery.copyWith(receiverName: v)),
          ),
          const SizedBox(height: 8),
          _phoneRow(
            title:
                isReturnFlow ? 'Pickup Alt Contact Number' : 'Receiver Alt Contact Number',
            countryCode: delivery.receiverAltCountryCode,
            number: delivery.receiverAltPhone,
            onCodeChanged: (v) =>
                _update(delivery.copyWith(receiverAltCountryCode: v)),
            onNumberChanged: (v) =>
                _update(delivery.copyWith(receiverAltPhone: v)),
            keyboard: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          if (isSingleLine)
          _rectField(
            label: 'Address',
            initial: delivery.destinationAddress,
            onChanged: (v) => _update(
              delivery.copyWith(destinationAddress: v),
            ),
          )
          else ...[
            _blockSelector(context, delivery, colors),
            _roadSelector(context, delivery, colors),
            _buildingSelector(context, delivery, colors),
            _rectField(
              label: 'Flat / Office No.',
              initial: delivery.flatOrOffice,
              keyboard: TextInputType.streetAddress,
              onChanged: (v) => _update(delivery.copyWith(flatOrOffice: v)),
            ),
          ],
          _rectField(
            label: 'Delivery Instructions',
            initial: delivery.instructions,
            keyboard: TextInputType.text,
            onChanged: (v) => _update(delivery.copyWith(instructions: v)),
          ),
        ],
      ),
    );
  }

  Widget _roadSelector(
    BuildContext context,
    DeliveryFormData delivery,
    AppColors colors,
  ) {
    final hasBlock = delivery.block != null;
    final label = !hasBlock
        ? 'Road (select block first)'
        : (delivery.roadName.isNotEmpty
              ? delivery.roadName
              : delivery.road?.name ?? 'Select road');
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: !hasBlock
            ? null
            : () async {
                _dismissKeyboard(context);
                final blockId = delivery.block!.id;
                final result = await Navigator.of(context)
                    .push<RoadPickerResult>(
                      MaterialPageRoute(
                        builder: (_) => RoadPickerPage(
                          token: token,
                          blockId: blockId,
                          selectedRoadId: delivery.road?.id,
                          initialQuery: delivery.roadName,
                        ),
                      ),
                    );
                if (result != null) {
                  onSelectRoad(result.road, result.customName);
                }
              },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: hasBlock ? Colors.black : Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: hasBlock ? colors.primary : Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _blockSelector(
    BuildContext context,
    DeliveryFormData delivery,
    AppColors colors,
  ) {
    final label = delivery.block != null
        ? '${delivery.block!.code} - ${delivery.block!.name}'
        : 'Select block';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () async {
          _dismissKeyboard(context);
          final result = await Navigator.of(context).push<BlockInfo>(
            MaterialPageRoute(
              builder: (_) => BlockPickerPage(
                token: token,
                selectedBlockId: delivery.block?.id,
                initialQuery: '',
              ),
            ),
          );
          if (result != null) {
            onSelectBlock(result);
            onSelectBlock(result);
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, color: colors.primary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildingSelector(
    BuildContext context,
    DeliveryFormData delivery,
    AppColors colors,
  ) {
    final hasRoadId = delivery.block != null && delivery.road != null;
    final hasRoadName = delivery.block != null && delivery.roadName.isNotEmpty;
    final label = !hasRoadId && !hasRoadName
        ? 'Building (select road first)'
        : (delivery.buildingName.isNotEmpty
              ? delivery.buildingName
              : delivery.building?.name ?? 'Select building');

    if (!hasRoadId && hasRoadName) {
      // Custom road; allow direct building text entry
      return _rectField(
        label: 'Building',
        initial: delivery.buildingName,
        fieldKey: ValueKey(
          'building-custom-${delivery.block?.id}-${delivery.roadName}',
        ),
        onChanged: (v) =>
            _update(delivery.copyWith(building: null, buildingName: v)),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: !hasRoadId
            ? null
            : () async {
                _dismissKeyboard(context);
                final result = await Navigator.of(context)
                    .push<BuildingPickerResult>(
                      MaterialPageRoute(
                        builder: (_) => BuildingPickerPage(
                          token: token,
                          blockId: delivery.block!.id,
                          roadId: delivery.road!.id,
                          selectedBuildingId: delivery.building?.id,
                          initialQuery: delivery.buildingName,
                        ),
                      ),
                    );
                if (result != null) {
                  onSelectBuilding(result.building);
                  _update(
                    delivery.copyWith(
                      building: result.building,
                      buildingName:
                          result.customName ?? result.building?.name ?? '',
                    ),
                  );
                }
              },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: hasRoadId ? Colors.black : Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: hasRoadId ? colors.primary : Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _update(DeliveryFormData data) => onChanged(data);

  void _dismissKeyboard(BuildContext context) {
    FocusScope.of(context).unfocus();
    FocusManager.instance.primaryFocus?.unfocus();
  }

  Widget _rectField({
    required String label,
    required String initial,
    int maxLines = 1,
    TextInputType keyboard = TextInputType.text,
    required ValueChanged<String> onChanged,
    Key? fieldKey,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        key: fieldKey,
        initialValue: initial,
        maxLines: maxLines,
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

  Widget _phoneRow({
    required String title,
    required String countryCode,
    required String number,
    required TextInputType keyboard,
    required ValueChanged<String> onCodeChanged,
    required ValueChanged<String> onNumberChanged,
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
    final codes = _phoneCodeLengths.keys.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFFE5E7EB)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: countryCode,
                  items: codes
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => v == null ? null : onCodeChanged(v),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _rectField(
                label: '',
                // key: ValueKey('$title-$countryCode-$displayNumber'),
                initial: displayNumber,
                keyboard: keyboard,
                onChanged: (v) =>
                    onNumberChanged(sanitizeNumber(v, countryCode)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class DomesticOrderCreatePageWrapper extends StatelessWidget {
  const DomesticOrderCreatePageWrapper({
    super.key,
    required this.token,
    this.draftId,
  });

  final String token;
  final int? draftId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DomesticCreateBloc(
        ordersRepository: context.read<OrdersRepository>(),
        addressRepository: DomesticOrderRepository(),
        token: token,
      ),
      child: DomesticOrderCreatePage(token: token, draftId: draftId),
    );
  }
}

class _DraftPreviewStep extends StatelessWidget {
  const _DraftPreviewStep({required this.state, required this.isReturnFlow});

  final DomesticCreateState state;
  final bool isReturnFlow;

  @override
  Widget build(BuildContext context) {
    final preview = state.previewData;
    final delivery = state.delivery;
    final address = _formatAddress(delivery, state.addressFormatTypeId);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Draft Preview',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              _row('Receiver', delivery.receiverName),
              _row(isReturnFlow ? 'Pickup Contact' : 'Contact', delivery.receiverPhone),
              if (delivery.receiverAltPhone.isNotEmpty)
                _row(
                  isReturnFlow ? 'Pickup Alt Contact' : 'Alt Contact',
                  delivery.receiverAltPhone,
                ),
              if (delivery.customerOrderId.isNotEmpty)
                _row('Customer Order ID', delivery.customerOrderId),
              _row(
                'Instructions',
                delivery.instructions.isEmpty ? '---' : delivery.instructions,
              ),
              const SizedBox(height: 8),
              Text(
                isReturnFlow ? 'Pickup Address' : 'Address',
                style: const TextStyle(fontWeight: FontWeight.w400),
              ),
              const SizedBox(height: 6),
              Text(
                address.isEmpty ? '---' : address,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const Divider(height: 24),
              _row('Packages', '${state.package.packageCount}'),
              if (state.package.isCod)
                _row(
                  'COD Amount',
                  (state.package.codAmount.isNotEmpty
                      ? state.package.codAmount
                      : '0'),
                  valueColor: Colors.red,
                ),
              if (preview != null)
                _row(
                  'Charge',
                  _formatCharge(preview),
                  valueColor: Colors.red,
                ),
              if (preview != null)
                _row(
                  'Service Type',
                  preview['service_type_details']?['name']?.toString() ??
                      _serviceLabel(state.selectedServiceType),
                ),
              const SizedBox(height: 10),
              _packageList(state),
              const SizedBox(height: 12),
              if (state.isAccepting)
                const Center(child: CircularProgressIndicator()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w400),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? const Color(0xFF374151),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _serviceLabel(DomesticServiceType type) {
    switch (type) {
      case DomesticServiceType.express:
        return 'Express';
      case DomesticServiceType.sameDay:
        return 'Same Day';
      case DomesticServiceType.nextDay:
        return 'Next Day';
    }
  }

  String _formatAddress(DeliveryFormData delivery, int addressFormatTypeId) {
    String part(String name, String code) {
      final cleanName = name.trim();
      final cleanCode = code.trim();
      if (cleanName.isEmpty && cleanCode.isEmpty) return '';
      if (cleanName.isNotEmpty && cleanCode.isNotEmpty) {
        return '$cleanName - $cleanCode';
      }
      return cleanName.isNotEmpty ? cleanName : cleanCode;
    }

    final parts = <String>[];
    if (delivery.flatOrOffice.trim().isNotEmpty) {
      parts.add(delivery.flatOrOffice.trim());
    }
    final buildingPart = part(
      delivery.building?.name ?? delivery.buildingName,
      delivery.building?.code ?? '',
    );
    if (buildingPart.isNotEmpty) parts.add(buildingPart);

    final roadPart = part(
      delivery.road?.name ?? delivery.roadName,
      delivery.road?.code ?? '',
    );
    if (roadPart.isNotEmpty) parts.add(roadPart);

    final blockPart = part(
      delivery.block?.name ?? '',
      delivery.block?.code ?? '',
    );
    if (blockPart.isNotEmpty) parts.add(blockPart);

    if (parts.isNotEmpty) return parts.join(', ');

    final fallback = delivery.destinationAddress.trim();
    if (fallback.isNotEmpty) return fallback;
    if (addressFormatTypeId == 2) return '---';
    return '---';
  }

  String _formatCharge(Map<String, dynamic> preview) {
    final raw = preview['calculatedTotalShippingCharge'] ??
        preview['shipping_charge'];
    if (raw == null) return '---';
    double? parsed;
    if (raw is num) {
      parsed = raw.toDouble();
    } else {
      parsed = double.tryParse(raw.toString());
    }
    if (parsed != null) {
      return parsed.toStringAsFixed(2);
    }
    return raw.toString();
  }

  Widget _packageList(DomesticCreateState state) {
    final items = state.package.items;
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // const Text(
        //   'Packages',
        //   style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        // ),
        Divider(),
        const SizedBox(height: 10),
        ...items.asMap().entries.map((entry) {
          final idx = entry.key + 1;
          final item = entry.value;
          final idLabel = item.externalPackageId.trim().isNotEmpty
              ? item.externalPackageId.trim()
              : 'Package $idx';
            final details = <String>[];
            if (item.weight.isNotEmpty) details.add('Weight: ${item.weight}');
            if (item.value.isNotEmpty) details.add('Value: ${item.value}');
            if (item.description.isNotEmpty) {
              details.add('Desc: ${item.description}');
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    idLabel,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  if (item.externalPackageId.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4, bottom: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.qr_code_2, size: 18, color: Color(0xFF4B5563)),
                          const SizedBox(width: 6),
                          Text(
                            item.externalPackageId,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF111827),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (details.isNotEmpty)
                    Text(
                      details.join(' • '),
                      style: const TextStyle(color: Color(0xFF374151)),
                    ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: enabled ? const Color(0x6666258E) : Colors.grey.shade300,
        ),
        child: Icon(
          icon,
          size: 20,
          color: enabled ? const Color(0xFF66258E) : Colors.grey,
        ),
      ),
    );
  }
}

class _PackageItemCard extends StatefulWidget {
  const _PackageItemCard({
    required this.index,
    required this.item,
    required this.commonDescription,
    required this.commonValue,
    required this.onChanged,
  });

  final int index;
  final PackageItemData item;
  final String commonDescription;
  final String commonValue;
  final ValueChanged<PackageItemData> onChanged;

  @override
  State<_PackageItemCard> createState() => _PackageItemCardState();
}

class _PackageItemCardState extends State<_PackageItemCard> {
  bool _expanded = false;
  late PackageItemData _item;

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
    // Refresh empty fields when common description/value change
    if (widget.commonDescription != oldWidget.commonDescription &&
        (_item.description.isEmpty || _item.description == oldWidget.commonDescription)) {
      final updated = _item.copyWith(description: widget.commonDescription);
      setState(() => _item = updated);
      widget.onChanged(updated);
    }
    if (widget.commonValue != oldWidget.commonValue &&
        (_item.value.isEmpty || _item.value == oldWidget.commonValue || _item.value == '0')) {
      final updated = _item.copyWith(value: widget.commonValue);
      setState(() => _item = updated);
      widget.onChanged(updated);
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = _item.externalPackageId.trim().isNotEmpty
        ? _item.externalPackageId.trim()
        : 'Package ${widget.index + 1}';
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
            title: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
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
                  _externalIdRow(context),
                  const SizedBox(height: 8),
                  _field(
                    label: 'Weight (KG)',
                    initial: _item.weight,
                    keyboard: TextInputType.number,
                    onChanged: (v) {
                      final updated = _item.copyWith(weight: _clampWeight(v));
                      setState(() => _item = updated);
                      widget.onChanged(updated);
                    },
                  ),
                  _field(
                  label: 'Description',
                  initial:
                      _item.description.isEmpty &&
                          widget.commonDescription.isNotEmpty
                      ? widget.commonDescription
                      : _item.description,
                  fieldKey: ValueKey(
                    'desc-${widget.index}-${_item.description}-${widget.commonDescription}',
                  ),
                  onChanged: (v) {
                    final updated = _item.copyWith(description: v);
                    setState(() => _item = updated);
                    widget.onChanged(updated);
                  },
                ),
                _field(
                  label: 'Value',
                  initial:
                      (_item.value.isEmpty || _item.value == '0') &&
                              widget.commonValue.isNotEmpty
                          ? widget.commonValue
                          : _item.value,
                  fieldKey: ValueKey(
                    'value-${widget.index}-${_item.value}-${widget.commonValue}',
                  ),
                  keyboard: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                    onChanged: (v) {
                      final updated = _item.copyWith(value: _clampValue(v));
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

  Widget _externalIdRow(BuildContext context) {
    final hasValue = _item.externalPackageId.trim().isNotEmpty;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Custom Package ID',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  hasValue ? _item.externalPackageId : 'Not scanned yet',
                  style: TextStyle(
                    color: hasValue ? Colors.black87 : Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.qr_code_scanner),
            label: Text(hasValue ? 'Rescan' : 'Scan'),
            onPressed: () => _openScanner(context),
          ),
          if (hasValue)
            IconButton(
              tooltip: 'Clear scanned ID',
              icon: const Icon(Icons.close),
              onPressed: _clearExternalId,
            ),
        ],
      ),
    );
  }

  Future<void> _openScanner(BuildContext context) async {
    final code = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => BarcodeScannerPage(
          title: 'Scan package ${widget.index + 1}',
        ),
      ),
    );
    if (code == null || code.trim().isEmpty) return;
    final updated = _item.copyWith(externalPackageId: code.trim());
    setState(() => _item = updated);
    widget.onChanged(updated);
  }

  void _clearExternalId() {
    if (_item.externalPackageId.isEmpty) return;
    final updated = _item.copyWith(externalPackageId: '');
    setState(() => _item = updated);
    widget.onChanged(updated);
  }

  Widget _field({
    required String label,
    required String initial,
    TextInputType? keyboard,
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
            borderSide: const BorderSide(color: Color(0xFF66258E), width: 1.5),
          ),
        ),
        keyboardType: keyboard,
        onChanged: onChanged,
      ),
    );
  }

  Widget? _subtitleText() {
    if (_item.weight.isEmpty &&
        _item.description.isEmpty &&
        _item.value.isEmpty &&
        _item.externalPackageId.isEmpty) {
      return const Text('Tap to add details');
    }
    final parts = <String>[];
    if (_item.externalPackageId.isNotEmpty) {
      parts.add('ID ${_item.externalPackageId}');
    }
    if (_item.weight.isNotEmpty) parts.add('${_item.weight} kg');
    if (_item.value.isNotEmpty) parts.add('Value ${_item.value}');
    if (parts.isEmpty) return null;
    return Text(parts.join(' • '));
  }

  String _clampWeight(String raw) {
    final parsed = double.tryParse(raw);
    if (parsed == null || parsed < 1) return '1';
    return raw;
  }

  String _clampValue(String raw) {
    final parsed = double.tryParse(raw);
    if (parsed == null || parsed < 0) return '0';
    return raw;
  }
}
