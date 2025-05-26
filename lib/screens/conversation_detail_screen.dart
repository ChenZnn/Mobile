import 'package:flutter/material.dart';
import '../models/conversations.dart';
import '../models/messages.dart';
import '../services/api_service.dart';

class ConversationDetailScreen extends StatefulWidget {
  final int conversationId;

  ConversationDetailScreen({required this.conversationId});

  @override
  _ConversationDetailScreenState createState() =>
      _ConversationDetailScreenState();
}

class _ConversationDetailScreenState extends State<ConversationDetailScreen> {
  final ApiService _apiService = ApiService();
  late Future<Conversation> _conversationFuture;
  late Future<List<Message>> _messagesFuture;

  TextEditingController _messageController = TextEditingController();

  final int currentUserId = 7; // Id de l'utilisateur connecté

  @override
  void initState() {
    super.initState();
    _conversationFuture = _apiService.getConversation(widget.conversationId);
    _messagesFuture =
        _apiService.getMessagesByConversationId(widget.conversationId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Conversation')),
      body: FutureBuilder<List<Message>>(
        future: _messagesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erreur : ${snapshot.error}'));
          }

          final messages = snapshot.data!;

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[messages.length - index - 1];
                    final isSentByUser = message.senderId == currentUserId;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 10),
                      child: Align(
                        alignment: isSentByUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isSentByUser ? Colors.blue : Colors.grey[300],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            message.content,
                            style: TextStyle(
                              color: isSentByUser ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Champ de saisie
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: "Écrivez un message...",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.send, color: Colors.blueAccent),
                      onPressed: () async {
                        final content = _messageController.text.trim();
                        if (content.isEmpty) return;

                        try {
                          await _apiService.sendMessage(widget.conversationId, content);
                          _messageController.clear(); // Vide le champ de saisie

                          setState(() {
                            // Recharge la liste des messages
                            _messagesFuture =
                                _apiService.getMessagesByConversationId(widget.conversationId);
                          });
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Erreur lors de l\'envoi du message')),
                          );
                        }
                      },

                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
