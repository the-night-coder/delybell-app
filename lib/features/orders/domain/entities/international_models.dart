import 'package:equatable/equatable.dart';

class CountryInfo extends Equatable {
  const CountryInfo({
    required this.id,
    required this.name,
    required this.shortCode,
  });

  final int id;
  final String name;
  final String shortCode;

  factory CountryInfo.fromJson(Map<String, dynamic> json) {
    return CountryInfo(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      name: json['name']?.toString() ?? '',
      shortCode: json['shortCode']?.toString() ?? '',
    );
  }

  @override
  List<Object?> get props => [id, name, shortCode];
}

class CityInfo extends Equatable {
  const CityInfo({
    required this.id,
    required this.countryId,
    required this.countryCode,
    required this.stateName,
    required this.name,
    required this.latitude,
    required this.longitude,
  });

  final int id;
  final int countryId;
  final String countryCode;
  final String stateName;
  final String name;
  final String latitude;
  final String longitude;

  factory CityInfo.fromJson(Map<String, dynamic> json) {
    return CityInfo(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      countryId: json['countryId'] is int
          ? json['countryId'] as int
          : int.tryParse('${json['countryId']}') ?? 0,
      countryCode: json['countryCode']?.toString() ?? '',
      stateName: json['stateName']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      latitude: json['latitude']?.toString() ?? '',
      longitude: json['longitude']?.toString() ?? '',
    );
  }

  @override
  List<Object?> get props => [id, countryId, countryCode, stateName, name, latitude, longitude];
}

class InternationalRateOption extends Equatable {
  const InternationalRateOption({
    required this.carrier,
    required this.serviceName,
    required this.serviceCode,
    required this.amount,
    required this.currency,
    required this.deliveryDays,
    required this.deliveryDate,
  });

  final String carrier;
  final String serviceName;
  final String serviceCode;
  final double amount;
  final String currency;
  final int deliveryDays;
  final String deliveryDate;

  factory InternationalRateOption.fromJson(Map<String, dynamic> json) {
    final amountRaw = json['amount'];
    final daysRaw = json['delivery_days'];
    return InternationalRateOption(
      carrier: json['carrier']?.toString() ?? '',
      serviceName: json['service_name']?.toString() ?? '',
      serviceCode: json['service_code']?.toString() ?? '',
      amount: amountRaw is num ? amountRaw.toDouble() : double.tryParse('$amountRaw') ?? 0,
      currency: json['currency']?.toString() ?? '',
      deliveryDays: daysRaw is int ? daysRaw : int.tryParse('$daysRaw') ?? 0,
      deliveryDate: json['delivery_date']?.toString() ?? '',
    );
  }

  @override
  List<Object?> get props => [
        carrier,
        serviceName,
        serviceCode,
        amount,
        currency,
        deliveryDays,
        deliveryDate,
      ];
}
