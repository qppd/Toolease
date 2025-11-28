import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/database_provider.dart';
import '../providers/student_provider.dart';
import '../providers/storage_provider.dart';
import '../providers/item_provider.dart';
import '../providers/borrow_record_provider.dart';
import '../services/database_service.dart';
import '../shared/widgets/app_scaffold.dart';
import '../core/design_system.dart';
import '../models/student.dart';
import '../models/storage.dart';
import '../models/item.dart';
import '../models/borrow_record.dart';

class DatabaseManagementScreen extends ConsumerStatefulWidget {
  const DatabaseManagementScreen({super.key});

  @override
  ConsumerState<DatabaseManagementScreen> createState() => _DatabaseManagementScreenState();
}

class _DatabaseManagementScreenState extends ConsumerState<DatabaseManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, int> _dataCounts = {};
  bool _isLoading = true;

  // Selection states
  Set<int> _selectedStudents = {};
  Set<int> _selectedStorages = {};
  Set<int> _selectedItems = {};
  Set<int> _selectedBorrowRecords = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadDataCounts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDataCounts() async {
    setState(() => _isLoading = true);
    try {
      final database = ref.read(databaseProvider);
      final databaseService = DatabaseService(database);
      final counts = await databaseService.getDataCounts();
      setState(() {
        _dataCounts = counts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data counts: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Database Management',
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildHeaderCard(),
                const SizedBox(height: 16),
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          labelColor: AppColors.primary,
                          unselectedLabelColor: AppColors.textSecondary,
                          indicatorColor: AppColors.primary,
                          tabs: [
                            Tab(text: 'Students (${_dataCounts['students'] ?? 0})'),
                            Tab(text: 'Storages (${_dataCounts['storages'] ?? 0})'),
                            Tab(text: 'Items (${_dataCounts['items'] ?? 0})'),
                            Tab(text: 'Records (${_dataCounts['borrowRecords'] ?? 0})'),
                          ],
                        ),
                      ),
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildStudentsTab(),
                            _buildStoragesTab(),
                            _buildItemsTab(),
                            _buildBorrowRecordsTab(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildHeaderCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber, color: AppColors.warning, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Database Management',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Manage and delete database records. Warning: These actions cannot be undone.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildDataCountChip('Students', _dataCounts['students'] ?? 0, Icons.people),
                _buildDataCountChip('Storages', _dataCounts['storages'] ?? 0, Icons.storage),
                _buildDataCountChip('Items', _dataCounts['items'] ?? 0, Icons.inventory_2),
                _buildDataCountChip('Records', _dataCounts['borrowRecords'] ?? 0, Icons.assignment),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataCountChip(String label, int count, IconData icon) {
    return Chip(
      avatar: Icon(icon, size: 16, color: AppColors.primary),
      label: Text('$label: $count'),
      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
    );
  }

  Widget _buildStudentsTab() {
    final studentsAsync = ref.watch(studentNotifierProvider);

    return studentsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
      data: (students) => Column(
        children: [
          _buildSelectionHeader(
            'Students',
            students.length,
            _selectedStudents.length,
            () => _deleteSelectedStudents(),
            () => _deleteAllStudents(),
            () => setState(() {
              if (_selectedStudents.length == students.length) {
                _selectedStudents.clear();
              } else {
                _selectedStudents = students.map((s) => s.id).toSet();
              }
            }),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: students.length,
              itemBuilder: (context, index) {
                final student = students[index];
                return _buildStudentTile(student);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoragesTab() {
    final storagesAsync = ref.watch(storageNotifierProvider);

    return storagesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
      data: (storages) => Column(
        children: [
          _buildSelectionHeader(
            'Storages',
            storages.length,
            _selectedStorages.length,
            () => _deleteSelectedStorages(),
            () => _deleteAllStorages(),
            () => setState(() {
              if (_selectedStorages.length == storages.length) {
                _selectedStorages.clear();
              } else {
                _selectedStorages = storages.map((s) => s.id).toSet();
              }
            }),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: storages.length,
              itemBuilder: (context, index) {
                final storage = storages[index];
                return _buildStorageTile(storage);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsTab() {
    final itemsAsync = ref.watch(itemNotifierProvider);

    return itemsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
      data: (items) => Column(
        children: [
          _buildSelectionHeader(
            'Items',
            items.length,
            _selectedItems.length,
            () => _deleteSelectedItems(),
            () => _deleteAllItems(),
            () => setState(() {
              if (_selectedItems.length == items.length) {
                _selectedItems.clear();
              } else {
                _selectedItems = items.map((i) => i.id).toSet();
              }
            }),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return _buildItemTile(item);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBorrowRecordsTab() {
    final recordsAsync = ref.watch(borrowRecordNotifierProvider);

    return recordsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
      data: (records) => Column(
        children: [
          _buildSelectionHeader(
            'Borrow Records',
            records.length,
            _selectedBorrowRecords.length,
            () => _deleteSelectedBorrowRecords(),
            () => _deleteAllBorrowRecords(),
            () => setState(() {
              if (_selectedBorrowRecords.length == records.length) {
                _selectedBorrowRecords.clear();
              } else {
                _selectedBorrowRecords = records.map((r) => r.id).toSet();
              }
            }),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: records.length,
              itemBuilder: (context, index) {
                final record = records[index];
                return _buildBorrowRecordTile(record);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionHeader(
    String title,
    int totalCount,
    int selectedCount,
    VoidCallback onDeleteSelected,
    VoidCallback onDeleteAll,
    VoidCallback onToggleSelectAll,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  '$selectedCount of $totalCount selected',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onToggleSelectAll,
            child: Text(selectedCount == totalCount ? 'Deselect All' : 'Select All'),
          ),
          const SizedBox(width: 8),
          if (selectedCount > 0)
            ElevatedButton.icon(
              onPressed: onDeleteSelected,
              icon: const Icon(Icons.delete),
              label: Text('Delete ($selectedCount)'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            ),
          const SizedBox(width: 8),
          if (totalCount > 0)
            ElevatedButton.icon(
              onPressed: onDeleteAll,
              icon: const Icon(Icons.delete_forever),
              label: const Text('Delete All'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            ),
        ],
      ),
    );
  }

  Widget _buildStudentTile(Student student) {
    final isSelected = _selectedStudents.contains(student.id);

    return Card(
      child: CheckboxListTile(
        value: isSelected,
        onChanged: (value) {
          setState(() {
            if (value == true) {
              _selectedStudents.add(student.id);
            } else {
              _selectedStudents.remove(student.id);
            }
          });
        },
        title: Text(student.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ID: ${student.studentId}'),
            Text('${student.yearLevel} - ${student.section}'),
          ],
        ),
        secondary: Icon(Icons.person, color: AppColors.primary),
      ),
    );
  }

  Widget _buildStorageTile(Storage storage) {
    final isSelected = _selectedStorages.contains(storage.id);

    return Card(
      child: CheckboxListTile(
        value: isSelected,
        onChanged: (value) {
          setState(() {
            if (value == true) {
              _selectedStorages.add(storage.id);
            } else {
              _selectedStorages.remove(storage.id);
            }
          });
        },
        title: Text(storage.name),
        subtitle: storage.description != null ? Text(storage.description!) : null,
        secondary: Icon(Icons.storage, color: AppColors.secondary),
      ),
    );
  }

  Widget _buildItemTile(Item item) {
    final isSelected = _selectedItems.contains(item.id);

    return Card(
      child: CheckboxListTile(
        value: isSelected,
        onChanged: (value) {
          setState(() {
            if (value == true) {
              _selectedItems.add(item.id);
            } else {
              _selectedItems.remove(item.id);
            }
          });
        },
        title: Text(item.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.description != null) Text(item.description!),
            Text('Available: ${item.availableQuantity} / ${item.totalQuantity}'),
          ],
        ),
        secondary: Icon(Icons.inventory_2, color: AppColors.accent),
      ),
    );
  }

  Widget _buildBorrowRecordTile(BorrowRecord record) {
    final isSelected = _selectedBorrowRecords.contains(record.id);

    return Card(
      child: CheckboxListTile(
        value: isSelected,
        onChanged: (value) {
          setState(() {
            if (value == true) {
              _selectedBorrowRecords.add(record.id);
            } else {
              _selectedBorrowRecords.remove(record.id);
            }
          });
        },
        title: Text('Borrow ID: ${record.borrowId}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status: ${record.status.name}'),
            Text('Items: ${record.items.length}'),
            Text('Date: ${record.borrowedAt.toString().split(' ')[0]}'),
          ],
        ),
        secondary: Icon(
          Icons.assignment,
          color: record.status == BorrowStatus.active ? AppColors.warning : AppColors.info,
        ),
      ),
    );
  }

  Future<void> _deleteSelectedStudents() async {
    if (_selectedStudents.isEmpty) return;

    final confirmed = await _showDeleteConfirmationDialog(
      'Delete Selected Students',
      'Are you sure you want to delete ${_selectedStudents.length} student(s)? This will also delete all their borrow records.',
    );

    if (confirmed) {
      await _performDeletion(() async {
        final database = ref.read(databaseProvider);
        final databaseService = DatabaseService(database);
        await databaseService.deleteSelectedStudents(_selectedStudents.toList());
        await ref.read(studentNotifierProvider.notifier).refreshStudents();
        setState(() => _selectedStudents.clear());
      });
    }
  }

  Future<void> _deleteAllStudents() async {
    final confirmed = await _showDeleteConfirmationDialog(
      'Delete All Students',
      'Are you sure you want to delete ALL students? This will also delete all borrow records.',
    );

    if (confirmed) {
      await _performDeletion(() async {
        final database = ref.read(databaseProvider);
        final databaseService = DatabaseService(database);
        await databaseService.deleteAllStudents();
        await ref.read(studentNotifierProvider.notifier).refreshStudents();
        await ref.read(borrowRecordNotifierProvider.notifier).refreshBorrowRecords();
        setState(() => _selectedStudents.clear());
      });
    }
  }

  Future<void> _deleteSelectedStorages() async {
    if (_selectedStorages.isEmpty) return;

    final confirmed = await _showDeleteConfirmationDialog(
      'Delete Selected Storages',
      'Are you sure you want to delete ${_selectedStorages.length} storage(s)? This will also delete all items in these storages and their borrow records.',
    );

    if (confirmed) {
      await _performDeletion(() async {
        final database = ref.read(databaseProvider);
        final databaseService = DatabaseService(database);
        await databaseService.deleteSelectedStorages(_selectedStorages.toList());
        await ref.read(storageNotifierProvider.notifier).refreshStorages();
        await ref.read(itemNotifierProvider.notifier).refreshItems();
        await ref.read(borrowRecordNotifierProvider.notifier).refreshBorrowRecords();
        setState(() => _selectedStorages.clear());
      });
    }
  }

  Future<void> _deleteAllStorages() async {
    final confirmed = await _showDeleteConfirmationDialog(
      'Delete All Storages',
      'Are you sure you want to delete ALL storages? This will also delete all items and borrow records.',
    );

    if (confirmed) {
      await _performDeletion(() async {
        final database = ref.read(databaseProvider);
        final databaseService = DatabaseService(database);
        await databaseService.deleteAllStorages();
        await ref.read(storageNotifierProvider.notifier).refreshStorages();
        await ref.read(itemNotifierProvider.notifier).refreshItems();
        await ref.read(borrowRecordNotifierProvider.notifier).refreshBorrowRecords();
        setState(() => _selectedStorages.clear());
      });
    }
  }

  Future<void> _deleteSelectedItems() async {
    if (_selectedItems.isEmpty) return;

    final confirmed = await _showDeleteConfirmationDialog(
      'Delete Selected Items',
      'Are you sure you want to delete ${_selectedItems.length} item(s)? This will also delete their borrow records.',
    );

    if (confirmed) {
      await _performDeletion(() async {
        final database = ref.read(databaseProvider);
        final databaseService = DatabaseService(database);
        await databaseService.deleteSelectedItems(_selectedItems.toList());
        await ref.read(itemNotifierProvider.notifier).refreshItems();
        await ref.read(borrowRecordNotifierProvider.notifier).refreshBorrowRecords();
        setState(() => _selectedItems.clear());
      });
    }
  }

  Future<void> _deleteAllItems() async {
    final confirmed = await _showDeleteConfirmationDialog(
      'Delete All Items',
      'Are you sure you want to delete ALL items? This will also delete all borrow records.',
    );

    if (confirmed) {
      await _performDeletion(() async {
        final database = ref.read(databaseProvider);
        final databaseService = DatabaseService(database);
        await databaseService.deleteAllItems();
        await ref.read(itemNotifierProvider.notifier).refreshItems();
        await ref.read(borrowRecordNotifierProvider.notifier).refreshBorrowRecords();
        setState(() => _selectedItems.clear());
      });
    }
  }

  Future<void> _deleteSelectedBorrowRecords() async {
    if (_selectedBorrowRecords.isEmpty) return;

    final confirmed = await _showDeleteConfirmationDialog(
      'Delete Selected Borrow Records',
      'Are you sure you want to delete ${_selectedBorrowRecords.length} borrow record(s)?',
    );

    if (confirmed) {
      await _performDeletion(() async {
        final database = ref.read(databaseProvider);
        final databaseService = DatabaseService(database);
        await databaseService.deleteSelectedBorrowRecords(_selectedBorrowRecords.toList());
        await ref.read(borrowRecordNotifierProvider.notifier).refreshBorrowRecords();
        setState(() => _selectedBorrowRecords.clear());
      });
    }
  }

  Future<void> _deleteAllBorrowRecords() async {
    final confirmed = await _showDeleteConfirmationDialog(
      'Delete All Borrow Records',
      'Are you sure you want to delete ALL borrow records? This will reset all item quantities.',
    );

    if (confirmed) {
      await _performDeletion(() async {
        final database = ref.read(databaseProvider);
        final databaseService = DatabaseService(database);
        await databaseService.deleteAllBorrowRecords();
        await ref.read(borrowRecordNotifierProvider.notifier).refreshBorrowRecords();
        await ref.read(itemNotifierProvider.notifier).refreshItems();
        setState(() => _selectedBorrowRecords.clear());
      });
    }
  }

  Future<bool> _showDeleteConfirmationDialog(String title, String content) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(content),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _performDeletion(Future<void> Function() deleteAction) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Deleting...'),
            ],
          ),
        ),
      );

      await deleteAction();
      await _loadDataCounts();

      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Deletion completed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error during deletion: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}