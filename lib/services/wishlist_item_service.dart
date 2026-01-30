import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/wishlist_item_model.dart';
import '../models/media_item_model.dart';

class WishListItemService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _mediaCollection = 'media_items';
  static const String _itemsCollection = 'wishlist_items';

  // Add an item to a wishlist
  Future<void> addItemToList(
    String uid,
    String wishlistId,
    MediaItemModel mediaItem,
  ) async {
    // 1. Ensure the media item exists in the global collection
    final mediaDoc = _firestore.collection(_mediaCollection).doc(mediaItem.id);
    final docSnapshot = await mediaDoc.get();

    if (!docSnapshot.exists) {
      await mediaDoc.set(mediaItem.toMap());
    }

    // 2. Check if this item is already in this specific wishlist for this user
    final existingItem = await _firestore
        .collection(_itemsCollection)
        .where('uid', isEqualTo: uid)
        .where('wishlistId', isEqualTo: wishlistId)
        .where('mediaItemId', isEqualTo: mediaItem.id)
        .get();

    if (existingItem.docs.isNotEmpty) {
      throw Exception('Item already in this list');
    }

    // 3. Create the unique user-list relationship
    final itemId = '${wishlistId}_${mediaItem.id}';
    final newItem = WishListItemModel(
      id: itemId,
      wishlistId: wishlistId,
      mediaItemId: mediaItem.id,
      uid: uid,
      addedAt: DateTime.now(),
    );

    await _firestore
        .collection(_itemsCollection)
        .doc(itemId)
        .set(newItem.toMap());
  }

  // Get all items in a specific wishlist
  Stream<List<Map<String, dynamic>>> getWishListItems(String wishlistId) {
    return _firestore
        .collection(_itemsCollection)
        .where('wishlistId', isEqualTo: wishlistId)
        .snapshots()
        .asyncMap((snapshot) async {
          List<Map<String, dynamic>> itemsWithMedia = [];

          for (var doc in snapshot.docs) {
            final itemData = doc.data();
            final mediaId = itemData['mediaItemId'];

            // Fetch the global media data for this item
            final mediaDoc = await _firestore
                .collection(_mediaCollection)
                .doc(mediaId)
                .get();

            if (mediaDoc.exists) {
              itemsWithMedia.add({
                'item': WishListItemModel.fromMap(itemData),
                'media': MediaItemModel.fromMap(mediaDoc.data()!),
              });
            }
          }
          return itemsWithMedia;
        });
  }

  // Update user specific data (rating/review)
  Future<void> updateItemDetails(
    String itemId, {
    double? rating,
    String? review,
  }) async {
    Map<String, dynamic> updates = {};
    if (rating != null) updates['rating'] = rating;
    if (review != null) updates['review'] = review;

    if (updates.isNotEmpty) {
      await _firestore.collection(_itemsCollection).doc(itemId).update(updates);
    }
  }

  // Delete an item from a list
  Future<void> removeItemFromList(String itemId) async {
    await _firestore.collection(_itemsCollection).doc(itemId).delete();
  }
}
