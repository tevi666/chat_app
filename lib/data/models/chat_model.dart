import 'package:chat_app/data/models/mesaage_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Chat {
  final String id;
  final List<String> users;
  final List<Message> messages;

  Chat({required this.id, required this.users, required this.messages});

  factory Chat.fromFirestore(DocumentSnapshot doc) {
    var data = doc.data() as Map<String, dynamic>;
    var messagesData = data['messages'] as List<dynamic>;
    List<Message> messages =
        messagesData.map((msg) => Message.fromFirestore(msg)).toList();

    return Chat(
      id: doc.id,
      users: List<String>.from(data['users']),
      messages: messages,
    );
  }
  
  Map<String, dynamic> toFirestore() {
    return {
      'users': users,
      'messages': messages.map((msg) => msg.toFirestore()).toList(),
    };
  }
}
