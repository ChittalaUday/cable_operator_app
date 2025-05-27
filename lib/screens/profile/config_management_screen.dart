import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/config_service.dart';

class ConfigManagementScreen extends StatefulWidget {
  const ConfigManagementScreen({super.key});

  @override
  State<ConfigManagementScreen> createState() => _ConfigManagementScreenState();
}

class _ConfigManagementScreenState extends State<ConfigManagementScreen>
    with SingleTickerProviderStateMixin {
  final ConfigService _configService = ConfigService();
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _addItem(String collection, Map<String, dynamic> data) async {
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection(collection).add(data);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item added successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateItem(
    String collection,
    String id,
    Map<String, dynamic> data,
  ) async {
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance
          .collection(collection)
          .doc(id)
          .update(data);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteItem(String collection, String id) async {
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection(collection).doc(id).update({
        'isActive': false,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showAddDialog(String collection, {Map<String, dynamic>? existingItem}) {
    final nameController = TextEditingController(text: existingItem?['name']);
    final amountController = TextEditingController(
      text: existingItem?['amount']?.toString() ?? '',
    );
    final daysController = TextEditingController(
      text: existingItem?['days']?.toString() ?? '',
    );

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(existingItem != null ? 'Edit Item' : 'Add New Item'),
            content: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a name';
                      }
                      return null;
                    },
                  ),
                  if (collection == 'packages') ...[
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: amountController,
                      decoration: const InputDecoration(
                        labelText: 'Amount',
                        border: OutlineInputBorder(),
                        prefixText: '₹',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter an amount';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid amount';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: daysController,
                      decoration: const InputDecoration(
                        labelText: 'Days',
                        border: OutlineInputBorder(),
                        suffixText: 'days',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter number of days';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    Navigator.pop(context);
                    final data = {
                      'name': nameController.text,
                      'isActive': true,
                    };
                    if (collection == 'packages') {
                      data['amount'] = double.parse(amountController.text);
                      data['days'] = int.parse(daysController.text);
                    }
                    if (existingItem != null) {
                      await _updateItem(collection, existingItem['id'], data);
                    } else {
                      await _addItem(collection, data);
                    }
                  }
                },
                child: Text(existingItem != null ? 'Update' : 'Add'),
              ),
            ],
          ),
    );
  }

  Widget _buildList(
    String collection,
    Stream<List<Map<String, dynamic>>> stream,
  ) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final items = snapshot.data!;
        if (items.isEmpty) {
          return const Center(child: Text('No items found'));
        }

        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                title: Text(item['name']),
                subtitle:
                    collection == 'packages'
                        ? Text('₹${item['amount']} • ${item['days']} days')
                        : null,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed:
                          () => _showAddDialog(collection, existingItem: item),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _deleteItem(collection, item['id']),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuration Management'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Categories'),
            Tab(text: 'Box Types'),
            Tab(text: 'Packages'),
          ],
        ),
      ),
      body: Stack(
        children: [
          TabBarView(
            controller: _tabController,
            children: [
              _buildList('categories', _configService.getCategories()),
              _buildList('boxTypes', _configService.getBoxTypes()),
              _buildList('packages', _configService.getPackages()),
            ],
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final collection =
              _tabController.index == 0
                  ? 'categories'
                  : _tabController.index == 1
                  ? 'boxTypes'
                  : 'packages';
          _showAddDialog(collection);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
