import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/item_unit_provider.dart';
import '../providers/item_provider.dart';
import '../database/database.dart' as db;
import '../models/item.dart' as models;
import '../services/websocket_service.dart';
import '../providers/database_provider.dart';
import '../core/design_system.dart';
import '../shared/widgets/app_card.dart';

class ManageTagsScreen extends ConsumerStatefulWidget {
  const ManageTagsScreen({super.key});

  @override
  ConsumerState<ManageTagsScreen> createState() => _ManageTagsScreenState();
}

class _ManageTagsScreenState extends ConsumerState<ManageTagsScreen> {
  final WebSocketService _wsService = WebSocketService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _wsService.connect();
  }

  @override
  void dispose() {
    _wsService.disconnect();
    _searchController.dispose();
    super.dispose();
  }

  List<db.ItemUnit> _getFilteredItemUnits(List<db.ItemUnit> itemUnits) {
    if (_searchQuery.isEmpty) return itemUnits;
    return itemUnits.where((unit) {
      return unit.serialNo.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             unit.id.toString().contains(_searchQuery);
    }).toList();
  }

  Future<void> _assignRFID(db.ItemUnit unit) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Scan RFID'),
        content: const Text('Press OK to scan RFID tag.'),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                final rfid = await _wsService.scanRFID();
                await ref.read(itemUnitProvider.notifier).updateItemUnitRFID(unit.id, rfid);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('RFID assigned: $rfid')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _createUnitsForExistingItems() async {
    try {
      final databaseService = ref.read(databaseServiceProvider);
      await databaseService.createUnitsForExistingItems();
      await ref.read(itemUnitProvider.notifier).refreshItemUnits();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item units created successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final itemUnitsAsync = ref.watch(itemUnitProvider);
    final itemsAsync = ref.watch(itemNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text(
          'Manage RFID Tags',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header Section
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'RFID Tag Management',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Assign and manage RFID tags for your inventory items',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Search Section
                    AppCard(
                      variant: AppCardVariant.outlined,
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(Icons.search_outlined, color: AppColors.primary),
                              const SizedBox(width: AppSpacing.sm),
                              Text(
                                'Search',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Search by RFID tag or unit ID...',
                              prefixIcon: Icon(
                                Icons.search,
                                color: AppColors.textSecondary,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                                borderSide: BorderSide(color: AppColors.outline),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                                borderSide: BorderSide(color: AppColors.outline),
                              ),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: Icon(Icons.clear, color: AppColors.textSecondary),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() {
                                          _searchQuery = '';
                                        });
                                      },
                                    )
                                  : null,
                            ),
                            onChanged: (value) {
                              setState(() {
                                _searchQuery = value;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Item Units List
            Expanded(
              child: itemUnitsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, size: 60, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Error: $error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => ref
                            .read(itemUnitProvider.notifier)
                            .refreshItemUnits(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
                data: (itemUnits) => itemUnits.isEmpty
                    ? itemsAsync.maybeWhen(
                        data: (items) => items.isNotEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.inventory_2_outlined, size: 80, color: AppColors.textSecondary),
                                    const SizedBox(height: AppSpacing.lg),
                                    Text(
                                      'No item units found',
                                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.sm),
                                    Text(
                                      'Items exist but no units have been created yet.',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: AppSpacing.lg),
                                    ElevatedButton.icon(
                                      onPressed: _createUnitsForExistingItems,
                                      icon: const Icon(Icons.add),
                                      label: const Text('Create Item Units'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        foregroundColor: AppColors.onPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.inventory_2_outlined, size: 80, color: AppColors.textSecondary),
                                    const SizedBox(height: AppSpacing.lg),
                                    Text(
                                      'No item units found',
                                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.sm),
                                    Text(
                                      'Add items first to create item units for RFID tagging.',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                        orElse: () => const Center(child: CircularProgressIndicator()),
                      )
                    : itemsAsync.when(
                        data: (items) => RefreshIndicator(
                          onRefresh: () => ref.read(itemUnitProvider.notifier).refreshItemUnits(),
                          child: _buildItemUnitsList(_getFilteredItemUnits(itemUnits), items),
                        ),
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (error, stack) => Center(child: Text('Error loading items: $error')),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemUnitsList(List<db.ItemUnit> itemUnits, List<models.Item> items) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: itemUnits.length,
      itemBuilder: (context, index) {
        final unit = itemUnits[index];
        final item = items.firstWhere((i) => i.id == unit.itemId);
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: _buildItemUnitCard(unit, item),
        );
      },
    );
  }

  Widget _buildItemUnitCard(db.ItemUnit unit, models.Item item) {
    final hasRFID = unit.serialNo.isNotEmpty;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: hasRFID ? AppColors.success.withValues(alpha: 0.1) : AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Icon(
                  hasRFID ? Icons.nfc : Icons.nfc_outlined,
                  color: hasRFID ? AppColors.success : AppColors.warning,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${item.name} - Unit ${unit.id}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      hasRFID ? 'RFID: ${unit.serialNo}' : 'RFID: Not Assigned',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: hasRFID ? AppColors.success : AppColors.warning,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _assignRFID(unit),
                icon: const Icon(Icons.nfc),
                label: Text(hasRFID ? 'Update RFID' : 'Assign RFID'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}