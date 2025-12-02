import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:typed_data';
import '../providers/database_provider.dart';
import '../models/student.dart' as models;
import '../models/item.dart' as models;
import '../models/storage.dart' as models;
import '../models/borrow_record.dart' as models;
import '../core/design_system.dart';
import '../shared/widgets/app_card.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> with WidgetsBindingObserver {
  bool _isGenerating = false;
  Map<String, dynamic> _reportData = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadReportData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh data when returning to the app/screen
      _loadReportData();
    }
  }

  Future<void> _loadReportData() async {
    try {
      final databaseService = ref.read(databaseServiceProvider);

      final students = await databaseService.getAllStudents();
      final storages = await databaseService.getAllStorages();
      final items = await databaseService.getAllItems();

      // Get all records for comprehensive reporting
      final allBorrowRecords = await databaseService.getAllBorrowRecords();
      final returnedRecords = await databaseService.getReturnedBorrowRecords();
      final archivedRecords = await databaseService.getArchivedBorrowRecords();
      final damagedItemRecords = await databaseService.getDamagedItemRecords();
      final lostItemRecords = await databaseService.getLostItemRecords();

      // Calculate statistics
      final activeBorrowRecords = allBorrowRecords.where((record) => record.status.name == 'active').toList();
      int activeBorrows = activeBorrowRecords.length;
      int totalItemsBorrowed = 0;
      List<Map<String, dynamic>> borrowHistory = [];
      List<Map<String, dynamic>> returnHistory = [];

      // Process all borrow records
      for (final record in allBorrowRecords) {
        final student = students.firstWhere((s) => s.id == record.studentId, orElse: () => students.first);
        totalItemsBorrowed += record.items.fold(0, (sum, item) => sum + item.quantity);
        
        borrowHistory.add({
          'studentName': student.name,
          'studentId': student.studentId,
          'borrowId': record.borrowId,
          'borrowDate': record.borrowedAt,
          'returnDate': record.returnedAt,
          'itemCount': record.items.fold(0, (sum, item) => sum + item.quantity),
          'status': record.status.name,
        });
      }

      // Process return records
      for (final record in returnedRecords) {
        final student = students.firstWhere((s) => s.id == record.studentId, orElse: () => students.first);
        
        returnHistory.add({
          'studentName': student.name,
          'studentId': student.studentId,
          'borrowId': record.borrowId,
          'borrowDate': record.borrowedAt,
          'returnDate': record.returnedAt,
          'itemCount': record.items.fold(0, (sum, item) => sum + item.quantity),
          'status': record.status.name,
        });
      }

      // Calculate inventory statistics for per-unit tracking
      final totalItems = items.length;
      final availableItems = items.where((item) => item.status == models.ItemStatus.available).length;
      final borrowedItems = items.where((item) => item.status == models.ItemStatus.borrowed).length;
      final damagedItems = items.where((item) => item.status == models.ItemStatus.damaged).length;
      final lostItems = items.where((item) => item.status == models.ItemStatus.lost).length;

      // Items that might need attention (damaged or lost)
      final itemsNeedingAttention = items
          .where((item) => item.status == models.ItemStatus.damaged || item.status == models.ItemStatus.lost)
          .toList();

      setState(() {
        _reportData = {
          'students': students,
          'storages': storages,
          'items': items,
          'activeBorrows': activeBorrows,
          'totalItemsBorrowed': totalItemsBorrowed,
          'borrowHistory': borrowHistory,
          'returnHistory': returnHistory,
          'allBorrowRecords': allBorrowRecords,
          'returnedRecords': returnedRecords,
          'archivedRecords': archivedRecords,
          'damagedItemRecords': damagedItemRecords,
          'lostItemRecords': lostItemRecords,
          'totalItems': totalItems,
          'availableItems': availableItems,
          'borrowedItems': borrowedItems,
          'damagedItems': damagedItems,
          'lostItems': lostItems,
          'itemsNeedingAttention': itemsNeedingAttention,
          'generatedAt': DateTime.now(),
        };
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading report data: $e')),
        );
      }
    }
  }

  Future<void> _generatePDFReport(String reportType) async {
    setState(() {
      _isGenerating = true;
    });

    try {
      final pdf = pw.Document();

      switch (reportType) {
        case 'inventory':
          await _generateInventoryReport(pdf);
          break;
        case 'students':
          await _generateStudentsReport(pdf);
          break;
        case 'borrows':
          await _generateBorrowsReport(pdf);
          break;
        case 'summary':
          await _generateSummaryReport(pdf);
          break;
        case 'archive':
          await _generateArchiveReport(pdf);
          break;
      }

      final pdfBytes = await pdf.save();

      if (mounted) {
        _showPreviewDialog(reportType, pdfBytes);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error generating report: $e')));
      }
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  void _showPreviewDialog(String reportType, Uint8List pdfBytes) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _PDFPreviewDialog(
        reportType: reportType,
        pdfBytes: pdfBytes,
        onSave: () => _savePDF(reportType, pdfBytes),
      ),
    );
  }

  Future<void> _savePDF(String reportType, Uint8List pdfBytes) async {
    try {
      final fileName =
          'ToolEase_${reportType}_Report_${DateTime.now().millisecondsSinceEpoch}.pdf';

      // For Android, we'll save to Downloads directory
      final directory = Directory('/storage/emulated/0/Download');
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(pdfBytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Report saved to Downloads: $fileName'),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(label: 'OK', onPressed: () {}),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving report: $e')));
      }
    }
  }

  Future<void> _generateInventoryReport(pw.Document pdf) async {
    final items = _reportData['items'] as List<models.Item>;
    final storages = _reportData['storages'] as List<models.Storage>;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              'ToolEase - Inventory Report',
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Paragraph(
            text: 'Generated on: ${DateTime.now().toString().split('.')[0]}',
          ),
          pw.SizedBox(height: 20),

          pw.Text(
            'Summary',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text('Total Items: ${items.length}'),
          pw.Text('Total Storages: ${storages.length}'),
          pw.Text('Total Items: ${_reportData['totalItems']}'),
          pw.Text('Available Items: ${_reportData['availableItems']}'),
          pw.Text('Borrowed Items: ${_reportData['borrowedItems']}'),
          pw.Text('Damaged Items: ${_reportData['damagedItems']}'),
          pw.Text('Lost Items: ${_reportData['lostItems']}'),
          pw.SizedBox(height: 20),

          pw.Text(
            'Items by Storage',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          ...storages.map((storage) {
            final storageItems = items
                .where((item) => item.storageId == storage.id)
                .toList();
            return pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 10),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    '${storage.name} (${storageItems.length} items)',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  ...storageItems.map(
                    (item) => pw.Padding(
                      padding: const pw.EdgeInsets.only(left: 20),
                      child: pw.Text(
                        '• ${item.toolName} (${item.serialNo}): ${item.status.displayName}',
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),

          if ((_reportData['lowStockItems'] as List).isNotEmpty) ...[
            pw.SizedBox(height: 20),
            pw.Text(
              'Items Needing Attention',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            ...(_reportData['itemsNeedingAttention'] as List<models.Item>).map(
              (item) => pw.Text(
                '• ${item.toolName} (${item.serialNo}): ${item.status.displayName}',
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _generateStudentsReport(pw.Document pdf) async {
    final students = _reportData['students'] as List<models.Student>;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              'ToolEase - Students Report',
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Paragraph(
            text: 'Generated on: ${DateTime.now().toString().split('.')[0]}',
          ),
          pw.SizedBox(height: 20),

          pw.Text(
            'Total Students: ${students.length}',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 20),

          pw.TableHelper.fromTextArray(
            headers: [
              'Student ID',
              'Name',
              'Year Level',
              'Section',
              'Registered',
            ],
            data: students
                .map(
                  (student) => [
                    student.studentId,
                    student.name,
                    student.yearLevel,
                    student.section,
                    student.createdAt.toString().split(' ')[0],
                  ],
                )
                .toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellAlignment: pw.Alignment.centerLeft,
          ),
        ],
      ),
    );
  }

  Future<void> _generateBorrowsReport(pw.Document pdf) async {
    final borrowHistory = _reportData['borrowHistory'] as List<Map<String, dynamic>>;
    final returnHistory = _reportData['returnHistory'] as List<Map<String, dynamic>>;
    final damagedItems = _reportData['damagedItemRecords'] as List;
    final lostItems = _reportData['lostItemRecords'] as List;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              'ToolEase - Complete Records Report',
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Paragraph(
            text: 'Generated on: ${DateTime.now().toString().split('.')[0]}',
          ),
          pw.SizedBox(height: 20),

          pw.Text(
            'Summary Statistics',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text('Active Borrows: ${_reportData['activeBorrows']}'),
          pw.Text('Returned Records: ${returnHistory.length}'),
          pw.Text('Damaged Items: ${damagedItems.length}'),
          pw.Text('Lost Items: ${lostItems.length}'),
          pw.Text('Total Records: ${borrowHistory.length}'),
          pw.SizedBox(height: 20),

          // All Borrow Records
          pw.Text(
            'All Borrow Records',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          if (borrowHistory.isNotEmpty)
            pw.TableHelper.fromTextArray(
              headers: [
                'Borrow ID',
                'Student',
                'Borrow Date',
                'Return Date',
                'Items',
                'Status',
              ],
              data: borrowHistory
                  .map(
                    (record) => [
                      record['borrowId'],
                      record['studentName'],
                      (record['borrowDate'] as DateTime).toString().split(' ')[0],
                      record['returnDate'] != null 
                        ? (record['returnDate'] as DateTime).toString().split(' ')[0]
                        : 'Not returned',
                      record['itemCount'].toString(),
                      record['status'].toUpperCase(),
                    ],
                  )
                  .toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellAlignment: pw.Alignment.centerLeft,
            )
          else
            pw.Text('No borrow records found.'),

          pw.SizedBox(height: 20),

          // Return Records
          if (returnHistory.isNotEmpty) ...[
            pw.Text(
              'Return Records',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.TableHelper.fromTextArray(
              headers: [
                'Borrow ID',
                'Student',
                'Returned Date',
                'Items Returned',
              ],
              data: returnHistory
                  .map(
                    (record) => [
                      record['borrowId'],
                      record['studentName'],
                      record['returnDate'] != null 
                        ? (record['returnDate'] as DateTime).toString().split(' ')[0]
                        : 'Unknown',
                      record['itemCount'].toString(),
                    ],
                  )
                  .toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellAlignment: pw.Alignment.centerLeft,
            ),
            pw.SizedBox(height: 20),
          ],

          // Damaged and Lost Items Summary
          if (damagedItems.isNotEmpty || lostItems.isNotEmpty) ...[
            pw.Text(
              'Items Issues Summary',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            if (damagedItems.isNotEmpty)
              pw.Text('Damaged items: ${damagedItems.length} units'),
            if (lostItems.isNotEmpty)
              pw.Text('Lost items: ${lostItems.length} units'),
          ],
        ],
      ),
    );
  }

  Future<void> _generateSummaryReport(pw.Document pdf) async {
    if (_reportData.isEmpty) {
      throw Exception('Report data not loaded. Please refresh and try again.');
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              'ToolEase - Summary Report',
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Paragraph(
            text: 'Generated on: ${DateTime.now().toString().split('.')[0]}',
          ),
          pw.SizedBox(height: 20),

          pw.Text(
            'Overview',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text('Students: ${(_reportData['students'] as List).length}'),
          pw.Text('Storages: ${(_reportData['storages'] as List).length}'),
          pw.Text('Items: ${(_reportData['items'] as List).length}'),
          pw.Text('Active Borrows: ${_reportData['activeBorrows'] ?? 0}'),
          pw.SizedBox(height: 20),

          pw.Text(
            'Inventory Status',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text('Total Items: ${_reportData['totalItems'] ?? 0}'),
          pw.Text('Available: ${_reportData['availableItems'] ?? 0}'),
          pw.Text('Currently Borrowed: ${_reportData['borrowedItems'] ?? 0}'),
          pw.Text('Damaged: ${_reportData['damagedItems'] ?? 0}'),
          pw.Text('Lost: ${_reportData['lostItems'] ?? 0}'),
          pw.Text(
            'Utilization Rate: ${(_reportData['totalItems'] ?? 0) > 0 ? ((_reportData['borrowedItems'] ?? 0) / (_reportData['totalItems'] ?? 1) * 100).round() : 0}%',
          ),
          pw.SizedBox(height: 20),

          if ((_reportData['lowStockItems'] as List?)?.isNotEmpty == true) ...[
            pw.Text(
              'Alerts',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(
              'Items Needing Attention: ${(_reportData['itemsNeedingAttention'] as List).length}',
              style: pw.TextStyle(color: PdfColors.red),
            ),
            ...(_reportData['itemsNeedingAttention'] as List<models.Item>)
                .take(5)
                .map(
                  (item) => pw.Text(
                    '• ${item.toolName} (${item.serialNo}): ${item.status.displayName}',
                  ),
                ),
            if ((_reportData['itemsNeedingAttention'] as List).length > 5)
              pw.Text(
                '... and ${(_reportData['itemsNeedingAttention'] as List).length - 5} more items',
              ),
          ],
        ],
      ),
    );
  }

  Future<void> _generateArchiveReport(pw.Document pdf) async {
    final archivedRecords = _reportData['archivedRecords'] as List;
    final allBorrowRecords = _reportData['allBorrowRecords'] as List;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              'ToolEase - Archive Management Report',
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Paragraph(
            text: 'Generated on: ${DateTime.now().toString().split('.')[0]}',
          ),
          pw.SizedBox(height: 20),

          pw.Text(
            'Archive Statistics',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text('Total Records: ${allBorrowRecords.length}'),
          pw.Text('Archived Records: ${archivedRecords.length}'),
          pw.Text('Active/Returned Records: ${allBorrowRecords.length - archivedRecords.length}'),
          pw.Text('Archive Percentage: ${allBorrowRecords.isNotEmpty ? ((archivedRecords.length / allBorrowRecords.length) * 100).round() : 0}%'),
          pw.SizedBox(height: 20),

          if (archivedRecords.isNotEmpty) ...[
            pw.Text(
              'Archived Records',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.TableHelper.fromTextArray(
              headers: [
                'Borrow ID',
                'Student ID',
                'Borrow Date',
                'Return Date',
                'Status',
              ],
              data: archivedRecords
                  .cast<models.BorrowRecord>()
                  .map(
                    (record) => [
                      record.borrowId,
                      'Student ${record.studentId}',
                      record.borrowedAt.toString().split(' ')[0],
                      record.returnedAt != null 
                        ? record.returnedAt!.toString().split(' ')[0]
                        : 'Not returned',
                      record.status.name.toUpperCase(),
                    ],
                  )
                  .toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellAlignment: pw.Alignment.centerLeft,
            ),
          ] else ...[
            pw.Text('No archived records found.'),
            pw.SizedBox(height: 20),
            pw.Text('This means all records are currently active or returned.'),
          ],
          
          pw.SizedBox(height: 20),
          pw.Text(
            'Archive Management Tips',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text('• Archive old returned records to keep the system organized'),
          pw.Text('• Archived records can be restored if needed'),
          pw.Text('• Regular archiving helps improve system performance'),
          pw.Text('• Consider archiving records older than 6 months'),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Reports & Analytics',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: _loadReportData,
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: _reportData.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Section
                  _buildHeaderSection(),

                  const SizedBox(height: AppSpacing.xl),

                  // Quick Stats Dashboard
                  _buildQuickStats(),

                  const SizedBox(height: AppSpacing.xl),

                  // Report Generation Section
                  _buildReportGeneration(),

                  const SizedBox(height: AppSpacing.xl),

                  // System Information
                  _buildSystemInformation(),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showArchiveManagementDialog,
        icon: const Icon(Icons.archive_outlined),
        label: const Text('Archive'),
        backgroundColor: AppColors.warning,
        foregroundColor: AppColors.onPrimary,
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.onPrimary.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.analytics_outlined,
              color: AppColors.onPrimary,
              size: 32,
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'System Reports & Analytics',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Generate comprehensive reports and view system analytics',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.onPrimary.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.dashboard_outlined, color: AppColors.primary),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Quick Statistics',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.6,
          crossAxisSpacing: AppSpacing.md,
          mainAxisSpacing: AppSpacing.md,
          children: [
            _buildStatCard(
              'Students',
              (_reportData['students'] as List).length,
              Icons.people_outline,
              AppColors.info,
              'Total registered',
            ),
            _buildStatCard(
              'Items',
              (_reportData['items'] as List).length,
              Icons.inventory_2_outlined,
              AppColors.accent,
              'In inventory',
            ),
            _buildStatCard(
              'Active Borrows',
              _reportData['activeBorrows'] ?? 0,
              Icons.assignment_outlined,
              AppColors.secondary,
              'Currently active',
            ),
            _buildStatCard(
              'Returned Items',
              (_reportData['returnedRecords'] as List).length,
              Icons.assignment_return_outlined,
              AppColors.success,
              'Successfully returned',
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.6,
          crossAxisSpacing: AppSpacing.md,
          mainAxisSpacing: AppSpacing.md,
          children: [
            _buildStatCard(
              'Damaged Items',
              (_reportData['damagedItemRecords'] as List).length,
              Icons.warning_outlined,
              AppColors.warning,
              'Need replacement',
            ),
            _buildStatCard(
              'Lost Items',
              (_reportData['lostItemRecords'] as List).length,
              Icons.error_outline,
              AppColors.error,
              'Missing items',
            ),
            _buildStatCard(
              'Low Stock',
              (_reportData['lowStockItems'] as List).length,
              Icons.inventory_outlined,
              AppColors.error,
              'Need restocking',
            ),
            _buildStatCard(
              'Archived Records',
              (_reportData['archivedRecords'] as List).length,
              Icons.archive_outlined,
              AppColors.info,
              'Archived transactions',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    int value,
    IconData icon,
    Color color,
    String description,
  ) {
    return AppCard(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 28, color: color),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value.toString(),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            description,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildReportGeneration() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.description_outlined, color: AppColors.primary),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Generate Reports',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),

        if (_isGenerating) ...[
          AppCard(
            variant: AppCardVariant.outlined,
            child: Column(
              children: [
                const CircularProgressIndicator(color: AppColors.primary),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Generating Report...',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Please wait while we compile your data',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.0,
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
            children: [
              _buildReportCard(
                'Summary Report',
                'Complete system overview',
                Icons.summarize_outlined,
                AppColors.primary,
                () => _generatePDFReport('summary'),
              ),
              _buildReportCard(
                'Inventory Report',
                'Stock levels and items',
                Icons.inventory_2_outlined,
                AppColors.accent,
                () => _generatePDFReport('inventory'),
              ),
              _buildReportCard(
                'Students Report',
                'All registered users',
                Icons.people_outline,
                AppColors.info,
                () => _generatePDFReport('students'),
              ),
              _buildReportCard(
                'Borrow Records',
                'All transactions',
                Icons.assignment_outlined,
                AppColors.secondary,
                () => _generatePDFReport('borrows'),
              ),
              _buildReportCard(
                'Archive Management',
                'Archived records',
                Icons.archive_outlined,
                AppColors.warning,
                () => _generatePDFReport('archive'),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildReportCard(
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return AppCard(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 32, color: color),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            description,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSystemInformation() {
    return AppCard(
      variant: AppCardVariant.outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'System Information',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          _buildInfoRow(
            Icons.picture_as_pdf_outlined,
            'Reports are generated in PDF format',
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildInfoRow(
            Icons.preview_outlined,
            'Preview reports before saving',
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildInfoRow(
            Icons.download_outlined,
            'Saved to device Downloads folder',
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildInfoRow(Icons.refresh_outlined, 'Data refreshed automatically'),

          if (_reportData['generatedAt'] != null) ...[
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.schedule_outlined,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Last updated: ${(_reportData['generatedAt'] as DateTime).toString().split('.')[0]}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showArchiveManagementDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.archive_outlined, color: AppColors.warning),
            const SizedBox(width: AppSpacing.sm),
            const Text('Archive Management'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Archive old records to keep your system organized and improve performance.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            
            Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: AppColors.info),
                const SizedBox(width: AppSpacing.xs),
                const Text('Current Statistics:'),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            
            Text('• Total Records: ${(_reportData['allBorrowRecords'] as List).length}'),
            Text('• Archived Records: ${(_reportData['archivedRecords'] as List).length}'),
            Text('• Active/Returned Records: ${(_reportData['allBorrowRecords'] as List).length - (_reportData['archivedRecords'] as List).length}'),
            
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Archive Management Tips:',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '• Archive old returned records (6+ months)\n'
                    '• Use "Archive Report" for detailed view\n'
                    '• Archived records can be restored if needed\n'
                    '• Regular archiving improves performance',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              _generatePDFReport('archive');
            },
            icon: const Icon(Icons.description_outlined),
            label: const Text('View Archive Report'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              foregroundColor: AppColors.onPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            text,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }
}

class _PDFPreviewDialog extends StatefulWidget {
  final String reportType;
  final Uint8List pdfBytes;
  final VoidCallback onSave;

  const _PDFPreviewDialog({
    required this.reportType,
    required this.pdfBytes,
    required this.onSave,
  });

  @override
  State<_PDFPreviewDialog> createState() => _PDFPreviewDialogState();
}

class _PDFPreviewDialogState extends State<_PDFPreviewDialog> {
  String? _tempFilePath;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _createTempFile();
  }

  Future<void> _createTempFile() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final tempFile = File(
        '${tempDir.path}/temp_preview_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
      await tempFile.writeAsBytes(widget.pdfBytes);

      setState(() {
        _tempFilePath = tempFile.path;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error creating preview: $e';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    if (_tempFilePath != null) {
      final file = File(_tempFilePath!);
      if (file.existsSync()) {
        file.deleteSync();
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(
          title: Text('${widget.reportType.toUpperCase()} Report Preview'),
          backgroundColor: Colors.purple,
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: () {
                widget.onSave();
                Navigator.of(context).pop();
              },
              tooltip: 'Save PDF',
            ),
          ],
        ),
        body: _isLoading
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading PDF preview...'),
                  ],
                ),
              )
            : _errorMessage != null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              )
            : PDFView(
                filePath: _tempFilePath!,
                enableSwipe: true,
                swipeHorizontal: false,
                autoSpacing: false,
                pageFling: true,
                backgroundColor: Colors.grey.shade100,
                onError: (error) {
                  setState(() {
                    _errorMessage = 'Error displaying PDF: $error';
                  });
                },
              ),
        bottomNavigationBar: !_isLoading && _errorMessage == null
            ? Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Colors.grey.shade300)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                        label: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          widget.onSave();
                          Navigator.of(context).pop();
                        },
                        icon: const Icon(Icons.download),
                        label: const Text('Save to Downloads'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : null,
      ),
    );
  }
}
