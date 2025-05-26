import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class AuthService {
  static const String baseUrl = 'https://yodai.wevox.cloud'; // URL de votre API
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';


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

    print('Status: ${response.statusCode}');
    print('Corps brut: ${response.body}');

    if (response.statusCode == 201) {
      try {
        final data = json.decode(response.body);
        if (data.containsKey('user')) {
          final user = User.fromJson(data['user']);
          return await login(username, password);
        } else {
          throw Exception('Utilisateur non trouvé dans la réponse');
        }
      } catch (e) {
        throw Exception('Erreur d\'inscription: réponse malformée → ${response.body}');
      }
    } else {
      try {
        final error = json.decode(response.body);
        // Vous pouvez ajouter ici des vérifications spécifiques pour le message d'erreur
        if (error['error'] == 'Conflict') {
          throw Exception('Conflit: L\'email ou le nom d\'utilisateur est déjà utilisé.');
        }
        throw Exception(error['message'] ?? 'Échec de l\'inscription');
      } catch (e) {
        throw Exception('Erreur d\'inscription: réponse invalide → ${response.body}');
      }
    }
  }

  // Connexion
  Future<User> login(String username, String password) async {
    try {
      final requestBody = json.encode({
        'username': username,
        'password': password,
      });

      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: requestBody,
      );

      // Accepter 200 ET 201 comme des codes de succès
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        // Votre token est déjà dans la réponse
        final token = data['token'] ?? data['access_token'];

        // Le format de la réponse est différent de ce que vous attendiez
        // Il n'y a pas de champ 'user' distinct, le token contient les infos utilisateur

        // Vous pouvez soit :

        // Option 1: Décoder le token JWT pour extraire les infos utilisateur
        // (Le token JWT contient les informations utilisateur dans sa charge utile)
        final userClaims = _decodeToken(token); // Créez cette méthode
        final user = User.fromJson(userClaims);

        // Option 2: Faire une requête séparée pour obtenir les informations utilisateur
        // final user = await getUserInfo(token);

        await _saveToken(token);
        await _saveUser(user);
        return user;
      } else {
        final error = response.body.isNotEmpty ? json.decode(response.body) : {'message': 'Réponse vide'};
        throw Exception(error['message'] ?? 'Échec de la connexion (Code: ${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Échec de la connexion: $e');
    }
  }

// Fonction pour décoder un token JWT
  Map<String, dynamic> _decodeToken(String token) {
    final parts = token.split('.');
    if (parts.length != 3) {
      throw Exception('Token JWT invalide');
    }

    // Décoder la partie payload (la deuxième partie du token)
    final payload = parts[1];
    String normalized = base64Url.normalize(payload);
    final decoded = utf8.decode(base64Url.decode(normalized));
    final Map<String, dynamic> decodedJson = json.decode(decoded);

    // Les données utilisateur sont elles-mêmes encodées en JSON dans le champ "data"
    if (decodedJson.containsKey('data')) {
      return json.decode(decodedJson['data']);
    }

    return decodedJson;
  }



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
