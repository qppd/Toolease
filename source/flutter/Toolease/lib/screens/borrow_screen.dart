import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/database_provider.dart';
import '../providers/item_provider.dart';
import '../providers/borrow_record_provider.dart';
import '../models/student.dart' as models;
import '../models/storage.dart' as models;
import '../models/item.dart' as models;
import '../core/design_system.dart';
import '../shared/widgets/app_scaffold.dart';
import '../shared/widgets/app_card.dart';
import '../shared/widgets/confirmation_dialog.dart';
import '../services/websocket_service.dart';

class BorrowScreen extends ConsumerStatefulWidget {
  const BorrowScreen({super.key});

  @override
  ConsumerState<BorrowScreen> createState() => _BorrowScreenState();
}

class _BorrowScreenState extends ConsumerState<BorrowScreen> {
  final _studentIdController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  models.Student? _selectedStudent;
  Set<int> _selectedStorages = {}; // Track multiple selected storages
  List<models.Storage> _storages = [];
  Map<int, List<models.Item>> _itemsByStorage = {}; // storageId -> items
  Map<int, int> _selectedItems = {}; // itemId -> quantity

  @override
  void initState() {
    super.initState();
    _loadStorages();
  }

  @override
  void dispose() {
    _studentIdController.dispose();
    super.dispose();
  }

  Future<void> _loadStorages() async {
    try {
      final databaseService = ref.read(databaseServiceProvider);
      final storages = await databaseService.getAllStorages();
      setState(() {
        _storages = storages;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading storages: $e')),
        );
      }
    }
  }

  Future<void> _searchStudent() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final databaseService = ref.read(databaseServiceProvider);
      final student = await databaseService.getStudentByStudentId(_studentIdController.text.trim());
      
      setState(() {
        _selectedStudent = student;
      });

