import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/database_provider.dart';
import '../providers/borrow_record_provider.dart';
import '../providers/websocket_connection_provider.dart';
import '../models/student.dart' as models;
import '../models/item.dart' as models;
import '../shared/rfid_scan_modal.dart';

class BorrowScreen extends ConsumerStatefulWidget {
  const BorrowScreen({super.key});

  @override
  ConsumerState<BorrowScreen> createState() => _BorrowScreenState();
}

class _BorrowScreenState extends ConsumerState<BorrowScreen> {
  final _studentIdController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  models.Student? _selectedStudent;
  final List<models.Item> _scannedItems = []; // Items in cart
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
      
      setState(() {
        _selectedStudent = student;
        _scannedItems.clear(); // Clear cart when changing student
      });

      if (student == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Student not found. Please register first.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Student found: ${student.name}'),
              backgroundColor: Colors.green,
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

  Future<void> _scanItem() async {
    if (_selectedStudent == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a student first'),
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
        customMessage: 'Scan item to borrow',
      );

      if (tagId == null) return;

      // Get item by serial number (RFID tag)
      final databaseService = ref.read(databaseServiceProvider);
      final item = await databaseService.getItemBySerialNo(tagId);

      if (item == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Item not found in system'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Check if item is available
      if (item.status != models.ItemStatus.available) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Item is ${item.status.displayName}'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Check if already in cart
      if (_scannedItems.any((i) => i.id == item.id)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Item already in cart'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Add to cart
      setState(() {
        _scannedItems.add(item);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added: ${item.toolName}'),
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

  void _removeItem(models.Item item) {
    setState(() {
      _scannedItems.removeWhere((i) => i.id == item.id);
    });
  }

  Future<void> _confirmBorrow() async {
    if (_selectedStudent == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a student'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_scannedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please scan at least one item'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Borrow'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Student: ${_selectedStudent!.name}'),
            Text('ID: ${_selectedStudent!.studentId}'),
            const SizedBox(height: 16),
            Text(
              'Items (${_scannedItems.length}):',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ..._scannedItems.map((item) => Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 4),
              child: Text('• ${item.toolName} (${item.serialNo})'),
            )),
          ],
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
      // Create borrow record
      final itemIds = _scannedItems.map((item) => item.id).toList();
      await ref.read(borrowRecordNotifierProvider.notifier).createBorrowRecord(
        studentId: _selectedStudent!.id,
        itemIds: itemIds,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Successfully borrowed ${_scannedItems.length} item(s)',
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Reset form
        setState(() {
          _selectedStudent = null;
          _scannedItems.clear();
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Borrow Items'),
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
                        child: Row(
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
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Scan Item Button
          if (_selectedStudent != null) ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _scanItem,
                  icon: const Icon(Icons.nfc, size: 28),
                  label: const Text(
                    'Scan Item',
                    style: TextStyle(fontSize: 18),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ),
            ),
          ],

          // Scanned Items Cart
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Cart (${_scannedItems.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_scannedItems.isNotEmpty)
                  TextButton.icon(
                    onPressed: _isProcessing
                        ? null
                        : () {
                            setState(() {
                              _scannedItems.clear();
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
            child: _scannedItems.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shopping_cart_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _selectedStudent == null
                              ? 'Select a student to start'
                              : 'Scan items to add to cart',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _scannedItems.length,
                    itemBuilder: (context, index) {
                      final item = _scannedItems[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.green,
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
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: _isProcessing
                                ? null
                                : () => _removeItem(item),
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Confirm Button
          if (_scannedItems.isNotEmpty)
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
                  onPressed: _isProcessing ? null : _confirmBorrow,
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
                        : 'Confirm Borrow (${_scannedItems.length} items)',
                    style: const TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    backgroundColor: Colors.green,
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
