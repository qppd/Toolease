import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/database_provider.dart';
import '../providers/borrow_record_provider.dart';
import '../providers/item_provider.dart';
import '../models/student.dart' as models;
import '../models/item.dart' as models;
import '../models/borrow_record.dart' as models;
import '../core/design_system.dart';
import '../shared/widgets/app_card.dart';

class ManageRecordsScreen extends ConsumerStatefulWidget {
  const ManageRecordsScreen({super.key});

  @override
  ConsumerState<ManageRecordsScreen> createState() => _ManageRecordsScreenState();
}

class _ManageRecordsScreenState extends ConsumerState<ManageRecordsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  
  List<models.BorrowRecord> _allRecords = [];
  List<models.BorrowRecord> _activeRecords = [];
  List<models.BorrowRecord> _returnedRecords = [];
  List<models.BorrowRecord> _archivedRecords = [];
  List<models.QuantityCondition> _damagedItems = [];
  List<models.QuantityCondition> _lostItems = [];
  Set<int> _selectedDamagedItems = {};
  Set<int> _selectedLostItems = {};
  
  List<models.Student> _students = [];
  List<models.Item> _items = [];
  
  Set<int> _selectedRecords = {};
  String _searchQuery = '';
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _loadAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final databaseService = ref.read(databaseServiceProvider);

      final futures = await Future.wait([
        databaseService.getAllBorrowRecords(),
        databaseService.getReturnedBorrowRecords(),
        databaseService.getArchivedBorrowRecords(),
        databaseService.getDamagedItemRecords(),
        databaseService.getLostItemRecords(),
        databaseService.getAllStudents(),
        databaseService.getAllItems(),
      ]);

      setState(() {
        _allRecords = futures[0] as List<models.BorrowRecord>;
        _returnedRecords = futures[1] as List<models.BorrowRecord>;
        _archivedRecords = futures[2] as List<models.BorrowRecord>;
        _damagedItems = futures[3] as List<models.QuantityCondition>;
        _lostItems = futures[4] as List<models.QuantityCondition>;
        _students = futures[5] as List<models.Student>;
        _items = futures[6] as List<models.Item>;
        
        // Filter active records
        _activeRecords = _allRecords
            .where((record) => record.status == models.BorrowStatus.active)
            .toList();
            
        // Clear selections when refreshing data
        _selectedRecords.clear();
        _selectedDamagedItems.clear();
        _selectedLostItems.clear();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading records: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getStudentName(int studentId) {
    try {
      return _students.firstWhere((s) => s.id == studentId).name;
    } catch (e) {
      return 'Unknown Student';
    }
  }

  String _getItemName(int itemId) {
    try {
      return _items.firstWhere((i) => i.id == itemId).name;
    } catch (e) {
      return 'Unknown Item';
    }
  }


  models.BorrowItem? _getBorrowItemFromCondition(models.QuantityCondition condition) {
    // Search through all records to find the borrow item
    for (final record in _allRecords) {
      for (final item in record.items) {
        if (item.id == condition.borrowItemId) {
          return item;
        }
      }
    }
    return null;
  }

  models.BorrowRecord? _getBorrowRecordFromBorrowItem(models.BorrowItem borrowItem) {
    // Find the record that contains this borrow item
    for (final record in _allRecords) {
      if (record.items.any((item) => item.id == borrowItem.id)) {
        return record;
      }
    }
    return null;
  }

  List<models.BorrowRecord> _getFilteredRecords(List<models.BorrowRecord> records) {
    var filtered = records.where((record) {
      final studentName = _getStudentName(record.studentId).toLowerCase();
      final borrowId = record.borrowId.toLowerCase();
      final query = _searchQuery.toLowerCase();
      
      final matchesSearch = query.isEmpty || 
          studentName.contains(query) || 
          borrowId.contains(query);
      
      final matchesDate = _selectedDate == null ||
          (record.borrowedAt.year == _selectedDate!.year &&
           record.borrowedAt.month == _selectedDate!.month &&
           record.borrowedAt.day == _selectedDate!.day);
      
      return matchesSearch && matchesDate;
    }).toList();
    
    // Sort by most recent first
    filtered.sort((a, b) => b.borrowedAt.compareTo(a.borrowedAt));
    return filtered;
  }

  Future<void> _archiveSelectedRecords() async {
    if (_selectedRecords.isEmpty) return;

    final confirmed = await _showConfirmDialog(
      'Archive Records',
      'Archive ${_selectedRecords.length} selected record(s)? They can be restored later.',
      'Archive',
      AppColors.warning,
    );

    if (!confirmed) return;

    try {
      setState(() => _isLoading = true);
      
      final databaseService = ref.read(databaseServiceProvider);
      await databaseService.bulkArchiveBorrowRecords(_selectedRecords.toList());
      
      await _loadAllData();
      setState(() => _selectedRecords.clear());
      
      // Invalidate providers to refresh other screens
      ref.invalidate(recentBorrowRecordsWithNamesNotifierProvider);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Records archived successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error archiving records: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _restoreSelectedRecords() async {
    if (_selectedRecords.isEmpty) return;

    final confirmed = await _showConfirmDialog(
      'Restore Records',
      'Restore ${_selectedRecords.length} selected record(s)? They will return to their original status.',
      'Restore',
      AppColors.success,
    );

    if (!confirmed) return;

    try {
      setState(() => _isLoading = true);
      
      final databaseService = ref.read(databaseServiceProvider);
      await databaseService.bulkRestoreBorrowRecords(_selectedRecords.toList());
      
      await _loadAllData();
      setState(() => _selectedRecords.clear());
      
      // Invalidate providers to refresh other screens
      ref.invalidate(recentBorrowRecordsWithNamesNotifierProvider);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Records restored successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error restoring records: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<bool> _showConfirmDialog(
    String title,
    String content,
    String actionText,
    Color actionColor,
  ) async {
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
            style: ElevatedButton.styleFrom(
              backgroundColor: actionColor,
              foregroundColor: Colors.white,
            ),
            child: Text(actionText),
          ),
        ],
      ),
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Manage Records',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAllData,
            tooltip: 'Refresh Data',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.onPrimary,
          unselectedLabelColor: AppColors.onPrimary.withValues(alpha: 0.7),
          indicatorColor: AppColors.onPrimary,
          tabs: [
            Tab(
              icon: const Icon(Icons.assignment, size: 20),
              text: 'All (${_allRecords.length})',
            ),
            Tab(
              icon: const Icon(Icons.schedule, size: 20),
              text: 'Active (${_activeRecords.length})',
            ),
            Tab(
              icon: const Icon(Icons.assignment_return, size: 20),
              text: 'Returned (${_returnedRecords.length})',
            ),
            Tab(
              icon: const Icon(Icons.archive, size: 20),
              text: 'Archived (${_archivedRecords.length})',
            ),
            Tab(
              icon: const Icon(Icons.warning, size: 20),
              text: 'Damaged (${_damagedItems.length})',
            ),
            Tab(
              icon: const Icon(Icons.error, size: 20),
              text: 'Lost (${_lostItems.length})',
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildSearchAndFilters(),
          if (_selectedRecords.isNotEmpty) _buildActionBar(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildRecordsList(_getFilteredRecords(_allRecords)),
                      _buildRecordsList(_getFilteredRecords(_activeRecords)),
                      _buildRecordsList(_getFilteredRecords(_returnedRecords)),
                      _buildRecordsList(_getFilteredRecords(_archivedRecords), isArchived: true),
                      _buildDamagedItemsList(),
                      _buildLostItemsList(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.surface,
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Search by student name or borrow ID...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _searchQuery = ''),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() => _selectedDate = date);
                    }
                  },
                  icon: const Icon(Icons.calendar_today),
                  label: Text(_selectedDate == null
                      ? 'Filter by Date'
                      : 'Date: ${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'),
                ),
              ),
              const SizedBox(width: 12),
              if (_selectedDate != null)
                IconButton(
                  onPressed: () => setState(() => _selectedDate = null),
                  icon: const Icon(Icons.clear),
                  tooltip: 'Clear Date Filter',
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.primary.withValues(alpha: 0.1),
      child: Row(
        children: [
          Text(
            '${_selectedRecords.length} selected',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          if (_tabController.index == 3) // Archived tab
            ElevatedButton.icon(
              onPressed: _restoreSelectedRecords,
              icon: const Icon(Icons.restore),
              label: const Text('Restore'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
              ),
            )
          else if (_tabController.index != 3) // Not archived tab
            ElevatedButton.icon(
              onPressed: _archiveSelectedRecords,
              icon: const Icon(Icons.archive),
              label: const Text('Archive'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.warning,
                foregroundColor: Colors.white,
              ),
            ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () => setState(() => _selectedRecords.clear()),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordsList(List<models.BorrowRecord> records, {bool isArchived = false}) {
    if (records.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isArchived ? Icons.archive_outlined : Icons.assignment_outlined,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              isArchived ? 'No archived records' : 'No records found',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAllData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: records.length,
        itemBuilder: (context, index) {
          final record = records[index];
          final isSelected = _selectedRecords.contains(record.id);
          
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: AppCard(
              child: InkWell(
              onTap: () => _showRecordDetails(record),
              onLongPress: () => _toggleRecordSelection(record.id),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                decoration: BoxDecoration(
                  border: isSelected ? Border.all(color: AppColors.primary, width: 2) : null,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (isSelected)
                            Container(
                              margin: const EdgeInsets.only(right: 12),
                              child: Icon(Icons.check_circle, color: AppColors.primary),
                            ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  record.borrowId,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  _getStudentName(record.studentId),
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _buildStatusChip(record.status),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.schedule, size: 16, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            'Borrowed: ${record.borrowedAt.day}/${record.borrowedAt.month}/${record.borrowedAt.year}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(width: 16),
                          if (record.returnedAt != null) ...[
                            Icon(Icons.assignment_return, size: 16, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Text(
                              'Returned: ${record.returnedAt!.day}/${record.returnedAt!.month}/${record.returnedAt!.year}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.inventory, size: 16, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            '${record.items.length} item(s), ${record.items.fold(0, (sum, item) => sum + item.quantity)} total quantity',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusChip(models.BorrowStatus status) {
    Color color;
    String text;
    
    switch (status) {
      case models.BorrowStatus.active:
        color = AppColors.warning;
        text = 'Active';
        break;
      case models.BorrowStatus.returned:
        color = AppColors.success;
        text = 'Returned';
        break;
      case models.BorrowStatus.archived:
        color = AppColors.info;
        text = 'Archived';
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildDamagedItemsList() {
    if (_damagedItems.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.warning_outlined, size: 64, color: AppColors.textSecondary),
            SizedBox(height: 16),
            Text('No damaged items found'),
          ],
        ),
      );
    }

    return Column(
      children: [
        if (_selectedDamagedItems.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppColors.warning.withValues(alpha: 0.1),
            child: Row(
              children: [
                Text(
                  '${_selectedDamagedItems.length} damaged items selected',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _repairSelectedDamagedItems,
                  icon: const Icon(Icons.build),
                  label: const Text('Mark as Repaired'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => setState(() => _selectedDamagedItems.clear()),
                  child: const Text('Clear'),
                ),
              ],
            ),
          ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _damagedItems.length,
            itemBuilder: (context, index) {
              final damagedItem = _damagedItems[index];
              final isSelected = _selectedDamagedItems.contains(damagedItem.id);
              final borrowItem = _getBorrowItemFromCondition(damagedItem);
              final borrowRecord = borrowItem != null ? _getBorrowRecordFromBorrowItem(borrowItem) : null;
              
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: AppCard(
                  child: InkWell(
                    onTap: () => _toggleDamagedItemSelection(damagedItem.id),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      decoration: BoxDecoration(
                        border: isSelected ? Border.all(color: AppColors.warning, width: 2) : null,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            if (isSelected)
                              Container(
                                margin: const EdgeInsets.only(right: 12),
                                child: Icon(Icons.check_circle, color: AppColors.warning),
                              ),
                            Icon(Icons.warning, color: AppColors.warning, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    borrowItem != null ? _getItemName(borrowItem.itemId) : 'Unknown Item',
                                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Borrower: ${borrowRecord != null ? _getStudentName(borrowRecord.studentId) : 'Unknown'}',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  Text(
                                    'Unit ${damagedItem.quantityUnit} - Damaged',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.warning.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Damaged',
                                style: TextStyle(
                                  color: AppColors.warning,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLostItemsList() {
    if (_lostItems.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outlined, size: 64, color: AppColors.textSecondary),
            SizedBox(height: 16),
            Text('No lost items found'),
          ],
        ),
      );
    }

    return Column(
      children: [
        if (_selectedLostItems.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppColors.error.withValues(alpha: 0.1),
            child: Row(
              children: [
                Text(
                  '${_selectedLostItems.length} lost items selected',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _replaceSelectedLostItems,
                  icon: const Icon(Icons.add_shopping_cart),
                  label: const Text('Mark as Replaced'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => setState(() => _selectedLostItems.clear()),
                  child: const Text('Clear'),
                ),
              ],
            ),
          ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _lostItems.length,
            itemBuilder: (context, index) {
              final lostItem = _lostItems[index];
              final isSelected = _selectedLostItems.contains(lostItem.id);
              final borrowItem = _getBorrowItemFromCondition(lostItem);
              final borrowRecord = borrowItem != null ? _getBorrowRecordFromBorrowItem(borrowItem) : null;
              
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: AppCard(
                  child: InkWell(
                    onTap: () => _toggleLostItemSelection(lostItem.id),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      decoration: BoxDecoration(
                        border: isSelected ? Border.all(color: AppColors.error, width: 2) : null,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            if (isSelected)
                              Container(
                                margin: const EdgeInsets.only(right: 12),
                                child: Icon(Icons.check_circle, color: AppColors.error),
                              ),
                            Icon(Icons.error, color: AppColors.error, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    borrowItem != null ? _getItemName(borrowItem.itemId) : 'Unknown Item',
                                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Borrower: ${borrowRecord != null ? _getStudentName(borrowRecord.studentId) : 'Unknown'}',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  Text(
                                    'Unit ${lostItem.quantityUnit} - Lost',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.error.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Lost',
                                style: TextStyle(
                                  color: AppColors.error,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _toggleRecordSelection(int recordId) {
    setState(() {
      if (_selectedRecords.contains(recordId)) {
        _selectedRecords.remove(recordId);
      } else {
        _selectedRecords.add(recordId);
      }
    });
  }

  void _toggleDamagedItemSelection(int conditionId) {
    setState(() {
      if (_selectedDamagedItems.contains(conditionId)) {
        _selectedDamagedItems.remove(conditionId);
      } else {
        _selectedDamagedItems.add(conditionId);
      }
    });
  }

  void _toggleLostItemSelection(int conditionId) {
    setState(() {
      if (_selectedLostItems.contains(conditionId)) {
        _selectedLostItems.remove(conditionId);
      } else {
        _selectedLostItems.add(conditionId);
      }
    });
  }

  Future<void> _repairSelectedDamagedItems() async {
    if (_selectedDamagedItems.isEmpty) return;

    final confirmed = await _showConfirmDialog(
      'Repair Items',
      'Mark ${_selectedDamagedItems.length} damaged item(s) as repaired and restore to stock?',
      'Mark as Repaired',
      AppColors.success,
    );

    if (!confirmed) return;

    try {
      setState(() => _isLoading = true);
      
      final databaseService = ref.read(databaseServiceProvider);
      await databaseService.restoreDamagedItemsToStock(_selectedDamagedItems.toList());
      
      await _loadAllData();
      setState(() => _selectedDamagedItems.clear());
      
      // Invalidate item provider to update dashboard in real-time
      ref.invalidate(itemNotifierProvider);
      ref.invalidate(allItemsProvider);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Damaged items marked as repaired and restored to stock')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error repairing items: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _replaceSelectedLostItems() async {
    if (_selectedLostItems.isEmpty) return;

    final confirmed = await _showConfirmDialog(
      'Replace Items',
      'Mark ${_selectedLostItems.length} lost item(s) as replaced and restore to stock?',
      'Mark as Replaced',
      AppColors.success,
    );

    if (!confirmed) return;

    try {
      setState(() => _isLoading = true);
      
      final databaseService = ref.read(databaseServiceProvider);
      await databaseService.restoreLostItemsToStock(_selectedLostItems.toList());
      
      await _loadAllData();
      setState(() => _selectedLostItems.clear());
      
      // Invalidate item provider to update dashboard in real-time
      ref.invalidate(itemNotifierProvider);
      ref.invalidate(allItemsProvider);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lost items marked as replaced and restored to stock')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error replacing items: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showRecordDetails(models.BorrowRecord record) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Record Details'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Borrow ID', record.borrowId),
              _buildDetailRow('Student', _getStudentName(record.studentId)),
              _buildDetailRow('Status', record.status.name.toUpperCase()),
              _buildDetailRow('Borrowed', '${record.borrowedAt.day}/${record.borrowedAt.month}/${record.borrowedAt.year}'),
              if (record.returnedAt != null)
                _buildDetailRow('Returned', '${record.returnedAt!.day}/${record.returnedAt!.month}/${record.returnedAt!.year}'),
              const SizedBox(height: 16),
              Text(
                'Items (${record.items.length}):',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...record.items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(_getItemName(item.itemId)),
                    ),
                    Text('Qty: ${item.quantity}'),
                  ],
                ),
              )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}