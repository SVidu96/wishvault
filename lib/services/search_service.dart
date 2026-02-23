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
      final response = await http.get(
        Uri.parse('https://www.googleapis.com/books/v1/volumes?q=$query'),
      );
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
      final response = await http.get(
        Uri.parse('https://www.googleapis.com/books/v1/volumes/$id'),
      );
      if (response.statusCode == 200) {
        return _mapToMediaItem(json.decode(response.body));
      }
    } catch (e) {
      debugPrint('Book Details Error: $e');
    }
    return null;
  }

  @override
  Future<Map<String, dynamic>> getDynamicContent(String apiId) async => {};

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
