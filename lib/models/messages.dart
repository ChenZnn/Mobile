class Message {
  final int id;
  final String content;
  final int senderId;
  final String createdAt;

  Message({
    required this.id,
    required this.content,
    required this.senderId,
    required this.createdAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    // Valeur temporaire : si l'humain envoie => c'est currentUserId (ou 7 ici)
    final bool isSentByHuman = json['is_sent_by_human'] ?? false;

    return Message(
      id: json['id'],
      content: json['content'],
      senderId: isSentByHuman ? 7 : -1, // 7 = id utilisateur actuel ; -1 = bot / autre
      createdAt: json['created_at'],
    );
  }
}
