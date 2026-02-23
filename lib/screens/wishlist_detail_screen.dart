import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../models/wishlist_model.dart';
import '../models/wishlist_item_model.dart';
import '../models/media_item_model.dart';
import '../services/wishlist_item_service.dart';
import '../services/wishlist_service.dart';
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
  final WishListService _wishListService = WishListService();
  late String _currentTitle;
  bool _isOwner = false;
  bool _isImporting = false;

  @override
  void initState() {
    super.initState();
    _currentTitle = widget.wishList.title;
    _checkOwnership();
  }

  void _checkOwnership() {
    final user = FirebaseAuth.instance.currentUser;
    setState(() {
      _isOwner = user != null && user.uid == widget.wishList.uid;
    });
  }

  Future<void> _importList() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // 1. Fetch current items in the shared list
    final List<Map<String, dynamic>> items = await _itemService
        .getWishListItems(widget.wishList.id)
        .first;

    if (items.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('This list is empty.')));
      }
      return;
    }

    if (!mounted) return;

    // 2. Show choice: Create new or Add to existing
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _ImportOptionsDialog(
        uid: user.uid,
        type: widget.wishList.type,
        sharedListTitle: widget.wishList.title,
      ),
    );

    if (result == null) return;

    setState(() => _isImporting = true);

    try {
      String targetListId;
      if (result['isNew'] == true) {
        // Create new list
        targetListId = const Uuid().v4();
        final newList = WishListModel(
          id: targetListId,
          uid: user.uid,
          title: result['title'],
          type: widget.wishList.type,
          createdAt: DateTime.now(),
        );
        await _wishListService.createWishList(newList);
      } else {
        // Use existing list
        targetListId = result['listId'];
      }

      // 3. Copy items
      int successCount = 0;
      for (var itemMap in items) {
        final MediaItemModel media = itemMap['media'];
        try {
          await _itemService.addItemToList(user.uid, targetListId, media);
          successCount++;
        } catch (e) {
          // Skip if already in list
          debugPrint('Item skip: $e');
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Successfully imported $successCount items to your list!',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Import failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  Future<void> _showRenameDialog() async {
    final TextEditingController controller = TextEditingController(
      text: _currentTitle,
    );
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Rename List',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: 'Enter new list name',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newTitle = controller.text.trim();
                if (newTitle.isNotEmpty && newTitle != _currentTitle) {
                  try {
                    await _wishListService.updateWishListTitle(
                      widget.wishList.id,
                      newTitle,
                    );
                    setState(() {
                      _currentTitle = newTitle;
                    });
                    if (context.mounted) Navigator.pop(context);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error renaming list: $e')),
                      );
                    }
                  }
                } else {
                  Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _currentTitle,
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (_isOwner)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Rename List',
              onPressed: _showRenameDialog,
            )
          else
            TextButton.icon(
              onPressed: _isImporting ? null : _importList,
              icon: _isImporting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_alt_rounded),
              label: const Text('Save to my WishVault'),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
              ),
            ),
        ],
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
                    ).colorScheme.primary.withValues(alpha: 0.3),
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
                  trailing: _isOwner
                      ? PopupMenuButton(
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
                        )
                      : null,
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: _isOwner
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        AddItemScreen(wishList: widget.wishList),
                  ),
                );
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

class _ImportOptionsDialog extends StatefulWidget {
  final String uid;
  final WishListType type;
  final String sharedListTitle;

  const _ImportOptionsDialog({
    required this.uid,
    required this.type,
    required this.sharedListTitle,
  });

  @override
  State<_ImportOptionsDialog> createState() => _ImportOptionsDialogState();
}

class _ImportOptionsDialogState extends State<_ImportOptionsDialog> {
  final WishListService _wishListService = WishListService();
  bool _createNew = true;
  String? _selectedListId;
  late TextEditingController _titleController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.sharedListTitle);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Save to my WishVault',
        style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<bool>(
              title: const Text('Create a new list'),
              value: true,
              groupValue: _createNew,
              onChanged: (v) => setState(() => _createNew = v!),
            ),
            if (_createNew)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'List Title'),
                ),
              ),
            RadioListTile<bool>(
              title: const Text('Add to an existing list'),
              value: false,
              groupValue: _createNew,
              onChanged: (v) => setState(() => _createNew = v!),
            ),
            if (!_createNew)
              StreamBuilder<List<WishListModel>>(
                stream: _wishListService.getUserWishLists(widget.uid),
                builder: (context, snapshot) {
                  final lists =
                      snapshot.data
                          ?.where((l) => l.type == widget.type)
                          .toList() ??
                      [];
                  if (lists.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('No existing lists of this type found.'),
                    );
                  }
                  return DropdownButtonFormField<String>(
                    initialValue: _selectedListId,
                    items: lists
                        .map(
                          (l) => DropdownMenuItem(
                            value: l.id,
                            child: Text(l.title),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _selectedListId = v),
                    decoration: const InputDecoration(
                      hintText: 'Select a list',
                    ),
                  );
                },
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_createNew) {
              if (_titleController.text.trim().isEmpty) return;
              Navigator.pop(context, {
                'isNew': true,
                'title': _titleController.text.trim(),
              });
            } else {
              if (_selectedListId == null) return;
              Navigator.pop(context, {
                'isNew': false,
                'listId': _selectedListId,
              });
            }
          },
          child: const Text('Import'),
        ),
      ],
    );
  }
}
