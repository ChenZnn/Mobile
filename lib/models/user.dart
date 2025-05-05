class User {
  final int id;  // Changé de String à int
  final String email;
  final String username;

  User({
    required this.id,
    required this.email,
    required this.username
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],  // Accepte directement l'int
      email: json['email'],
      username: json['username'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
    };
  }
}
