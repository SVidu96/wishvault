import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/wishlist_model.dart';
import '../services/wishlist_service.dart';
import '../screens/wishlist_detail_screen.dart';

class WishListsTabView extends StatelessWidget {
  final String uid;
  final WishListService _wishListService = WishListService();

  WishListsTabView({super.key, required this.uid});

  IconData _getIconForType(WishListType type) {
    switch (type) {
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

  @override
  Widget build(BuildContext context) {
    return Container(
      child: StreamBuilder<List<WishListModel>>(
        stream: _wishListService.getUserWishLists(uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: Colors.red,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Search Error',
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.roboto(
                        color: Colors.red[700],
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final wishLists = snapshot.data ?? [];

          if (wishLists.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.card_giftcard_rounded,
                    size: 64,
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Wish Lists yet',
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + to create your first list!',
                    style: GoogleFonts.roboto(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: wishLists.length,
            itemBuilder: (context, index) {
              final list = wishLists[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: Icon(
                      _getIconForType(list.type),
                      color: Colors.white,
                    ),
                  ),
                  title: Text(
                    list.title,
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    list.type.displayName,
                    style: GoogleFonts.roboto(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            WishListDetailScreen(wishList: list),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
