import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/football_field.dart';
import '../../models/time_slot.dart';
import '../../services/supabase_service.dart';

class AdminTimeSlotsScreen extends StatefulWidget {
  const AdminTimeSlotsScreen({super.key});

  @override
  State<AdminTimeSlotsScreen> createState() => _AdminTimeSlotsScreenState();
}

class _AdminTimeSlotsScreenState extends State<AdminTimeSlotsScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  List<FootballField> _fields = [];
  FootballField? _selectedField;
  List<TimeSlot> _timeSlots = [];
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
      if (fields.isNotEmpty) {
        _selectedField = fields.first;
        _loadTimeSlots();
      }
    });
  }

  Future<void> _loadTimeSlots() async {
    if (_selectedField == null) return;
    final slots = await _supabaseService.getTimeSlots(_selectedField!.id);
    setState(() {
      _timeSlots = slots;
    });
  }

  Widget _buildTimeSlotDialogTextField({
    required TextEditingController controller,
    required String labelText,
    required String hintText,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: labelText,
          hintText: hintText,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  void _showAddTimeSlotDialog() {
    final startTimeController = TextEditingController();
    final endTimeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text(
          'Add Time Slot',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTimeSlotDialogTextField(
              controller: startTimeController,
              labelText: 'Start Time (e.g. 08:00)',
              hintText: 'HH:MM',
            ),
            _buildTimeSlotDialogTextField(
              controller: endTimeController,
              labelText: 'End Time (e.g. 09:00)',
              hintText: 'HH:MM',
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
              if (startTimeController.text.isNotEmpty &&
                  endTimeController.text.isNotEmpty &&
                  _selectedField != null) {
                await _supabaseService.addTimeSlot(TimeSlot(
                  id: '',
                  fieldId: _selectedField!.id,
                  startTime: startTimeController.text,
                  endTime: endTimeController.text,
                  isAvailable: true,
                  createdAt: DateTime.now(),
                ));
                if (mounted) {
                  Navigator.pop(context);
                  _loadTimeSlots();
                }
              }
            },
            child: const Text('Add Slot'),
          ),
        ],
      ),
    );
  }

  void _showBulkAddDialog() {
    final startHourController = TextEditingController(text: '8');
    final endHourController = TextEditingController(text: '22');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text(
          'Bulk Generate Slots',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTimeSlotDialogTextField(
              controller: startHourController,
              labelText: 'Start Hour (e.g. 8)',
              hintText: 'HH',
            ),
            _buildTimeSlotDialogTextField(
              controller: endHourController,
              labelText: 'End Hour (e.g. 22)',
              hintText: 'HH',
            ),
            const SizedBox(height: 4),
            Text(
              'Generates 1-hour active slots automatically.',
              style: GoogleFonts.outfit(fontSize: 12, color: Colors.white38),
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
              final startHour = int.tryParse(startHourController.text) ?? 8;
              final endHour = int.tryParse(endHourController.text) ?? 22;

              if (_selectedField != null && startHour < endHour) {
                for (var h = startHour; h < endHour; h++) {
                  final start = '${h.toString().padLeft(2, '0')}:00';
                  final end = '${(h + 1).toString().padLeft(2, '0')}:00';
                  await _supabaseService.addTimeSlot(TimeSlot(
                    id: '',
                    fieldId: _selectedField!.id,
                    startTime: start,
                    endTime: end,
                    isAvailable: true,
                    createdAt: DateTime.now(),
                  ));
                }
                if (mounted) {
                  Navigator.pop(context);
                  _loadTimeSlots();
                }
              }
            },
            child: const Text('Generate'),
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
          'MANAGE SLOTS',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.go('/admin'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bolt, size: 26),
            onPressed: _showBulkAddDialog,
            tooltip: 'Bulk Add Slots',
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTimeSlotDialog,
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
          : Column(
              children: [
                // Selection Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: DropdownButtonFormField<FootballField>(
                    initialValue: _selectedField,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Select Arena',
                      labelStyle: GoogleFonts.outfit(color: Colors.white60),
                    ),
                    items: _fields.map((field) {
                      return DropdownMenuItem(
                        value: field,
                        child: Text(
                          field.name,
                          style: GoogleFonts.outfit(color: Colors.white),
                        ),
                      );
                    }).toList(),
                    onChanged: (field) {
                      setState(() {
                        _selectedField = field;
                      });
                      _loadTimeSlots();
                    },
                  ),
                ),
                Expanded(
                  child: _timeSlots.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.access_time, size: 64, color: Colors.white10),
                              const SizedBox(height: 12),
                              Text(
                                'No slots configured for this field',
                                style: GoogleFonts.outfit(color: Colors.white54, fontSize: 15),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: _timeSlots.length,
                          itemBuilder: (context, index) {
                            final slot = _timeSlots[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: slot.isAvailable
                                      ? theme.colorScheme.primary.withOpacity(0.12)
                                      : Colors.white10,
                                  width: 1.5,
                                ),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                title: Text(
                                  '${slot.startTime} - ${slot.endTime}',
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: slot.isAvailable ? Colors.white : Colors.white30,
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Switch(
                                      value: slot.isAvailable,
                                      activeColor: theme.colorScheme.primary,
                                      onChanged: (value) async {
                                        await _supabaseService.toggleTimeSlotAvailability(
                                          slot.id,
                                          value,
                                        );
                                        _loadTimeSlots();
                                      },
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            backgroundColor: const Color(0xFF1E293B),
                                            title: Text(
                                              'Delete Time Slot',
                                              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white),
                                            ),
                                            content: Text(
                                              'Are you sure you want to delete ${slot.startTime} - ${slot.endTime}?',
                                              style: GoogleFonts.outfit(color: Colors.white70),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(context),
                                                child: const Text('Cancel'),
                                              ),
                                              ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.redAccent,
                                                ),
                                                onPressed: () async {
                                                  await _supabaseService.deleteTimeSlot(slot.id);
                                                  if (mounted) {
                                                    Navigator.pop(context);
                                                    _loadTimeSlots();
                                                  }
                                                },
                                                child: const Text('Delete'),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
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
    );
  }
}

