import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/universe.dart';
import '../models/character.dart';
import 'auth_service.dart';

class ApiService {
  static const String baseUrl = 'https://yodai.wevox.cloud/'; // Remplacer par votre URL
  final AuthService _authService = AuthService();

  // Récupérer tous les univers
  Future<List<Universe>> getUniverses(String universeId) async {
    final token = await _authService.getToken();

    final response = await http.get(
      Uri.parse('$baseUrl/universes'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Universe.fromJson(json)).toList();
    } else {
      throw Exception('Erreur lors de la récupération des univers');
    }
  }

  // Créer un nouvel univers
  Future<Universe> createUniverse(Universe universe) async {
    final token = await _authService.getToken();

    final response = await http.post(
      Uri.parse('$baseUrl/universes'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(universe.toJson()),
    );

    if (response.statusCode == 201) {
      return Universe.fromJson(json.decode(response.body));
    } else {
      throw Exception('Erreur lors de la création de l\'univers');
    }
  }

  // Supprimer un univers
  Future<void> deleteUniverse(String universeId) async {
    final token = await _authService.getToken();

    final response = await http.delete(
      Uri.parse('$baseUrl/universes/$universeId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Erreur lors de la suppression de l\'univers');
    }
  }

  // Récupérer les personnages d'un univers
  Future<List<Character>> getCharacters(String universeId) async {
    final token = await _authService.getToken();

    final response = await http.get(
      Uri.parse('$baseUrl/universes/$universeId/characters'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Character.fromJson(json)).toList();
    } else {
      throw Exception('Erreur lors de la récupération des personnages');
    }
  }

  // Créer un nouveau personnage
  Future<Character> createCharacter(Character character, File? imageFile) async {
    final token = await _authService.getToken();

    final response = await http.post(
      Uri.parse('$baseUrl/universes/${character.universeId}/characters'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'name': character.name,
        'description': character.description,
      }),
    );

    if (response.statusCode == 201) {
      return Character.fromJson(json.decode(response.body));
    } else {
      throw Exception('Erreur lors de la création du personnage');
    }
  }

  // Supprimer un personnage
  Future<void> deleteCharacter(String characterId) async {
    final token = await _authService.getToken();

    final response = await http.delete(
      Uri.parse('$baseUrl/characters/$characterId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Erreur lors de la suppression du personnage');
    }
  }

  // Télécharger l'image d'un personnage
  Future<String> uploadCharacterImage(String characterId, String imagePath) async {
    final token = await _authService.getToken();

    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/characters/$characterId/image'),
    );

    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(await http.MultipartFile.fromPath('image', imagePath));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['image_url'];
    } else {
      throw Exception('Erreur lors du téléchargement de l\'image');
    }
  }
  Future<String> uploadUniverseImage(String universeId, String imagePath) async {
    final token = await _authService.getToken();

    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/universes/$universeId/image'),
    );

    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(await http.MultipartFile.fromPath('image', imagePath));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['image_url'];
    } else {
      throw Exception('Erreur lors du téléchargement de l\'image: ${response.body}');
    }
  }
}
