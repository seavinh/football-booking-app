import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/booking.dart';
import '../../models/football_field.dart';
import '../../services/supabase_service.dart';

class BookingScreen extends StatefulWidget {
  final String fieldId;

  const BookingScreen({super.key, required this.fieldId});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  FootballField? _field;
  DateTime _selectedDate = DateTime.now();
  String? _selectedStartTime;
  String? _selectedEndTime;
  List<Map<String, dynamic>> _bookedSlots = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _error;

  final List<String> _timeSlots = [
    '08:00', '09:00', '10:00', '11:00', '12:00',
    '13:00', '14:00', '15:00', '16:00', '17:00',
    '18:00', '19:00', '20:00', '21:00',
  ];

  @override
  void initState() {
    super.initState();
    _loadField();
  }

  Future<void> _loadField() async {
    try {
      final field = await _supabaseService.getFootballField(widget.fieldId);
      setState(() {
        _field = field;
        _isLoading = false;
      });
      _loadBookedSlots();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadBookedSlots() async {
    try {
      final slots = await _supabaseService.getBookedSlots(widget.fieldId, _selectedDate);
      setState(() {
        _bookedSlots = slots;
      });
    } catch (e) {
      // Handle error silently
    }
  }

  bool _isSlotBooked(String time) {
    final endTime = '${int.parse(time.split(':')[0]) + 1}:00';
    return _bookedSlots.any((slot) {
      final slotStart = slot['start_time'];
      final slotEnd = slot['end_time'];
      return (time.compareTo(slotStart) < 0 && endTime.compareTo(slotStart) > 0) ||
          (time.compareTo(slotEnd) < 0 && endTime.compareTo(slotEnd) > 0);
    });
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _selectedStartTime = null;
        _selectedEndTime = null;
      });
      _loadBookedSlots();
    }
  }

  Future<void> _submitBooking() async {
    if (_selectedStartTime == null || _selectedEndTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select start and end time')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final booking = Booking(
        id: '',
        userId: Supabase.instance.client.auth.currentUser!.id,
        fieldId: widget.fieldId,
        bookingDate: _selectedDate,
        startTime: _selectedStartTime!,
        endTime: _selectedEndTime!,
        status: 'pending',
        createdAt: DateTime.now(),
      );

      await _supabaseService.createBooking(booking);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking created successfully!')),
        );
        context.go('/my-bookings');
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Field'),
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
                        onPressed: _loadField,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_field != null) ...[
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.sports_soccer,
                                  size: 48,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _field!.name,
                                        style: Theme.of(context).textTheme.titleLarge,
                                      ),
                                      if (_field!.pricePerHour != null)
                                        Text(
                                          '\$${_field!.pricePerHour!.toStringAsFixed(2)} / hour',
                                          style: TextStyle(
                                            color: Theme.of(context).colorScheme.primary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                      Text(
                        'Select Date',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.calendar_today),
                          title: Text(DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate)),
                          trailing: const Icon(Icons.edit_calendar),
                          onTap: _selectDate,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Select Start Time',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _timeSlots.map((time) {
                          final isBooked = _isSlotBooked(time);
                          final isSelected = _selectedStartTime == time;
                          return ChoiceChip(
                            label: Text(time),
                            selected: isSelected,
                            onSelected: isBooked
                                ? null
                                : (selected) {
                                    setState(() {
                                      _selectedStartTime = time;
                                      _selectedEndTime = '${int.parse(time.split(':')[0]) + 1}:00';
                                    });
                                  },
                            backgroundColor: isBooked ? Colors.grey[300] : null,
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                      if (_selectedStartTime != null) ...[
                        Text(
                          'Selected: $_selectedStartTime - $_selectedEndTime',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : _submitBooking,
                            child: _isSubmitting
                                ? const CircularProgressIndicator()
                                : const Text('Confirm Booking'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
    );
  }
}
