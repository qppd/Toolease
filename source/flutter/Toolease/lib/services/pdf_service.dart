import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PdfService {
  static Future<String> generateInventoryReport({
    required List<Map<String, dynamic>> items,
    required String reportTitle,
    String? subtitle,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            _buildHeader(reportTitle, subtitle),
            pw.SizedBox(height: 20),
            _buildInventoryTable(items),
            pw.SizedBox(height: 20),
            _buildFooter(),
          ];
        },
      ),
    );

    return await _savePdfToTemp(pdf, reportTitle);
  }

  static Future<String> generateBorrowReport({
    required List<Map<String, dynamic>> borrowRecords,
    required String reportTitle,
    String? subtitle,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            _buildHeader(reportTitle, subtitle),
            pw.SizedBox(height: 20),
            _buildBorrowTable(borrowRecords),
            pw.SizedBox(height: 20),
            _buildFooter(),
          ];
        },
      ),
    );

    return await _savePdfToTemp(pdf, reportTitle);
  }

  static pw.Widget _buildHeader(String title, String? subtitle) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'ToolEase Inventory System',
          style: pw.TextStyle(
            fontSize: 24,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        if (subtitle != null) ...[
          pw.SizedBox(height: 4),
          pw.Text(
            subtitle,
            style: const pw.TextStyle(fontSize: 14),
          ),
        ],
        pw.SizedBox(height: 4),
        pw.Text(
          'Generated on: ${DateTime.now().toString().substring(0, 19)}',
          style: const pw.TextStyle(fontSize: 12),
        ),
        pw.Divider(thickness: 2),
      ],
    );
  }

  static pw.Widget _buildInventoryTable(List<Map<String, dynamic>> items) {
    return pw.Table(
      border: pw.TableBorder.all(),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(4),
        2: const pw.FlexColumnWidth(2),
        3: const pw.FlexColumnWidth(2),
        4: const pw.FlexColumnWidth(2),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(
            color: PdfColors.grey300,
          ),
          children: [
            _buildTableCell('Item Name', isHeader: true),
            _buildTableCell('Description', isHeader: true),
            _buildTableCell('Storage', isHeader: true),
            _buildTableCell('Total Qty', isHeader: true),
            _buildTableCell('Available', isHeader: true),
          ],
        ),
        ...items.map((item) => pw.TableRow(
              children: [
                _buildTableCell(item['name'] ?? ''),
                _buildTableCell(item['description'] ?? ''),
                _buildTableCell(item['storage'] ?? ''),
                _buildTableCell(item['totalQuantity']?.toString() ?? '0'),
                _buildTableCell(item['availableQuantity']?.toString() ?? '0'),
              ],
            )),
      ],
    );
  }

  static pw.Widget _buildBorrowTable(List<Map<String, dynamic>> records) {
    return pw.Table(
      border: pw.TableBorder.all(),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(3),
        2: const pw.FlexColumnWidth(2),
        3: const pw.FlexColumnWidth(2),
        4: const pw.FlexColumnWidth(2),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(
            color: PdfColors.grey300,
          ),
          children: [
            _buildTableCell('Borrow ID', isHeader: true),
            _buildTableCell('Student', isHeader: true),
            _buildTableCell('Status', isHeader: true),
            _buildTableCell('Borrowed Date', isHeader: true),
            _buildTableCell('Return Date', isHeader: true),
          ],
        ),
        ...records.map((record) => pw.TableRow(
              children: [
                _buildTableCell(record['borrowId'] ?? ''),
                _buildTableCell(record['studentName'] ?? ''),
                _buildTableCell(record['status'] ?? ''),
                _buildTableCell(_formatDate(record['borrowedAt'])),
                _buildTableCell(_formatDate(record['returnedAt'])),
              ],
            )),
      ],
    );
  }

  static pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 12 : 10,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  static pw.Widget _buildFooter() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Divider(),
        pw.SizedBox(height: 8),
        pw.Text(
          'This report was automatically generated by ToolEase Inventory System.',
          style: const pw.TextStyle(fontSize: 10),
        ),
        pw.Text(
          'For questions or issues, please contact the system administrator.',
          style: const pw.TextStyle(fontSize: 10),
        ),
      ],
    );
  }

  static String _formatDate(dynamic date) {
    if (date == null) return '-';
    if (date is DateTime) {
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }
    return date.toString();
  }

  static Future<String> _savePdfToTemp(pw.Document pdf, String fileName) async {
    final output = await pdf.save();
    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${tempDir.path}/${fileName}_$timestamp.pdf');
    await file.writeAsBytes(output);
    return file.path;
  }

  static Future<void> deleteTempPdf(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('Error deleting temp PDF: $e');
    }
  }
}