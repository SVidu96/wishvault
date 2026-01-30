import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:url_launcher/url_launcher.dart';
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

class MediaItemDetailScreen extends StatefulWidget {
  final WishListItemModel? item; // Null if opened from search or deep link
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
  Map<String, List<WatchProvider>> _watchProviders = {};
  bool _isLoadingProviders = true;
  bool _isInMyList = false;
  WishListItemModel? _myListItem;

  @override
  void initState() {
    super.initState();
    _myListItem = widget.item;
    _isInMyList = widget.item != null;
    _currentRating = widget.item?.rating ?? 0.0;
    _reviewController.text = widget.item?.review ?? '';
    _loadWatchProviders();
    _checkIfInMyList();
  }

  Future<void> _checkIfInMyList() async {
    if (_isInMyList) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // We can't easily check all lists, but we can check if it's in ANY list for this user.
    // For now, if it's passed as null, we'll let it stay as "Add to List".
    // A more thorough check could be added to WishListItemService.
  }

  Future<void> _loadWatchProviders() async {
    final service = MovieSearchService();
    final providers = await service.getWatchProviders(widget.media.apiId);
    if (mounted) {
      setState(() {
        _watchProviders = providers;
        _isLoadingProviders = false;
      });
    }
  }

  Future<void> _shareMovie() async {
    final String shareUrl =
        '${Env.movieDetailBaseUrl}?id=${widget.media.apiId}';
    final String text =
        'Check out this movie: ${widget.media.title}\n$shareUrl';

    await Share.share(text, subject: 'WishVault Movie Share');
  }

  Future<void> _addToMyList() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isSaving = true);

    try {
      // 1. Find if user has a Movies list
      WishListModel? moviesList = await _wishListService.getFirstWishListByType(
        user.uid,
        WishListType.movies,
      );

      // 2. If no list, prompt to create
      if (moviesList == null) {
        if (mounted) {
          final bool? create = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('New Movie List'),
              content: const Text(
                'You don\'t have a Movie list yet. Create one now?',
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
            moviesList = WishListModel(
              id: const Uuid().v4(),
              uid: user.uid,
              title: 'My Movies',
              type: WishListType.movies,
              createdAt: DateTime.now(),
            );
            await _wishListService.createWishList(moviesList);
          } else {
            setState(() => _isSaving = false);
            return;
          }
        }
      }

      if (moviesList != null) {
        await _itemService.addItemToList(user.uid, moviesList.id, widget.media);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Added to your Movie list!')),
          );
          setState(() {
            _isInMyList = true;
            // We'd need to fetch the newly created WishListItemModel to get the true ID if we wanted to allow editing immediately.
            // For now, simplicity.
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

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not launch deep link')));
      }
    }
  }

  Future<void> _updateRating(double rating) async {
    if (!_isInMyList || _myListItem == null) return;

    setState(() => _isSaving = true);
    try {
      await _itemService.updateItemDetails(_myListItem!.id, rating: rating);
      setState(() => _currentRating = rating);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update rating: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _saveReview() async {
    if (!_isInMyList || _myListItem == null) return;

    setState(() => _isSaving = true);
    try {
      await _itemService.updateItemDetails(
        _myListItem!.id,
        review: _reviewController.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Review saved!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save review: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final overview =
        widget.media.extraData?['overview'] ?? 'No description available.';
    final releaseDate = widget.media.extraData?['release_date'] ?? 'Unknown';
    final voteAverage =
        widget.media.extraData?['vote_average']?.toString() ?? 'N/A';

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
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildInfoBadge(Icons.calendar_today, releaseDate),
                      const SizedBox(width: 12),
                      _buildInfoBadge(Icons.star, '$voteAverage (TMDB)'),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Add to List Button if not already in list
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

                  const SizedBox(height: 24),

                  // Categorized Watch Providers
                  if (_isLoadingProviders)
                    const Center(child: CircularProgressIndicator())
                  else
                    ..._buildWatchProviderSections(),

                  const SizedBox(height: 32),

                  // Personal Rating (Only if in list)
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
                        onRatingUpdate: _updateRating,
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),
                  Text(
                    'Overview',
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
                        hintText: 'Add your personal review or notes here...',
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
                        onPressed: _isSaving ? null : _saveReview,
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

  List<Widget> _buildWatchProviderSections() {
    List<Widget> sections = [];
    _watchProviders.forEach((category, providers) {
      if (providers.isNotEmpty) {
        sections.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: providers
                      .map((p) => _buildProviderIcon(p))
                      .toList(),
                ),
              ],
            ),
          ),
        );
      }
    });

    if (sections.isEmpty && !_isLoadingProviders) {
      sections.add(
        Text(
          'Not available to stream currently',
          style: GoogleFonts.roboto(color: Colors.grey),
        ),
      );
    }
    return sections;
  }

  Widget _buildProviderIcon(WatchProvider provider) {
    return GestureDetector(
      onTap: () => _launchUrl(provider.tmdbLink),
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey[200],
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            provider.logoUrl,
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.broken_image, size: 20),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: Theme.of(context).colorScheme.onSecondaryContainer,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.roboto(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
