import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/wishlist_model.dart';

class WishListService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String collectionPath = 'wishlists';

  // Create a new wish list
  Future<void> createWishList(WishListModel wishList) async {
    try {
      await _firestore
          .collection(collectionPath)
          .doc(wishList.id)
          .set(wishList.toMap());
    } catch (e) {
      print('Error creating wish list: $e');
      rethrow;
    }
  }

  // Get wish lists for a specific user
  Stream<List<WishListModel>> getUserWishLists(String uid) {
    // Note: Ensure collection name is 'wishlists' (all lowercase)
    // and field name is 'userId'
    return _firestore
        .collection(collectionPath)
        .where('uid', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => WishListModel.fromMap(doc.data()))
              .toList();
        });
  }

  // Get the first wish list of a specific type for a user
  Future<WishListModel?> getFirstWishListByType(
    String uid,
    WishListType type,
  ) async {
    final snapshot = await _firestore
        .collection(collectionPath)
        .where('uid', isEqualTo: uid)
        .where('type', isEqualTo: type.name)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return WishListModel.fromMap(snapshot.docs.first.data());
  }

  // Update a wish list title
  Future<void> updateWishListTitle(String wishListId, String newTitle) async {
    try {
      await _firestore.collection(collectionPath).doc(wishListId).update({
        'title': newTitle,
      });
    } catch (e) {
      print('Error updating wish list title: $e');
      rethrow;
    }
  }

  // Delete a wish list
  Future<void> deleteWishList(String wishListId) async {
    try {
      await _firestore.collection(collectionPath).doc(wishListId).delete();
    } catch (e) {
      print('Error deleting wish list: $e');
      rethrow;
    }
  }
}
