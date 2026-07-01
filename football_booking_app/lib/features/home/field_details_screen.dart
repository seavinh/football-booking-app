import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/football_field.dart';

class FieldDetailsScreen extends StatelessWidget {
  final String fieldId;

  const FieldDetailsScreen({super.key, required this.fieldId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
        future: _loadField(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }
          final field = snapshot.data;
          if (field == null) {
            return const Center(child: Text('Field not found'));
          }
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(field.name),
                  background: field.imageUrl != null
                      ? Image.network(
                          field.imageUrl!,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                          child: Icon(
                            Icons.sports_soccer,
                            size: 100,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (field.address != null) ...[
                        Row(
                          children: [
                            const Icon(Icons.location_on, color: Colors.grey),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                field.address!,
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (field.pricePerHour != null) ...[
                        Row(
                          children: [
                            const Icon(Icons.attach_money, color: Colors.grey),
                            const SizedBox(width: 8),
                            Text(
                              '\$${field.pricePerHour!.toStringAsFixed(2)} / hour',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => context.push('/booking/${field.id}'),
                          icon: const Icon(Icons.calendar_today),
                          label: const Text('Book Now'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
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