      if (student == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Student not found. Please register first.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error searching student: $e')),
        );
      }
    }
  }

  Future<void> _toggleStorageSelection(models.Storage storage) async {
    try {
      final databaseService = ref.read(databaseServiceProvider);
      
      if (_selectedStorages.contains(storage.id)) {
        // Deselect storage and remove its items from selection
        final storageItems = _itemsByStorage[storage.id] ?? [];
        final storageItemIds = storageItems.map((item) => item.id).toSet();
        
        setState(() {
          _selectedStorages.remove(storage.id);
          _itemsByStorage.remove(storage.id);
          
          // Remove selected items from this storage
          _selectedItems.removeWhere((itemId, _) => storageItemIds.contains(itemId));
        });
      } else {
        // Select storage and load its items
        final items = await databaseService.getItemsByStorage(storage.id);
        setState(() {
          _selectedStorages.add(storage.id);
          _itemsByStorage[storage.id] = items;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading items: $e')),
        );
      }
    }
  }

  Future<void> _showBorrowConfirmation() async {
    if (_selectedStudent == null || _selectedItems.isEmpty) return;

    final confirmed = await _showBorrowConfirmationDialog();

    if (confirmed == true && mounted) {
      await _createBorrowRecord();
    }
  }

  Future<bool?> _showBorrowConfirmationDialog() async {
    final wsService = WebSocketService();
    wsService.connect();

    // Get selected item details
    final selectedItemDetails = <models.Item>[];
    for (final entry in _selectedItems.entries) {
      for (final items in _itemsByStorage.values) {
        final item = items.firstWhere(
          (item) => item.id == entry.key,
          orElse: () => items.first,
        );
        if (item.id == entry.key) {
          selectedItemDetails.add(item);
          break;
        }
      }
    }

    final scannedSerials = <int, String>{}; // itemId -> serial

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          // Listen to WebSocket
          wsService.stream?.listen((message) {
            if (message is String) {
              try {
                // Parse JSON message from ESP32
                final data = message; // Assuming it's '{"action":"rfid_scan","uid":"123"}'
                if (data.contains('"action":"rfid_scan"') && data.contains('"uid"')) {
                  final uidStart = data.indexOf('"uid":"') + 7;
                  final uidEnd = data.indexOf('"', uidStart);
                  if (uidStart != -1 && uidEnd != -1) {
                    final rfid = data.substring(uidStart, uidEnd);
                    // Find the first unscanned item
                    for (final item in selectedItemDetails) {
                      if (!scannedSerials.containsKey(item.id)) {
                        setState(() {
                          scannedSerials[item.id] = rfid;
                        });
                        break;
                      }
                    }
                  }
                }
              } catch (e) {
                // Ignore invalid messages
              }
            }
          });

          final allScanned = selectedItemDetails.every((item) => scannedSerials.containsKey(item.id));

          return AlertDialog(
            title: const Text('Confirm Borrow - Scan RFID Tags'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Student Information
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Student Details',
                          style: AppTypography.labelLarge.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text('Name: ${_selectedStudent!.name}', style: AppTypography.bodyMedium),
                        Text('ID: ${_selectedStudent!.studentId}', style: AppTypography.bodyMedium),
                        Text('Year: ${_selectedStudent!.yearLevel} | Section: ${_selectedStudent!.section}',
                          style: AppTypography.bodyMedium),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Items Summary
                  Text(
                    'Items to Borrow',
                    style: AppTypography.labelLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  ...selectedItemDetails.map((item) {
                    final quantity = _selectedItems[item.id] ?? 0;
                    return Container(
                      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                        border: Border.all(color: AppColors.outline.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name,
                                  style: AppTypography.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (item.description?.isNotEmpty == true)
                                  Text(
                                    item.description!,
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.xs,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                            ),
                            child: Text(
                              'Qty: $quantity',
                              style: AppTypography.labelMedium.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),

                  const SizedBox(height: AppSpacing.md),

                  // Total Summary
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Items',
                          style: AppTypography.labelLarge.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          _selectedItems.values.fold(0, (sum, qty) => sum + qty).toString(),
                          style: AppTypography.h6.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.md),

                  Text(
                    'Please scan the RFID tag for each item to confirm borrowing.',
                    style: AppTypography.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ...selectedItemDetails.map((item) {
                    final quantity = _selectedItems[item.id] ?? 0;
                    final scanned = scannedSerials.containsKey(item.id);
                    return Container(
                      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: scanned ? AppColors.success.withValues(alpha: 0.1) : AppColors.surface,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        border: Border.all(
                          color: scanned ? AppColors.success : AppColors.outline,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w600),
                          ),
                          Text('Quantity: $quantity', style: AppTypography.bodySmall),
                          const SizedBox(height: AppSpacing.xs),
                          TextFormField(
                            initialValue: scannedSerials[item.id] ?? '',
                            enabled: false,
                            decoration: InputDecoration(
                              labelText: 'RFID Serial Number',
                              border: const OutlineInputBorder(),
                              filled: true,
                              fillColor: scanned ? AppColors.success.withValues(alpha: 0.1) : AppColors.surface,
                            ),
                          ),
                          if (!scanned)
                            Text(
                              'Scan RFID tag to populate',
                              style: AppTypography.bodySmall.copyWith(color: AppColors.error),
                            ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  wsService.disconnect();
                  Navigator.of(context).pop(false);
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: allScanned
                    ? () {
                        wsService.disconnect();
                        Navigator.of(context).pop(true);
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                ),
                child: const Text('Confirm Borrow'),
              ),
            ],
          );
        },
      ),
    );
  }



  Future<void> _createBorrowRecord() async {
    if (_selectedStudent == null || _selectedItems.isEmpty) return;

    try {
      final databaseService = ref.read(databaseServiceProvider);
      final borrowItems = _selectedItems.entries
          .map((e) => (itemId: e.key, quantity: e.value))
          .toList();

      await databaseService.createBorrowRecord(
        studentId: _selectedStudent!.id,
        items: borrowItems,
      );

      // Invalidate providers to refresh dashboard data
      ref.invalidate(itemNotifierProvider);
      ref.invalidate(activeBorrowCountNotifierProvider);
      ref.invalidate(allItemsProvider);
      ref.invalidate(activeBorrowRecordsCountProvider);
      ref.invalidate(recentBorrowRecordsWithNamesNotifierProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Items borrowed successfully!')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating borrow record: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalSelectedItems = _selectedItems.values.fold(0, (sum, qty) => sum + qty);
    
    return AppScaffold(
      title: 'Borrow Items',
      body: Column(
        children: [
          // Progress indicator
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(bottom: BorderSide(color: AppColors.outline.withValues(alpha: 0.2))),
            ),
            child: Row(
              children: [
                _buildStepIndicator(1, 'Student', _selectedStudent != null),
                _buildStepDivider(_selectedStudent != null),
                _buildStepIndicator(2, 'Items', _selectedStorages.isNotEmpty),
                _buildStepDivider(totalSelectedItems > 0),
                _buildStepIndicator(3, 'Review', totalSelectedItems > 0),
              ],
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Step 1: Student Search Section
                  _buildStudentSearchSection(),
                  
                  const SizedBox(height: AppSpacing.lg),
                  
                  // Step 2: Storage Selection
                  if (_selectedStudent != null) ...[
                    _buildStorageSelectionSection(),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  
                  // Step 3: Items List
                  if (_selectedStorages.isNotEmpty) ...[
                    _buildItemsSelectionSection(),
                  ],
                  
                  // Bottom padding for floating action button
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: totalSelectedItems > 0
        ? FloatingActionButton.extended(
            onPressed: _showBorrowConfirmation,
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.onPrimary,
            icon: const Icon(Icons.shopping_cart_checkout),
            label: Text('Borrow $totalSelectedItems ${totalSelectedItems == 1 ? 'Item' : 'Items'}'),
          )
        : null,
    );
  }

  Widget _buildStepIndicator(int step, String label, bool isActive) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? AppColors.primary : AppColors.outline,
          ),
          child: Center(
            child: Text(
              step.toString(),
              style: AppTypography.labelMedium.copyWith(
                color: isActive ? AppColors.onPrimary : AppColors.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: isActive ? AppColors.primary : AppColors.textSecondary,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildStepDivider(bool isActive) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 20),
        color: isActive ? AppColors.primary : AppColors.outline,
      ),
    );
  }

  Widget _buildStudentSearchSection() {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.person_search, color: AppColors.primary, size: 24),
                  const SizedBox(width: AppSpacing.sm),
                  Text('Find Student', style: AppTypography.h6),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _studentIdController,
                      decoration: InputDecoration(
                        labelText: 'Student ID',
                        border: const OutlineInputBorder(),
                        hintText: 'Enter student ID',
                        prefixIcon: const Icon(Icons.badge),
                        filled: true,
                        fillColor: AppColors.surface,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter student ID';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  ElevatedButton.icon(
                    onPressed: _searchStudent,
                    icon: const Icon(Icons.search),
                    label: const Text('Search'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm + 4,
                      ),
                    ),
                  ),
                ],
              ),
              if (_selectedStudent != null) ...[
                const SizedBox(height: AppSpacing.md),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.check_circle, color: AppColors.success, size: 20),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            'Student Found',
                            style: AppTypography.labelLarge.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text('Name: ${_selectedStudent!.name}', style: AppTypography.bodyMedium),
                      Text('Year Level: ${_selectedStudent!.yearLevel}', style: AppTypography.bodyMedium),
                      Text('Section: ${_selectedStudent!.section}', style: AppTypography.bodyMedium),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStorageSelectionSection() {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.inventory_2, color: AppColors.primary, size: 24),
                const SizedBox(width: AppSpacing.sm),
                Text('Select Storage Locations', style: AppTypography.h6),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Choose one or more storage locations to browse items',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: _storages.map((storage) {
                final isSelected = _selectedStorages.contains(storage.id);
                return FilterChip(
                  label: Text(storage.name),
                  selected: isSelected,
                  onSelected: (_) => _toggleStorageSelection(storage),
                  backgroundColor: AppColors.surface,
                  selectedColor: AppColors.primary.withValues(alpha: 0.2),
                  checkmarkColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: isSelected ? AppColors.primary : AppColors.onSurface,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                );
              }).toList(),
            ),
            if (_selectedStorages.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                '${_selectedStorages.length} ${_selectedStorages.length == 1 ? 'storage' : 'storages'} selected',
                style: AppTypography.labelMedium.copyWith(color: AppColors.primary),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildItemsSelectionSection() {
    // Flatten all items from selected storages
    final allItems = <models.Item>[];
    final storageNames = <int, String>{};
    
    for (final storageId in _selectedStorages) {
      final storage = _storages.firstWhere((s) => s.id == storageId);
      storageNames[storageId] = storage.name;
      allItems.addAll(_itemsByStorage[storageId] ?? []);
    }

    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.shopping_cart, color: AppColors.primary, size: 24),
                const SizedBox(width: AppSpacing.sm),
                Text('Select Items', style: AppTypography.h6),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Available items from selected storage locations',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.md),
            
            if (allItems.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  children: [
                    Icon(Icons.inventory_2, size: 48, color: AppColors.textSecondary),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'No items found',
                      style: AppTypography.bodyLarge.copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Try selecting different storage locations',
                      style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: allItems.length,
                separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final item = allItems[index];
                  final selectedQuantity = _selectedItems[item.id] ?? 0;
                  final storageName = storageNames[item.storageId] ?? 'Unknown';
                  final isOutOfStock = item.availableQuantity <= 0;
                  
                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(
                        color: selectedQuantity > 0 
                          ? AppColors.primary.withValues(alpha: 0.5)
                          : AppColors.outline.withValues(alpha: 0.3),
                        width: selectedQuantity > 0 ? 2 : 1,
                      ),
                      color: selectedQuantity > 0 
                        ? AppColors.primary.withValues(alpha: 0.05)
                        : AppColors.surface,
                    ),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: AppTypography.bodyLarge.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Row(
                                    children: [
                                      Icon(Icons.location_on, size: 16, color: AppColors.primary),
                                      const SizedBox(width: 4),
                                      Text(
                                        storageName,
                                        style: AppTypography.bodySmall.copyWith(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (item.description?.isNotEmpty == true) ...[
                                    const SizedBox(height: AppSpacing.xs),
                                    Text(
                                      item.description!,
                                      style: AppTypography.bodyMedium.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Column(
                              children: [
                                Text(
                                  '${item.availableQuantity}/${item.totalQuantity}',
                                  style: AppTypography.labelLarge.copyWith(
                                    color: isOutOfStock ? AppColors.error : AppColors.success,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  'Available',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        
                        if (isOutOfStock)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.sm,
                              horizontal: AppSpacing.md,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                              border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.block, color: AppColors.error, size: 16),
                                const SizedBox(width: AppSpacing.xs),
                                Text(
                                  'Out of Stock',
                                  style: AppTypography.labelMedium.copyWith(
                                    color: AppColors.error,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Row(
                            children: [
                              Expanded(
                                child: selectedQuantity > 0
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: AppSpacing.xs,
                                        horizontal: AppSpacing.sm,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.check_circle, color: AppColors.primary, size: 16),
                                          const SizedBox(width: AppSpacing.xs),
                                          Text(
                                            '$selectedQuantity ${selectedQuantity == 1 ? 'item' : 'items'} selected',
                                            style: AppTypography.labelMedium.copyWith(
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : Text(
                                      'Tap + to add items',
                                      style: AppTypography.bodyMedium.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: AppColors.outline.withValues(alpha: 0.3)),
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      onPressed: selectedQuantity > 0 ? () {
                                        setState(() {
                                          if (selectedQuantity == 1) {
                                            _selectedItems.remove(item.id);
                                          } else {
                                            _selectedItems[item.id] = selectedQuantity - 1;
                                          }
                                        });
                                      } : null,
                                      icon: const Icon(Icons.remove),
                                      iconSize: 20,
                                      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                                    ),
                                    Container(
                                      constraints: const BoxConstraints(minWidth: 40),
                                      child: Text(
                                        selectedQuantity.toString(),
                                        textAlign: TextAlign.center,
                                        style: AppTypography.bodyLarge.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: selectedQuantity < item.availableQuantity ? () {
                                        setState(() {
                                          _selectedItems[item.id] = selectedQuantity + 1;
                                        });
                                      } : null,
                                      icon: const Icon(Icons.add),
                                      iconSize: 20,
                                      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}