import 'package:flutter/material.dart';
import '../../core/design_system.dart';

/// A reusable confirmation dialog with customizable content and actions
class ConfirmationDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final String confirmButtonText;
  final String cancelButtonText;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;
  final Color? confirmButtonColor;
  final IconData? titleIcon;

  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.content,
    required this.confirmButtonText,
    required this.onConfirm,
    this.cancelButtonText = 'Cancel',
    this.onCancel,
    this.confirmButtonColor,
    this.titleIcon,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      title: Row(
        children: [
          if (titleIcon != null) ...[
            Icon(
              titleIcon,
              color: confirmButtonColor ?? AppColors.primary,
              size: 28,
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          Expanded(
            child: Text(
              title,
              style: AppTypography.h6,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: content,
      ),
      actions: [
        TextButton(
          onPressed: () {
            onCancel?.call();
          },
          child: Text(
            cancelButtonText,
            style: AppTypography.labelLarge.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            onConfirm();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: confirmButtonColor ?? AppColors.primary,
            foregroundColor: AppColors.onPrimary,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
          ),
          child: Text(confirmButtonText),
        ),
      ],
    );
  }
}

/// Shows a confirmation dialog and returns a Future that completes when the user makes a choice
Future<bool?> showConfirmationDialog({
  required BuildContext context,
  required String title,
  required Widget content,
  required String confirmButtonText,
  String cancelButtonText = 'Cancel',
  Color? confirmButtonColor,
  IconData? titleIcon,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => ConfirmationDialog(
      title: title,
      content: content,
      confirmButtonText: confirmButtonText,
      cancelButtonText: cancelButtonText,
      confirmButtonColor: confirmButtonColor,
      titleIcon: titleIcon,
      onConfirm: () => Navigator.of(context).pop(true),
      onCancel: () => Navigator.of(context).pop(false),
    ),
  );
}
