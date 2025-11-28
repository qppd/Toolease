import 'package:flutter/material.dart';
import '../screens/pdf_preview_screen.dart';
import '../services/pdf_service.dart';

/// Utility class for generating and previewing PDF reports in ToolEase
/// 
/// Usage example:
/// ```dart
/// PdfUtils.generateAndPreviewInventoryReport(
///   context,
///   items: inventoryItems,
///   reportTitle: 'Monthly Inventory Report',
///   subtitle: 'Generated on ${DateTime.now()}',
/// );
/// ```
class PdfUtils {
  static Future<void> generateAndPreviewInventoryReport(
    BuildContext context, {
    required List<Map<String, dynamic>> items,
    required String reportTitle,
    String? subtitle,
  }) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Generating PDF report...'),
            ],
          ),
        ),
      );

      final pdfPath = await PdfService.generateInventoryReport(
        items: items,
        reportTitle: reportTitle,
        subtitle: subtitle,
      );

      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => PdfPreviewScreen(
              pdfPath: pdfPath,
              title: reportTitle,
            ),
          ),
        ).then((_) {
          // Clean up temp file after preview is closed
          PdfService.deleteTempPdf(pdfPath);
        });
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  static Future<void> generateAndPreviewBorrowReport(
    BuildContext context, {
    required List<Map<String, dynamic>> borrowRecords,
    required String reportTitle,
    String? subtitle,
  }) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Generating PDF report...'),
            ],
          ),
        ),
      );

      final pdfPath = await PdfService.generateBorrowReport(
        borrowRecords: borrowRecords,
        reportTitle: reportTitle,
        subtitle: subtitle,
      );

      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => PdfPreviewScreen(
              pdfPath: pdfPath,
              title: reportTitle,
            ),
          ),
        ).then((_) {
          // Clean up temp file after preview is closed
          PdfService.deleteTempPdf(pdfPath);
        });
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}