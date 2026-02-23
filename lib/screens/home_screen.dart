import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../views/home_tab_view.dart';
import '../views/wishlists_tab_view.dart';
import '../views/placeholder_view.dart';
import '../widgets/create_wishlist_sheet.dart';

class HomeScreen extends StatefulWidget {
  final UserModel user;

  const HomeScreen({super.key, required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  int _selectedIndex = 0;

  Future<void> _handleSignOut() async {
    try {
      await _authService.signOut();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error signing out: $e')));
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _showCreateWishListSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreateWishListSheet(
        uid: widget.user.uid,
        onCreated: () => Navigator.pop(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      HomeTabView(user: widget.user),
      WishListsTabView(uid: widget.user.uid),
      const PlaceholderView(title: 'Social'),
      const PlaceholderView(title: 'Notifications'),
      const PlaceholderView(title: 'Settings'),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'WishVault',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
            onPressed: _handleSignOut,
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: pages[_selectedIndex],
      ),
      floatingActionButton: _selectedIndex == 1
          ? FloatingActionButton.extended(
              onPressed: _showCreateWishListSheet,
              label: const Text('Add'),
              icon: const Icon(Icons.add),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            )
          : null,
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Theme.of(context).colorScheme.surface,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Theme.of(context).colorScheme.onSurfaceVariant,
        selectedLabelStyle: GoogleFonts.outfit(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelStyle: GoogleFonts.outfit(fontSize: 12),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.card_giftcard_outlined),
            activeIcon: Icon(Icons.card_giftcard_rounded),
            label: 'Wish Lists',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline_rounded),
            activeIcon: Icon(Icons.people_rounded),
            label: 'Social',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_none_rounded),
            activeIcon: Icon(Icons.notifications_rounded),
            label: 'Notifications',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
