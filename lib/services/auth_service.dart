import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class AuthService {
  static const String baseUrl = 'https://yodai.wevox.cloud'; // URL de votre API
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';

  // Inscription
  Future<User> register(String username, String email, String password, String firstname, String lastname) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'username': username,
        'email': email,
        'password': password,
        'firstname': firstname,
        'lastname': lastname,
      }),
    );

    if (response.statusCode == 201) {
      final data = json.decode(response.body);
      // Ajustez selon le format réel de réponse de votre API
      final user = User.fromJson(data);

      // Connectez l'utilisateur après l'inscription
      return await login(email, password);
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Échec de l\'inscription');
    }
  }

  // Connexion
  Future<User> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      // Ajustez ces lignes selon le format réel de réponse de votre API
      final token = data['token'] ?? data['access_token'];
      final userJson = data['user'] ?? data;
      final user = User.fromJson(userJson);

      await _saveToken(token);
      await _saveUser(user);
      return user;
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Échec de la connexion');
    }
  }

  // Le reste des méthodes reste inchangé
  // ...

  // Déconnexion
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(tokenKey);
    await prefs.remove(userKey);
  }

  // Vérifier si l'utilisateur est connecté
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }

  // Récupérer le token
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(tokenKey);
  }

  // Récupérer l'utilisateur connecté
  Future<User?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString(userKey);

    if (userData != null) {
      return User.fromJson(json.decode(userData));
    }
    return null;
  }

  // Sauvegarder le token
  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(tokenKey, token);
  }

  // Sauvegarder l'utilisateur
  Future<void> _saveUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(userKey, json.encode(user.toJson()));
  }
}
