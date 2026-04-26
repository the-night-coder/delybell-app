import 'package:flutter/material.dart';

class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.primary,
    required this.primarySoft,
    required this.border,
    required this.surface,
    required this.mutedText,
    required this.danger,
    required this.success,
  });

  final Color primary;
  final Color primarySoft;
  final Color border;
  final Color surface;
  final Color mutedText;
  final Color danger;
  final Color success;

  @override
  AppColors copyWith({
    Color? primary,
    Color? primarySoft,
    Color? border,
    Color? surface,
    Color? mutedText,
    Color? danger,
    Color? success,
  }) {
    return AppColors(
      primary: primary ?? this.primary,
      primarySoft: primarySoft ?? this.primarySoft,
      border: border ?? this.border,
      surface: surface ?? this.surface,
      mutedText: mutedText ?? this.mutedText,
      danger: danger ?? this.danger,
      success: success ?? this.success,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      primary: Color.lerp(primary, other.primary, t)!,
      primarySoft: Color.lerp(primarySoft, other.primarySoft, t)!,
      border: Color.lerp(border, other.border, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      mutedText: Color.lerp(mutedText, other.mutedText, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      success: Color.lerp(success, other.success, t)!,
    );
  }
}
