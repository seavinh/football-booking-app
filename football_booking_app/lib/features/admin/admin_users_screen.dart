import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/user_profile.dart';
import '../../services/supabase_service.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  List<UserProfile> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final users = await _supabaseService.getAllProfiles();
    setState(() {
      _users = users.where((u) => u.isAdmin).toList();
      _isLoading = false;
    });
  }

  void _showRoleDialog(UserProfile user) {
    final isAdmin = user.isAdmin;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text(
          'Change Role',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        content: Text(
          isAdmin
              ? 'Demote "${user.fullName?.isNotEmpty == true ? user.fullName : user.id}" to regular user?'
              : 'Promote "${user.fullName?.isNotEmpty == true ? user.fullName : user.id}" to admin?',
          style: GoogleFonts.outfit(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isAdmin ? Colors.amber : const Color(0xFF10B981),
            ),
            onPressed: () async {
              final newRole = isAdmin ? 'user' : 'admin';
              await _supabaseService.updateProfileRole(user.id, newRole);
              if (context.mounted) {
                Navigator.pop(context);
                _loadUsers();
              }
            },
            child: Text(isAdmin ? 'Demote' : 'Promote'),
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
          'MANAGE USERS',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.go('/admin'),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF10B981),
              ),
            )
          : _users.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.people_outline, size: 64, color: Colors.white10),
                      const SizedBox(height: 12),
                      Text(
                        'No users found',
                        style: GoogleFonts.outfit(color: Colors.white54, fontSize: 16),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: const Color(0xFF10B981),
                  onRefresh: _loadUsers,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    itemCount: _users.length,
                    itemBuilder: (context, index) {
                      final user = _users[index];
                      final isAdmin = user.isAdmin;
                      final displayName = user.fullName?.isNotEmpty == true
                          ? '${user.fullName} (${user.id.substring(0, 8)})'
                          : 'No Name (${user.id.substring(0, 8)})';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isAdmin
                                ? Colors.amber.withValues(alpha: 0.3)
                                : theme.colorScheme.primary.withValues(alpha: 0.12),
                            width: 1.5,
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: isAdmin
                                ? Colors.amber.withValues(alpha: 0.15)
                                : theme.colorScheme.primary.withValues(alpha: 0.15),
                            child: Icon(
                              isAdmin ? Icons.admin_panel_settings : Icons.person,
                              color: isAdmin ? Colors.amber : theme.colorScheme.primary,
                            ),
                          ),
                          title: Text(
                            displayName,
                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (user.fullName?.isNotEmpty == true) ...[
                                  Text(
                                    'ID: ${user.id.substring(0, 8)}',
                                    style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12),
                                  ),
                                  const SizedBox(height: 4),
                                ],
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isAdmin
                                            ? Colors.amber.withValues(alpha: 0.15)
                                            : theme.colorScheme.primary.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        isAdmin ? 'Admin' : 'User',
                                        style: GoogleFonts.outfit(
                                          color: isAdmin ? Colors.amber : theme.colorScheme.primary,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          trailing: IconButton(
                            icon: Icon(
                              isAdmin ? Icons.arrow_downward : Icons.arrow_upward,
                              color: isAdmin ? Colors.amber : const Color(0xFF10B981),
                            ),
                            onPressed: () => _showRoleDialog(user),
                            tooltip: isAdmin ? 'Demote to User' : 'Promote to Admin',
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF10B981),
        onPressed: _showAddAdminDialog,
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
    );
  }

  void _showAddAdminDialog() {
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isAdding = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1E293B),
            title: Text('Add New Admin', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Full Name', labelStyle: TextStyle(color: Colors.white70)),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    TextFormField(
                      controller: phoneCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Phone', labelStyle: TextStyle(color: Colors.white70)),
                    ),
                    TextFormField(
                      controller: emailCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Email', labelStyle: TextStyle(color: Colors.white70)),
                      validator: (v) => !v!.contains('@') ? 'Invalid email' : null,
                    ),
                    TextFormField(
                      controller: passCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Password', labelStyle: TextStyle(color: Colors.white70)),
                      obscureText: true,
                      validator: (v) => v!.length < 6 ? 'Min 6 characters' : null,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
                onPressed: isAdding
                    ? null
                    : () async {
                        if (formKey.currentState!.validate()) {
                          setDialogState(() => isAdding = true);
                          try {
                            await _supabaseService.createAdminUser(
                              emailCtrl.text.trim(),
                              passCtrl.text,
                              nameCtrl.text.trim(),
                              phoneCtrl.text.trim(),
                            );
                            if (context.mounted) {
                              Navigator.pop(context);
                              _loadUsers();
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                            }
                          } finally {
                            if (context.mounted) {
                              setDialogState(() => isAdding = false);
                            }
                          }
                        }
                      },
                child: isAdding ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Add Admin'),
              ),
            ],
          );
        },
      ),
    );
  }
}
