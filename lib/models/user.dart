class User {
  final int id;
  final String email;
  final String username;
  final String firstname;
  final String lastname;

  User({
    required this.id,
    required this.email,
    required this.username,
    required this.firstname,
    required this.lastname,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'] ?? '',
      username: json['username'] ?? '',
      firstname: json['firstname'] ?? '',
      lastname: json['lastname'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'firstname': firstname,
      'lastname': lastname,
    };
  }
}
