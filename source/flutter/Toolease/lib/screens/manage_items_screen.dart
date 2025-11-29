import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/item_provider.dart';
import '../providers/storage_provider.dart';
import '../models/item.dart' as models;
import '../core/design_system.dart';
import '../shared/widgets/app_card.dart';

class ManageItemsScreen extends ConsumerStatefulWidget {
  const ManageItemsScreen({super.key});

  @override
  ConsumerState<ManageItemsScreen> createState() => _ManageItemsScreenState();
}

class _ManageItemsScreenState extends ConsumerState<ManageItemsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int? _selectedStorageId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<models.Item> _getFilteredItems(List<models.Item> items) {
    var filtered = items;

    // Filter by storage if selected
    if (_selectedStorageId != null) {
      filtered = filtered
          .where((item) => item.storageId == _selectedStorageId)
          .toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((item) {
        return item.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (item.description?.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ??
                false);
      }).toList();
    }

    return filtered;
  }

  Future<void> _showItemDialog({models.Item? item}) async {
    final nameController = TextEditingController(text: item?.name ?? '');
    final descriptionController = TextEditingController(
      text: item?.description ?? '',
    );
    final totalQuantityController = TextEditingController(
      text: item?.totalQuantity.toString() ?? '',
    );
    final availableQuantityController = TextEditingController(
      text: item?.availableQuantity.toString() ?? '',
    );
    final serialNoController = TextEditingController(text: item?.serialNo ?? '');
    int? selectedStorageId = item?.storageId;
    final formKey = GlobalKey<FormState>();

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        final storagesAsync = ref.watch(storageNotifierProvider);

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(item == null ? 'Add Item' : 'Edit Item'),
              contentPadding: const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 0.0),
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 40.0,
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: 'Item Name',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter item name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: descriptionController,
                          decoration: const InputDecoration(
                            labelText: 'Description',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 16),
                        storagesAsync.when(
                          loading: () => const CircularProgressIndicator(),
                          error: (_, __) =>
                              const Text('Error loading storages'),
                          data: (storages) => DropdownButtonFormField<int>(
                            value: selectedStorageId,
                            decoration: const InputDecoration(
                              labelText: 'Storage Location',
                              border: OutlineInputBorder(),
                            ),
                            items: storages
                                .map(
                                  (storage) => DropdownMenuItem<int>(
                                    value: storage.id,
                                    child: Text(storage.name),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedStorageId = value;
                              });
                            },
                            validator: (value) {
                              if (value == null) {
                                return 'Please select a storage location';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: totalQuantityController,
                          decoration: const InputDecoration(
                            labelText: 'Total Quantity',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter total quantity';
                            }
                            final quantity = int.tryParse(value);
                            if (quantity == null || quantity <= 0) {
                              return 'Please enter a valid quantity';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: availableQuantityController,
                          decoration: const InputDecoration(
                            labelText: 'Available Quantity',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter available quantity';
                            }
                            final quantity = int.tryParse(value);
                            if (quantity == null || quantity < 0) {
                              return 'Please enter a valid quantity';
                            }
                            final totalQuantity =
                                int.tryParse(totalQuantityController.text) ?? 0;
                            if (quantity > totalQuantity) {
                              return 'Available quantity cannot exceed total quantity';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: serialNoController,
                          decoration: const InputDecoration(
                            labelText: 'Serial Number',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(
                          height: 24,
                        ), // Extra spacing for keyboard
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate() &&
                        selectedStorageId != null) {
                      try {
                        if (item == null) {
                          // Add new item
                          final newItem = models.Item(
                            id: 0,
                            name: nameController.text.trim(),
                            description:
                                descriptionController.text.trim().isEmpty
                                ? null
                                : descriptionController.text.trim(),
                            storageId: selectedStorageId!,
                            totalQuantity: int.parse(
                              totalQuantityController.text,
                            ),
                            availableQuantity: int.parse(
                              availableQuantityController.text,
                            ),
                            serialNo: serialNoController.text.trim().isEmpty
                                ? null
                                : serialNoController.text.trim(),
                            createdAt: DateTime.now(),
                          );
                          await ref
                              .read(itemNotifierProvider.notifier)
                              .addItem(newItem);
                        } else {
                          // Update existing item
                          final updatedItem = item.copyWith(
                            name: nameController.text.trim(),
                            description:
                                descriptionController.text.trim().isEmpty
                                ? null
                                : descriptionController.text.trim(),
                            storageId: selectedStorageId!,
                            totalQuantity: int.parse(
                              totalQuantityController.text,
                            ),
                            availableQuantity: int.parse(
                              availableQuantityController.text,
                            ),
                            serialNo: serialNoController.text.trim().isEmpty
                                ? null
                                : serialNoController.text.trim(),
                          );
                          await ref
                              .read(itemNotifierProvider.notifier)
                              .updateItem(updatedItem);
                        }

                        if (context.mounted) {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                item == null
                                    ? 'Item added successfully!'
                                    : 'Item updated successfully!',
                              ),
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text('Error: $e')));
                        }
                      }
                    }
                  },
                  child: Text(item == null ? 'Add' : 'Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _confirmDelete(models.Item item) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Item'),
          content: Text('Are you sure you want to delete "${item.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                try {
                  await ref
                      .read(itemNotifierProvider.notifier)
                      .deleteItem(item.id);
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Item deleted successfully!'),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error deleting item: $e')),
                    );
                  }
                }
              },
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(itemNotifierProvider);
    final storagesAsync = ref.watch(storageNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text(
          'Manage Items',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_outlined),
            onPressed: () => _showItemDialog(),
            tooltip: 'Add New Item',
          ),
        ],
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
                      'Inventory Management',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Manage your inventory items and stock levels',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Filters and Search
                    _buildFiltersSection(storagesAsync),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Items List - Real-time data from StateNotifier
            Expanded(
              child: itemsAsync.when(
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
                            .read(itemNotifierProvider.notifier)
                            .refreshItems(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
                data: (items) {
                  final filteredItems = _getFilteredItems(items);
                  return RefreshIndicator(
                    onRefresh: () =>
                        ref.read(itemNotifierProvider.notifier).refreshItems(),
                    child: filteredItems.isEmpty
                        ? _buildEmptyState()
                        : _buildItemsList(filteredItems),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltersSection(AsyncValue storagesAsync) {
    return AppCard(
      variant: AppCardVariant.outlined,
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.filter_list_outlined, color: AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Filters & Search',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Storage Filter
          storagesAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
            error: (_, __) => Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: AppColors.error),
                  const SizedBox(width: AppSpacing.sm),
                  const Text('Error loading storages'),
                ],
              ),
            ),
            data: (storages) => DropdownButtonFormField<int?>(
              value: _selectedStorageId,
              decoration: InputDecoration(
                labelText: 'Filter by Storage',
                prefixIcon: Icon(
                  Icons.storage_outlined,
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
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  borderSide: BorderSide(color: AppColors.primary),
                ),
              ),
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('All Storages'),
                ),
                ...storages.map(
                  (storage) => DropdownMenuItem<int?>(
                    value: storage.id,
                    child: Text(storage.name),
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedStorageId = value;
                });
              },
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Search Bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search items by name or description...',
              prefixIcon: Icon(
                Icons.search_outlined,
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
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                borderSide: BorderSide(color: AppColors.primary),
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
    );
  }

  Widget _buildEmptyState() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.inventory_2_outlined,
                        size: 64,
                        color: AppColors.textTertiary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      _searchQuery.isNotEmpty || _selectedStorageId != null
                          ? 'No items found'
                          : 'No items added yet',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      _searchQuery.isNotEmpty || _selectedStorageId != null
                          ? 'Try adjusting your search criteria or filters'
                          : 'Start by adding items to your inventory',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    if (_searchQuery.isEmpty && _selectedStorageId == null)
                      ElevatedButton.icon(
                        onPressed: () => _showItemDialog(),
                        icon: const Icon(Icons.add),
                        label: const Text('Add First Item'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.onPrimary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: AppSpacing.md,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildItemsList(List<models.Item> items) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: _buildItemCard(item),
        );
      },
    );
  }

  Widget _buildItemCard(models.Item item) {
    final stockLevel = item.totalQuantity > 0
        ? item.availableQuantity / item.totalQuantity
        : 0.0;
    final stockColor = stockLevel > 0.5
        ? AppColors.success
        : stockLevel > 0.2
        ? AppColors.warning
        : AppColors.error;

    return AppCard(
      onTap: () => _showItemDialog(item: item),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Icon(
                  Icons.inventory_2_outlined,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (item.description != null &&
                        item.description!.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        item.description!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    _showItemDialog(item: item);
                  } else if (value == 'delete') {
                    _confirmDelete(item);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, color: AppColors.info),
                        SizedBox(width: AppSpacing.sm),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, color: AppColors.error),
                        SizedBox(width: AppSpacing.sm),
                        Text('Delete'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Stock Information
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildStockMetric(
                    'Total',
                    '${item.totalQuantity}',
                    Icons.inventory_outlined,
                    AppColors.textPrimary,
                  ),
                ),
                Expanded(
                  child: _buildStockMetric(
                    'Available',
                    '${item.availableQuantity}',
                    Icons.check_circle_outline,
                    stockColor,
                  ),
                ),
                Expanded(
                  child: _buildStockMetric(
                    'Borrowed',
                    '${item.totalQuantity - item.availableQuantity}',
                    Icons.schedule_outlined,
                    AppColors.warning,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Additional Info
          Row(
            children: [
              Icon(Icons.access_time, size: 16, color: AppColors.textTertiary),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Added ${item.createdAt.toLocal().toString().split(' ')[0]}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textTertiary),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: stockColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                ),
                child: Text(
                  '${(stockLevel * 100).round()}% Available',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: stockColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStockMetric(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
