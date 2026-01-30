import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/wishlist_model.dart';
import '../models/wishlist_item_model.dart';
import '../models/media_item_model.dart';
import '../services/wishlist_item_service.dart';
import 'add_item_screen.dart';
import 'media_item_detail_screen.dart';

class WishListDetailScreen extends StatefulWidget {
  final WishListModel wishList;

  const WishListDetailScreen({super.key, required this.wishList});

  @override
  State<WishListDetailScreen> createState() => _WishListDetailScreenState();
}

class _WishListDetailScreenState extends State<WishListDetailScreen> {
  final WishListItemService _itemService = WishListItemService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.wishList.title,
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _itemService.getWishListItems(widget.wishList.id),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = snapshot.data ?? [];

          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 64,
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No items in this list',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + to add your first ${widget.wishList.type.displayName.toLowerCase()}!',
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
            itemCount: items.length,
            itemBuilder: (context, index) {
              final itemMap = items[index];
              final WishListItemModel item = itemMap['item'];
              final MediaItemModel media = itemMap['media'];

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: Container(
                    width: 60,
                    height: 90,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[200],
                      image: media.posterUrl != null
                          ? DecorationImage(
                              image: NetworkImage(media.posterUrl!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: media.posterUrl == null
                        ? const Icon(Icons.image_not_supported_outlined)
                        : null,
                  ),
                  title: Text(
                    media.title,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (media.subtitle != null)
                        Text(
                          media.subtitle!,
                          style: GoogleFonts.roboto(
                            fontSize: 12,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      if (item.rating != null)
                        Row(
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              color: Colors.amber,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              item.rating!.toStringAsFixed(1),
                              style: GoogleFonts.roboto(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            MediaItemDetailScreen(item: item, media: media),
                      ),
                    );
                  },
                  trailing: PopupMenuButton(
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Remove from List'),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'delete') {
                        _itemService.removeItemFromList(item.id);
                      }
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddItemScreen(wishList: widget.wishList),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
