import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:sparepark/screens/chat/chat_page.dart';
import 'package:sparepark/shared/auth_service.dart';
import 'package:sparepark/shared/widgets/app_bar.dart';
// import 'package:sparepark/chat_screen.dart';
// import 'package:sparepark/models/user_model.dart';

class ChatList extends StatefulWidget {
  @override
  _ChatListState createState() => _ChatListState();
}

class _ChatListState extends State<ChatList> {
  late User? currentUser;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    // Get the current user when the widget is first created
    currentUser = FirebaseAuth.instance.currentUser;
  }

  Future<void> getMessageCount() async {
    print("Finding messages for current user");

    if (currentUser == null) {
      print("Current user is null");
      return;
    }

    setState(() {
      isLoading = true;
    });

    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection("users")
        .doc(currentUser!.uid)
        .collection("messages")
        .doc(currentUser!.uid)
        .collection("chats")
        .get();

    List<String> messages = [];
    snapshot.docs.forEach((doc) {
      messages.add(doc['message']);
    });

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final isLoggedInStream = authService.user!.map((user) => user != null);
    return Scaffold(
      appBar: CustomAppBar(
          title: 'Conversations', isLoggedInStream: isLoggedInStream),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser!.uid)
            .collection('messages')
            .snapshots(),
        builder: (context, AsyncSnapshot snapshot) {
          if (isLoading) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }
          if (snapshot.hasData) {
            if (snapshot.data.docs.length < 1) {
              return Center(
                child: Text("No Chats Available !"),
              );
            }
            return ListView.builder(
              itemCount: snapshot.data.docs.length,
              itemBuilder: (context, index) {
                var friendId = snapshot.data.docs[index].id;
                var lastMsg = snapshot.data.docs[index]['last_msg'];
                return FutureBuilder(
                  future: FirebaseFirestore.instance
                      .collection('users')
                      .doc(friendId)
                      .get(),
                  builder: (context, AsyncSnapshot asyncSnapshot) {
                    if (asyncSnapshot.hasData) {
                      var friend = asyncSnapshot.data;
                      return ListTile(
                        leading: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            image: DecorationImage(
                              fit: BoxFit.cover,
                              image: CachedNetworkImageProvider(
                                  friend['image'] as String),
                            ),
                          ),
                        ),
                        title: Text(friend['name']),
                        subtitle: Container(
                          child: Text(
                            "$lastMsg",
                            style: TextStyle(color: Colors.grey),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatPage(
                                u_id: friend.id,
                                currentUserId: currentUser!.uid,
                                // friend: User.fromSnapshot(friend),
                              ),
                            ),
                          );
                        },
                      );
                    } else {
                      return Container();
                    }
                  },
                );
              },
            );
          } else {
            return Center(
              child: CircularProgressIndicator(),
            );
          }
        },
      ),
    );
  }
}
