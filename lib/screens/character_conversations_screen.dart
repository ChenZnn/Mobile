import 'package:flutter/material.dart';
import '../models/conversations.dart';
import '../services/api_service.dart';
import 'package:untitled/screens/conversation_detail_screen.dart';

class CharacterConversationsScreen extends StatefulWidget {
  final int characterId;
  final int? conversationId;

  CharacterConversationsScreen({
    required this.characterId,
    this.conversationId,
  });

  @override
  _CharacterConversationsScreenState createState() =>
      _CharacterConversationsScreenState();
}

class _CharacterConversationsScreenState
    extends State<CharacterConversationsScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<Conversation>> _conversationsFuture;

  @override
  void initState() {
    super.initState();
    // Récupérer les conversations pour ce personnage spécifique
    _conversationsFuture = _apiService.getConversationsByCharacter(widget.characterId);
  }

  Future<void> _deleteConversation(int conversationId) async {
    try {
      bool success = await _apiService.deleteConversation(conversationId);
      if (success) {
        // Rafraîchir la liste après la suppression
        setState(() {
          _conversationsFuture = _apiService.getConversationsByCharacter(widget.characterId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Conversation supprimée avec succès')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Échec de la suppression')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Conversations de ce personnage')),
      body: FutureBuilder<List<Conversation>>(
        future: _conversationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          }

          final conversations = snapshot.data;
          if (conversations == null || conversations.isEmpty) {
            return Center(child: Text("Aucune conversation trouvée pour ce personnage."));
          }

          // Filtrer les conversations pour n'afficher que celles du personnage actuel
          final characterConversations = conversations.where(
            (conversation) => conversation.characterId == widget.characterId
          ).toList();
          
          if (characterConversations.isEmpty) {
            return Center(child: Text("Aucune conversation trouvée pour ce personnage."));
          }

          return ListView.builder(
            itemCount: characterConversations.length,
            itemBuilder: (context, index) {
              final conversation = characterConversations[index];
              return ListTile(
                title: Text('Conversation #${conversation.id}'),
                subtitle: Text('Créée le ${conversation.createdAt}'),
                trailing: IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteConversation(conversation.id),
                ),
                onTap: () {
                  // Naviguer vers la page de détails de la conversation
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ConversationDetailScreen(conversationId: conversation.id),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
