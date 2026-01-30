import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../models/wishlist_model.dart';
import '../services/wishlist_service.dart';

class CreateWishListSheet extends StatefulWidget {
  final String uid;
  final VoidCallback onCreated;

  const CreateWishListSheet({
    super.key,
    required this.uid,
    required this.onCreated,
  });

  @override
  State<CreateWishListSheet> createState() => _CreateWishListSheetState();
}

class _CreateWishListSheetState extends State<CreateWishListSheet> {
  final _titleController = TextEditingController();
  WishListType _selectedType = WishListType.movies;
  final WishListService _wishListService = WishListService();
  bool _isCreating = false;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

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

  Future<void> _createList() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a title')));
      return;
    }

    setState(() => _isCreating = true);

    try {
      final newList = WishListModel(
        id: const Uuid().v4(),
        uid: widget.uid,
        title: title,
        type: _selectedType,
        createdAt: DateTime.now(),
      );

      await _wishListService.createWishList(newList);
      widget.onCreated();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error creating list: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Create New List',
              style: GoogleFonts.outfit(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'List Title',
                hintText: 'e.g., My Must Watch Movies',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                prefixIcon: const Icon(Icons.title_rounded),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 24),
            Text(
              'Select Type',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: WishListType.values.map((type) {
                final isSelected = _selectedType == type;
                return ChoiceChip(
                  label: Text(type.displayName),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedType = type);
                    }
                  },
                  backgroundColor: Colors.grey[100],
                  selectedColor: Theme.of(context).colorScheme.primaryContainer,
                  labelStyle: GoogleFonts.roboto(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.black87,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                  avatar: Icon(
                    _getIconForType(type),
                    size: 16,
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey[600],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isCreating ? null : _createList,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: _isCreating
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        'Create List',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
