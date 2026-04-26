import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/app_colors.dart';
import '../../domain/entities/invoice.dart';
import '../bloc/invoices_bloc.dart';

class InvoicesPage extends StatefulWidget {
  const InvoicesPage({super.key});

  @override
  State<InvoicesPage> createState() => _InvoicesPageState();
}

class _InvoicesPageState extends State<InvoicesPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors =
        Theme.of(context).extension<AppColors>() ??
        const AppColors(
          primary: Color(0xFF66258E),
          primarySoft: Color(0xFFEDE9FE),
          border: Color(0xFFE5E7EB),
          surface: Colors.white,
          mutedText: Color(0xFF6B7280),
          danger: Color(0xFFE11D48),
          success: Color(0xFF16A34A),
        );

    return SafeArea(
      child: BlocConsumer<InvoicesBloc, InvoicesState>(
        listener: (context, state) {
          if (state.status == InvoiceStatus.failure &&
              state.errorMessage.isNotEmpty) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.errorMessage)));
          }
        },
        builder: (context, state) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                child: Row(
                  children: [
                    const Text(
                      'Invoices',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    _TabButton(
                      label: 'Paid',
                      isActive: state.tab == InvoiceTab.paid,
                      onTap: () => context.read<InvoicesBloc>().add(
                        const InvoicesTabChanged(InvoiceTab.paid),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _TabButton(
                      label: 'Unpaid',
                      isActive: state.tab == InvoiceTab.unpaid,
                      onTap: () => context.read<InvoicesBloc>().add(
                        const InvoicesTabChanged(InvoiceTab.unpaid),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search invoice (ex: INV-123)',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: colors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: colors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: colors.primary),
                    ),
                  ),
                  textInputAction: TextInputAction.search,
                  onSubmitted: (value) => context.read<InvoicesBloc>().add(
                    InvoicesRequested(search: value.trim(), reset: true),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    context.read<InvoicesBloc>().add(const InvoicesRefreshed());
                  },
                  child: _buildBody(context, state, colors),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    InvoicesState state,
    AppColors colors,
  ) {
    if (state.status == InvoiceStatus.loading && state.invoices.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.status == InvoiceStatus.failure && state.invoices.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red),
              const SizedBox(height: 8),
              Text(
                state.errorMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => context.read<InvoicesBloc>().add(
                  const InvoicesRequested(reset: true),
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.pixels >=
                notification.metrics.maxScrollExtent - 200 &&
            state.hasMore &&
            !state.isLoadingMore) {
          context.read<InvoicesBloc>().add(const InvoicesLoadMore());
        }
        return false;
      },
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
        itemCount: state.invoices.length + (state.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= state.invoices.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final invoice = state.invoices[index];
          return _InvoiceCard(invoice: invoice, colors: colors);
        },
      ),
    );
  }
}

class _InvoiceCard extends StatelessWidget {
  const _InvoiceCard({required this.invoice, required this.colors});

  final Invoice invoice;
  final AppColors colors;

  Color get _statusColor {
    switch (invoice.paymentStatusId) {
      case 2:
        return colors.success;
      case 3:
      case 4:
        return colors.danger;
      default:
        return const Color(0xFFF59E0B);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.black.withValues(alpha: 0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                    color: _statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    invoice.paymentStatus,
                    style: TextStyle(
                      color: _statusColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  'BHD ${invoice.payableAmount}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              invoice.generatedId,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(
                  Icons.person_outline,
                  size: 18,
                  color: Color(0xFF6B7280),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    invoice.customerName.isEmpty
                        ? 'Customer'
                        : invoice.customerName,
                    style: const TextStyle(color: Color(0xFF374151)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(
                  Icons.event_note_outlined,
                  size: 18,
                  color: Color(0xFF6B7280),
                ),
                const SizedBox(width: 6),
                Text(
                  'Due ${invoice.dueDate}',
                  style: const TextStyle(color: Color(0xFF6B7280)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>();
    final borderColor = colors?.primary ?? const Color(0xFF66258E);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? (colors?.primarySoft ?? const Color(0xFFEDE9FE))
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? borderColor : const Color(0xFF374151),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
