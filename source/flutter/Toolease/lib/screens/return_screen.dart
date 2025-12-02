import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/database_provider.dart';
import '../providers/borrow_record_provider.dart';
import '../providers/websocket_connection_provider.dart';
import '../models/student.dart' as models;
import '../models/borrow_record.dart' as models;
import '../models/item.dart' as models;
import '../shared/rfid_scan_modal.dart';

class ReturnScreen extends ConsumerStatefulWidget {
  const ReturnScreen({super.key});

  @override
  ConsumerState<ReturnScreen> createState() => _ReturnScreenState();
}

class _ReturnScreenState extends ConsumerState<ReturnScreen> {
  final _studentIdController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  models.Student? _selectedStudent;
  List<models.BorrowRecord> _activeBorrows = [];
  final Map<int, models.ItemCondition> _returnConditions = {}; // itemId -> condition
  final Set<int> _selectedItemIds = {}; // Items to return
  bool _isProcessing = false;

  @override
  void dispose() {
    _studentIdController.dispose();
    super.dispose();
  }

  Future<void> _searchStudent() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final databaseService = ref.read(databaseServiceProvider);
      final student = await databaseService.getStudentByStudentId(
        _studentIdController.text.trim(),
      );
      
      if (student != null) {
        final activeBorrows = await databaseService.getActiveBorrowsByStudent(
          student.id,
        );
        
        setState(() {
          _selectedStudent = student;
          _activeBorrows = activeBorrows;
          _selectedItemIds.clear();
          _returnConditions.clear();
        });

        if (activeBorrows.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No active borrows for this student'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      } else {
        setState(() {
          _selectedStudent = null;
          _activeBorrows = [];
          _selectedItemIds.clear();
          _returnConditions.clear();
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Student not found'),
              backgroundColor: Colors.red,
            ),
          );
        }
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

  Future<void> _scanItemForReturn() async {
    if (_selectedStudent == null || _activeBorrows.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please search for a student with active borrows'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final websocketService = ref.read(websocketServiceProvider);
      final tagId = await RFIDScanModal.show(
        context: context,
        websocketService: websocketService,
        customMessage: 'Scan item RFID tag',
      );

      if (tagId == null) return;

      // Find the item in active borrows
      models.Item? itemToReturn;
      models.BorrowRecord? borrowRecord;
      
      for (final record in _activeBorrows) {
        for (final borrowItem in record.items.where((i) => i.returnedAt == null)) {
          // Get the actual item details
          final databaseService = ref.read(databaseServiceProvider);
          final item = await databaseService.getItemById(borrowItem.itemId);
          
          if (item?.serialNo == tagId) {
            itemToReturn = item;
            borrowRecord = record;
            break;
          }
        }
        if (itemToReturn != null) break;
      }

      if (itemToReturn == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Item not found in this student\'s borrows'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Check if already selected
      if (_selectedItemIds.contains(itemToReturn.id)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Item already selected for return'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Ask for condition
      final condition = await _showConditionDialog(itemToReturn);
      if (condition == null) return;

      // Add to return list
      setState(() {
        _selectedItemIds.add(itemToReturn!.id);
        _returnConditions[itemToReturn.id] = condition;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added: ${itemToReturn.toolName}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 1),
          ),
        );
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

  Future<models.ItemCondition?> _showConditionDialog(models.Item item) async {
    return showDialog<models.ItemCondition>(
      context: context,
      builder: (context) => _ConditionDialog(item: item),
    );
  }

  String _getConditionDisplayName(models.ItemCondition condition) {
    switch (condition) {
      case models.ItemCondition.good:
        return 'Good';
      case models.ItemCondition.damaged:
        return 'Damaged';
      case models.ItemCondition.lost:
        return 'Lost';
    }
  }

  String _getConditionDescription(models.ItemCondition condition) {
    switch (condition) {
      case models.ItemCondition.good:
        return 'Item in good condition';
      case models.ItemCondition.damaged:
        return 'Item has damage';
      case models.ItemCondition.lost:
        return 'Item is lost';
    }
  }

  Color _getConditionColor(models.ItemCondition condition) {
    switch (condition) {
      case models.ItemCondition.good:
        return Colors.green;
      case models.ItemCondition.damaged:
        return Colors.orange;
      case models.ItemCondition.lost:
        return Colors.red;
    }
  }

  void _removeItem(int itemId) {
    setState(() {
      _selectedItemIds.remove(itemId);
      _returnConditions.remove(itemId);
    });
  }

  Future<void> _confirmReturn() async {
    if (_selectedItemIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please scan at least one item to return'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Group items by borrow record and prepare return data
    final Map<int, List<({int borrowItemId, models.ItemCondition condition})>> returnsByRecord = {};
    
    for (final itemId in _selectedItemIds) {
      for (final record in _activeBorrows) {
        try {
          final borrowItem = record.items.firstWhere(
            (bi) => bi.itemId == itemId && bi.returnedAt == null,
          );
          
          if (!returnsByRecord.containsKey(record.id)) {
            returnsByRecord[record.id] = [];
          }
          
          returnsByRecord[record.id]!.add((
            borrowItemId: borrowItem.id,
            condition: _returnConditions[itemId] ?? models.ItemCondition.good,
          ));
          break;
        } catch (e) {
          continue;
        }
      }
    }

    // Build confirmation items list
    final confirmationItems = <Widget>[];
    for (final itemId in _selectedItemIds) {
      final databaseService = ref.read(databaseServiceProvider);
      final item = await databaseService.getItemById(itemId);
      final condition = _returnConditions[itemId]!;
      
      confirmationItems.add(
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 4),
          child: Row(
            children: [
              Expanded(
                child: Text('• ${item?.toolName ?? 'Unknown'} (${item?.serialNo})'),
              ),
              Chip(
                label: Text(
                  _getConditionDisplayName(condition),
                  style: const TextStyle(fontSize: 12),
                ),
                backgroundColor: _getConditionColor(condition),
                labelStyle: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      );
    }

    // Show confirmation
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Return'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Student: ${_selectedStudent!.name}'),
              Text('ID: ${_selectedStudent!.studentId}'),
              const SizedBox(height: 16),
              Text(
                'Returning ${_selectedItemIds.length} item(s):',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...confirmationItems,
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // Process returns for each borrow record
      for (final entry in returnsByRecord.entries) {
        await ref.read(borrowRecordNotifierProvider.notifier).returnItems(
          borrowRecordId: entry.key,
          itemReturns: entry.value,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Successfully returned ${_selectedItemIds.length} item(s)',
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Reset form
        setState(() {
          _selectedStudent = null;
          _activeBorrows = [];
          _selectedItemIds.clear();
          _returnConditions.clear();
          _studentIdController.clear();
        });
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
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get all borrowed items (not yet returned)
    final borrowedItems = <models.Item>[];
    for (final record in _activeBorrows) {
      for (final borrowItem in record.items.where((i) => i.returnedAt == null)) {
        // We'll need to fetch item details - this is a simplified version
        // In real implementation, we'd use FutureBuilder or cache
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Return Items'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Student Selection Section
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.surface,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Student Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _studentIdController,
                          decoration: const InputDecoration(
                            labelText: 'Student ID',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person),
                          ),
                          enabled: !_isProcessing,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter student ID';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: _isProcessing ? null : _searchStudent,
                        icon: const Icon(Icons.search),
                        label: const Text('Search'),
                      ),
                    ],
                  ),
                  if (_selectedStudent != null) ...[
                    const SizedBox(height: 16),
                    Card(
                      color: Colors.green.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.check_circle, color: Colors.green),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _selectedStudent!.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Text(
                                        'ID: ${_selectedStudent!.studentId}',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (_activeBorrows.isNotEmpty) ...[
                              const Divider(height: 24),
                              Text(
                                'Active Borrows: ${_activeBorrows.length} record(s)',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              ..._activeBorrows.map((record) {
                                final unreturned = record.items
                                    .where((i) => i.returnedAt == null)
                                    .length;
                                return Padding(
                                  padding: const EdgeInsets.only(left: 8, bottom: 4),
                                  child: Text(
                                    '• ${unreturned} item(s) from ${record.borrowedAt.day}/${record.borrowedAt.month}/${record.borrowedAt.year}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Scan Item Button
          if (_selectedStudent != null && _activeBorrows.isNotEmpty) ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _scanItemForReturn,
                  icon: const Icon(Icons.nfc, size: 28),
                  label: const Text(
                    'Scan Item to Return',
                    style: TextStyle(fontSize: 18),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ),
            ),
          ],

          // Selected Items for Return
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Items to Return (${_selectedItemIds.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_selectedItemIds.isNotEmpty)
                  TextButton.icon(
                    onPressed: _isProcessing
                        ? null
                        : () {
                            setState(() {
                              _selectedItemIds.clear();
                              _returnConditions.clear();
                            });
                          },
                    icon: const Icon(Icons.clear_all),
                    label: const Text('Clear All'),
                  ),
              ],
            ),
          ),
          const Divider(),

          // Items List
          Expanded(
            child: _selectedItemIds.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.assignment_return_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _selectedStudent == null
                              ? 'Search for a student to start'
                              : _activeBorrows.isEmpty
                                  ? 'No active borrows'
                                  : 'Scan items to return',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                      ],
                    ),
                  )
                : FutureBuilder<List<models.Item?>>(
                    future: Future.wait(
                      _selectedItemIds.map((id) =>
                        ref.read(databaseServiceProvider).getItemById(id),
                      ),
                    ),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final items = snapshot.data!;
                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          if (item == null) return const SizedBox();
                          
                          final condition = _returnConditions[item.id]!;
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _getConditionColor(condition),
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              title: Text(
                                item.toolName,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${item.model} | ${item.productNo}'),
                                  Text(
                                    'Serial: ${item.serialNo}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Chip(
                                    label: Text(
                                      _getConditionDisplayName(condition),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.white,
                                      ),
                                    ),
                                    backgroundColor: _getConditionColor(condition),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: _isProcessing
                                        ? null
                                        : () => _removeItem(item.id),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),

          // Confirm Button
          if (_selectedItemIds.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _confirmReturn,
                  icon: _isProcessing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.check_circle),
                  label: Text(
                    _isProcessing
                        ? 'Processing...'
                        : 'Confirm Return (${_selectedItemIds.length} items)',
                    style: const TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Stateful dialog for selecting item condition
class _ConditionDialog extends StatefulWidget {
  final models.Item item;

  const _ConditionDialog({required this.item});

  @override
  State<_ConditionDialog> createState() => _ConditionDialogState();
}

class _ConditionDialogState extends State<_ConditionDialog> {
  models.ItemCondition _selectedCondition = models.ItemCondition.good;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Item Condition: ${widget.item.toolName}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Serial: ${widget.item.serialNo}'),
          const SizedBox(height: 16),
          const Text(
            'Select condition:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...models.ItemCondition.values.map((condition) => RadioListTile<models.ItemCondition>(
            title: Text(_getConditionDisplayName(condition)),
            subtitle: Text(_getConditionDescription(condition)),
            value: condition,
            groupValue: _selectedCondition,
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedCondition = value;
                });
              }
            },
            contentPadding: EdgeInsets.zero,
          )),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _selectedCondition),
          child: const Text('Confirm'),
        ),
      ],
    );
  }

  String _getConditionDisplayName(models.ItemCondition condition) {
    switch (condition) {
      case models.ItemCondition.good:
        return 'Good';
      case models.ItemCondition.damaged:
        return 'Damaged';
      case models.ItemCondition.lost:
        return 'Lost';
    }
  }

  String _getConditionDescription(models.ItemCondition condition) {
    switch (condition) {
      case models.ItemCondition.good:
        return 'Item in good condition';
      case models.ItemCondition.damaged:
        return 'Item has damage';
      case models.ItemCondition.lost:
        return 'Item is lost';
    }
  }
}
