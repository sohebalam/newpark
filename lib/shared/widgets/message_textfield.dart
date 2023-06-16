import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class MessageTextField extends StatefulWidget {
  final String currentId;
  final String friendId;

  MessageTextField(this.currentId, this.friendId);

  @override
  _MessageTextFieldState createState() => _MessageTextFieldState();
}

class _MessageTextFieldState extends State<MessageTextField> {
  TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.keyboard),
            onPressed: () {
              // TODO: Implement camera functionality
            },
          ),
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration.collapsed(hintText: 'Send a message'),
            ),
          ),
          IconButton(
            icon: Icon(Icons.send),
            onPressed: () async {
              String message = _controller.text.trim();
              if (message.isNotEmpty) {
                _controller.clear();
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(widget.currentId)
                    .collection('messages')
                    .doc(widget.friendId)
                    .collection('chats')
                    .add({
                  "senderId": widget.currentId,
                  "receiverId": widget.friendId,
                  "message": message,
                  "type": "text",
                  "date": DateTime.now(),
                }).then((value) {
                  FirebaseFirestore.instance
                      .collection('users')
                      .doc(widget.currentId)
                      .collection('messages')
                      .doc(widget.friendId)
                      .set({
                    'last_msg': message,
                  });
                });

                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(widget.friendId)
                    .collection('messages')
                    .doc(widget.currentId)
                    .collection("chats")
                    .add({
                  "senderId": widget.currentId,
                  "receiverId": widget.friendId,
                  "message": message,
                  "type": "text",
                  "date": DateTime.now(),
                }).then((value) {
                  FirebaseFirestore.instance
                      .collection('users')
                      .doc(widget.friendId)
                      .collection('messages')
                      .doc(widget.currentId)
                      .set({"last_msg": message});
                });
              }
            },
          ),
        ],
      ),
    );
  }
}
