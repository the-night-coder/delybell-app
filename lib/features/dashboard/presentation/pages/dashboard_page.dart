import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../login/models/login_response.dart';
import '../../../../core/error_utils.dart';
import '../bloc/dashboard_bloc.dart';
import '../../../orders/presentation/bloc/orders_bloc.dart';
import '../../../../dashboard/models/order_summary.dart';
import '../../../dashboard/domain/repositories/dashboard_repository.dart';
import '../../../orders/presentation/pages/domestic_order_create_page.dart';
import '../../../orders/presentation/pages/international_order_create_page.dart';
import '../../../../dashboard/models/dashboard_summary.dart';
import '../../../orders/presentation/pages/order_detail_page.dart';
import '../../../orders/presentation/pages/draft_detail_page.dart';
import '../../../orders/presentation/pages/draft_place_page.dart';
import '../../../orders/domain/repositories/orders_repository.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import '../../../invoices/presentation/bloc/invoices_bloc.dart';
import '../../../invoices/presentation/pages/invoices_page.dart';
import '../../../invoices/domain/repositories/invoices_repository.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key, required this.loginResponse, this.onLogout});

  final LoginResponse loginResponse;
  final Future<void> Function(BuildContext context)? onLogout;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _currentIndex = 0;

  void _onNavTap(int index) {
    setState(() => _currentIndex = index);
  }

  void _showCreateOrderSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Create Order',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFE0E7FF),
                  child: Icon(
                    Icons.local_shipping_outlined,
                    color: Color(0xFF4F46E5),
                  ),
                ),
                title: const Text('Domestic Delivery'),
                subtitle: const Text('Ship within Bahrain quickly'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => DomesticOrderCreatePageWrapper(
                        token: widget.loginResponse.token,
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFFCE7F3),
                  child: Icon(Icons.public_outlined, color: Color(0xFFBE185D)),
                ),
                title: const Text('International Delivery'),
                subtitle: const Text('Send packages worldwide'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => InternationalOrderCreatePageWrapper(
                        token: widget.loginResponse.token,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final homeView = BlocProvider(
      create: (_) => DashboardBloc(
        context.read<DashboardRepository>(),
        token: widget.loginResponse.token,
      )..add(const DashboardRequested()),
      child: DashboardHomeView(loginResponse: widget.loginResponse),
    );

    final views = [
      homeView,
      OrdersView(token: widget.loginResponse.token),
      InvoicesView(token: widget.loginResponse.token),
      ProfilePage(
        userType: widget.loginResponse.user.userTypeId,
        name: widget.loginResponse.user.fullName.isEmpty
            ? 'Delybell user'
            : widget.loginResponse.user.fullName,
        email: widget.loginResponse.user.email,
        phone: widget.loginResponse.user.phone,
        customerId: 'ID #${widget.loginResponse.user.id}',
        token: widget.loginResponse.token,
        onLogout: widget.onLogout,
        initialFirstName: widget.loginResponse.user.firstName,
        initialLastName: widget.loginResponse.user.lastName,
        initialCompanyName: widget.loginResponse.user.companyName,
        initialCompanyReg: widget.loginResponse.user.companyRegistrationNumber,
        initialVatNumber: widget.loginResponse.user.vatNumber,
        initialAddressLine: widget.loginResponse.user.addressLineOne,
        initialFirstNameAr: widget.loginResponse.user.firstNameAr,
        initialLastNameAr: widget.loginResponse.user.lastNameAr,
        initialNationalityId: widget.loginResponse.user.nationalityId,
        initialNationalityName: widget.loginResponse.user.nationalityName,
        initialPackageDescription: widget.loginResponse.user.packageDescription,
      ),
    ];

    final showFab = _currentIndex == 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: views[_currentIndex],
      ),
      floatingActionButton: showFab
          ? FloatingActionButton(
              onPressed: _showCreateOrderSheet,
              backgroundColor: Theme.of(context).colorScheme.primary,
              shape: const CircleBorder(),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onNavTap,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Orders',
          ),
          NavigationDestination(
            icon: Icon(Icons.request_quote_outlined),
            selectedIcon: Icon(Icons.request_quote),
            label: 'Invoices',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class DashboardHomeView extends StatelessWidget {
  const DashboardHomeView({super.key, required this.loginResponse});

  final LoginResponse loginResponse;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        final summary = state.summary ?? const DashboardSummary.empty();
        final isCodUser = loginResponse.user.userTypeId == 5;
        final stats = [
          (
            'Live Orders',
            Icons.local_shipping_outlined,
            summary.liveOrders.toString(),
          ),
          // ('Draft Orders', Icons.edit_note_outlined, summary.draftOrders.toString()),
          // ('In Progress', Icons.timelapse_outlined, summary.inProgressOrders.toString()),
          // ('Cancelled', Icons.cancel_outlined, summary.cancelledOrders.toString()),
          (
            'Orders Today',
            Icons.calendar_today_outlined,
            summary.ordersPlacedToday.toString(),
          ),
          // ('Orders This Month', Icons.calendar_month_outlined, summary.ordersThisMonth.toString()),
          // (
          //   'COD Amount',
          //   Icons.payments_outlined,
          //   'BHD ${summary.codAmount.toStringAsFixed(2)}',
          // ),
          (
            'Pickup Today',
            Icons.store_mall_directory_outlined,
            summary.todayPickupOrders.toString(),
          ),
          if (isCodUser)
            (
              'COD Amount',
              Icons.payments_outlined,
              (summary.codAmount.toStringAsFixed(3)),
            )
          else
            (
              'Delivered',
              Icons.check_circle_outline,
              summary.deliveredOrders.toString(),
            ),
          // (
          //   'Same Day Deliveries',
          //   Icons.flash_on_outlined,
          //   summary.todaySameDayDeliveryOrders.toString(),
          // ),
          // (
          //   'Next Day Deliveries',
          //   Icons.nightlight_round,
          //   summary.todayNextDayDeliveryOrders.toString(),
          // ),
        ];

        final isLoading = state.status == DashboardStatus.loading;
        final isInitialLoading =
            (state.status == DashboardStatus.initial || isLoading) &&
            state.summary == null;
        final hasError = state.status == DashboardStatus.failure;
        final errorMessage = state.errorMessage ?? 'Unable to load dashboard';

        if (isInitialLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (hasError && state.summary == null) {
          return SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: _DashboardError(
                  message: errorMessage,
                  onRetry: () => context.read<DashboardBloc>().add(
                    const DashboardRequested(resetData: true),
                  ),
                ),
              ),
            ),
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final contentWidth = math.max(width - 48, 0);
            final crossAxisCount = contentWidth < 680 ? 2 : 3;
            final actionsStack = contentWidth < 900;
            final double cardWidth = math.max(
              (actionsStack ? contentWidth : (contentWidth - 20) / 2) as double,
              280,
            );

            return SafeArea(
              child: RefreshIndicator(
                onRefresh: () async {
                  context.read<DashboardBloc>().add(const DashboardRefreshed());
                  await context.read<DashboardBloc>().stream.firstWhere(
                    (state) => state.status != DashboardStatus.loading,
                  );
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const _BrandMark(),
                          const Spacer(),
                          // FilledButton.icon(
                          //   onPressed: () {},
                          //   icon: const Icon(Icons.print),
                          //   label: const Text('Print all sticker'),
                          //   style: FilledButton.styleFrom(
                          //     backgroundColor: Theme.of(
                          //       context,
                          //     ).colorScheme.primary,
                          //     shape: RoundedRectangleBorder(
                          //       borderRadius: BorderRadius.circular(18),
                          //     ),
                          //   ),
                          // ),
                        ],
                      ),
                      if (isLoading)
                        const Padding(
                          padding: EdgeInsets.only(top: 16),
                          child: LinearProgressIndicator(minHeight: 3),
                        ),
                      const SizedBox(height: 24),
                      Text(
                        'Good day, ${loginResponse.user.firstName}',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Here is what\'s happening with your logistics today.',
                        style: TextStyle(color: Color(0xFF6B7280)),
                      ),
                      const SizedBox(height: 24),
                      if (hasError)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _DashboardError(
                            message: errorMessage,
                            onRetry: () => context.read<DashboardBloc>().add(
                              const DashboardRequested(resetData: true),
                            ),
                          ),
                        ),
                      GridView.builder(
                        shrinkWrap: true,
                        itemCount: stats.length,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          // childAspectRatio: crossAxisCount == 1 ? 1.2 : 1.1,
                          childAspectRatio: 1.0,
                        ),
                        itemBuilder: (context, index) => DashboardStatCard(
                          title: stats[index].$1,
                          icon: stats[index].$2,
                          value: stats[index].$3,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Wrap(
                        alignment: WrapAlignment.start,
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          SizedBox(
                            width: cardWidth,
                            child: DashboardActionCard(
                              title: 'Place Domestic Order',
                              subtitle:
                                  'Orders placed and delivered within Bahrain',
                              icon: Icons.local_shipping,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        DomesticOrderCreatePageWrapper(
                                          token: loginResponse.token,
                                        ),
                                  ),
                                );
                              },
                            ),
                          ),
                          SizedBox(
                            width: cardWidth,
                            child: DashboardActionCard(
                              title: 'Place International Order',
                              subtitle:
                                  'Orders sent to countries other than Bahrain',
                              icon: Icons.public,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        InternationalOrderCreatePageWrapper(
                                          token: loginResponse.token,
                                        ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class OrdersView extends StatelessWidget {
  const OrdersView({super.key, required this.token});

  final String token;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          OrdersBloc(
              context.read<OrdersRepository>(),
              token: token,
              dashboardRepository: context.read<DashboardRepository>(),
            )
            ..add(const OrdersCountsRequested())
            ..add(const OrdersRequested()),
      child: _OrdersContent(token: token),
    );
  }
}

class _OrdersContent extends StatefulWidget {
  const _OrdersContent({required this.token});

  final String token;

  @override
  State<_OrdersContent> createState() => _OrdersContentState();
}

class _OrdersContentState extends State<_OrdersContent> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: BlocBuilder<OrdersBloc, OrdersState>(
        builder: (context, state) {
          if (_controller.text != state.searchTerm) {
            _controller.text = state.searchTerm;
            _controller.selection = TextSelection.fromPosition(
              TextPosition(offset: _controller.text.length),
            );
          }

          Widget listArea() {
            if (state.status == OrdersStatus.failure && state.orders.isEmpty) {
              return _OrdersError(
                message: state.errorMessage ?? 'Unable to load orders',
                onRetry: () => context.read<OrdersBloc>().add(
                  const OrdersRequested(reset: true),
                ),
              );
            }

            if (state.status == OrdersStatus.loading && state.orders.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            return RefreshIndicator(
              onRefresh: () async {
                context.read<OrdersBloc>().add(const OrdersRefreshed());
                await context.read<OrdersBloc>().stream.firstWhere(
                  (s) => s.status != OrdersStatus.loading,
                );
              },
              child: state.orders.isEmpty
                  ? ListView(
                      padding: const EdgeInsets.all(32),
                      children: const [
                        Center(
                          child: Text(
                            'No orders found.',
                            style: TextStyle(color: Color(0xFF6B7280)),
                          ),
                        ),
                      ],
                    )
                  : Stack(
                      children: [
                        ListView.builder(
                          padding: const EdgeInsets.only(top: 8, bottom: 80),
                          itemCount:
                              state.orders.length + (state.hasMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index >= state.orders.length) {
                              context.read<OrdersBloc>().add(
                                const OrdersLoadMore(),
                              );
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }

                            final order = state.orders[index];
                            final isDraft = state.tab == OrderTab.draft;
                            final isInternational = order.orderType
                                .toLowerCase()
                                .contains('international');
                            final canCancel = _canCancelOrder(order);
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 4,
                              ),
                              child: _OrderCard(
                                order: order,
                                showMenu: isDraft || canCancel,
                                useDestinationAddress:
                                    isDraft || isInternational,
                                onMenuTap: isDraft
                                    ? () => _showDraftActions(context, order)
                                    : canCancel
                                        ? () => _showOrderActions(context, order)
                                        : null,
                                onTap: () {
                                  if (isDraft) {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            DraftDetailPage(order: order),
                                      ),
                                    );
                                  } else {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => OrderDetailPage(
                                          order: order,
                                          token: widget.token,
                                        ),
                                      ),
                                    );
                                  }
                                },
                              ),
                            );
                          },
                        ),
                        if (state.tab == OrderTab.draft &&
                            state.orders.isNotEmpty)
                          Positioned(
                            left: 24,
                            right: 24,
                            bottom: 16,
                            child: Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      backgroundColor: Colors.white
                                    ),
                                    onPressed: state.isPlacingDraft
                                        ? null
                                        : () async {
                                            final confirm = await showDialog<bool>(
                                              context: context,
                                              builder: (dialogCtx) => AlertDialog(
                                                title: const Text(
                                                  'Clear all drafts?',
                                                ),
                                                content: const Text(
                                                  'This will remove all draft orders. Are you sure?',
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.of(
                                                          dialogCtx,
                                                        ).pop(false),
                                                    child: const Text('Cancel'),
                                                  ),
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.of(
                                                          dialogCtx,
                                                        ).pop(true),
                                                    child: const Text('Clear'),
                                                  ),
                                                ],
                                              ),
                                            );
                                            if (confirm == true &&
                                                context.mounted) {
                                              _clearDrafts(context);
                                            }
                                          },
                                    icon: const Icon(Icons.cleaning_services),
                                    label: const Text('Clear Drafts'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      elevation: 2,
                                      backgroundColor: const Color(0xFF66258E),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    onPressed: state.isPlacingDraft
                                        ? null
                                        : () async {
                                            final result =
                                                await Navigator.of(
                                                  context,
                                                ).push<bool>(
                                                  MaterialPageRoute(
                                                    builder: (_) =>
                                                        DraftPlacePage(
                                                          token: widget.token,
                                                          serviceType:
                                                              state
                                                                  .orders
                                                                  .isNotEmpty
                                                              ? state
                                                                    .orders
                                                                    .first
                                                                    .serviceType
                                                              : '',
                                                        ),
                                                  ),
                                                );
                                            if (result == true &&
                                                context.mounted) {
                                              context.read<OrdersBloc>().add(
                                                const OrdersRefreshed(),
                                              );
                                            }
                                          },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                        horizontal: 8,
                                      ),
                                      child: Text(
                                        state.isPlacingDraft
                                            ? 'Placing...'
                                            : 'Place Orders',
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Orders',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: const Color(0xFF66258E),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => DomesticOrderCreatePageWrapper(
                                  token: widget.token,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.add, color: Colors.white),
                          label: const Text(
                            'Create Order',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'Search orders by ID, receiver, phone...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: state.searchTerm.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _controller.clear();
                                  context.read<OrdersBloc>().add(
                                    const OrdersRequested(
                                      reset: true,
                                      search: '',
                                    ),
                                  );
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (value) {
                        context.read<OrdersBloc>().add(
                          OrdersRequested(reset: true, search: value.trim()),
                        );
                      },
                      onChanged: (value) {
                        context.read<OrdersBloc>().add(
                          OrdersRequested(reset: true, search: value.trim()),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _OrdersTabBar(current: state.tab),
                  ],
                ),
              ),
              Expanded(child: listArea()),
            ],
          );
        },
      ),
    );
  }

  bool _canCancelOrder(OrderSummary order) {
    final normalized = order.status.toLowerCase();
    final hasOpen = normalized.contains('open');
    final hasPending = normalized.contains('pending');
    final hasPickup = normalized.contains('pickup');
    final pendingPickup = normalized.contains('pending pickup') ||
        normalized.contains('pickup pending') ||
        (hasPending && hasPickup);
    return hasOpen || pendingPickup;
  }

  void _showOrderActions(BuildContext context, OrderSummary order) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.cancel_outlined, color: Colors.red),
                title: const Text('Cancel order'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _confirmCancelOrder(context, order);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmCancelOrder(
    BuildContext context,
    OrderSummary order,
  ) async {
    var reasonInput = '';
    final reason = await showDialog<String?>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          title: const Text('Cancel this order?'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'This will cancel the order before pickup. '
                  'You can add a reason (optional).',
                ),
                const SizedBox(height: 12),
                TextField(
                  maxLines: 2,
                  decoration: const InputDecoration(
                    hintText: 'Reason (optional)',
                  ),
                  textInputAction: TextInputAction.done,
                  onChanged: (value) => reasonInput = value,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(null),
              child: const Text('Keep order'),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.of(dialogCtx).pop(reasonInput.trim()),
              child: const Text('Cancel order'),
            ),
          ],
        );
      },
    );
    if (!mounted || reason == null) return;
    final trimmedReason = reason.trim();
    await _cancelOrder(
      context,
      order,
      trimmedReason.isEmpty ? null : trimmedReason,
    );
  }

  Future<void> _cancelOrder(
    BuildContext context,
    OrderSummary order,
    String? reason,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      const SnackBar(content: Text('Canceling order...')),
    );
    try {
      await context.read<OrdersRepository>().cancelOrder(
        token: widget.token,
        orderId: order.id,
        reason: reason,
      );
      if (!mounted) return;
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(content: Text('Order canceled')),
      );
      context.read<OrdersBloc>().add(const OrdersRefreshed());
    } catch (error) {
      if (!mounted) return;
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            ErrorUtils.friendly(
              error.toString(),
              fallback: 'Unable to cancel order',
            ),
          ),
        ),
      );
    }
  }

  void _showDraftActions(BuildContext context, OrderSummary order) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Delete'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _deleteDraft(context, order.id);
                },
              ),
              ListTile(
                leading: const Icon(Icons.schedule, color: Color(0xFF2563EB)),
                title: const Text('Mark for future pickup'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  context.read<OrdersBloc>().add(
                    OrdersDraftFuturePickupRequested(order.id),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Marked for future pickup')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.edit_outlined,
                  color: Color(0xFF2563EB),
                ),
                title: const Text('Edit draft'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => DomesticOrderCreatePageWrapper(
                        token: widget.token,
                        draftId: order.id,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _deleteDraft(BuildContext context, int id) {
    context.read<OrdersBloc>().add(OrdersDraftDeleteRequested(id));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Deleting draft...')));
  }

  void _clearDrafts(BuildContext context) {
    context.read<OrdersBloc>().add(const OrdersDraftClearRequested());
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Clearing all drafts...')));
  }
}

class _OrdersTabBar extends StatelessWidget {
  const _OrdersTabBar({required this.current});

  final OrderTab current;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OrdersBloc, OrdersState>(
      builder: (context, state) {
        final tabs = [
          (OrderTab.draft, 'Draft', state.draftCount),
          (OrderTab.inprogress, 'In Progress', state.inProgressCount),
          (OrderTab.completed, 'Completed', state.completedCount),
          (OrderTab.canceled, 'Canceled', state.canceledCount),
        ];

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: tabs
                .map(
                  (tab) => Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: ChoiceChip(
                      label: Text('${tab.$2} (${tab.$3})'),
                      selected: current == tab.$1,
                      onSelected: (_) => context.read<OrdersBloc>().add(
                        OrdersTabChanged(tab.$1),
                      ),
                      selectedColor: const Color(0xFFE0E7FF),
                      labelStyle: TextStyle(
                        color: current == tab.$1
                            ? const Color(0xFF1D4ED8)
                            : Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        );
      },
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    this.onTap,
    this.onMenuTap,
    this.showMenu = false,
    this.useDestinationAddress = false,
  });

  final OrderSummary order;
  final VoidCallback? onTap;
  final VoidCallback? onMenuTap;
  final bool showMenu;
  final bool useDestinationAddress;

  Color _statusColor(String status) {
    final normalized = status.toLowerCase();
    if (normalized.contains('pickup')) return const Color(0xFF1D9BF0);
    if (normalized.contains('open')) return const Color(0xFF6B21A8);
    if (normalized.contains('delivered')) return const Color(0xFF16A34A);
    if (normalized.contains('cancel')) return const Color(0xFFDC2626);
    return const Color(0xFF2563EB);
  }

  String _humanize(String input) {
    if (input.isEmpty) return input;
    final buffer = StringBuffer();
    for (var i = 0; i < input.length; i++) {
      final char = input[i];
      if (i > 0 && char.toUpperCase() == char && char != ' ') {
        buffer.write(' ');
      }
      buffer.write(char);
    }
    return buffer.toString();
  }

  String _displayAddress() {
    final primary =
        useDestinationAddress ? order.destinationAddress : order.addressLine;
    final fallback =
        useDestinationAddress ? order.addressLine : order.destinationAddress;
    final sender = order.senderAddress.trim();
    final normalizedPrimary = primary.trim();
    if (normalizedPrimary.isNotEmpty && normalizedPrimary != '-') {
      return normalizedPrimary;
    }
    final normalizedFallback = fallback.trim();
    if (normalizedFallback.isNotEmpty && normalizedFallback != '-') {
      return normalizedFallback;
    }
    if (sender.isNotEmpty && sender != '-') {
      return sender;
    }
    return '-';
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(order.status);
    final isReturn = order.orderFlowType.toLowerCase().contains('return');
    final isInternational =
        order.orderType.toLowerCase().contains('international');
    final statusLabel = _humanize(order.status);
    final serviceLabel = _humanize(order.serviceType);
    final flowLabel = _humanize(order.orderFlowType);

    final card = Container(
      decoration: BoxDecoration(
        color: order.isFuturePickup
            ? const Color(0xFFFFF7D6)
            : isReturn
            ? const Color(0xFFEF4444).withValues(alpha: 0.08)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      margin: const EdgeInsets.only(bottom: 14),
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
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  statusLabel.isEmpty ? 'Status' : statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
              if (isReturn) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF9333EA).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.refresh,
                        size: 14,
                        color: Color(0xFF9333EA),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        flowLabel,
                        style: const TextStyle(
                          color: Color(0xFF9333EA),
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (isInternational) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.public,
                        size: 14,
                        color: Color(0xFF0284C7),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'International',
                        style: TextStyle(
                          color: Color(0xFF0284C7),
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              Spacer(),
              if (showMenu)
                GestureDetector(onTap: onMenuTap, child: Icon(Icons.more_vert)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  order.generatedOrderId,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2563EB),
                  ),
                ),
              ),
              if (order.serviceType.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3E8FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    serviceLabel,
                    style: const TextStyle(
                      color: Color(0xFF7C3AED),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              const Icon(
                Icons.place_outlined,
                size: 18,
                color: Color(0xFF6B7280),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _displayAddress(),
                  style: const TextStyle(color: Color(0xFF4B5563)),
                ),
              ),
            ],
          ),
          const Divider(height: 22),
          Row(
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.inventory_2_outlined,
                    size: 18,
                    color: Color(0xFF111827),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${order.packageCount} Pkgs',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Row(
                children: [
                  const Icon(
                    Icons.monitor_weight_outlined,
                    size: 18,
                    color: Color(0xFF111827),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${order.totalWeight} KG',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                'BHD ${order.shippingCharge.isEmpty ? '0.000' : order.shippingCharge}',
                style: const TextStyle(
                  color: Color(0xFFB91C1C),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (onTap == null && onMenuTap == null) return card;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: card,
    );
  }
}

class _OrdersError extends StatelessWidget {
  const _OrdersError({required this.message, required this.onRetry});

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
            const SizedBox(height: 8),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class InvoicesView extends StatelessWidget {
  const InvoicesView({super.key, required this.token});

  final String token;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          InvoicesBloc(context.read<InvoicesRepository>(), token: token)
            ..add(const InvoicesRequested(reset: true)),
      child: const InvoicesPage(),
    );
  }
}

class DashboardStatCard extends StatelessWidget {
  const DashboardStatCard({
    super.key,
    required this.title,
    required this.icon,
    required this.value,
  });

  final String title;
  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE4E7EC)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: const Color(0xFFF3E8FF),
            ),
            child: Icon(icon, color: const Color(0xFF5B21B6), size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: (28 - (value.length <= 8 ? 0 : value.length * 0.6)),
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4F46E5),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4B5563),
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class DashboardActionCard extends StatelessWidget {
  const DashboardActionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 56,
            width: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: const Color(0xFFF3E8FF),
            ),
            child: Icon(icon, color: const Color(0xFF5B21B6)),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(subtitle, style: const TextStyle(color: Color(0xFF6B7280))),
          const SizedBox(height: 12),
          TextButton(
            onPressed: onTap,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF0F52BA),
            ),
            child: const Text('Click to Order ->'),
          ),
        ],
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Image.asset('assets/icons/delybell.png', height: 40, fit: BoxFit.cover),
      ],
    );
  }
}

class _DashboardError extends StatelessWidget {
  const _DashboardError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE4E6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFDC2626)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Color(0xFFB91C1C)),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
