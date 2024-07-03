import 'package:chat_app/data/models/chat_model.dart';
import 'package:chat_app/data/models/mesaage_model.dart';
import 'package:chat_app/data/models/user_status_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<Chat>> getChats() {
    return _db.collection('chats').snapshots().map((snapshot) {
      print('Fetched ${snapshot.docs.length} chats from Firestore');
      return snapshot.docs.map((doc) {
        var data = doc.data();
        print('Chat data: $data');
        return Chat.fromFirestore(doc);
      }).toList();
    });
  }

  Future<void> sendMessage(String chatId, String senderId, String text, {String? imageUrl, String? audioUrl}) async {
    var message = Message(
      senderId: senderId,
      text: text,
      timestamp: DateTime.now(),
      imageUrl: imageUrl ?? '',
      audioUrl: audioUrl ?? '',
    );
    return _db.collection('chats').doc(chatId).update({
      'messages': FieldValue.arrayUnion([message.toFirestore()]),
    });
  }

  Future<void> createNewChat(List<String> users) async {
    var docRef = await _db.collection('chats').add({
      'users': users,
      'messages': []
    });
    print('Chat created with ID: ${docRef.id}');
  }

  Future<UserStatus> getUserStatus(String userId) async {
    var userDoc = await _db.collection('users').doc(userId).get();
    if (userDoc.exists) {
      var data = userDoc.data() as Map<String, dynamic>;
      return UserStatus.fromFirestore(data, userId);
    }
    return UserStatus(isOnline: false, lastSeen: DateTime.now(), id: userId, name: userId);
  }

  Future<void> addUser(String fullName) async {
    var user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      var userDoc = _db.collection('users').doc(user.uid);
      await userDoc.set({
        'name': fullName,
        'isOnline': true,
        'lastSeen': Timestamp.now(),
      });
    }
  }
}
