import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
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

  // Search & Filter State
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _activeFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  List<FootballField> _getFilteredFields() {
    return _fields.where((field) {
      // 1. Filter by search query
      final matchesSearch = field.name.toLowerCase().contains(_searchQuery) ||
          (field.address?.toLowerCase().contains(_searchQuery) ?? false);

      // 2. Filter by active filter tag
      bool matchesTag = true;
      if (_activeFilter != 'All') {
        final nameLower = field.name.toLowerCase();
        if (_activeFilter == 'Indoor') {
          matchesTag = nameLower.contains('indoor');
        } else if (_activeFilter == '5 vs 5') {
          matchesTag = !nameLower.contains('7') && !nameLower.contains('11');
        } else if (_activeFilter == '7 vs 7') {
          matchesTag = nameLower.contains('7') || nameLower.contains('seven');
        } else if (_activeFilter == 'Grass') {
          matchesTag = !nameLower.contains('turf') && !nameLower.contains('artificial');
        }
      }

      return matchesSearch && matchesTag;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filteredFields = _getFilteredFields();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'PITCHMASTER',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
        actions: [
          if (_profile?.isAdmin == true)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings_outlined, size: 26),
              onPressed: () => context.push('/admin'),
              tooltip: 'Admin Dashboard',
            ),
          IconButton(
            icon: const Icon(Icons.receipt_long_outlined, size: 24),
            onPressed: () => context.push(_profile?.isAdmin == true ? '/admin/bookings' : '/my-bookings'),
            tooltip: _profile?.isAdmin == true ? 'All Bookings' : 'My Bookings',
          ),
          IconButton(
            icon: const Icon(Icons.logout_outlined, size: 24),
            onPressed: () async {
              await _supabaseService.signOut();
              if (mounted) {
                context.go('/login');
              }
            },
            tooltip: 'Logout',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF10B981),
              ),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.cloud_off, size: 64, color: Colors.white24),
                        const SizedBox(height: 16),
                        Text(
                          'Something went wrong',
                          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(_error!, style: const TextStyle(color: Colors.redAccent), textAlign: TextAlign.center),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _loadData,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  color: const Color(0xFF10B981),
                  backgroundColor: const Color(0xFF1E293B),
                  onRefresh: _loadData,
                  child: CustomScrollView(
                    slivers: [
                      // Header Welcoming Banner
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor: theme.colorScheme.primary.withOpacity(0.15),
                                    child: Icon(
                                      _profile?.isAdmin == true ? Icons.admin_panel_settings : Icons.sports_soccer,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Welcome back,',
                                        style: GoogleFonts.outfit(
                                          fontSize: 14,
                                          color: Colors.white54,
                                        ),
                                      ),
                                      Text(
                                        _profile?.fullName != null && _profile!.fullName!.isNotEmpty
                                            ? _profile!.fullName!
                                            : (_profile?.isAdmin == true ? 'Manager' : 'Player'),
                                        style: GoogleFonts.outfit(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'Find & Book Your Next Field',
                                style: GoogleFonts.outfit(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.5,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              // Glowing Search Bar
                              TextField(
                                controller: _searchController,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  hintText: 'Search fields by name or location...',
                                  prefixIcon: Icon(Icons.search, color: theme.colorScheme.primary.withOpacity(0.7)),
                                  suffixIcon: _searchQuery.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.clear, color: Colors.white54),
                                          onPressed: () => _searchController.clear(),
                                        )
                                      : null,
                                ),
                              ),
                              const SizedBox(height: 20),
                              
                              // Horizontal scrollable filter chips
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    'All',
                                    'Indoor',
                                    '5 vs 5',
                                    '7 vs 7',
                                    'Grass',
                                  ].map((filter) {
                                    final isActive = _activeFilter == filter;
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 10),
                                      child: ChoiceChip(
                                        label: Text(
                                          filter,
                                          style: GoogleFonts.outfit(
                                            color: isActive ? Colors.white : Colors.white70,
                                            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                                          ),
                                        ),
                                        selected: isActive,
                                        onSelected: (selected) {
                                          if (selected) {
                                            setState(() {
                                              _activeFilter = filter;
                                            });
                                          }
                                        },
                                        selectedColor: theme.colorScheme.primary,
                                        backgroundColor: theme.colorScheme.surface,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          side: BorderSide(
                                            color: isActive
                                                ? theme.colorScheme.primary
                                                : theme.colorScheme.primary.withOpacity(0.15),
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // List of Fields
                      filteredFields.isEmpty
                          ? SliverFillRemaining(
                              hasScrollBody: false,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.sports_soccer, size: 64, color: Colors.white10),
                                    const SizedBox(height: 12),
                                    Text(
                                      'No matching fields found',
                                      style: GoogleFonts.outfit(
                                        color: Colors.white54,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : SliverPadding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              sliver: SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    return FieldCard(field: filteredFields[index]);
                                  },
                                  childCount: filteredFields.length,
                                ),
                              ),
                            ),
                    ],
                  ),
                ),
    );
  }
}

