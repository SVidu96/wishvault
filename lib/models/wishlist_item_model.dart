import 'package:cloud_firestore/cloud_firestore.dart';

class WishListItemModel {
  final String id; // Unique ID for this entry in the user's list
  final String wishlistId;
  final String mediaItemId; // Link to the global MediaItemModel
  final String uid; // Personal user ID
  final double? rating;
  final String? review;
  final DateTime addedAt;
  final bool isCompleted;

  WishListItemModel({
    required this.id,
    required this.wishlistId,
    required this.mediaItemId,
    required this.uid,
    this.rating,
    this.review,
    required this.addedAt,
    this.isCompleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'wishlistId': wishlistId,
      'mediaItemId': mediaItemId,
      'uid': uid,
      'rating': rating,
      'review': review,
      'addedAt': addedAt.toIso8601String(),
      'isCompleted': isCompleted,
    };
  }

  factory WishListItemModel.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic date) {
      if (date is String) return DateTime.parse(date);
      if (date is Timestamp) return date.toDate();
      return DateTime.now();
    }

    return WishListItemModel(
      id: map['id'] ?? '',
      wishlistId: map['wishlistId'] ?? '',
      mediaItemId: map['mediaItemId'] ?? '',
      uid: map['uid'] ?? '',
      rating: (map['rating'] as num?)?.toDouble(),
      review: map['review'],
      addedAt: parseDate(map['addedAt']),
      isCompleted: map['isCompleted'] ?? false,
    );
  }
}
