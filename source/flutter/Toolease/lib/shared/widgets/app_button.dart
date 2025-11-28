import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

enum AppButtonVariant {
  primary,
  secondary,
  outline,
  ghost,
  danger,
}

enum AppButtonSize {
  small,
  medium,
  large,
}

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final IconData? icon;
  final bool isLoading;
  final bool fullWidth;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.medium,
    this.icon,
    this.isLoading = false,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null || isLoading;
    
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: _getHeight(),
      child: ElevatedButton(
        onPressed: isDisabled ? null : onPressed,
        style: _getButtonStyle(isDisabled),
        child: isLoading
            ? SizedBox(
                width: _getIconSize(),
                height: _getIconSize(),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: _getContentColor(isDisabled),
                ),
              )
            : _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: _getIconSize()),
          const SizedBox(width: AppSpacing.sm),
          Text(text),
        ],
      );
    }
    return Text(text);
  }

  ButtonStyle _getButtonStyle(bool isDisabled) {
    return ElevatedButton.styleFrom(
      backgroundColor: _getBackgroundColor(isDisabled),
      foregroundColor: _getContentColor(isDisabled),
      elevation: _getElevation(),
      shadowColor: AppColors.shadow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        side: _getBorder(isDisabled),
      ),
      padding: _getPadding(),
      textStyle: _getTextStyle(),
    ).copyWith(
      overlayColor: WidgetStateProperty.resolveWith<Color?>(
        (Set<WidgetState> states) {
          if (states.contains(WidgetState.hovered)) {
            return _getHoverColor();
          }
          if (states.contains(WidgetState.pressed)) {
            return _getPressedColor();
          }
          return null;
        },
      ),
    );
  }

  Color _getBackgroundColor(bool isDisabled) {
    if (isDisabled) {
      return variant == AppButtonVariant.outline || variant == AppButtonVariant.ghost
          ? Colors.transparent
          : AppColors.textDisabled;
    }

    switch (variant) {
      case AppButtonVariant.primary:
        return AppColors.primary;
      case AppButtonVariant.secondary:
        return AppColors.secondary;
      case AppButtonVariant.outline:
      case AppButtonVariant.ghost:
        return Colors.transparent;
      case AppButtonVariant.danger:
        return AppColors.error;
    }
  }

  Color _getContentColor(bool isDisabled) {
    if (isDisabled) {
      return variant == AppButtonVariant.outline || variant == AppButtonVariant.ghost
          ? AppColors.textDisabled
          : AppColors.onSurface.withValues(alpha: 0.38);
    }

    switch (variant) {
      case AppButtonVariant.primary:
        return AppColors.onPrimary;
      case AppButtonVariant.secondary:
        return AppColors.onSecondary;
      case AppButtonVariant.outline:
        return AppColors.primary;
      case AppButtonVariant.ghost:
        return AppColors.textPrimary;
      case AppButtonVariant.danger:
        return AppColors.onError;
    }
  }

  BorderSide _getBorder(bool isDisabled) {
    if (variant == AppButtonVariant.outline) {
      return BorderSide(
        color: isDisabled ? AppColors.textDisabled : AppColors.primary,
        width: AppSpacing.borderWidth,
      );
    }
    return BorderSide.none;
  }

  Color _getHoverColor() {
    switch (variant) {
      case AppButtonVariant.primary:
        return AppColors.onPrimary.withValues(alpha: 0.08);
      case AppButtonVariant.secondary:
        return AppColors.onSecondary.withValues(alpha: 0.08);
      case AppButtonVariant.outline:
        return AppColors.primary.withValues(alpha: 0.08);
      case AppButtonVariant.ghost:
        return AppColors.textPrimary.withValues(alpha: 0.08);
      case AppButtonVariant.danger:
        return AppColors.onError.withValues(alpha: 0.08);
    }
  }

  Color _getPressedColor() {
    switch (variant) {
      case AppButtonVariant.primary:
        return AppColors.onPrimary.withValues(alpha: 0.12);
      case AppButtonVariant.secondary:
        return AppColors.onSecondary.withValues(alpha: 0.12);
      case AppButtonVariant.outline:
        return AppColors.primary.withValues(alpha: 0.12);
      case AppButtonVariant.ghost:
        return AppColors.textPrimary.withValues(alpha: 0.12);
      case AppButtonVariant.danger:
        return AppColors.onError.withValues(alpha: 0.12);
    }
  }

  double _getElevation() {
    if (variant == AppButtonVariant.outline || variant == AppButtonVariant.ghost) {
      return AppSpacing.elevationNone;
    }
    return AppSpacing.elevationSm;
  }

  double _getHeight() {
    switch (size) {
      case AppButtonSize.small:
        return 40.0;
      case AppButtonSize.medium:
        return AppSpacing.buttonHeight;
      case AppButtonSize.large:
        return 56.0;
    }
  }

  double _getIconSize() {
    switch (size) {
      case AppButtonSize.small:
        return AppSpacing.iconSizeSm;
      case AppButtonSize.medium:
        return AppSpacing.iconSizeMd;
      case AppButtonSize.large:
        return AppSpacing.iconSizeLg;
    }
  }

  EdgeInsetsGeometry _getPadding() {
    switch (size) {
      case AppButtonSize.small:
        return const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        );
      case AppButtonSize.medium:
        return const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        );
      case AppButtonSize.large:
        return const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.md,
        );
    }
  }

  TextStyle _getTextStyle() {
    switch (size) {
      case AppButtonSize.small:
        return AppTypography.labelMedium;
      case AppButtonSize.medium:
        return AppTypography.button;
      case AppButtonSize.large:
        return AppTypography.buttonLarge;
    }
  }
}