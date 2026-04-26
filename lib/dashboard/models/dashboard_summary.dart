class DashboardSummary {
  const DashboardSummary({
    required this.liveOrders,
    required this.draftOrders,
    required this.inProgressOrders,
    required this.deliveredOrders,
    required this.cancelledOrders,
    required this.ordersPlacedToday,
    required this.ordersThisMonth,
    required this.codAmount,
    required this.todayPickupOrders,
    required this.todaySameDayDeliveryOrders,
    required this.todayNextDayDeliveryOrders,
  });

  final int liveOrders;
  final int draftOrders;
  final int inProgressOrders;
  final int deliveredOrders;
  final int cancelledOrders;
  final int ordersPlacedToday;
  final int ordersThisMonth;
  final double codAmount;
  final int todayPickupOrders;
  final int todaySameDayDeliveryOrders;
  final int todayNextDayDeliveryOrders;

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    double _doubleValue(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value.toDouble();
      if (value is String) {
        final parsed = double.tryParse(value);
        return parsed ?? 0;
      }
      return 0;
    }

    int _intValue(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value.toInt();
      if (value is String) {
        final parsedInt = int.tryParse(value);
        if (parsedInt != null) return parsedInt;
        final parsedDouble = double.tryParse(value);
        return parsedDouble?.toInt() ?? 0;
      }
      return 0;
    }

    return DashboardSummary(
      liveOrders: _intValue(json['live_orders']),
      draftOrders: _intValue(json['draft_orders']),
      inProgressOrders: _intValue(json['in_progress_orders']),
      deliveredOrders: _intValue(json['delivered_orders']),
      cancelledOrders: _intValue(json['cancelled_orders']),
      ordersPlacedToday: _intValue(json['orders_placed_today']),
      ordersThisMonth: _intValue(json['orders_this_month']),
      codAmount: _doubleValue(json['cod_amount']),
      todayPickupOrders: _intValue(json['today_pickup_orders']),
      todaySameDayDeliveryOrders: _intValue(json['today_same_day_delivery_orders']),
      todayNextDayDeliveryOrders: _intValue(json['today_next_day_delivery_orders']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'live_orders': liveOrders,
      'draft_orders': draftOrders,
      'in_progress_orders': inProgressOrders,
      'delivered_orders': deliveredOrders,
      'cancelled_orders': cancelledOrders,
      'orders_placed_today': ordersPlacedToday,
      'orders_this_month': ordersThisMonth,
      'cod_amount': codAmount,
      'today_pickup_orders': todayPickupOrders,
      'today_same_day_delivery_orders': todaySameDayDeliveryOrders,
      'today_next_day_delivery_orders': todayNextDayDeliveryOrders,
    };
  }

  const DashboardSummary.empty()
      : liveOrders = 0,
        draftOrders = 0,
        inProgressOrders = 0,
        deliveredOrders = 0,
        cancelledOrders = 0,
        ordersPlacedToday = 0,
        ordersThisMonth = 0,
        codAmount = 0,
        todayPickupOrders = 0,
        todaySameDayDeliveryOrders = 0,
        todayNextDayDeliveryOrders = 0;
}
