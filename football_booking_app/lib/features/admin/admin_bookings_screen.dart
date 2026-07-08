import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/booking.dart';
import '../../services/supabase_service.dart';

enum SortOption { dateNewest, dateOldest, venueAZ, venueZA, status }

class AdminBookingsScreen extends StatefulWidget {
  const AdminBookingsScreen({super.key});

  @override
  State<AdminBookingsScreen> createState() => _AdminBookingsScreenState();
}

class _AdminBookingsScreenState extends State<AdminBookingsScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  List<Booking> _bookings = [];
  List<Booking> _filteredBookings = [];
  bool _isLoading = true;
  String? _error;

  String _searchQuery = '';
  String _statusFilter = 'all';
  SortOption _sortOption = SortOption.dateNewest;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBookings() async {
    try {
      final bookings = await _supabaseService.getAllBookings();
      setState(() {
        _bookings = bookings;
        _isLoading = false;
      });
      _applyFiltersAndSort();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _applyFiltersAndSort() {
    List<Booking> result = List.from(_bookings);

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      result = result.where((b) {
        final name = (b.fieldName ?? '').toLowerCase();
        final address = (b.fieldAddress ?? '').toLowerCase();
        return name.contains(query) || address.contains(query);
      }).toList();
    }

    if (_statusFilter != 'all') {
      result = result.where((b) => b.status == _statusFilter).toList();
    }

    switch (_sortOption) {
      case SortOption.dateNewest:
        result.sort((a, b) => b.bookingDate.compareTo(a.bookingDate));
        break;
      case SortOption.dateOldest:
        result.sort((a, b) => a.bookingDate.compareTo(b.bookingDate));
        break;
      case SortOption.venueAZ:
        result.sort((a, b) => (a.fieldName ?? '').compareTo(b.fieldName ?? ''));
        break;
      case SortOption.venueZA:
        result.sort((a, b) => (b.fieldName ?? '').compareTo(a.fieldName ?? ''));
        break;
      case SortOption.status:
        final statusOrder = {'pending': 0, 'confirmed': 1, 'cancelled': 2};
        result.sort((a, b) => (statusOrder[a.status] ?? 3).compareTo(statusOrder[b.status] ?? 3));
        break;
    }

    setState(() => _filteredBookings = result);
  }

  int _countByStatus(String status) {
    return _bookings.where((b) => b.status == status).length;
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'confirmed':
        return const Color(0xFF10B981);
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }

  void _showStatusDialog(Booking booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Update Status',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        content: Text(
          'Change status for ${booking.fieldName ?? "Unknown Field"}?',
          style: GoogleFonts.outfit(color: Colors.white70),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                onPressed: booking.status == 'confirmed'
                    ? null
                    : () async {
                        await _supabaseService.updateBookingStatus(booking.id, 'confirmed');
                        if (mounted) {
                          Navigator.pop(context);
                          _loadBookings();
                        }
                      },
                child: const Text('Confirm'),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                onPressed: booking.status == 'cancelled'
                    ? null
                    : () async {
                        await _supabaseService.updateBookingStatus(booking.id, 'cancelled');
                        if (mounted) {
                          Navigator.pop(context);
                          _loadBookings();
                        }
                      },
                child: const Text('Cancel'),
              ),
            ],
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: GoogleFonts.outfit(color: Colors.white54)),
          ),
        ],
      ),
    );
  }

  void _showBookingDetails(Booking booking) {
    final color = _statusColor(booking.status);
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    booking.fieldName ?? 'Unknown Field',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: color.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    booking.status.toUpperCase(),
                    style: GoogleFonts.outfit(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _detailRow(Icons.confirmation_number_outlined, 'Booking ID', booking.id.substring(0, 8).toUpperCase()),
            _detailRow(Icons.location_on_outlined, 'Location', booking.fieldAddress ?? 'N/A'),
            _detailRow(Icons.calendar_today_outlined, 'Date', DateFormat('EEEE, MMMM d, yyyy').format(booking.bookingDate)),
            _detailRow(Icons.access_time, 'Time', '${booking.startTime} - ${booking.endTime}'),
            _detailRow(Icons.person_outline, 'User ID', booking.userId.substring(0, 8).toUpperCase()),
            _detailRow(Icons.schedule, 'Booked On', DateFormat('MMM d, yyyy • HH:mm').format(booking.createdAt)),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _showStatusDialog(booking);
                    },
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: Text('Update Status', style: GoogleFonts.outfit()),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: const BorderSide(color: Colors.white24),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF10B981)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.outfit(fontSize: 12, color: Colors.white54),
                ),
                Text(
                  value,
                  style: GoogleFonts.outfit(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSortSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Sort By',
              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 16),
            _sortOptionTile('Date (Newest First)', SortOption.dateNewest),
            _sortOptionTile('Date (Oldest First)', SortOption.dateOldest),
            _sortOptionTile('Venue (A-Z)', SortOption.venueAZ),
            _sortOptionTile('Venue (Z-A)', SortOption.venueZA),
            _sortOptionTile('Status', SortOption.status),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _sortOptionTile(String title, SortOption option) {
    final isSelected = _sortOption == option;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: GoogleFonts.outfit(
          color: isSelected ? const Color(0xFF10B981) : Colors.white70,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: Color(0xFF10B981))
          : const Icon(Icons.radio_button_unchecked, color: Colors.white38),
      onTap: () {
        setState(() => _sortOption = option);
        _applyFiltersAndSort();
        Navigator.pop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'ALL BOOKINGS',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.go('/admin'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: _showSortSheet,
            tooltip: 'Sort',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF10B981)),
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!, style: const TextStyle(color: Colors.redAccent)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadBookings,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: const Color(0xFF10B981),
                  onRefresh: _loadBookings,
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                          child: _buildStatsSummary(),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                          child: _buildSearchBar(),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                          child: _buildFilterChips(),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${_filteredBookings.length} booking${_filteredBookings.length != 1 ? 's' : ''} found',
                                style: GoogleFonts.outfit(color: Colors.white54, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_filteredBookings.isEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 60),
                            child: Center(
                              child: Column(
                                children: [
                                  const Icon(Icons.search_off, size: 56, color: Colors.white12),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No bookings match your filters',
                                    style: GoogleFonts.outfit(color: Colors.white54, fontSize: 15),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                          sliver: SliverList.builder(
                            itemCount: _filteredBookings.length,
                            itemBuilder: (context, index) {
                              final booking = _filteredBookings[index];
                              final color = _statusColor(booking.status);

                              return GestureDetector(
                                onTap: () => _showBookingDetails(booking),
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surface,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              booking.fieldName ?? 'Unknown Field',
                                              style: GoogleFonts.outfit(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                                fontSize: 16,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          _buildStatusBadge(booking.status, color),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      if (booking.fieldAddress != null)
                                        Row(
                                          children: [
                                            const Icon(Icons.location_on_outlined, size: 14, color: Colors.white54),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                booking.fieldAddress!,
                                                style: GoogleFonts.outfit(fontSize: 13, color: Colors.white54),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          const Icon(Icons.calendar_today_outlined, size: 14, color: Colors.white54),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              '${DateFormat('yyyy-MM-dd').format(booking.bookingDate)}  |  ${booking.startTime} - ${booking.endTime}',
                                              style: GoogleFonts.outfit(fontSize: 13, color: Colors.white70),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          _buildEditButton(booking, theme),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildStatusBadge(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.outfit(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _buildEditButton(Booking booking, ThemeData theme) {
    return GestureDetector(
      onTap: () => _showStatusDialog(booking),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: theme.colorScheme.secondary.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.edit_outlined,
          size: 16,
          color: theme.colorScheme.secondary,
        ),
      ),
    );
  }

  Widget _buildStatsSummary() {
    final pending = _countByStatus('pending');
    final confirmed = _countByStatus('confirmed');
    final cancelled = _countByStatus('cancelled');
    final total = _bookings.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overview',
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _statCard('Total', total, Colors.blueAccent),
            const SizedBox(width: 10),
            _statCard('Pending', pending, Colors.orange),
            const SizedBox(width: 10),
            _statCard('Confirmed', confirmed, const Color(0xFF10B981)),
            const SizedBox(width: 10),
            _statCard('Cancelled', cancelled, Colors.redAccent),
          ],
        ),
      ],
    );
  }

  Widget _statCard(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Text(
              count.toString(),
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 11,
                color: color.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      onChanged: (value) {
        setState(() => _searchQuery = value);
        _applyFiltersAndSort();
      },
      style: GoogleFonts.outfit(color: Colors.white),
      decoration: InputDecoration(
        hintText: 'Search by venue or location...',
        hintStyle: GoogleFonts.outfit(color: Colors.white38),
        prefixIcon: const Icon(Icons.search, color: Colors.white54),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, color: Colors.white54),
                onPressed: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                  _applyFiltersAndSort();
                },
              )
            : null,
        filled: true,
        fillColor: const Color(0xFF1E293B),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0x3310B981)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0x3310B981)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.5),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = [
      ('all', 'All'),
      ('pending', 'Pending'),
      ('confirmed', 'Confirmed'),
      ('cancelled', 'Cancelled'),
    ];

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final (value, label) = filters[index];
          final isSelected = _statusFilter == value;
          final chipColor = value == 'all'
              ? Colors.blueAccent
              : _statusColor(value);

          return GestureDetector(
            onTap: () {
              setState(() => _statusFilter = value);
              _applyFiltersAndSort();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isSelected ? chipColor.withValues(alpha: 0.2) : const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? chipColor.withValues(alpha: 0.6) : const Color(0x3310B981),
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? chipColor : Colors.white60,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
