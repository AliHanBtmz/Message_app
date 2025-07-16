import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> sendMessage({
    required String chatId,
    required String message,
    required String sender,
    required String receiver,
  }) async {
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add({
          'text': message,
          'sender': sender,
          'receiver': receiver,
          'timestamp': FieldValue.serverTimestamp(),
        });
  }
}
