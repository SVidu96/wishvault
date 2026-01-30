class MediaItemModel {
  final String id; // Global ID in our DB
  final String apiId; // ID from external API (TMDB, etc.)
  final String title;
  final String? subtitle;
  final String? posterUrl;
  final String type; // movie, book, etc.
  final Map<String, dynamic>? extraData; // Any other API-specific data

  MediaItemModel({
    required this.id,
    required this.apiId,
    required this.title,
    this.subtitle,
    this.posterUrl,
    required this.type,
    this.extraData,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'apiId': apiId,
      'title': title,
      'subtitle': subtitle,
      'posterUrl': posterUrl,
      'type': type,
      'extraData': extraData,
    };
  }

  factory MediaItemModel.fromMap(Map<String, dynamic> map) {
    return MediaItemModel(
      id: map['id'] ?? '',
      apiId: map['apiId'] ?? '',
      title: map['title'] ?? '',
      subtitle: map['subtitle'],
      posterUrl: map['posterUrl'],
      type: map['type'] ?? '',
      extraData: map['extraData'],
    );
  }
}
