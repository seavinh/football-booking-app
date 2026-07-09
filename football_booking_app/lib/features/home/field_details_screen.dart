import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/football_field.dart';

class FieldDetailsScreen extends StatelessWidget {
  final String fieldId;

  const FieldDetailsScreen({super.key, required this.fieldId});

  // Modern simulated amenities based on the field name
  List<Map<String, dynamic>> _getAmenities(FootballField field) {
    return [
      {'name': 'Floodlights', 'icon': Icons.lightbulb_outline, 'avail': true},
      {'name': 'Showers', 'icon': Icons.shower_outlined, 'avail': true},
      {'name': 'Free Parking', 'icon': Icons.local_parking, 'avail': true},
      {'name': 'Locker Rooms', 'icon': Icons.meeting_room_outlined, 'avail': field.name.length % 2 == 0},
      {'name': 'Free Wifi', 'icon': Icons.wifi, 'avail': field.name.length % 3 != 0},
      {'name': 'Drinking Water', 'icon': Icons.water_drop_outlined, 'avail': true},
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: FutureBuilder<FootballField?>(
        future: _loadField(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF10B981),
              ),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.redAccent),
              ),
            );
          }
          final field = snapshot.data;
          if (field == null) {
            return const Center(child: Text('Field not found'));
          }

          final amenities = _getAmenities(field);

          return Stack(
            children: [
              CustomScrollView(
                slivers: [
                  // Sliver AppBar with collapsing header image
                  SliverAppBar(
                    expandedHeight: 320,
                    pinned: true,
                    backgroundColor: const Color(0xFF0F172A),
                    leading: Container(
                      margin: const EdgeInsets.only(left: 12, top: 8, bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => context.pop(),
                      ),
                    ),
                    flexibleSpace: FlexibleSpaceBar(
                      background: Stack(
                        fit: StackFit.expand,
                        children: [
                          field.imageUrl != null && field.imageUrl!.isNotEmpty
                              ? Image.network(
                                  field.imageUrl!,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  color: theme.colorScheme.primary.withValues(alpha: 0.15),
                                  child: Icon(
                                    Icons.sports_soccer,
                                    size: 100,
                                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                                  ),
                                ),
                          // Shadow overlay on background image
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.black87.withValues(alpha: 0.4),
                                    Colors.transparent,
                                    const Color(0xFF0F172A),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Detail Body
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Field Name
                          Text(
                            field.name,
                            style: GoogleFonts.outfit(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Rating & Quick Info Row
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFBBF24).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.star_rounded, color: Color(0xFFFBBF24), size: 18),
                                    SizedBox(width: 4),
                                    Text(
                                      '4.8',
                                      style: TextStyle(
                                        color: Color(0xFFFBBF24),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Grass Field',
                                style: GoogleFonts.outfit(
                                  color: Colors.white60,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text('•', style: TextStyle(color: Colors.white30)),
                              const SizedBox(width: 8),
                              Text(
                                '10+ bookings today',
                                style: GoogleFonts.outfit(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Location Card
                          if (field.address != null) ...[
                            Text(
                              'Location',
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
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
                                    backgroundColor: theme.colorScheme.secondary.withValues(alpha: 0.15),
                                    child: Icon(Icons.location_on_outlined, color: theme.colorScheme.secondary),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          field.name,
                                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          field.address!,
                                          style: GoogleFonts.outfit(color: Colors.white54, fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],

                          // Amenities section
                          Text(
                            'Facilities & Amenities',
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: amenities.length,
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 10,
                              crossAxisSpacing: 10,
                              childAspectRatio: 3.2,
                            ),
                            itemBuilder: (context, index) {
                              final item = amenities[index];
                              final isAvail = item['avail'] as bool;
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isAvail
                                        ? theme.colorScheme.primary.withValues(alpha: 0.1)
                                        : Colors.white10,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      item['icon'] as IconData,
                                      color: isAvail ? theme.colorScheme.primary : Colors.white24,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        item['name'] as String,
                                        style: GoogleFonts.outfit(
                                          color: isAvail ? Colors.white : Colors.white24,
                                          fontSize: 13,
                                          decoration: isAvail ? null : TextDecoration.lineThrough,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // Bottom Sticky Call to Action
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.95),
                    border: const Border(
                      top: BorderSide(color: Color(0x1F10B981), width: 1.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Pricing info
                      if (field.pricePerHour != null)
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'PRICE PER HOUR',
                                style: GoogleFonts.outfit(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white54,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    '\$${field.pricePerHour!.toStringAsFixed(0)}',
                                    style: GoogleFonts.outfit(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w900,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                  Text(
                                    '/hr',
                                    style: GoogleFonts.outfit(
                                      fontSize: 14,
                                      color: Colors.white54,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      
                      // Booking Button
                      ElevatedButton(
                        onPressed: () => context.push('/booking/${field.id}'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                          elevation: 6,
                          shadowColor: theme.colorScheme.primary.withValues(alpha: 0.4),
                        ),
                        child: Text(
                          'BOOK NOW',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<FootballField?> _loadField() async {
    try {
      final response = await Supabase.instance.client
          .from('football_fields')
          .select()
          .eq('id', fieldId)
          .single();
      return FootballField.fromJson(response);
    } catch (e) {
      return null;
    }
  }
}

