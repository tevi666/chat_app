import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:chat_app/data/models/mesaage_model.dart';
import 'package:chat_app/data/services/firestore_service.dart';
import 'package:chat_app/presentations/widgets/base_text.dart';
import 'package:chat_app/utilities/utils.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String userName;
  final Color avatarColor;
  final bool isOnline;
  final DateTime lastSeen;

  ChatScreen({
    super.key,
    required this.chatId,
    required this.userName,
    required this.avatarColor,
    required this.isOnline,
    required this.lastSeen,
  });

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _controller = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final ScrollController _scrollController = ScrollController();
  final String fixedUserId = "Alex Row";

  File? _selectedImage;
  bool _isRecording = false;
  bool _isSendingText = false;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _scrollToBottom();
  }

  Future<void> _requestPermissions() async {
    await Permission.microphone.request();
  }

void _sendMessage({String? imageUrl, String? audioUrl}) {
  if (_controller.text.isNotEmpty || _selectedImage != null || audioUrl != null) {
    String messageText = _controller.text;
    setState(() {
      _isSendingText = false;
      _controller.clear();
      _selectedImage = null;
    });
    if (_selectedImage != null) {
      _uploadImage(_selectedImage!).then((url) {
        _firestoreService.sendMessage(
          widget.chatId,
          fixedUserId,
          messageText,
          imageUrl: url,
          audioUrl: audioUrl,
        );
        _scrollToBottom();
      });
    } else {
      _firestoreService.sendMessage(
        widget.chatId,
        fixedUserId,
        messageText,
        imageUrl: imageUrl,
        audioUrl: audioUrl,
      );
      _scrollToBottom();
    }
  }
}



  Future<String> _uploadImage(File image) async {
    final String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    final Reference storageRef = FirebaseStorage.instance.ref().child('chat_images/$fileName');
    final UploadTask uploadTask = storageRef.putFile(image);
    final TaskSnapshot downloadUrl = await uploadTask;
    return await downloadUrl.ref.getDownloadURL();
  }

  Future<void> _pickImage() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Пожалуйста, войдите в систему для загрузки изображений.')),
        );
        return;
      }

      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      print('Error picking or uploading image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking or uploading image: $e')),
      );
    }
  }

void _scrollToBottom() {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  });
}



  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    if (difference == 0) {
      return 'Сегодня';
    } else if (difference == 1) {
      return 'Вчера';
    } else {
      return DateFormat('dd.MM.yy').format(date);
    }
  }

  bool _shouldShowDateDivider(DateTime currentMessageDate, DateTime? previousMessageDate) {
    if (previousMessageDate == null) return true;
    final currentDate = DateTime(currentMessageDate.year, currentMessageDate.month, currentMessageDate.day);
    final previousDate = DateTime(previousMessageDate.year, previousMessageDate.month, previousMessageDate.day);
    return currentDate != previousDate;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 500,
        leading: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Image.asset('assets/back.png'),
            ),
            CircleAvatar(
              radius: 30,
              backgroundColor: widget.avatarColor,
              child: BaseText(
                text: getInitials(widget.userName),
                fontSize: 30,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BaseText(text: widget.userName, fontSize: 18, color: Colors.black),
                const BaseText(
                  text: 'Online',
                  fontSize: 14,
                  color: Color(0xff5E7A90),
                  fontFamily: 'Gilroy-M',
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(widget.chatId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const Center(child: Text('Нет данных'));
                }
                var chatData = snapshot.data!.data() as Map<String, dynamic>;
                var messagesData = chatData['messages'] as List<dynamic>;
                List<Message> messages = messagesData
                    .map((msg) => Message.fromFirestore(msg))
                    .toList();
                messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

                DateTime? previousMessageDate;

                return ListView.builder(
  controller: _scrollController,
  itemCount: messages.length,
  itemBuilder: (context, index) {
    var message = messages[index];
    bool isMe = message.senderId == fixedUserId;
    bool shouldShowDivider = _shouldShowDateDivider(message.timestamp, previousMessageDate);
    previousMessageDate = message.timestamp;

    return Column(
      key: ValueKey(message.timestamp),
      children: [
        if (shouldShowDivider)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                const Expanded(
                  child: Divider(color: Color(0xFF9DB7CB)),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    _formatDate(message.timestamp),
                    style: const TextStyle(color: Color(0xFF9DB7CB)),
                  ),
                ),
                const Expanded(
                  child: Divider(color: Color(0xFF9DB7CB)),
                ),
              ],
            ),
          ),
        Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
            margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
            decoration: BoxDecoration(
              color: isMe ? const Color(0xFF3CED78) : Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (message.imageUrl.isNotEmpty)
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(10),
                      topRight: Radius.circular(10),
                    ),
                    child: Image.network(
                      message.imageUrl,
                      height: 150,
                      width: 280,
                      fit: BoxFit.cover,
                    ),
                  ),
                if (message.audioUrl != null)
                  Container(),
                SizedBox(
                  width: 270,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          message.text,
                          style: const TextStyle(
                            color: Color(0xFF00521C),
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.left,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            DateFormat.Hm().format(message.timestamp),
                            style: const TextStyle(
                              color: Color(0xFF00521C),
                              fontSize: 16,
                            ),
                          ),
                          if (isMe) ...[
                            const SizedBox(width: 5),
                            const Icon(
                              Icons.done,
                              size: 16,
                              color: Color(0xFF00521C),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  },
);

              },
            ),
          ),
          if (_selectedImage != null)
            Container(
              height: 150,
              margin: const EdgeInsets.all(8.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(
                  _selectedImage!,
                  fit: BoxFit.fill,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDF2F6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.attach_file),
                    onPressed: _pickImage,
                  ),
                ),
                const SizedBox(width: 15,),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDF2F6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: "Сообщение",
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(12),
                      ),
                      onChanged: (text) {
                        setState(() {
                          _isSendingText = text.isNotEmpty;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 15,),
                GestureDetector(
                  onTap: _isSendingText ? () => _sendMessage() : null,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _isSendingText ? Colors.blue : const Color(0xFFEDF2F6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _isSendingText ? Icons.send : Icons.mic,
                      size: 20,
                      color: _isSendingText ? Colors.white : Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
