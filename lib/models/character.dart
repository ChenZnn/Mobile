class Character {
  final String id;
  final String universeId;
  final String name;
  final String? description;
  final String? imageUrl;
  final DateTime createdAt;

  Character({
    required this.id,
    required this.universeId,
    required this.name,
    this.description,
    this.imageUrl,
    required this.createdAt,
  });

  factory Character.fromJson(Map<String, dynamic> json) {
    return Character(
      id: json['id'],
      universeId: json['universe_id'],
      name: json['name'],
      description: json['description'],
      imageUrl: json['image_url'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'universe_id': universeId,
      'name': name,
      'description': description,
      'image_url': imageUrl,
    };
  }
}
