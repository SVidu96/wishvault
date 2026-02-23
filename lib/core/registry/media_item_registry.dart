import 'package:flutter/material.dart';
import '../../models/media_item_model.dart';
import '../../models/watch_provider_model.dart';
import '../../models/wishlist_model.dart';
import '../../services/search_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

/// The single source of truth for a Media Type's behavior, search, and UI.
abstract class MediaDefinition {
  WishListType get type;
  IconData get icon;
  String get displayName => type.displayName;

  // Search Capability
  SearchService get searchService;

  // UI Capability: Badges
  List<Widget> buildBadges(BuildContext context, MediaItemModel media);

  // UI Capability: Custom Sections (e.g. providers)
  List<Widget> buildCustomSections(
    BuildContext context,
    Map<String, dynamic> extraContent,
  );

  // Common UI Helper: Badge
  @protected
  Widget buildBadge(BuildContext context, IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.secondaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // Common UI Helper: Provider Section
  @protected
  Widget buildProviderSection(
    BuildContext context,
    String title,
    List<WatchProvider> providers,
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 16,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title.toUpperCase(),
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 20,
            runSpacing: 20,
            children: providers
                .map((p) => _buildProviderIcon(context, p))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildProviderIcon(BuildContext context, WatchProvider p) {
    return InkWell(
      onTap: () async {
        final uri = Uri.parse(p.tmdbLink);
        try {
          final launched = await launchUrl(
            uri,
            mode: LaunchMode.externalApplication,
          );
          if (!launched) debugPrint('Could not launch ${p.tmdbLink}');
        } catch (e) {
          debugPrint('Error launching URL: $e');
          try {
            await launchUrl(uri);
          } catch (_) {}
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
              image: DecorationImage(
                image: NetworkImage(p.logoUrl),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 60,
            child: Text(
              p.name,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The global registry that manages all media types.
class MediaRegistry {
  static final Map<WishListType, MediaDefinition> _definitions = {};

  static void register(MediaDefinition definition) {
    _definitions[definition.type] = definition;
  }

  static MediaDefinition getDefinition(WishListType type) {
    return _definitions[type] ?? _definitions[WishListType.other]!;
  }

  static MediaDefinition getDefinitionByString(String typeStr) {
    final type = WishListType.fromString(typeStr);
    return getDefinition(type);
  }
}
