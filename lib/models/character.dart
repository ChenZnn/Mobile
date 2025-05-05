class Character {
  final int id;             // Transformé en int
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

  /// Crée un Character à partir d'un Map JSON
  factory Character.fromJson(Map<String, dynamic> json) {
    return Character(
      // Conversion vers int
      id: json['id'] is String ? int.parse(json['id']) : json['id'] as int,

      // universeId reste en String
      universeId: json['universe_id'] is int
          ? json['universe_id'].toString()
          : json['universe_id'],

      name: json['name'],
      description: json['description'],
      imageUrl: json['image'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  /// Convertit l'objet Character en Map JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,              // ID en int
      'universe_id': universeId,
      'name': name,
      'description': description,
      'image_url': imageUrl,
    };
  }

  /// Crée une copie de Character avec des champs potentiellement modifiés
  Character copyWith({
    int? id,                // Type changé en int
    String? universeId,
    String? name,
    String? description,
    String? imageUrl,
    DateTime? createdAt,
  }) {
    return Character(
      id: id ?? this.id,
      universeId: universeId ?? this.universeId,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'Character(id: $id, name: $name, universeId: $universeId)';
  }
}
