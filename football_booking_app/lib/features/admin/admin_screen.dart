import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  Widget _buildStatCard(BuildContext context, String value, String label, IconData icon, Color color) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 12),
            Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 11,
                color: Colors.white54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'ADMIN PANEL',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.go('/'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Field Overview',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            // Statistics Summary Cards
            Row(
              children: [
                _buildStatCard(context, '12', 'Total Fields', Icons.sports_soccer, theme.colorScheme.primary),
                const SizedBox(width: 12),
                _buildStatCard(context, '148', 'All Bookings', Icons.receipt_long_outlined, theme.colorScheme.secondary),
                const SizedBox(width: 12),
                _buildStatCard(context, '89%', 'Slot Utility', Icons.pie_chart_outline, Colors.amber),
              ],
            ),
            const SizedBox(height: 32),

            Text(
              'Management Tools',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),

            _AdminMenuCard(
              icon: Icons.sports_soccer,
              title: 'Manage Football Fields',
              subtitle: 'Add, update, or remove fields from selection.',
              color: theme.colorScheme.primary,
              onTap: () => context.push('/admin/fields'),
            ),
            const SizedBox(height: 14),
            _AdminMenuCard(
              icon: Icons.access_time_filled_outlined,
              title: 'Manage Time Slots',
              subtitle: 'Configure daily booking availability slots.',
              color: theme.colorScheme.secondary,
              onTap: () => context.push('/admin/time-slots'),
            ),
            const SizedBox(height: 14),
            _AdminMenuCard(
              icon: Icons.receipt_long_rounded,
              title: 'Approve & Confirm Bookings',
              subtitle: 'Review pending player reservation requests.',
              color: Colors.amber,
              onTap: () => context.push('/admin/bookings'),
            ),
            const SizedBox(height: 14),
            _AdminMenuCard(
              icon: Icons.people_outline,
              title: 'Manage Users',
              subtitle: 'View users and promote them to admin.',
              color: const Color(0xFF10B981),
              onTap: () => context.push('/admin/users'),
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
  final Color color;
  final VoidCallback onTap;

  const _AdminMenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.12), width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: color.withOpacity(0.12),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: Colors.white54,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: color.withOpacity(0.6)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

