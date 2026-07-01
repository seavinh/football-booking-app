import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/football_field.dart';
import '../../services/supabase_service.dart';
import '../../widgets/field_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  List<FootballField> _fields = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFields();
  }

  Future<void> _loadFields() async {
    try {
      final fields = await _supabaseService.getFootballFields();
      setState(() {
        _fields = fields;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Football Fields'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => context.push('/my-bookings'),
            tooltip: 'My Bookings',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _supabaseService.signOut();
              if (mounted) {
                context.go('/login');
              }
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadFields,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadFields,
                  child: _fields.isEmpty
                      ? const Center(
                          child: Text('No football fields available'),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _fields.length,
                          itemBuilder: (context, index) {
                            return FieldCard(field: _fields[index]);
                          },
                        ),
                ),
    );
  }
}
