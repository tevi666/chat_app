import 'package:chat_app/data/models/mesaage_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Chat {
  final String id;
  final List<String> users;
  final List<Message> messages;

  Chat({required this.id, required this.users, required this.messages});

  factory Chat.fromFirestore(DocumentSnapshot doc) {
    var data = doc.data() as Map<String, dynamic>;
    var users = List<String>.from(data['users'] ?? []);
    var messages = (data['messages'] as List<dynamic>).map((msg) => Message.fromFirestore(msg)).toList();
    return Chat(id: doc.id, users: users, messages: messages);
  }
}
