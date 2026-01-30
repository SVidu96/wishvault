import '../models/media_item_model.dart';
import '../models/wishlist_model.dart';
import '../core/config/env.dart';
import 'package:tmdb_api/tmdb_api.dart';

abstract class SearchService {
  Future<List<MediaItemModel>> search(String query);
  Future<Map<String, List<WatchProvider>>> getWatchProviders(String id);
  Future<MediaItemModel?> getDetails(String id);
}

class WatchProvider {
  final String name;
  final String logoUrl;
  final String tmdbLink;

  WatchProvider({
    required this.name,
    required this.logoUrl,
    required this.tmdbLink,
  });
}

class MovieSearchService implements SearchService {
  late TMDB _tmdb;

  MovieSearchService() {
    print(
      'DEBUG: Initializing TMDB with Key: ${Env.tmdbV3Key.isNotEmpty ? "FOUND" : "MISSING"}',
    );
    _tmdb = TMDB(ApiKeys(Env.tmdbV3Key, Env.tmdbV4Token));
  }

  @override
  Future<List<MediaItemModel>> search(String query) async {
    if (!Env.isConfigured) {
      print('⚠️ Error: TMDB API Keys are not configured in Env');
      return [];
    }
    try {
      final Map results = await _tmdb.v3.search.queryMovies(query);
      final List list = results['results'] ?? [];

      return list.map((item) {
        return MediaItemModel(
          id: 'tmdb_${item['id']}',
          apiId: item['id'].toString(),
          title: item['title'] ?? 'Unknown',
          subtitle: item['release_date'],
          posterUrl: item['poster_path'] != null
              ? 'https://image.tmdb.org/t/p/w500${item['poster_path']}'
              : null,
          type: 'movie',
          extraData: Map<String, dynamic>.from(item),
        );
      }).toList();
    } catch (e) {
      print('TMDB Search Error: $e');
      return [];
    }
  }

  @override
  Future<MediaItemModel?> getDetails(String id) async {
    try {
      final int movieId = int.parse(id);
      final Map item = await _tmdb.v3.movies.getDetails(movieId);
      return MediaItemModel(
        id: 'tmdb_${item['id']}',
        apiId: item['id'].toString(),
        title: item['title'] ?? 'Unknown',
        subtitle: item['release_date'],
        posterUrl: item['poster_path'] != null
            ? 'https://image.tmdb.org/t/p/w500${item['poster_path']}'
            : null,
        type: 'movie',
        extraData: Map<String, dynamic>.from(item),
      );
    } catch (e) {
      print('TMDB Details Error: $e');
      return null;
    }
  }

  @override
  Future<Map<String, List<WatchProvider>>> getWatchProviders(String id) async {
    try {
      final int movieId = int.parse(id);
      final Map results = await _tmdb.v3.movies.getWatchProviders(movieId);
      final Map allResults = results['results'] ?? {};

      final Map regionData = allResults['US'] ?? {};
      final String tmdbLink = regionData['link'] ?? '';

      List<WatchProvider> parseList(String key) {
        final List list = regionData[key] ?? [];
        return list
            .map(
              (item) => WatchProvider(
                name: item['provider_name'] ?? '',
                logoUrl: item['logo_path'] != null
                    ? 'https://image.tmdb.org/t/p/original${item['logo_path']}'
                    : '',
                tmdbLink: tmdbLink,
              ),
            )
            .toList();
      }

      return {
        'Stream': parseList('flatrate'),
        'Rent': parseList('rent'),
        'Buy': parseList('buy'),
        'Free': parseList('free'),
      };
    } catch (e) {
      print('TMDB Providers Error: $e');
      return {};
    }
  }
}

class SearchServiceFactory {
  static SearchService getService(WishListType type) {
    if (type == WishListType.movies) return MovieSearchService();
    return DefaultSearchService();
  }
}

class DefaultSearchService implements SearchService {
  @override
  Future<List<MediaItemModel>> search(String query) async => [];
  @override
  Future<Map<String, List<WatchProvider>>> getWatchProviders(String id) async =>
      {};
  @override
  Future<MediaItemModel?> getDetails(String id) async => null;
}
