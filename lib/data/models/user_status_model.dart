import 'package:cloud_firestore/cloud_firestore.dart';

class UserStatus {
  final bool isOnline;
  final DateTime lastSeen;
  final String id;
  final String name;

  UserStatus({
    required this.isOnline,
    required this.lastSeen,
    required this.id,
    required this.name,
  });

  factory UserStatus.fromFirestore(Map<String, dynamic> data, String userId) {
    return UserStatus(
      isOnline: data['isOnline'],
      lastSeen: (data['lastSeen'] as Timestamp).toDate(),
      id: userId,
      name: data['name'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'isOnline': isOnline,
      'lastSeen': Timestamp.fromDate(lastSeen),
      'name': name,
    };
  }
}
