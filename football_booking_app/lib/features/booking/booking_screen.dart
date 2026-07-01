import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/booking.dart';
import '../../models/football_field.dart';
import '../../models/time_slot.dart';
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
  TimeSlot? _selectedSlot;
  List<TimeSlot> _availableSlots = [];
  List<Map<String, dynamic>> _bookedSlots = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _error;

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
      _loadTimeSlots();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadTimeSlots() async {
    try {
      final slots = await _supabaseService.getAvailableTimeSlots(widget.fieldId);
      final booked = await _supabaseService.getBookedSlots(widget.fieldId, _selectedDate);
      setState(() {
        _availableSlots = slots;
        _bookedSlots = booked;
      });
    } catch (e) {
      // Handle error silently
    }
  }

  bool _isSlotBooked(TimeSlot slot) {
    return _bookedSlots.any((booked) {
      final slotStart = booked['start_time'];
      final slotEnd = booked['end_time'];
      return (slot.startTime.compareTo(slotStart) < 0 && slot.endTime.compareTo(slotStart) > 0) ||
          (slot.startTime.compareTo(slotEnd) < 0 && slot.endTime.compareTo(slotEnd) > 0);
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
        _selectedSlot = null;
      });
      _loadTimeSlots();
    }
  }

  Future<void> _submitBooking() async {
    if (_selectedSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a time slot')),
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
        startTime: _selectedSlot!.startTime,
        endTime: _selectedSlot!.endTime,
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
                                      if (_field!.address != null)
                                        Text(
                                          _field!.address!,
                                          style: Theme.of(context).textTheme.bodyMedium,
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
                        'Select Time Slot',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_availableSlots.isEmpty)
                        const Card(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(
                              child: Text('No time slots available for this field'),
                            ),
                          ),
                        )
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _availableSlots.map((slot) {
                            final isBooked = _isSlotBooked(slot);
                            final isSelected = _selectedSlot?.id == slot.id;
                            return ChoiceChip(
                              label: Text('${slot.startTime} - ${slot.endTime}'),
                              selected: isSelected,
                              onSelected: isBooked
                                  ? null
                                  : (selected) {
                                      setState(() {
                                        _selectedSlot = slot;
                                      });
                                    },
                              backgroundColor: isBooked ? Colors.grey[300] : null,
                            );
                          }).toList(),
                        ),
                      const SizedBox(height: 24),
                      if (_selectedSlot != null) ...[
                        Card(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Booking Summary',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text('Field: ${_field?.name}'),
                                Text('Date: ${DateFormat('yyyy-MM-dd').format(_selectedDate)}'),
                                Text('Time: ${_selectedSlot!.startTime} - ${_selectedSlot!.endTime}'),
                                if (_field?.pricePerHour != null)
                                  Text(
                                    'Price: \$${_field!.pricePerHour!.toStringAsFixed(2)}',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                              ],
                            ),
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
