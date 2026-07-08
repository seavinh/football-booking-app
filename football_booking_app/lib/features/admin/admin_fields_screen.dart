import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
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

  Widget _buildFieldDialogTextField({
    required TextEditingController controller,
    required String labelText,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: labelText,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  void _showAddFieldDialog() {
    final nameController = TextEditingController();
    final addressController = TextEditingController();
    final priceController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text(
          'Add Football Field',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildFieldDialogTextField(controller: nameController, labelText: 'Name'),
            _buildFieldDialogTextField(controller: addressController, labelText: 'Address'),
            _buildFieldDialogTextField(
              controller: priceController,
              labelText: 'Price per hour (\$)',
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
            child: const Text('Add Field'),
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
        backgroundColor: const Color(0xFF1E293B),
        title: Text(
          'Edit Football Field',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildFieldDialogTextField(controller: nameController, labelText: 'Name'),
            _buildFieldDialogTextField(controller: addressController, labelText: 'Address'),
            _buildFieldDialogTextField(
              controller: priceController,
              labelText: 'Price per hour (\$)',
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
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  void _deleteField(FootballField field) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text(
          'Delete Field',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to delete "${field.name}"?',
          style: GoogleFonts.outfit(color: Colors.white70),
        ),
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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'MANAGE FIELDS',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.go('/admin'),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddFieldDialog,
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add, size: 28),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF10B981),
              ),
            )
          : _fields.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.sports_soccer, size: 64, color: Colors.white10),
                      const SizedBox(height: 12),
                      Text(
                        'No fields created yet',
                        style: GoogleFonts.outfit(color: Colors.white54, fontSize: 16),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: const Color(0xFF10B981),
                  onRefresh: _loadFields,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    itemCount: _fields.length,
                    itemBuilder: (context, index) {
                      final field = _fields[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: theme.colorScheme.primary.withOpacity(0.12), width: 1.5),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: theme.colorScheme.primary.withOpacity(0.15),
                            child: Icon(Icons.sports_soccer, color: theme.colorScheme.primary),
                          ),
                          title: Text(
                            field.name,
                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '${field.address ?? "No address"} • \$${field.pricePerHour?.toStringAsFixed(0) ?? "0"}/hr',
                              style: GoogleFonts.outfit(color: Colors.white54, fontSize: 13),
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit_outlined, color: theme.colorScheme.secondary),
                                onPressed: () => _showEditFieldDialog(field),
                                tooltip: 'Edit Field',
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                onPressed: () => _deleteField(field),
                                tooltip: 'Delete Field',
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

