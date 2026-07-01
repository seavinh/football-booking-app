import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/football_field.dart';
import '../../services/supabase_service.dart';

class AdminFieldsScreen extends StatefulWidget {
  const AdminFieldsScreen({super.key});

  @override
  State<AdminFieldsScreen> createState() => _AdminFieldsScreenState();
}

class _AdminFieldsScreenState extends State<AdminFieldsScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  List<FootballField> _fields = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFields();
  }

  Future<void> _loadFields() async {
    final fields = await _supabaseService.getFootballFields();
    setState(() {
      _fields = fields;
      _isLoading = false;
    });
  }

  void _showAddFieldDialog() {
    final nameController = TextEditingController();
    final addressController = TextEditingController();
    final priceController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Football Field'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: addressController,
              decoration: const InputDecoration(labelText: 'Address'),
            ),
            TextField(
              controller: priceController,
              decoration: const InputDecoration(labelText: 'Price per hour'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                await _supabaseService.addFootballField({
                  'name': nameController.text,
                  'address': addressController.text,
                  'price_per_hour': double.tryParse(priceController.text) ?? 0,
                });
                if (mounted) {
                  Navigator.pop(context);
                  _loadFields();
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditFieldDialog(FootballField field) {
    final nameController = TextEditingController(text: field.name);
    final addressController = TextEditingController(text: field.address ?? '');
    final priceController = TextEditingController(
      text: field.pricePerHour?.toString() ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Football Field'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: addressController,
              decoration: const InputDecoration(labelText: 'Address'),
            ),
            TextField(
              controller: priceController,
              decoration: const InputDecoration(labelText: 'Price per hour'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _supabaseService.updateFootballField(field.id, {
                'name': nameController.text,
                'address': addressController.text,
                'price_per_hour': double.tryParse(priceController.text) ?? 0,
              });
              if (mounted) {
                Navigator.pop(context);
                _loadFields();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _deleteField(FootballField field) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Field'),
        content: Text('Are you sure you want to delete "${field.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await _supabaseService.deleteFootballField(field.id);
              if (mounted) {
                Navigator.pop(context);
                _loadFields();
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Fields'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/admin'),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddFieldDialog,
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _fields.isEmpty
              ? const Center(child: Text('No football fields yet'))
              : RefreshIndicator(
                  onRefresh: _loadFields,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _fields.length,
                    itemBuilder: (context, index) {
                      final field = _fields[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: const Icon(Icons.sports_soccer),
                          title: Text(field.name),
                          subtitle: Text(
                            '${field.address ?? "No address"} • \$${field.pricePerHour?.toStringAsFixed(2) ?? "0"}/hr',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => _showEditFieldDialog(field),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteField(field),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
