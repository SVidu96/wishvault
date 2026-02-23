import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:app_links/app_links.dart';
import 'firebase_options.dart';
import 'widgets/auth_wrapper.dart';
import 'services/search_service.dart';
import 'services/wishlist_service.dart';
import 'screens/media_item_detail_screen.dart';
import 'screens/wishlist_detail_screen.dart';
import 'core/config/env.dart';
import 'models/wishlist_model.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  void _initDeepLinks() {
    _appLinks = AppLinks();

    // Handle links when app is in background/foreground
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    });

    // Handle initial link (when app is launched via link)
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) _handleDeepLink(uri);
    });
  }

  void _handleDeepLink(Uri uri) async {
    debugPrint('Incoming Deep Link: $uri');

    // ITEM LINKS (Movies, Books, TV, etc.)
    // Production: https://[domain]/item?id=xxx&type=xxx (or legacy /movie)
    // Testing: wishvault://item?id=xxx&type=xxx
    bool isItemWeb =
        uri.host == Env.appDomain &&
        (uri.path.contains('item') || uri.path.contains('movie'));
    bool isItemCustom =
        uri.scheme == 'wishvault' &&
        (uri.host == 'item' || uri.host == 'movie');

    if (isItemWeb || isItemCustom) {
      final String? id = uri.queryParameters['id'];
      final String? typeStr = uri.queryParameters['type'];
      if (id != null) {
        _navigateToItem(id, WishListType.fromString(typeStr ?? 'movies'));
      }
      return;
    }

    // LIST LINKS
    // Production: https://[domain]/list?id=xxx
    // Testing: wishvault://list?id=xxx
    bool isListWeb = uri.host == Env.appDomain && uri.path.contains('list');
    bool isListCustom = uri.scheme == 'wishvault' && uri.host == 'list';

    if (isListWeb || isListCustom) {
      final String? id = uri.queryParameters['id'];
      if (id != null) {
        _navigateToList(id);
      }
    }
  }

  Future<void> _navigateToList(String id) async {
    final wishListService = WishListService();
    final wishList = await wishListService.getWishListById(id);

    if (wishList != null && navigatorKey.currentState != null) {
      navigatorKey.currentState!.push(
        MaterialPageRoute(
          builder: (context) => WishListDetailScreen(wishList: wishList),
        ),
      );
    }
  }

  Future<void> _navigateToItem(String id, WishListType type) async {
    final searchService = SearchServiceFactory.getService(type);
    final media = await searchService.getDetails(id);

    if (media != null && navigatorKey.currentState != null) {
      navigatorKey.currentState!.push(
        MaterialPageRoute(
          builder: (context) => MediaItemDetailScreen(media: media),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WishVault',
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
    );
  }
}
