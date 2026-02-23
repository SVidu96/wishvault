import 'package:flutter/material.dart';
import '../../models/media_item_model.dart';
import '../../models/watch_provider_model.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

/// Define specific UI components and behaviors for each Media Item Type.
abstract class MediaItemTypeConfig {
  String get typeName;
  IconData get icon;

  // Define badges based on metadata
  List<Widget> buildBadges(BuildContext context, MediaItemModel media);

  // Define custom sections (e.g., Streaming links, Buy links)
  List<Widget> buildCustomSections(
    BuildContext context,
    Map<String, dynamic> extraContent,
  );
}

class MovieTypeConfig extends MediaItemTypeConfig {
  @override
  String get typeName => 'movies';
  @override
  IconData get icon => Icons.movie_rounded;

  @override
  List<Widget> buildBadges(BuildContext context, MediaItemModel media) {
    final releaseDate = media.extraData?['release_date'] ?? 'Unknown';
    final voteAverage = media.extraData?['vote_average']?.toString() ?? 'N/A';
    return [
      _buildBadge(context, Icons.calendar_today, releaseDate),
      _buildBadge(context, Icons.star_rounded, '$voteAverage (TMDB)'),
    ];
  }

  @override
  List<Widget> buildCustomSections(
    BuildContext context,
    Map<String, dynamic> extraContent,
  ) {
    final providersRaw = extraContent['watch_providers'];
    if (providersRaw == null || providersRaw is! Map) return [];

    // Safe cast the map to handle potential dynamic type issues
    final Map providers = providersRaw;
    List<Widget> sections = [];

    providers.forEach((category, list) {
      if (list is List && list.isNotEmpty) {
        // Ensure the list elements are actually WatchProviders
        final watchList = list.whereType<WatchProvider>().toList();
        if (watchList.isNotEmpty) {
          sections.add(
            _buildProviderSection(context, category.toString(), watchList),
          );
        }
      }
    });
    return sections;
  }
}

class TvTypeConfig extends MovieTypeConfig {
  @override
  String get typeName => 'tvSeries';
  @override
  IconData get icon => Icons.tv_rounded;

  @override
  List<Widget> buildBadges(BuildContext context, MediaItemModel media) {
    final releaseDate = media.extraData?['first_air_date'] ?? 'Unknown';
    final episodes = media.extraData?['number_of_episodes']?.toString();
    final voteAverage = media.extraData?['vote_average']?.toString() ?? 'N/A';

    return [
      _buildBadge(context, Icons.calendar_today, releaseDate),
      if (episodes != null)
        _buildBadge(context, Icons.layers_rounded, '$episodes Eps'),
      _buildBadge(context, Icons.star_rounded, '$voteAverage (TMDB)'),
    ];
  }
}

class BookTypeConfig extends MediaItemTypeConfig {
  @override
  String get typeName => 'books';
  @override
  IconData get icon => Icons.book_rounded;

  @override
  List<Widget> buildBadges(BuildContext context, MediaItemModel media) {
    final info = media.extraData?['volumeInfo'] ?? {};
    final pageCount = info['pageCount']?.toString();
    final categories = (info['categories'] as List?)?.first?.toString();
    final publishedDate = info['publishedDate']?.toString();
    final rating = info['averageRating']?.toString();

    return [
      if (publishedDate != null)
        _buildBadge(
          context,
          Icons.calendar_today_rounded,
          publishedDate.split('-').first,
        ),
      if (pageCount != null)
        _buildBadge(context, Icons.menu_book_rounded, '$pageCount Pages'),
      if (categories != null)
        _buildBadge(context, Icons.category_rounded, categories),
      if (rating != null) _buildBadge(context, Icons.star_rounded, '$rating/5'),
    ];
  }

  @override
  List<Widget> buildCustomSections(
    BuildContext context,
    Map<String, dynamic> extraContent,
  ) {
    final providers =
        extraContent['book_providers'] as Map<String, List<WatchProvider>>?;
    if (providers == null) return [];

    List<Widget> sections = [];
    providers.forEach((category, list) {
      if (list.isNotEmpty) {
        sections.add(_buildProviderSection(context, category, list));
      }
    });
    return sections;
  }
}

/// A fallback for Custom User-defined types
class CustomTypeConfig extends MediaItemTypeConfig {
  @override
  String get typeName => 'other';
  @override
  IconData get icon => Icons.list_alt_rounded;

  @override
  List<Widget> buildBadges(BuildContext context, MediaItemModel media) => [];

  @override
  List<Widget> buildCustomSections(
    BuildContext context,
    Map<String, dynamic> extraContent,
  ) => [];
}

// Helper methods for clean UI
Widget _buildBadge(BuildContext context, IconData icon, String text) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: Theme.of(
        context,
      ).colorScheme.secondaryContainer.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14),
        const SizedBox(width: 4),
        Text(
          text,
          style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );
}

Widget _buildProviderSection(
  BuildContext context,
  String title,
  List<WatchProvider> providers,
) {
  return Padding(
    padding: const EdgeInsets.only(top: 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 16,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title.toUpperCase(),
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 20,
          runSpacing: 20,
          children: providers
              .map((p) => _buildProviderIcon(context, p))
              .toList(),
        ),
      ],
    ),
  );
}

Widget _buildProviderIcon(BuildContext context, WatchProvider p) {
  return InkWell(
    onTap: () async {
      final uri = Uri.parse(p.tmdbLink);
      try {
        // On modern Android, canLaunchUrl can be finicky even with manifest queries.
        // We try to launch directly with a fallback.
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        if (!launched) {
          debugPrint('Could not launch ${p.tmdbLink}');
        }
      } catch (e) {
        debugPrint('Error launching URL: $e');
        // Final fallback: try without specifying mode
        try {
          await launchUrl(uri);
        } catch (e2) {
          debugPrint('Final fallback failed: $e2');
        }
      }
    },
    borderRadius: BorderRadius.circular(12),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
            image: DecorationImage(
              image: NetworkImage(p.logoUrl),
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 60,
          child: Text(
            p.name,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    ),
  );
}

/// The Registry that holds all configurations
class MediaItemRegistry {
  static final Map<String, MediaItemTypeConfig> _configs = {
    'movies': MovieTypeConfig(),
    'tvSeries': TvTypeConfig(),
    'books': BookTypeConfig(),
    'other': CustomTypeConfig(),
  };

  static MediaItemTypeConfig getConfig(String type) {
    return _configs[type] ?? _configs['other']!;
  }
}
