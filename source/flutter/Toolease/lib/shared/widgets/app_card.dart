import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

enum AppCardVariant {
  elevated,
  outlined,
  filled,
}

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final AppCardVariant variant;
  final Color? backgroundColor;
  final double? elevation;
  final BorderRadius? borderRadius;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.variant = AppCardVariant.elevated,
    this.backgroundColor,
    this.elevation,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBorderRadius = borderRadius ?? BorderRadius.circular(AppSpacing.radiusMd);
    
    return Material(
      color: _getBackgroundColor(),
      elevation: _getElevation(),
      shadowColor: AppColors.shadow,
      borderRadius: effectiveBorderRadius,
      child: InkWell(
        onTap: onTap,
        borderRadius: effectiveBorderRadius,
        child: Container(
          decoration: _getDecoration(effectiveBorderRadius),
          padding: padding ?? const EdgeInsets.all(AppSpacing.cardPadding),
          child: child,
        ),
      ),
    );
  }

  Color _getBackgroundColor() {
    if (backgroundColor != null) return backgroundColor!;
    
    switch (variant) {
      case AppCardVariant.elevated:
        return AppColors.surface;
      case AppCardVariant.outlined:
        return AppColors.surface;
      case AppCardVariant.filled:
        return AppColors.surfaceVariant;
    }
  }

  double _getElevation() {
    if (elevation != null) return elevation!;
    
    switch (variant) {
      case AppCardVariant.elevated:
        return AppSpacing.elevationMd;
      case AppCardVariant.outlined:
        return AppSpacing.elevationNone;
      case AppCardVariant.filled:
        return AppSpacing.elevationNone;
    }
  }

  Decoration? _getDecoration(BorderRadius borderRadius) {
    if (variant == AppCardVariant.outlined) {
      return BoxDecoration(
        borderRadius: borderRadius,
        border: Border.all(
          color: AppColors.outline,
          width: AppSpacing.borderWidth,
        ),
      );
    }
    return null;
  }
}