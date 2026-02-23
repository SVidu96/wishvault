import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum WishListType {
  movies,
  tvSeries,
  books,
  restaurants,
  places,
  other;

  String get displayName {
    switch (this) {
      case WishListType.movies:
        return 'Movies';
      case WishListType.tvSeries:
        return 'TV Series';
      case WishListType.books:
        return 'Books';
      case WishListType.restaurants:
        return 'Restaurants';
      case WishListType.places:
        return 'Places';
      case WishListType.other:
        return 'Other';
    }
  }

  IconData get icon {
    switch (this) {
      case WishListType.movies:
        return Icons.movie_rounded;
      case WishListType.tvSeries:
        return Icons.live_tv_rounded;
      case WishListType.books:
        return Icons.menu_book_rounded;
      case WishListType.restaurants:
        return Icons.restaurant_rounded;
      case WishListType.places:
        return Icons.place_rounded;
      case WishListType.other:
        return Icons.more_horiz_rounded;
    }
  }

  static WishListType fromString(String value) {
    return WishListType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => WishListType.other,
    );
  }
}

class WishListModel {
  final String id;
  final String uid; // Standardized to uid
  final String title;
  final WishListType type;
  final DateTime createdAt;

  WishListModel({
    required this.id,
    required this.uid,
    required this.title,
    required this.type,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'uid': uid,
      'title': title,
      'type': type.name,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory WishListModel.fromMap(Map<String, dynamic> map) {
    // Handle different date formats (String or Timestamp)
    DateTime parseDate(dynamic date) {
      if (date is String) return DateTime.parse(date);
      if (date is Timestamp) return date.toDate();
      return DateTime.now();
    }

    return WishListModel(
      id: map['id'] ?? '',
      uid: map['uid'] ?? '',
      title: map['title'] ?? '',
      type: WishListType.fromString(map['type'] ?? 'other'),
      createdAt: parseDate(map['createdAt']),
    );
  }
}
