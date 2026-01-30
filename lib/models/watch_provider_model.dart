class WatchProvider {
  final String name;
  final String logoUrl;
  final String tmdbLink;

  WatchProvider({
    required this.name,
    required this.logoUrl,
    required this.tmdbLink,
  });

  Map<String, dynamic> toMap() => {
    'name': name,
    'logoUrl': logoUrl,
    'tmdbLink': tmdbLink,
  };

  factory WatchProvider.fromMap(Map<String, dynamic> map) => WatchProvider(
    name: map['name'] ?? '',
    logoUrl: map['logoUrl'] ?? '',
    tmdbLink: map['tmdbLink'] ?? '',
  );
}
