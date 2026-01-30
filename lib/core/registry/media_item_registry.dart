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
    final providers =
        extraContent['watch_providers'] as Map<String, List<WatchProvider>>?;
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

    return [
      if (pageCount != null)
        _buildBadge(context, Icons.menu_book_rounded, '$pageCount Pages'),
      if (categories != null)
        _buildBadge(context, Icons.category_rounded, categories),
    ];
  }

  @override
  List<Widget> buildCustomSections(
    BuildContext context,
    Map<String, dynamic> extraContent,
  ) => [];
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
      color: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.5),
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
        Text(
          title,
          style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          children: providers
              .map((p) => _buildProviderIcon(context, p))
              .toList(),
        ),
      ],
    ),
  );
}

Widget _buildProviderIcon(BuildContext context, WatchProvider p) {
  return GestureDetector(
    onTap: () async {
      final uri = Uri.parse(p.tmdbLink);
      if (await canLaunchUrl(uri)) await launchUrl(uri);
    },
    child: Container(
      width: 45,
      height: 45,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        image: DecorationImage(
          image: NetworkImage(p.logoUrl),
          fit: BoxFit.cover,
        ),
      ),
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
