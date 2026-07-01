import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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

  void _showAddTimeSlotDialog() {
    final startTimeController = TextEditingController();
    final endTimeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Time Slot'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: startTimeController,
              decoration: const InputDecoration(
                labelText: 'Start Time (e.g. 08:00)',
                hintText: 'HH:MM',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: endTimeController,
              decoration: const InputDecoration(
                labelText: 'End Time (e.g. 09:00)',
                hintText: 'HH:MM',
              ),
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
            child: const Text('Add'),
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
        title: const Text('Bulk Add Time Slots'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: startHourController,
              decoration: const InputDecoration(labelText: 'Start Hour (e.g. 8)'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: endHourController,
              decoration: const InputDecoration(labelText: 'End Hour (e.g. 22)'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            const Text(
              'Creates 1-hour slots from start to end',
              style: TextStyle(fontSize: 12, color: Colors.grey),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Time Slots'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/admin'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box),
            onPressed: _showBulkAddDialog,
            tooltip: 'Bulk Add Slots',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTimeSlotDialog,
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: DropdownButtonFormField<FootballField>(
                    initialValue: _selectedField,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Select Field',
                      border: OutlineInputBorder(),
                    ),
                    items: _fields.map((field) {
                      return DropdownMenuItem(
                        value: field,
                        child: Text(field.name),
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
                      ? const Center(child: Text('No time slots for this field'))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _timeSlots.length,
                          itemBuilder: (context, index) {
                            final slot = _timeSlots[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                title: Text('${slot.startTime} - ${slot.endTime}'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Switch(
                                      value: slot.isAvailable,
                                      onChanged: (value) async {
                                        await _supabaseService.toggleTimeSlotAvailability(
                                          slot.id,
                                          value,
                                        );
                                        _loadTimeSlots();
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text('Delete Time Slot'),
                                            content: Text(
                                              'Delete ${slot.startTime} - ${slot.endTime}?',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(context),
                                                child: const Text('Cancel'),
                                              ),
                                              ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.red,
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
