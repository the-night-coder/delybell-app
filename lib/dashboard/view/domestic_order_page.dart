import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/domestic_order_bloc.dart';
import '../models/address_lookup.dart';
import '../data/domestic_order_repository.dart';

class DomesticOrderPage extends StatefulWidget {
  const DomesticOrderPage({super.key});

  @override
  State<DomesticOrderPage> createState() => _DomesticOrderPageState();
}

class _DomesticOrderPageState extends State<DomesticOrderPage> {
  @override
  void initState() {
    super.initState();
    context.read<DomesticOrderBloc>().add(const DomesticBlocksRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: BlocBuilder<DomesticOrderBloc, DomesticOrderState>(
          builder: (context, state) {
            final current = state.currentStep + 1;
            return Text('Create Order ($current/3)');
          },
        ),
        centerTitle: true,
      ),
      backgroundColor: const Color(0xFFF7F8FB),
      body: BlocBuilder<DomesticOrderBloc, DomesticOrderState>(
        builder: (context, state) {
          final bloc = context.read<DomesticOrderBloc>();

          Widget page() {
            switch (state.currentStep) {
              case 0:
                return _PackageDetails(
                  serviceType: state.serviceType,
                  packageCount: state.packageCount,
                );
              case 1:
                return _AddressSelectors(state: state);
              case 2:
              default:
                return _Summary(state: state);
            }
          }

          void goTo(int step) {
            final clamped = step.clamp(0, 2);
            bloc.add(DomesticStepChanged(clamped));
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _StepHeader(
                current: state.currentStep,
                labels: const ['Package', 'Delivery', 'Review'],
                onStepTap: goTo,
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: page(),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Row(
                  children: [
                    if (state.currentStep > 0)
                      OutlinedButton.icon(
                        onPressed: () => goTo(state.currentStep - 1),
                        icon: const Icon(Icons.arrow_back_ios_new, size: 16),
                        label: const Text('Back'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey.shade800,
                          side: BorderSide(color: Colors.grey.shade300),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    if (state.currentStep > 0) const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => goTo(state.currentStep + 1),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(state.currentStep == 2 ? 'Finish' : 'Next'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
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
    final primary = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
      child: Row(
        children: List.generate(labels.length, (index) {
          final isActive = index == current;
          final isDone = index < current;
          final circleBorder = isActive || isDone ? primary : Colors.grey.shade500;
          final fillColor = isActive
              ? primary.withValues(alpha: 0.15)
              : isDone
                  ? primary.withValues(alpha: 0.08)
                  : Colors.transparent;
          final labelColor =
              isActive ? primary : (isDone ? Colors.black87 : Colors.grey.shade700);

          return Expanded(
            child: Row(
              children: [
                InkWell(
                  onTap: () => onStepTap(index),
                  child: Column(
                    children: [
                      Container(
                        height: 22,
                        width: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: fillColor,
                          border: Border.all(color: circleBorder, width: 2),
                        ),
                        child: isDone
                            ? Icon(Icons.check, size: 14, color: primary)
                            : null,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        labels[index],
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                          color: labelColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                if (index != labels.length - 1)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: _DashedLine(
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _DashedLine extends StatelessWidget {
  const _DashedLine({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final dashWidth = 6.0;
        final dashSpace = 4.0;
        final dashCount = (constraints.maxWidth / (dashWidth + dashSpace)).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(dashCount, (_) {
            return Container(
              width: dashWidth,
              height: 2,
              color: color,
            );
          }),
        );
      },
    );
  }
}

class _PackageDetails extends StatelessWidget {
  const _PackageDetails({
    required this.serviceType,
    required this.packageCount,
  });

  final DomesticServiceType serviceType;
  final int packageCount;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<DomesticOrderBloc>();

    Widget _chip(DomesticServiceType type, String label) {
      final isSelected = serviceType == type;
      return ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => bloc.add(DomesticServiceTypeChanged(type)),
        selectedColor: const Color(0xFFE9E4FF),
        labelStyle: TextStyle(
          color: isSelected ? const Color(0xFF4F46E5) : Colors.black87,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Service Type',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          children: [
            _chip(DomesticServiceType.express, 'Express'),
            _chip(DomesticServiceType.nextDay, 'Next Day'),
            _chip(DomesticServiceType.sameDay, 'Same Day'),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'No. of packages',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: () =>
                  bloc.add(DomesticPackageCountChanged(packageCount - 1)),
            ),
            Text(
              '$packageCount',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () =>
                  bloc.add(DomesticPackageCountChanged(packageCount + 1)),
            ),
          ],
        ),
      ],
    );
  }
}

class _AddressSelectors extends StatelessWidget {
  const _AddressSelectors({required this.state});

  final DomesticOrderState state;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<DomesticOrderBloc>();

    return Column(
      children: [
        _LookupField<BlockInfo>(
          label: 'Block',
          hint: 'Select Block',
          items: state.blocks,
          isLoading: state.blocksStatus == LookupStatus.loading,
          error: state.blocksError,
          selected: state.selectedBlock,
          enabled: true,
          onTap: () => bloc.add(const DomesticBlocksRequested()),
          onClear: () => bloc.add(const DomesticBlockCleared()),
          itemLabel: (item) => '${item.code} - ${item.name}',
          onChanged: (block) {
            if (block != null) {
              bloc.add(DomesticBlockSelected(block));
              bloc.add(const DomesticRoadsRequested());
            }
          },
        ),
        const SizedBox(height: 12),
        _LookupField<RoadInfo>(
          label: 'Road',
          hint: state.selectedBlock == null ? 'Select Block first' : 'Select Road',
          items: state.roads,
          isLoading: state.roadsStatus == LookupStatus.loading,
          error: state.roadsError,
          selected: state.selectedRoad,
          enabled: state.selectedBlock != null,
          onTap: () => bloc.add(const DomesticRoadsRequested()),
          onClear: () => bloc.add(const DomesticRoadCleared()),
          itemLabel: (item) => '${item.code} - ${item.name}',
          onChanged: (road) {
            if (road != null) {
              bloc.add(DomesticRoadSelected(road));
              bloc.add(const DomesticBuildingsRequested());
            }
          },
        ),
        const SizedBox(height: 12),
        _LookupField<BuildingInfo>(
          label: 'Building',
          hint: state.selectedRoad == null ? 'Select Road first' : 'Select Building',
          items: state.buildings,
          isLoading: state.buildingsStatus == LookupStatus.loading,
          error: state.buildingsError,
          selected: state.selectedBuilding,
          enabled: state.selectedRoad != null,
          onTap: () => bloc.add(const DomesticBuildingsRequested()),
          onClear: () => bloc.add(const DomesticBuildingCleared()),
          itemLabel: (item) => '${item.code} - ${item.name}',
          onChanged: (building) {
            if (building != null) {
              bloc.add(DomesticBuildingSelected(building));
            }
          },
        ),
      ],
    );
  }
}

class _LookupField<T> extends StatelessWidget {
  const _LookupField({
    required this.label,
    required this.hint,
    required this.items,
    required this.isLoading,
    required this.error,
    required this.selected,
    required this.enabled,
    required this.onTap,
    required this.onClear,
    required this.itemLabel,
    required this.onChanged,
  });

  final String label;
  final String hint;
  final List<T> items;
  final bool isLoading;
  final String? error;
  final T? selected;
  final bool enabled;
  final VoidCallback onTap;
  final VoidCallback onClear;
  final String Function(T item) itemLabel;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            if (selected != null)
              TextButton.icon(
                onPressed: onClear,
                icon: const Icon(Icons.clear, size: 16),
                label: const Text('Clear'),
              ),
          ],
        ),
        DropdownButtonFormField<T>(
          isExpanded: true,
          value: selected,
          onTap: enabled ? onTap : null,
          onChanged: enabled ? onChanged : null,
          decoration: InputDecoration(
            hintText: hint,
            suffixIcon: isLoading ? const Padding(
              padding: EdgeInsets.all(10),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ) : null,
          ),
          items: items
              .map(
                (item) => DropdownMenuItem<T>(
                  value: item,
                  child: Text(itemLabel(item)),
                ),
              )
              .toList(),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              error!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.state});

  final DomesticOrderState state;

  @override
  Widget build(BuildContext context) {
    String _serviceLabel(DomesticServiceType type) {
      switch (type) {
        case DomesticServiceType.express:
          return 'Express';
        case DomesticServiceType.nextDay:
          return 'Next Day';
        case DomesticServiceType.sameDay:
          return 'Same Day';
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Service: ${_serviceLabel(state.serviceType)}'),
        Text('Packages: ${state.packageCount}'),
        Text('Block: ${state.selectedBlock?.name ?? '-'}'),
        Text('Road: ${state.selectedRoad?.name ?? '-'}'),
        Text('Building: ${state.selectedBuilding?.name ?? '-'}'),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: () {},
          child: const Text('Place Order (draft)'),
        ),
      ],
    );
  }
}

Widget domesticOrderPageWithDependencies({required String token}) {
  return RepositoryProvider(
    create: (_) => DomesticOrderRepository(),
    child: Builder(
      builder: (context) {
        return BlocProvider(
          create: (_) => DomesticOrderBloc(
            context.read<DomesticOrderRepository>(),
            token: token,
          ),
          child: const DomesticOrderPage(),
        );
      },
    ),
  );
}
