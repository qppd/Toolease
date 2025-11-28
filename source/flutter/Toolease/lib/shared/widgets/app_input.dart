import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

enum AppInputVariant {
  outlined,
  filled,
}

class AppInput extends StatefulWidget {
  final String? label;
  final String? hint;
  final String? helperText;
  final String? errorText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final bool obscureText;
  final bool enabled;
  final bool readOnly;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixIconPressed;
  final AppInputVariant variant;
  final int? maxLines;
  final int? minLines;
  final String? Function(String?)? validator;

  const AppInput({
    super.key,
    this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.controller,
    this.onChanged,
    this.onTap,
    this.keyboardType,
    this.inputFormatters,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixIconPressed,
    this.variant = AppInputVariant.outlined,
    this.maxLines = 1,
    this.minLines,
    this.validator,
  });

  @override
  State<AppInput> createState() => _AppInputState();
}

class _AppInputState extends State<AppInput> {
  late final FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: AppTypography.labelLarge.copyWith(
              color: hasError ? AppColors.error : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
        TextFormField(
          controller: widget.controller,
          focusNode: _focusNode,
          onChanged: widget.onChanged,
          onTap: widget.onTap,
          keyboardType: widget.keyboardType,
          inputFormatters: widget.inputFormatters,
          obscureText: widget.obscureText,
          enabled: widget.enabled,
          readOnly: widget.readOnly,
          maxLines: widget.maxLines,
          minLines: widget.minLines,
          validator: widget.validator,
          style: AppTypography.bodyMedium.copyWith(
            color: widget.enabled ? AppColors.textPrimary : AppColors.textDisabled,
          ),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: AppTypography.bodyMedium.copyWith(
              color: AppColors.textTertiary,
            ),
            prefixIcon: widget.prefixIcon != null
                ? Icon(
                    widget.prefixIcon,
                    color: _getIconColor(hasError),
                    size: AppSpacing.iconSizeMd,
                  )
                : null,
            suffixIcon: widget.suffixIcon != null
                ? IconButton(
                    onPressed: widget.onSuffixIconPressed,
                    icon: Icon(
                      widget.suffixIcon,
                      color: _getIconColor(hasError),
                      size: AppSpacing.iconSizeMd,
                    ),
                  )
                : null,
            border: _getBorder(hasError, false),
            enabledBorder: _getBorder(hasError, false),
            focusedBorder: _getBorder(hasError, true),
            errorBorder: _getBorder(true, false),
            focusedErrorBorder: _getBorder(true, true),
            disabledBorder: _getDisabledBorder(),
            filled: widget.variant == AppInputVariant.filled,
            fillColor: widget.variant == AppInputVariant.filled
                ? AppColors.surfaceVariant
                : null,
            contentPadding: _getContentPadding(),
            errorText: widget.errorText,
            errorStyle: AppTypography.caption.copyWith(
              color: AppColors.error,
            ),
          ),
        ),
        if (widget.helperText != null && widget.errorText == null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            widget.helperText!,
            style: AppTypography.caption.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ],
    );
  }

  Color _getIconColor(bool hasError) {
    if (!widget.enabled) return AppColors.textDisabled;
    if (hasError) return AppColors.error;
    if (_isFocused) return AppColors.primary;
    return AppColors.textSecondary;
  }

  InputBorder _getBorder(bool hasError, bool isFocused) {
    final color = hasError
        ? AppColors.error
        : isFocused
            ? AppColors.primary
            : AppColors.outline;
            
    final width = isFocused ? AppSpacing.borderWidthThick : AppSpacing.borderWidth;

    if (widget.variant == AppInputVariant.outlined) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        borderSide: BorderSide(color: color, width: width),
      );
    } else {
      return UnderlineInputBorder(
        borderSide: BorderSide(color: color, width: width),
      );
    }
  }

  InputBorder _getDisabledBorder() {
    if (widget.variant == AppInputVariant.outlined) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        borderSide: const BorderSide(
          color: AppColors.textDisabled,
          width: AppSpacing.borderWidth,
        ),
      );
    } else {
      return const UnderlineInputBorder(
        borderSide: BorderSide(
          color: AppColors.textDisabled,
          width: AppSpacing.borderWidth,
        ),
      );
    }
  }

  EdgeInsetsGeometry _getContentPadding() {
    if (widget.variant == AppInputVariant.outlined) {
      return const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      );
    } else {
      return const EdgeInsets.symmetric(
        horizontal: 0,
        vertical: AppSpacing.md,
      );
    }
  }
}