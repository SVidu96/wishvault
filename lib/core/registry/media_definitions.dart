import 'package:flutter/material.dart';
import '../../models/media_item_model.dart';
import '../../models/wishlist_model.dart';
import '../../models/watch_provider_model.dart';
import '../../services/search_service.dart';
import 'media_item_registry.dart';

/// Base for TMDB-based media (Movies, TV)
abstract class TmdbMediaDefinition extends MediaDefinition {
  final MovieSearchService _tmdbService = MovieSearchService();

  @override
  SearchService get searchService => _tmdbService;

  @override
  List<Widget> buildCustomSections(
    BuildContext context,
    Map<String, dynamic> extraContent,
  ) {
    final providersRaw = extraContent['watch_providers'];
    if (providersRaw == null || providersRaw is! Map) return [];

    final Map providers = providersRaw;
    List<Widget> sections = [];

    providers.forEach((category, list) {
      if (list is List && list.isNotEmpty) {
        final watchList = list.whereType<WatchProvider>().toList();
        if (watchList.isNotEmpty) {
          sections.add(
            buildProviderSection(context, category.toString(), watchList),
          );
        }
      }
    });
    return sections;
  }
}

class MovieDefinition extends TmdbMediaDefinition {
  @override
  WishListType get type => WishListType.movies;
  @override
  IconData get icon => Icons.movie_rounded;

  @override
  List<Widget> buildBadges(BuildContext context, MediaItemModel media) {
    final releaseDate = media.extraData?['release_date'] ?? 'Unknown';
    final voteAverage = media.extraData?['vote_average']?.toString() ?? 'N/A';
    return [
      buildBadge(context, Icons.calendar_today, releaseDate),
      buildBadge(context, Icons.star_rounded, '$voteAverage (TMDB)'),
    ];
  }
}

class TvDefinition extends TmdbMediaDefinition {
  @override
  WishListType get type => WishListType.tvSeries;
  @override
  IconData get icon => Icons.tv_rounded;

  @override
  SearchService get searchService => TvSearchService();

  @override
  List<Widget> buildBadges(BuildContext context, MediaItemModel media) {
    final releaseDate = media.extraData?['first_air_date'] ?? 'Unknown';
    final episodes = media.extraData?['number_of_episodes']?.toString();
    final voteAverage = media.extraData?['vote_average']?.toString() ?? 'N/A';

    return [
      buildBadge(context, Icons.calendar_today, releaseDate),
      if (episodes != null)
        buildBadge(context, Icons.layers_rounded, '$episodes Eps'),
      buildBadge(context, Icons.star_rounded, '$voteAverage (TMDB)'),
    ];
  }
}

class BookDefinition extends MediaDefinition {
  @override
  WishListType get type => WishListType.books;
  @override
  IconData get icon => Icons.book_rounded;

  @override
  SearchService get searchService => BookSearchService();

  @override
  List<Widget> buildBadges(BuildContext context, MediaItemModel media) {
    final info = media.extraData?['volumeInfo'] ?? {};
    final pageCount = info['pageCount']?.toString();
    final categories = (info['categories'] as List?)?.first?.toString();
    final publishedDate = info['publishedDate']?.toString();
    final rating = info['averageRating']?.toString();

    return [
      if (publishedDate != null)
        buildBadge(
          context,
          Icons.calendar_today_rounded,
          publishedDate.split('-').first,
        ),
      if (pageCount != null)
        buildBadge(context, Icons.menu_book_rounded, '$pageCount Pages'),
      if (categories != null)
        buildBadge(context, Icons.category_rounded, categories),
      if (rating != null) buildBadge(context, Icons.star_rounded, '$rating/5'),
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
        sections.add(buildProviderSection(context, category, list));
      }
    });
    return sections;
  }
}

class CustomDefinition extends MediaDefinition {
  @override
  WishListType get type => WishListType.other;
  @override
  IconData get icon => Icons.list_alt_rounded;

  @override
  SearchService get searchService => DefaultSearchService();

  @override
  List<Widget> buildBadges(BuildContext context, MediaItemModel media) => [];

  @override
  List<Widget> buildCustomSections(
    BuildContext context,
    Map<String, dynamic> extraContent,
  ) => [];
}

/// Example of how easy it is to add a new type
class PlaceDefinition extends MediaDefinition {
  @override
  WishListType get type => WishListType.places;
  @override
  IconData get icon => Icons.place_rounded;

  @override
  SearchService get searchService => DefaultSearchService(); // Implement later

  @override
  List<Widget> buildBadges(BuildContext context, MediaItemModel media) {
    return [buildBadge(context, Icons.star_rounded, 'Top Rated')];
  }

  @override
  List<Widget> buildCustomSections(
    BuildContext context,
    Map<String, dynamic> extraContent,
  ) => [];
}
