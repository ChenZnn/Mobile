// lib/models/universe.dart
class Universe {
  final String id;
  final String name;
  final String description;
  final DateTime? createdAt;
  final String? imageUrl; // Ajout de cette propriété

  Universe({
    required this.id,
    required this.name,
    required this.description,
    this.createdAt,
    this.imageUrl, required String creatorId, // Ajout dans le constructeur
  });

  factory Universe.fromJson(Map<String, dynamic> json) {
    return Universe(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      createdAt: DateTime.parse(json['created_at']),
      imageUrl: json['image_url'], creatorId: '', // Parse depuis le JSON
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'created_at': createdAt?.toIso8601String(),
      'image_url': imageUrl,
    };
  }
}
