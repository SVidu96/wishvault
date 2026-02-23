import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:share_plus/share_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../models/media_item_model.dart';
import '../models/wishlist_item_model.dart';
import '../models/wishlist_model.dart';
import '../services/wishlist_item_service.dart';
import '../services/search_service.dart';
import '../services/wishlist_service.dart';
import '../core/config/env.dart';
import '../core/registry/media_item_registry.dart';

class MediaItemDetailScreen extends StatefulWidget {
  final WishListItemModel? item;
  final MediaItemModel media;

  const MediaItemDetailScreen({super.key, this.item, required this.media});

  @override
  State<MediaItemDetailScreen> createState() => _MediaItemDetailScreenState();
}

class _MediaItemDetailScreenState extends State<MediaItemDetailScreen> {
  final WishListItemService _itemService = WishListItemService();
  final WishListService _wishListService = WishListService();

  late double _currentRating;
  final TextEditingController _reviewController = TextEditingController();
  bool _isSaving = false;
  Map<String, dynamic> _dynamicContent = {};
  bool _isLoadingContent = true;
  bool _isInMyList = false;
  late MediaItemTypeConfig _config;

  @override
  void initState() {
    super.initState();
    _config = MediaItemRegistry.getConfig(widget.media.type);
    _isInMyList = widget.item != null;
    _currentRating = widget.item?.rating ?? 0.0;
    _reviewController.text = widget.item?.review ?? '';
    _loadDynamicContent();
  }

  Future<void> _loadDynamicContent() async {
    final service = SearchServiceFactory.getService(
      WishListType.fromString(widget.media.type),
    );
    final content = await service.getDynamicContent(widget.media.apiId);
    if (mounted) {
      setState(() {
        _dynamicContent = content;
        _isLoadingContent = false;
      });
    }
  }

  Future<void> _shareMovie() async {
    final String shareUrl =
        '${Env.itemDetailBaseUrl}?id=${widget.media.apiId}&type=${widget.media.type}';
    final String text =
        'Check out this ${widget.media.type}: ${widget.media.title}\n$shareUrl';
    await Share.share(text, subject: 'WishVault Share');
  }

  Future<void> _addToMyList() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isSaving = true);

    try {
      final type = WishListType.fromString(widget.media.type);
      WishListModel? targetList = await _wishListService.getFirstWishListByType(
        user.uid,
        type,
      );

      if (targetList == null) {
        if (mounted) {
          final bool? create = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text('New ${type.displayName} List'),
              content: Text(
                'You don\'t have a ${type.displayName} list yet. Create one now?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Create'),
                ),
              ],
            ),
          );

          if (create == true) {
            targetList = WishListModel(
              id: const Uuid().v4(),
              uid: user.uid,
              title: 'My ${type.displayName}',
              type: type,
              createdAt: DateTime.now(),
            );
            await _wishListService.createWishList(targetList);
          } else {
            setState(() => _isSaving = false);
            return;
          }
        }
      }

      if (targetList != null) {
        await _itemService.addItemToList(user.uid, targetList.id, widget.media);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Added to your ${type.displayName} list!')),
          );
          setState(() {
            _isInMyList = true;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().contains('already')
                  ? 'Item already in list'
                  : 'Error: $e',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final overview =
        widget.media.extraData?['overview'] ??
        widget.media.extraData?['volumeInfo']?['description'] ??
        'No description available.';

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 400,
            pinned: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.share_rounded),
                onPressed: _shareMovie,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black26,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (widget.media.posterUrl != null)
                    Image.network(widget.media.posterUrl!, fit: BoxFit.cover)
                  else
                    Container(color: Colors.grey[300]),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black87],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.media.title,
                    style: GoogleFonts.outfit(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // DYNAMIC BADGES (from Registry)
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: _config.buildBadges(context, widget.media),
                  ),

                  const SizedBox(height: 24),

                  if (!_isInMyList)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _addToMyList,
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Add to my WishVault'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),

                  // DYNAMIC SECTIONS (e.g., streaming providers)
                  if (_isLoadingContent)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else
                    ..._config.buildCustomSections(context, _dynamicContent),

                  const SizedBox(height: 32),

                  if (_isInMyList) ...[
                    Text(
                      'Your Rating',
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: RatingBar.builder(
                        initialRating: _currentRating,
                        minRating: 0,
                        direction: Axis.horizontal,
                        allowHalfRating: true,
                        itemCount: 5,
                        itemPadding: const EdgeInsets.symmetric(
                          horizontal: 4.0,
                        ),
                        itemBuilder: (context, _) =>
                            const Icon(Icons.star_rounded, color: Colors.amber),
                        onRatingUpdate: (rating) async {
                          if (widget.item != null) {
                            await _itemService.updateItemDetails(
                              widget.item!.id,
                              rating: rating,
                            );
                          }
                        },
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),
                  Text(
                    'Description',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    overview,
                    style: GoogleFonts.roboto(
                      fontSize: 16,
                      height: 1.6,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),

                  if (_isInMyList) ...[
                    const SizedBox(height: 32),
                    Text(
                      'Private Notes',
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _reviewController,
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText: 'Add your personal notes here...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        filled: true,
                        fillColor: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerLow,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          if (widget.item != null) {
                            await _itemService.updateItemDetails(
                              widget.item!.id,
                              review: _reviewController.text,
                            );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Saved!')),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.save_rounded),
                        label: const Text('Save Notes'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
