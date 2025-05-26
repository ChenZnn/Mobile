import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/conversations.dart';
import '../models/messages.dart';
import '../models/universe.dart';
import '../models/character.dart';
import 'auth_service.dart';

class ApiService {
  static const String baseUrl = 'https://yodai.wevox.cloud'; // Remplacer par votre URL
  final AuthService _authService = AuthService();

  Future<List<Universe>> getUniverses(String filter) async {
    try {
      final token = await _authService.getToken();

      if (token == null) {
        throw Exception('Token d\'authentification non disponible');
      }

      print("Token utilisé: $token"); // Pour débogage

      // Création d'une URL avec ou sans paramètre de filtre
      final Uri uri = Uri.parse('$baseUrl/universes');

      // Options pour la requête
      final options = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

      // Exécution de la requête
      final response = await http.get(
        uri,
        headers: options,
      );

      print("Status code: ${response.statusCode}");
      print("Response body: ${response.body}");

      if (response.statusCode == 200) {
        // Analyse de la réponse
        final dynamic jsonResponse = json.decode(response.body);

        // S'assurer que nous avons bien une liste
        List<dynamic> universesData;

        if (jsonResponse is List) {
          universesData = jsonResponse;
        } else if (jsonResponse is Map && jsonResponse.containsKey('universes')) {
          universesData = jsonResponse['universes'];
        } else {
          print("Format de réponse inattendu: $jsonResponse");
          throw Exception('Format de réponse inattendu');
        }

        // Conversion en objets Universe
        return universesData.map((data) => Universe.fromJson(data)).toList();
      } else {
        throw Exception('Erreur lors de la récupération des univers: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print("Exception dans getUniverses: $e");
      throw Exception('Erreur lors de la récupération des univers: $e');
    }
  }

  /// Récupère les détails d'un univers spécifique par son ID.
  Future<Universe> getUniverse(String universeId) async {
    try {
      final token = await _authService.getToken();

      if (token == null) {
        throw Exception('Token d\'authentification non disponible');
      }

      print("Récupération de l'univers avec ID: $universeId");

      final response = await http.get(
        Uri.parse('$baseUrl/universes/$universeId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print("Status code: ${response.statusCode}");

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final dynamic jsonResponse = json.decode(response.body);

        // Gestion des différents formats possibles de réponse
        Map<String, dynamic> universeData;

        if (jsonResponse is Map<String, dynamic>) {
          if (jsonResponse.containsKey('universe')) {
            universeData = jsonResponse['universe'];
          } else if (jsonResponse.containsKey('data')) {
            universeData = jsonResponse['data'];
          } else {
            universeData = jsonResponse;
          }
        } else {
          print("Format de réponse inattendu: $jsonResponse");
          throw Exception('Format de réponse inattendu pour l\'univers');
        }

        print("Données de l'univers: $universeData");

        return Universe.fromJson(universeData);
      } else {
        print("Erreur: ${response.statusCode} - ${response.body}");
        throw Exception('Erreur lors de la récupération de l\'univers: ${response.statusCode}');
      }
    } catch (e) {
      print("Exception dans getUniverse: $e");
      rethrow; // Propagation de l'erreur pour qu'elle puisse être traitée par l'appelant
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
  Future<void> deleteCharacter(int characterId) async {
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

  Future<Map<String, dynamic>> createConversation(int characterId, int userId) async {
    final token = await _authService.getToken();

    final response = await http.post(
      Uri.parse('$baseUrl/conversations'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'character_id': characterId,
        'user_id': userId,
      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erreur ${response.statusCode} : ${response.body}');
    }
  }



  Future<int> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('user_id') ?? 0;
  }

  Future<List<Conversation>> getAllConversations(int characterId) async {
    final token = await _authService.getToken();

    final response = await http.get(
      Uri.parse('$baseUrl/conversations?character_id=$characterId'), // Ajouter le filtre character_id
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data as List).map((json) => Conversation.fromJson(json)).toList();
    } else {
      throw Exception('Erreur lors de la récupération des conversations : ${response.statusCode}');
    }
  }

  Future<bool> deleteConversation(int conversationId) async {
    final token = await _authService.getToken();

    final response = await http.delete(
      Uri.parse('$baseUrl/conversations/$conversationId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['result'] == true;
    } else {
      throw Exception(
        'Erreur lors de la suppression de la conversation : ${response.statusCode} - ${response.body}',
      );
    }
  }

  Future<Conversation> getConversation(int characterId) async {
    final token = await _authService.getToken(); // Récupérer le token d'authentification

    final url = '$baseUrl/conversations?character_id=$characterId'; // L'API renvoie toutes les conversations d'un personnage
    print('URL appelée : $url');

    // Effectuer la requête GET avec le token dans les en-têtes
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',  // Ajouter le token d'authentification
        'Content-Type': 'application/json', // Définir le type de contenu en JSON
      },
    );

    // Vérifier la réponse de l'API
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);  // Décoder la réponse JSON
      final conversations = (data as List)
          .map((json) => Conversation.fromJson(json))
          .toList();

      if (conversations.isNotEmpty) {
        return conversations.first;  // Retourner la première conversation (si plusieurs sont retournées)
      } else {
        throw Exception('Aucune conversation trouvée pour ce personnage.');
      }
    } else {
      // Gérer les erreurs en cas d'échec de la requête
      throw Exception('Erreur lors de la récupération de la conversation : ${response.statusCode}');
    }
  }







  Future<List<Message>> getMessagesByConversationId(int conversationId) async {
    final token = await _authService.getToken(); // Assurez-vous que _authService est défini

    final response = await http.get(
      Uri.parse('$baseUrl/conversations/$conversationId/messages'),
      headers: {
        'Authorization': 'Bearer $token', // Remplace par ton token dynamiquement si besoin
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> body = jsonDecode(response.body);
      return body.map((json) => Message.fromJson(json)).toList();
    } else {
      throw Exception('Erreur lors du chargement des messages');
    }
  }

  Future<void> sendMessage(int conversationId, String content) async {
    final token = await _authService.getToken(); // Assurez-vous que _authService est défini

    final response = await http.post(
      Uri.parse('$baseUrl/conversations/$conversationId/messages'),
      headers: {
        'Authorization': 'Bearer $token', // adapter selon ta gestion d’authentification
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'content': content,
      }),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      // Réponse réussie
      print("Message envoyé avec succès");
    } else {
      // Afficher l'erreur détaillée
      print('Erreur: ${response.statusCode}');
      print('Corps de la réponse: ${response.body}');  // Log de la réponse
      throw Exception('Échec de l\'envoi du message : ${response.body}');
    }


  }

  // Méthode pour récupérer toutes les conversations d'un personnage spécifique
  Future<List<Conversation>> getConversationsByCharacter(int characterId) async {
    try {
      final token = await _authService.getToken();
  
      final response = await http.get(
        Uri.parse('$baseUrl/conversations?character_id=$characterId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
  
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Conversation.fromJson(json)).toList();
      } else {
        print('Erreur lors de la récupération des conversations: ${response.statusCode}');
        print('Réponse: ${response.body}');
        return [];
      }
    } catch (e) {
      print('Exception lors de la récupération des conversations: $e');
      return [];
    }
  }

}


