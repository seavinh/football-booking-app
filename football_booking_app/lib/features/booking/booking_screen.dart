import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
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
          (slot.startTime.compareTo(slotEnd) < 0 && slot.endTime.compareTo(slotEnd) > 0) ||
          (slot.startTime == slotStart && slot.endTime == slotEnd);
    });
  }

  List<DateTime> _getUpcomingDays() {
    final today = DateTime.now();
    return List.generate(14, (index) {
      return DateTime(today.year, today.month, today.day).add(Duration(days: index));
    });
  }

  Future<void> _submitBooking() async {
    if (_selectedSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a time slot'), backgroundColor: Colors.redAccent),
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
          const SnackBar(
            content: Text('Booking created successfully! awaiting confirmation.'),
            backgroundColor: Color(0xFF10B981),
          ),
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
    final theme = Theme.of(context);
    final days = _getUpcomingDays();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'BOOK A PITCH',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF10B981),
              ),
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!, style: const TextStyle(color: Colors.redAccent)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadField,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Field Quick Card
                      if (_field != null)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.1)),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.15),
                                child: Icon(Icons.sports_soccer, color: theme.colorScheme.primary),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _field!.name,
                                      style: GoogleFonts.outfit(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _field!.address ?? 'No Address',
                                      style: GoogleFonts.outfit(
                                        fontSize: 13,
                                        color: Colors.white60,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 24),

                      // Horizontal Date Strip
                      Text(
                        'Select Date',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 90,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: days.length,
                          itemBuilder: (context, index) {
                            final date = days[index];
                            final isSameDay = DateFormat('yyyy-MM-dd').format(date) ==
                                DateFormat('yyyy-MM-dd').format(_selectedDate);

                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedDate = date;
                                  _selectedSlot = null;
                                });
                                _loadTimeSlots();
                              },
                              child: Container(
                                width: 68,
                                margin: const EdgeInsets.only(right: 10),
                                decoration: BoxDecoration(
                                  color: isSameDay
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSameDay
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.primary.withValues(alpha: 0.15),
                                    width: 1.5,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      DateFormat('E').format(date).toUpperCase(),
                                      style: GoogleFonts.outfit(
                                        fontSize: 12,
                                        fontWeight: isSameDay ? FontWeight.bold : FontWeight.w500,
                                        color: isSameDay ? Colors.white : Colors.white54,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      DateFormat('d').format(date),
                                      style: GoogleFonts.outfit(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: isSameDay ? Colors.white : Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Time Slots
                      Text(
                        'Select Time Slot',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),

                      _availableSlots.isEmpty
                          ? Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.white10),
                              ),
                              child: Center(
                                child: Text(
                                  'No time slots configured for this field.',
                                  style: GoogleFonts.outfit(color: Colors.white38),
                                ),
                              ),
                            )
                          : GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _availableSlots.length,
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                mainAxisSpacing: 10,
                                crossAxisSpacing: 10,
                                childAspectRatio: 2.2,
                              ),
                              itemBuilder: (context, index) {
                                final slot = _availableSlots[index];
                                final isBooked = _isSlotBooked(slot);
                                final isSelected = _selectedSlot?.id == slot.id;

                                return GestureDetector(
                                  onTap: isBooked
                                      ? null
                                      : () {
                                          setState(() {
                                            _selectedSlot = slot;
                                          });
                                        },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? theme.colorScheme.primary
                                          : isBooked
                                              ? const Color(0xFF1E293B).withValues(alpha: 0.4)
                                              : theme.colorScheme.surface,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isSelected
                                            ? theme.colorScheme.primary
                                            : isBooked
                                                ? Colors.white10
                                                : theme.colorScheme.primary.withValues(alpha: 0.2),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              slot.startTime,
                                              style: GoogleFonts.outfit(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: isBooked ? Colors.white30 : Colors.white,
                                              ),
                                            ),
                                            Text(
                                              slot.endTime,
                                              style: GoogleFonts.outfit(
                                                fontSize: 11,
                                                color: isSelected
                                                    ? Colors.white70
                                                    : isBooked
                                                        ? Colors.white24
                                                        : Colors.white38,
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (isBooked)
                                          const Positioned(
                                            top: 4,
                                            right: 4,
                                            child: Icon(Icons.lock, size: 12, color: Colors.white24),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                      const SizedBox(height: 32),

                      // Premium Receipt Card
                      if (_selectedSlot != null) ...[
                        Text(
                          'Booking Summary',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2), width: 1.5),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'PITCH',
                                    style: GoogleFonts.outfit(fontSize: 11, color: Colors.white54, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    'DATE',
                                    style: GoogleFonts.outfit(fontSize: 11, color: Colors.white54, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _field?.name ?? '',
                                    style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                  Text(
                                    DateFormat('MMM dd, yyyy').format(_selectedDate),
                                    style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                ],
                              ),
                              const Divider(height: 24, color: Colors.white10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'TIME SLOT',
                                    style: GoogleFonts.outfit(fontSize: 11, color: Colors.white54, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    'PRICE',
                                    style: GoogleFonts.outfit(fontSize: 11, color: Colors.white54, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${_selectedSlot!.startTime} - ${_selectedSlot!.endTime}',
                                    style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: theme.colorScheme.secondary),
                                  ),
                                  Text(
                                    _field?.pricePerHour != null ? '\$${_field!.pricePerHour!.toStringAsFixed(2)}' : '-',
                                    style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : _submitBooking,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: _isSubmitting
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                                  )
                                : const Text('CONFIRM BOOKING'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
    );
  }
}

