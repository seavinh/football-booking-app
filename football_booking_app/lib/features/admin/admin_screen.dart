import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _AdminMenuCard(
              icon: Icons.sports_soccer,
              title: 'Manage Fields',
              subtitle: 'Add, edit, delete football fields',
              onTap: () => context.push('/admin/fields'),
            ),
            const SizedBox(height: 16),
            _AdminMenuCard(
              icon: Icons.access_time,
              title: 'Manage Time Slots',
              subtitle: 'Set available time slots per field',
              onTap: () => context.push('/admin/time-slots'),
            ),
            const SizedBox(height: 16),
            _AdminMenuCard(
              icon: Icons.calendar_today,
              title: 'Manage Bookings',
              subtitle: 'View and confirm user bookings',
              onTap: () => context.push('/admin/bookings'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminMenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _AdminMenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(icon, size: 48, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
