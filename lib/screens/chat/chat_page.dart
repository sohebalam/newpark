import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sparepark/shared/style/contstants.dart';
import 'package:sparepark/shared/widgets/message_textfield.dart';
import 'package:sparepark/shared/widgets/single_message.dart';

class ChatPage extends StatefulWidget {
  final String u_id;
  final String currentUserId;

  const ChatPage({Key? key, required this.u_id, required this.currentUserId})
      : super(key: key);

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  // User? _currentUser;
  String _otherUserName = '';
  String _otherUserImage = '';

  @override
  void initState() {
    super.initState();

    FirebaseFirestore.instance
        .collection('users')
        .doc(widget.u_id)
        .get()
        .then((DocumentSnapshot documentSnapshot) {
      if (documentSnapshot.exists) {
        setState(() {
          _otherUserName = documentSnapshot.get('name');
          _otherUserImage = documentSnapshot.get('image');
        });
      } else {
        print('User does not exist in the database');
      }
    }).catchError((error) {
      print('Error retrieving user data: $error');
    });

    // Load the Firebase image after a delay of 1 second
    Future.delayed(Duration(seconds: 1), () {
      if (_otherUserImage.isNotEmpty) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    print(widget.currentUserId);
    print(_otherUserName);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Constants().primaryColor,
        title: Row(
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(80),
                  child: _otherUserImage.isNotEmpty
                      ? Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            image: DecorationImage(
                              fit: BoxFit.cover,
                              image:
                                  CachedNetworkImageProvider(_otherUserImage),
                            ),
                          ),
                        )
                      : Image.asset(
                          'assets/person.png', // replace with your local image path
                          height: 30,
                        ),
                ),
                if (_otherUserImage.isEmpty)
                  Container(
                    height: 30,
                    width: 30,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(80),
                    ),
                    child: Icon(
                      Icons.person,
                      color: Colors.grey[500],
                    ),
                  ),
              ],
            ),
            SizedBox(
              width: 5,
            ),
            Text(
              _otherUserName,
              style: TextStyle(fontSize: 20),
            )
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(25),
                    topRight: Radius.circular(25)),
              ),
              child: StreamBuilder(
                  stream: FirebaseFirestore.instance
                      .collection("users")
                      .doc(widget.currentUserId)
                      .collection('messages')
                      .doc(widget.u_id)
                      .collection('chats')
                      .orderBy("date", descending: true)
                      .snapshots(),
                  builder: (context, AsyncSnapshot snapshot) {
                    if (snapshot.hasData) {
                      if (snapshot.data.docs.length < 1) {
                        return Center(
                          child: Text("Say Hi"),
                        );
                      }
                      return ListView.builder(
                        itemCount: snapshot.data.docs.length,
                        reverse: true,
                        physics: BouncingScrollPhysics(),
                        itemBuilder: (context, index) {
                          bool isMe = snapshot.data.docs[index]['senderId'] ==
                              widget.currentUserId;
                          DateTime date =
                              snapshot.data.docs[index]['date'].toDate();
                          String datetime =
                              DateFormat('MMM d, h:mm a').format(date);
                          String message = snapshot.data.docs[index]['message'];
                          return SingleMessage(
                            friendName: _otherUserName,
                            datetime: datetime,
                            message: message,
                            isMe: isMe,
                          );
                        },
                      );
                    }
                    return Center(child: CircularProgressIndicator());
                  }),
            ),
          ),
          if (widget.currentUserId != null || widget.u_id != null)
            Container(
              child: MessageTextField(
                widget.currentUserId,
                widget.u_id,
              ),
            ),
        ],
      ),
    );
  }
}
