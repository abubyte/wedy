import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Helper class for creating shimmer loading effects
class ShimmerHelper {
  /// Creates a shimmer container with specified dimensions and border radius
  ///
  /// [width] - Width of the shimmer container. If null, uses available width.
  /// [height] - Height of the shimmer container. Required.
  /// [borderRadius] - Border radius of the shimmer container. Defaults to 8.0.
  /// [baseColor] - Base color for shimmer effect. Defaults to AppColors.surface.
  /// [highlightColor] - Highlight color for shimmer effect. Defaults to lighter surface color.
  static Widget shimmerContainer({
    double? width,
    required double height,
    double borderRadius = 8.0,
    Color? baseColor,
    Color? highlightColor,
  }) {
    return Shimmer.fromColors(
      baseColor: baseColor ?? const Color(0xFFE5E7EB),
      highlightColor: highlightColor ?? const Color(0xFFFFFFFF),
      period: const Duration(milliseconds: 1500),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: baseColor ?? const Color(0xFFE5E7EB),
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }

  /// Creates a shimmer container with circular border radius
  ///
  /// [width] - Width of the shimmer container. If null, uses available width.
  /// [height] - Height of the shimmer container. Required.
  /// [baseColor] - Base color for shimmer effect. Defaults to AppColors.surface.
  /// [highlightColor] - Highlight color for shimmer effect. Defaults to lighter surface color.
  static Widget shimmerCircle({double? width, required double height, Color? baseColor, Color? highlightColor}) {
    return shimmerContainer(
      width: width,
      height: height,
      borderRadius: height / 2, // Make it circular
      baseColor: baseColor,
      highlightColor: highlightColor,
    );
  }

  /// Creates a shimmer container with rounded rectangle border radius
  ///
  /// [width] - Width of the shimmer container. If null, uses available width.
  /// [height] - Height of the shimmer container. Required.
  /// [baseColor] - Base color for shimmer effect. Defaults to AppColors.surface.
  /// [highlightColor] - Highlight color for shimmer effect. Defaults to lighter surface color.
  static Widget shimmerRounded({double? width, required double height, Color? baseColor, Color? highlightColor}) {
    return shimmerContainer(
      width: width,
      height: height,
      borderRadius: 12.0,
      baseColor: baseColor,
      highlightColor: highlightColor,
    );
  }

  /// Creates a shimmer container with square border radius (no rounding)
  ///
  /// [width] - Width of the shimmer container. If null, uses available width.
  /// [height] - Height of the shimmer container. Required.
  /// [baseColor] - Base color for shimmer effect. Defaults to AppColors.surface.
  /// [highlightColor] - Highlight color for shimmer effect. Defaults to lighter surface color.
  static Widget shimmerSquare({double? width, required double height, Color? baseColor, Color? highlightColor}) {
    return shimmerContainer(
      width: width,
      height: height,
      borderRadius: 0.0,
      baseColor: baseColor,
      highlightColor: highlightColor,
    );
  }
}
