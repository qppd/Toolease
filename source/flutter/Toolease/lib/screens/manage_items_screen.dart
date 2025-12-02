import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/item_provider.dart';
import '../providers/storage_provider.dart';
import '../providers/websocket_connection_provider.dart';
import '../models/item.dart' as models;
import '../shared/rfid_scan_modal.dart';

class ManageItemsScreen extends ConsumerStatefulWidget {
  const ManageItemsScreen({super.key});

  @override
  ConsumerState<ManageItemsScreen> createState() => _ManageItemsScreenState();
}

class _ManageItemsScreenState extends ConsumerState<ManageItemsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int? _selectedStorageId;
  models.ItemStatus? _selectedStatus;

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

    // Filter by status if selected
    if (_selectedStatus != null) {
      filtered = filtered
          .where((item) => item.status == _selectedStatus)
          .toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((item) {
        return item.toolName.toLowerCase().contains(query) ||
            item.model.toLowerCase().contains(query) ||
            item.productNo.toLowerCase().contains(query) ||
            item.serialNo.toLowerCase().contains(query) ||
            (item.remarks?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    return filtered;
  }

  Future<void> _showAddItemDialog() async {
    final toolNameController = TextEditingController();
    final modelController = TextEditingController();
    final productNoController = TextEditingController();
    final serialNoController = TextEditingController();
    final remarksController = TextEditingController();
    final yearController = TextEditingController(text: DateTime.now().year.toString());
    int? selectedStorageId;
    final formKey = GlobalKey<FormState>();
    bool serialNoLocked = false;
    
    // Get Bluetooth service
    final websocketService = ref.read(websocketServiceProvider);

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add Item'),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: toolNameController,
                          decoration: const InputDecoration(
                            labelText: 'Tool Name *',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter tool name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: modelController,
                          decoration: const InputDecoration(
                            labelText: 'Model *',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter model';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: productNoController,
                          decoration: const InputDecoration(
                            labelText: 'Product No. *',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter product number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: serialNoController,
                                decoration: InputDecoration(
                                  labelText: 'Serial No. (RFID) *',
                                  border: const OutlineInputBorder(),
                                  enabled: !serialNoLocked,
                                ),
                                readOnly: true,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please scan RFID tag';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: serialNoLocked
                                  ? null
                                  : () async {
                                      final tagId = await RFIDScanModal.show(
                                        context: context,
                                        websocketService: websocketService,
                                        customMessage: 'Scan RFID tag for this item',
                                      );
                                      if (tagId != null) {
                                        setDialogState(() {
                                          serialNoController.text = tagId;
                                        });
                                      }
                                    },
                              icon: const Icon(Icons.nfc),
                              label: const Text('Scan'),
                            ),
                          ],
                        ),
                        if (serialNoLocked)
                          const Padding(
                            padding: EdgeInsets.only(top: 8, left: 12),
                            child: Text(
                              '🔒 Serial No. locked after saving',
                              style: TextStyle(
                                color: Colors.orange,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: remarksController,
                          decoration: const InputDecoration(
                            labelText: 'Remarks',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: yearController,
                          decoration: const InputDecoration(
                            labelText: 'Year *',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter year';
                            }
                            final year = int.tryParse(value.trim());
                            if (year == null || year < 1900 || year > 2100) {
                              return 'Please enter a valid year';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        Consumer(
                          builder: (context, ref, child) {
                            final storagesAsync = ref.watch(storageNotifierProvider);
                            return storagesAsync.when(
                              loading: () => const CircularProgressIndicator(),
                              error: (_, __) => const Text('Error loading storages'),
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
                                  setDialogState(() {
                                    selectedStorageId = value;
                                  });
                                },
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 24),
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
                    if (formKey.currentState!.validate()) {
                      try {
                        await ref.read(itemNotifierProvider.notifier).addItem(
                              toolName: toolNameController.text.trim(),
                              model: modelController.text.trim(),
                              productNo: productNoController.text.trim(),
                              serialNo: serialNoController.text.trim(),
                              remarks: remarksController.text.trim().isEmpty
                                  ? null
                                  : remarksController.text.trim(),
                              year: yearController.text.trim(),
                              storageId: selectedStorageId,
                            );
                        
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Item added successfully'),
                              backgroundColor: Colors.green,
                            ),
                          );
                          Navigator.of(dialogContext).pop();
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: ${e.toString()}'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(itemNotifierProvider);
    final storagesAsync = ref.watch(storageNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Items'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.surface,
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by name, model, product no, or serial no...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: storagesAsync.when(
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                        data: (storages) => DropdownButtonFormField<int>(
                          value: _selectedStorageId,
                          decoration: const InputDecoration(
                            labelText: 'Filter by Storage',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          items: [
                            const DropdownMenuItem<int>(
                              value: null,
                              child: Text('All Storages'),
                            ),
                            ...storages.map(
                              (storage) => DropdownMenuItem<int>(
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
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<models.ItemStatus>(
                        value: _selectedStatus,
                        decoration: const InputDecoration(
                          labelText: 'Filter by Status',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        items: [
                          const DropdownMenuItem<models.ItemStatus>(
                            value: null,
                            child: Text('All Statuses'),
                          ),
                          ...models.ItemStatus.values.map(
                            (status) => DropdownMenuItem<models.ItemStatus>(
                              value: status,
                              child: Text(status.displayName),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedStatus = value;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Items List
          Expanded(
            child: itemsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Error: ${error.toString()}'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.refresh(itemNotifierProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (items) {
                final filteredItems = _getFilteredItems(items);

                if (filteredItems.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No items found',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          items.isEmpty
                              ? 'Add your first item to get started'
                              : 'Try adjusting your filters',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredItems.length,
                  itemBuilder: (context, index) {
                    final item = filteredItems[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getStatusColor(item.status),
                          child: Icon(
                            _getStatusIcon(item.status),
                            color: Colors.white,
                          ),
                        ),
                        title: Text(
                          item.toolName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text('${item.model} | ${item.productNo}'),
                            Text('Serial: ${item.serialNo}'),
                            if (item.remarks != null && item.remarks!.isNotEmpty)
                              Text(
                                'Remarks: ${item.remarks}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                          ],
                        ),
                        trailing: Chip(
                          label: Text(
                            item.status.displayName,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                            ),
                          ),
                          backgroundColor: _getStatusColor(item.status),
                        ),
                        onTap: () => _showItemDetailsDialog(item),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddItemDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Item'),
      ),
    );
  }

  Color _getStatusColor(models.ItemStatus status) {
    switch (status) {
      case models.ItemStatus.available:
        return Colors.green;
      case models.ItemStatus.borrowed:
        return Colors.orange;
      case models.ItemStatus.lost:
        return Colors.red;
      case models.ItemStatus.damaged:
        return Colors.purple;
    }
  }

  IconData _getStatusIcon(models.ItemStatus status) {
    switch (status) {
      case models.ItemStatus.available:
        return Icons.check_circle;
      case models.ItemStatus.borrowed:
        return Icons.schedule;
      case models.ItemStatus.lost:
        return Icons.error;
      case models.ItemStatus.damaged:
        return Icons.build;
    }
  }

  void _showItemDetailsDialog(models.Item item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item.toolName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Model', item.model),
            _buildDetailRow('Product No.', item.productNo),
            _buildDetailRow('Serial No.', item.serialNo),
            if (item.remarks != null)
              _buildDetailRow('Remarks', item.remarks!),
            _buildDetailRow('Year', item.year),
            _buildDetailRow('Status', item.status.displayName),
            _buildDetailRow(
              'Created',
              '${item.createdAt.day}/${item.createdAt.month}/${item.createdAt.year}',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
