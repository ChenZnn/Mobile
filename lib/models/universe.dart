class Universe {
  final String id;
  final String name;
  final String description;
  final DateTime? createdAt;
  final String? imageUrl;
  final String creatorId; // Ajout comme propriété de classe

  Universe({
    required this.id,
    required this.name,
    required this.description,
    required this.creatorId, // Gardé comme paramètre requis
    this.createdAt,
    this.imageUrl,
  });

  factory Universe.fromJson(Map<String, dynamic> json) {
    return Universe(
      id: json['id'] is int ? json['id'].toString() : json['id'],
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      imageUrl: json['image'], // ✅ Corrigé pour utiliser 'image' au lieu de 'image_url'
      creatorId: json['creator_id']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'created_at': createdAt?.toIso8601String(),
      'image_url': imageUrl,
      'creator_id': creatorId,
    };
  }
}
