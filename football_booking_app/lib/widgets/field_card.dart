import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/football_field.dart';

class FieldCard extends StatelessWidget {
  final FootballField field;

  const FieldCard({super.key, required this.field});

  // Generates sporty tags based on field name or ID to make UI look complete
  List<String> _getTags() {
    final nameLower = field.name.toLowerCase();
    final List<String> tags = [];
    
    if (nameLower.contains('indoor')) {
      tags.add('Indoor');
    } else {
      tags.add('Outdoor');
    }

    if (nameLower.contains('7') || nameLower.contains('seven')) {
      tags.add('7x7 Pitch');
    } else if (nameLower.contains('11') || nameLower.contains('eleven')) {
      tags.add('11x11 Stadium');
    } else {
      tags.add('5x5 Court');
    }

    if (nameLower.contains('turf') || nameLower.contains('artificial')) {
      tags.add('Artificial Turf');
    } else {
      tags.add('Premium Grass');
    }

    return tags;
  }

  // Generates a mock rating for premium feel
  double _getRating() {
    final code = field.id.hashCode % 10;
    return 4.5 + (code / 20.0); // Between 4.5 and 5.0
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rating = _getRating();
    final tags = _getTags();

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.15)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () => context.push('/field/${field.id}'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Header Stack
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 1.8,
                    child: field.imageUrl != null && field.imageUrl!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: field.imageUrl!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: const Color(0xFF1E293B),
                              child: const Center(
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: theme.colorScheme.primary.withValues(alpha: 0.1),
                              child: Icon(
                                Icons.sports_soccer,
                                size: 64,
                                color: theme.colorScheme.primary.withValues(alpha: 0.5),
                              ),
                            ),
                          )
                        : Container(
                            color: theme.colorScheme.primary.withValues(alpha: 0.1),
                            child: Icon(
                              Icons.sports_soccer,
                              size: 64,
                              color: theme.colorScheme.primary.withValues(alpha: 0.5),
                            ),
                          ),
                  ),
                  // Dark gradient overlay over image
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.85)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ),
                  // Rating Tag top left
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black87.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber.withValues(alpha: 0.3), width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            rating.toStringAsFixed(1),
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Price Tag bottom right
                  if (field.pricePerHour != null)
                    Positioned(
                      bottom: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.primary.withValues(alpha: 0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          '\$${field.pricePerHour!.toStringAsFixed(0)}/hr',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              
              // Description Area
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      field.name,
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (field.address != null)
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined, size: 16, color: theme.colorScheme.secondary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              field.address!,
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                color: Colors.white60,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 12),
                    // Visual tags/chips
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: tags.map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: theme.colorScheme.primary.withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            tag,
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

