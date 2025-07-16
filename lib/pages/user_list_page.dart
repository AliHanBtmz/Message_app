import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_page.dart';
import '../auth/auth_service.dart';
import '../auth/login_page.dart';

class UserListPage extends StatefulWidget {
  const UserListPage({super.key});

  @override
  State<UserListPage> createState() => _UserListPageState();
}

class _UserListPageState extends State<UserListPage> {
  final currentUser = FirebaseAuth.instance.currentUser!;
  final TextEditingController _emailController = TextEditingController();

  Future<void> _addFriend() async {
    final email = _emailController.text.trim();

    if (email == currentUser.email) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Kendinizi ekleyemezsiniz.")),
      );
      return;
    }

    try {
      final userQuery =
          await FirebaseFirestore.instance
              .collection('users')
              .where('email', isEqualTo: email)
              .get();

      if (userQuery.docs.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Kullanıcı bulunamadı.")));
        return;
      }

      final friendDoc = userQuery.docs.first;
      final friendUid = friendDoc['uid'];
      final friendName = friendDoc['name'];
      final friendEmail = friendDoc['email'];

      await FirebaseFirestore.instance
          .collection('friends')
          .doc(currentUser.uid)
          .collection('userFriends')
          .doc(friendUid)
          .set({
            'friendUid': friendUid,
            'friendEmail': friendEmail,
            'friendName': friendName,
            'addedAt': FieldValue.serverTimestamp(),
          });

      final currentUserDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .get();
      await FirebaseFirestore.instance
          .collection('friends')
          .doc(friendUid)
          .collection('userFriends')
          .doc(currentUser.uid)
          .set({
            'friendUid': currentUser.uid,
            'friendEmail': currentUser.email,
            'friendName': currentUserDoc['name'],
            'addedAt': FieldValue.serverTimestamp(),
          });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Arkadaş başarıyla eklendi.")),
      );

      _emailController.clear();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Hata: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffDFD0B8),

      appBar: AppBar(
        title: const Text(
          "Arkadaşlarım",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Color(0xff222831),

        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await AuthService().signOut();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      hintText: 'Arkadaş e-posta',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.person_add, color: Colors.white),
                  onPressed: _addFriend,
                ),
              ],
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('friends')
                      .doc(currentUser.uid)
                      .collection('userFriends')
                      .orderBy('addedAt')
                      .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());

                final friends = snapshot.data!.docs;

                if (friends.isEmpty) {
                  return const Center(child: Text("Henüz arkadaşınız yok."));
                }

                return ListView.builder(
                  itemCount: friends.length,
                  itemBuilder: (context, index) {
                    final friend = friends[index];

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: Card(
                        color: const Color(0xff393E46),
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          title: Text(
                            friend['friendName'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            friend['friendEmail'],
                            style: const TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => ChatPage(
                                      otherUserEmail: friend['friendEmail'],
                                      otherUserUid: friend['friendUid'],
                                    ),
                              ),
                            );
                          },
                        ),
                      ),
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
