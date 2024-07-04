import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chat_app/data/models/chat_model.dart';
import 'package:chat_app/data/services/firestore_service.dart';
import 'package:chat_app/presentations/widgets/base_text.dart';
import 'package:chat_app/screens/chat_screen.dart';
import 'package:chat_app/utilities/constants/app_colors.dart';
import 'package:chat_app/utilities/utils.dart';

class ChatListScreen extends StatefulWidget {
  final FirestoreService _firestoreService = FirestoreService();

  ChatListScreen({super.key});

  @override
  _ChatListScreenState createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  String searchQuery = "";
  String? selectedUser = "Alex Row";

  @override
  void initState() {
    super.initState();
    _loginAsUser(selectedUser!);
  }

  Future<void> _loginAsUser(String userName) async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInAnonymously();
      User? user = userCredential.user;

      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'name': userName,
          'isOnline': true,
          'lastSeen': Timestamp.now(),
        });
      }
    } catch (e) {
      print('Login error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Padding(
          padding: EdgeInsets.only(left: 10),
          child: BaseText(text: "Чаты", fontSize: 32, color: Colors.black),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 20.0, right: 20, bottom: 24, top: 10),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Поиск",
                hintStyle: const TextStyle(color: Color(0xFF9DB7CB)),
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Image.asset('assets/search.png'),
                ),
                filled: true,
                fillColor: const Color(0xFFEDF2F6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          const Divider(height: 1, color: Color(0xffEDF2F6)),
          Expanded(
            child: StreamBuilder<List<Chat>>(
              stream: widget._firestoreService.getChats(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: BaseText(text: 'Ошибка загрузки данных', color: AppColors.red));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: BaseText(text: 'Нет доступных чатов', color: AppColors.red));
                }

                var chats = snapshot.data!.where((chat) {
                  return chat.users.any((user) => user.toLowerCase().contains(searchQuery));
                }).toList();

                if (chats.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.only(left: 0),
                      child: BaseText(
                        text: 'Нет пользователей, соответствующих поисковому запросу',
                        color: AppColors.red,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: chats.length,
                  itemBuilder: (context, index) {
                    var chat = chats[index];
                    var user = chat.users.firstWhere((user) => user != currentUser?.uid);
                    var initials = getInitials(user);
                    var avatarColor = getColorFromString(user, AppColors.colors);
                    var timeString = getMessageTime(chat.messages.last.timestamp);

                    String messageText = chat.messages.last.text;
                    if (messageText.length > 30) {
                      messageText = messageText.substring(0, 30) + '...';
                    }

                    return Column(
                      children: [
                        ListTile(
                          leading: CircleAvatar(
                            radius: 40,
                            backgroundColor: avatarColor,
                            child: BaseText(
                              fontSize: 24,
                              text: initials,
                            ),
                          ),
                          title: BaseText(text: user, fontSize: 18, color: Colors.black),
                          subtitle: RichText(
                            text: TextSpan(
                              children: [
                                if (selectedUser != null && chat.messages.last.senderId == selectedUser)
                                  const TextSpan(
                                    text: 'Вы: ',
                                    style: TextStyle(color: Color(0xFF2B333E)),
                                  ),
                                TextSpan(
                                  text: messageText,
                                  style: const TextStyle(color: AppColors.darkGray, fontSize: 14, fontFamily: 'Gilroy-M'),
                                ),
                              ],
                            ),
                          ),
                          trailing: BaseText(text: timeString, fontSize: 12, color: AppColors.darkGray, fontFamily: 'Gilroy-M'),
                          onTap: () async {
                            var userStatus = await widget._firestoreService.getUserStatus(user);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatScreen(
                                  chatId: chat.id,
                                  userName: user,
                                  avatarColor: avatarColor,
                                  isOnline: userStatus.isOnline,
                                  lastSeen: userStatus.lastSeen,
                                ),
                              ),
                            );
                          },
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: Divider(height: 1, color: Color(0xffEDF2F6)),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
