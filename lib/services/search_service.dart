import '../models/media_item_model.dart';
import '../models/wishlist_model.dart';
import '../core/config/env.dart';
import '../models/watch_provider_model.dart';
import 'package:tmdb_api/tmdb_api.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

abstract class SearchService {
  Future<List<MediaItemModel>> search(String query);
  Future<MediaItemModel?> getDetails(String id);

  // High-level "Dynamic" content (e.g., Streaming links, Book preview links)
  Future<Map<String, dynamic>> getDynamicContent(String apiId) async => {};
}

class MovieSearchService implements SearchService {
  late TMDB _tmdb;

  MovieSearchService() {
    _tmdb = TMDB(ApiKeys(Env.tmdbV3Key, Env.tmdbV4Token));
  }

  @override
  Future<List<MediaItemModel>> search(String query) async {
    if (!Env.isConfigured) return [];
    try {
      final Map results = await _tmdb.v3.search.queryMovies(query);
      final List list = results['results'] ?? [];
      return list.map((item) => _mapToMediaItem(item)).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<MediaItemModel?> getDetails(String id) async {
    try {
      final int movieId = int.parse(id);
      final Map item = await _tmdb.v3.movies.getDetails(movieId);
      return _mapToMediaItem(item);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<Map<String, dynamic>> getDynamicContent(String apiId) async {
    try {
      final int movieId = int.parse(apiId);
      final Map results = await _tmdb.v3.movies.getWatchProviders(movieId);
      return _parseWatchProviders(results);
    } catch (e) {
      debugPrint('Movie Watch Providers Error: $e');
      return {};
    }
  }

  Map<String, dynamic> _parseWatchProviders(Map results) {
    try {
      final Map allResults = results['results'] ?? {};

      // Try US first, then any available region as fallback
      Map regionData = allResults['US'] ?? {};
      if (regionData.isEmpty && allResults.isNotEmpty) {
        regionData = allResults.values.first;
      }

      if (regionData.isEmpty) return {};

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
        'watch_providers': {
          'Stream': parseList('flatrate'),
          'Rent': parseList('rent'),
          'Buy': parseList('buy'),
        },
      };
    } catch (e) {
      return {};
    }
  }

  MediaItemModel _mapToMediaItem(Map item) {
    return MediaItemModel(
      id: 'tmdb_movie_${item['id']}',
      apiId: item['id'].toString(),
      title: item['title'] ?? item['name'] ?? 'Unknown',
      subtitle: item['release_date'] ?? item['first_air_date'],
      posterUrl: item['poster_path'] != null
          ? 'https://image.tmdb.org/t/p/w500${item['poster_path']}'
          : null,
      type: 'movies',
      extraData: Map<String, dynamic>.from(item),
    );
  }
}

class TvSearchService extends MovieSearchService {
  @override
  Future<List<MediaItemModel>> search(String query) async {
    if (!Env.isConfigured) return [];
    try {
      final Map results = await _tmdb.v3.search.queryTvShows(query);
      final List list = results['results'] ?? [];
      return list.map((item) => _mapToMediaItem(item)).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<MediaItemModel?> getDetails(String id) async {
    try {
      final int tvId = int.parse(id);
      final Map item = await _tmdb.v3.tv.getDetails(tvId);
      return _mapToMediaItem(item);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<Map<String, dynamic>> getDynamicContent(String apiId) async {
    try {
      final Map results = await _tmdb.v3.tv.getWatchProviders(apiId);
      return _parseWatchProviders(results);
    } catch (e) {
      debugPrint('TV Watch Providers Error: $e');
      return {};
    }
  }

  @override
  MediaItemModel _mapToMediaItem(Map item) {
    final base = super._mapToMediaItem(item);
    return MediaItemModel(
      id: 'tmdb_tv_${item['id']}',
      apiId: base.apiId,
      title: item['name'] ?? base.title,
      subtitle: item['first_air_date'] ?? base.subtitle,
      posterUrl: base.posterUrl,
      type: 'tvSeries',
      extraData: base.extraData,
    );
  }
}

class BookSearchService implements SearchService {
  @override
  Future<List<MediaItemModel>> search(String query) async {
    try {
      final url =
          'https://www.googleapis.com/books/v1/volumes?q=$query${Env.googleBooksApiKey.isNotEmpty ? '&key=${Env.googleBooksApiKey}' : ''}';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(
          response.statusCode == 200 ? response.body : '{}',
        );
        final List items = data['items'] ?? [];
        return items.map((item) => _mapToMediaItem(item)).toList();
      }
    } catch (e) {
      debugPrint('Books Search Error: $e');
    }
    return [];
  }

  @override
  Future<MediaItemModel?> getDetails(String id) async {
    try {
      final url =
          'https://www.googleapis.com/books/v1/volumes/$id${Env.googleBooksApiKey.isNotEmpty ? '?key=${Env.googleBooksApiKey}' : ''}';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return _mapToMediaItem(json.decode(response.body));
      }
    } catch (e) {
      debugPrint('Book Details Error: $e');
    }
    return null;
  }

  @override
  Future<Map<String, dynamic>> getDynamicContent(String apiId) async {
    try {
      final details = await getDetails(apiId);
      if (details == null) return {};

      final data = details.extraData ?? {};
      final saleInfo = data['saleInfo'] ?? {};
      final accessInfo = data['accessInfo'] ?? {};
      final info = data['volumeInfo'] ?? {};

      List<WatchProvider> buyList = [];
      List<WatchProvider> readList = [];
      List<WatchProvider> rentList = [];

      String ensureHttps(String url) {
        if (url.startsWith('http://')) {
          return url.replaceFirst('http://', 'https://');
        }
        return url;
      }

      // Google Play Books - Buy
      if (saleInfo['buyLink'] != null) {
        buyList.add(
          WatchProvider(
            name: 'Google Play',
            logoUrl:
                'https://www.gstatic.com/images/branding/product/2x/play_books_48dp.png',
            tmdbLink: ensureHttps(saleInfo['buyLink']),
          ),
        );
      }

      // Google Play Books - Rent (if available in offers)
      final List? offers = saleInfo['offers'];
      if (offers != null && offers.any((o) => o['finskyOfferType'] == 3)) {
        if (saleInfo['buyLink'] != null) {
          rentList.add(
            WatchProvider(
              name: 'Google Play',
              logoUrl:
                  'https://www.gstatic.com/images/branding/product/2x/play_books_48dp.png',
              tmdbLink: ensureHttps(saleInfo['buyLink']),
            ),
          );
        }
      }

      // External Providers via ISBN
      final List? identifiers = info['industryIdentifiers'];
      String? isbn13;
      if (identifiers != null) {
        for (var id in identifiers) {
          if (id['type'] == 'ISBN_13') {
            isbn13 = id['identifier'];
            break;
          }
        }
      }

      if (isbn13 != null) {
        buyList.add(
          WatchProvider(
            name: 'Amazon',
            logoUrl: 'https://www.amazon.com/favicon.ico',
            tmdbLink: 'https://www.amazon.com/s?k=$isbn13',
          ),
        );
        buyList.add(
          WatchProvider(
            name: 'Barnes & Noble',
            logoUrl: 'https://www.barnesandnoble.com/favicon.ico',
            tmdbLink: 'https://www.barnesandnoble.com/s/$isbn13',
          ),
        );
      }

      // Read & Preview
      String? readUrl = accessInfo['webReaderLink'] ?? info['previewLink'];
      if (readUrl != null) {
        readList.add(
          WatchProvider(
            name: 'Google Books',
            logoUrl:
                'https://www.gstatic.com/images/branding/product/2x/books_48dp.png',
            tmdbLink: ensureHttps(readUrl),
          ),
        );
      }

      return {
        'book_providers': {
          if (readList.isNotEmpty) 'Read & Preview': readList,
          if (buyList.isNotEmpty) 'Buy': buyList,
          if (rentList.isNotEmpty) 'Rent': rentList,
        },
      };
    } catch (e) {
      debugPrint('Book Dynamic Content Error: $e');
      return {};
    }
  }

  MediaItemModel _mapToMediaItem(Map data) {
    final info = data['volumeInfo'] ?? {};
    return MediaItemModel(
      id: 'google_books_${data['id']}',
      apiId: data['id'],
      title: info['title'] ?? 'Unknown',
      subtitle: (info['authors'] as List?)?.join(', '),
      posterUrl: info['imageLinks']?['thumbnail'],
      type: 'books',
      extraData: Map<String, dynamic>.from(data),
    );
  }
}

class SearchServiceFactory {
  static SearchService getService(WishListType type) {
    switch (type) {
      case WishListType.movies:
        return MovieSearchService();
      case WishListType.tvSeries:
        return TvSearchService();
      case WishListType.books:
        return BookSearchService();
      default:
        return DefaultSearchService();
    }
  }
}

class DefaultSearchService implements SearchService {
  @override
  Future<List<MediaItemModel>> search(String query) async => [];
  @override
  Future<MediaItemModel?> getDetails(String id) async => null;
  @override
  Future<Map<String, dynamic>> getDynamicContent(String apiId) async => {};
}
