import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/wishlist_model.dart';
import '../models/media_item_model.dart';
import '../services/search_service.dart';
import '../services/wishlist_item_service.dart';
import '../core/registry/media_item_registry.dart';
import 'media_item_detail_screen.dart';

class AddItemScreen extends StatefulWidget {
  final WishListModel wishList;

  const AddItemScreen({super.key, required this.wishList});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final TextEditingController _searchController = TextEditingController();
  final WishListItemService _itemService = WishListItemService();
  late SearchService _searchService;

  List<MediaItemModel> _searchResults = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _searchService = SearchServiceFactory.getService(widget.wishList.type);
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final results = await _searchService.search(query);
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Search failed: $e')));
      }
    }
  }

  Future<void> _addItem(MediaItemModel mediaItem) async {
    try {
      await _itemService.addItemToList(
        widget.wishList.uid,
        widget.wishList.id,
        mediaItem,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Added "${mediaItem.title}" to list')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Add to ${widget.wishList.title}',
          style: GoogleFonts.outfit(fontSize: 18),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText:
                    'Search for ${widget.wishList.type.displayName.toLowerCase()}...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _performSearch('');
                  },
                ),
              ),
              onSubmitted: _performSearch,
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _searchResults.isEmpty
                ? Center(
                    child: Text(
                      _searchController.text.isEmpty
                          ? 'Search for something amazing!'
                          : 'No results found',
                      style: GoogleFonts.outfit(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final item = _searchResults[index];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: 50,
                            height: 75,
                            color: Colors.grey[200],
                            child: item.posterUrl != null
                                ? Image.network(
                                    item.posterUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, e, s) =>
                                        const Icon(Icons.broken_image),
                                  )
                                : Icon(
                                    MediaRegistry.getDefinitionByString(
                                      item.type,
                                    ).icon,
                                  ),
                          ),
                        ),
                        title: Text(
                          item.title,
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: item.subtitle != null
                            ? Text(item.subtitle!)
                            : null,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MediaItemDetailScreen(
                                media: item,
                                // item: null by default
                              ),
                            ),
                          );
                        },
                        trailing: IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: () => _addItem(item),
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
