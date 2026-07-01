import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../models/booking.dart';
import '../../services/supabase_service.dart';

class AdminBookingsScreen extends StatefulWidget {
  const AdminBookingsScreen({super.key});

  @override
  State<AdminBookingsScreen> createState() => _AdminBookingsScreenState();
}

class _AdminBookingsScreenState extends State<AdminBookingsScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  List<Booking> _bookings = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    try {
      final bookings = await _supabaseService.getAllBookings();
      setState(() {
        _bookings = bookings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'confirmed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _showStatusDialog(Booking booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Status'),
        content: Text('Booking for ${booking.fieldName ?? "Unknown Field"}'),
      actions: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
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
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
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
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Bookings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/admin'),
        ),
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
                        onPressed: _loadBookings,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _bookings.isEmpty
                  ? const Center(child: Text('No bookings yet'))
                  : RefreshIndicator(
                      onRefresh: _loadBookings,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _bookings.length,
                        itemBuilder: (context, index) {
                          final booking = _bookings[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              title: Text(booking.fieldName ?? 'Unknown Field'),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(booking.fieldAddress ?? ''),
                                  Text(
                                    '${DateFormat('yyyy-MM-dd').format(booking.bookingDate)} | ${booking.startTime} - ${booking.endTime}',
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _statusColor(booking.status).withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      booking.status,
                                      style: TextStyle(
                                        color: _statusColor(booking.status),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () => _showStatusDialog(booking),
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
