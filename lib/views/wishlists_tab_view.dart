import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../models/wishlist_model.dart';
import '../services/wishlist_service.dart';
import '../screens/wishlist_detail_screen.dart';
import '../core/config/env.dart';

class WishListsTabView extends StatefulWidget {
  final String uid;

  const WishListsTabView({super.key, required this.uid});

  @override
  State<WishListsTabView> createState() => _WishListsTabViewState();
}

class _WishListsTabViewState extends State<WishListsTabView> {
  final WishListService _wishListService = WishListService();
  WishListModel? _selectedList;

  void _clearSelection() {
    setState(() {
      _selectedList = null;
    });
  }

  Future<void> _handleRename() async {
    if (_selectedList == null) return;

    final TextEditingController controller = TextEditingController(
      text: _selectedList!.title,
    );

    final bool? renamed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Rename List',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'New list name',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                await _wishListService.updateWishListTitle(
                  _selectedList!.id,
                  newName,
                );
                if (context.mounted) Navigator.pop(context, true);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (renamed == true) {
      _clearSelection();
    }
  }

  Future<void> _handleDelete() async {
    if (_selectedList == null) return;

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete List?',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to delete "${_selectedList!.title}"? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _wishListService.deleteWishList(_selectedList!.id);
              if (context.mounted) Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      _clearSelection();
    }
  }

  Future<void> _handleShare() async {
    if (_selectedList == null) return;

    final String shareUrl =
        '${Env.appScheme}://${Env.appDomain}/list?id=${_selectedList!.id}&uid=${widget.uid}';
    final String text =
        'Check out my "${_selectedList!.title}" wishlist on WishVault!\n$shareUrl';

    await Share.share(text, subject: 'WishVault List Share');
    _clearSelection();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            // Contextual Action Bar
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: _selectedList != null ? 60 : 0,
              color: Theme.of(context).colorScheme.primaryContainer,
              child: _selectedList != null
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: _clearSelection,
                          ),
                          Expanded(
                            child: Text(
                              'Selected: ${_selectedList!.title}',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.share_rounded, size: 20),
                            tooltip: 'Share List',
                            onPressed: _handleShare,
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 20),
                            tooltip: 'Rename',
                            onPressed: _handleRename,
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              size: 20,
                              color: Colors.red,
                            ),
                            tooltip: 'Delete',
                            onPressed: _handleDelete,
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            Expanded(
              child: StreamBuilder<List<WishListModel>>(
                stream: _wishListService.getUserWishLists(widget.uid),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
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
                            ).colorScheme.primary.withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No Wish Lists yet',
                            style: GoogleFonts.outfit(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
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
                      final isSelected = _selectedList?.id == list.id;

                      return GestureDetector(
                        onLongPress: () {
                          setState(() {
                            _selectedList = list;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: isSelected
                                ? Border.all(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    width: 2,
                                  )
                                : null,
                          ),
                          child: Card(
                            elevation: isSelected ? 4 : 1,
                            margin: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              leading: CircleAvatar(
                                backgroundColor: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.primary
                                          .withValues(alpha: 0.1),
                                child: Icon(
                                  list.type.icon,
                                  color: isSelected
                                      ? Colors.white
                                      : Theme.of(context).colorScheme.primary,
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
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                              ),
                              trailing: isSelected
                                  ? const Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                    )
                                  : const Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      size: 16,
                                    ),
                              onTap: () {
                                if (_selectedList != null) {
                                  _clearSelection();
                                } else {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          WishListDetailScreen(wishList: list),
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
