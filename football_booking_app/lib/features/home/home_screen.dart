import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/football_field.dart';
import '../../models/user_profile.dart';
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
  UserProfile? _profile;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        _supabaseService.getFootballFields(),
        _supabaseService.getProfile(),
      ]);
      setState(() {
        _fields = results[0] as List<FootballField>;
        _profile = results[1] as UserProfile;
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
          if (_profile?.isAdmin == true)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings),
              onPressed: () => context.push('/admin'),
              tooltip: 'Admin Panel',
            ),
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => context.push(_profile?.isAdmin == true ? '/admin/bookings' : '/my-bookings'),
            tooltip: _profile?.isAdmin == true ? 'All Bookings' : 'My Bookings',
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
                        onPressed: _loadData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
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
