import 'package:flutter/material.dart';

class SingleMessage extends StatelessWidget {
  final String message;
  final bool isMe;
  final String friendName;
  final String datetime;

  SingleMessage({
    required this.message,
    required this.isMe,
    required this.friendName,
    required this.datetime,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            isMe ? 'You' : friendName,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isMe
                  ? Theme.of(context).colorScheme.secondary
                  : Theme.of(context).textTheme.bodyText1!.color,
            ),
          ),
          SizedBox(height: 4.0),
          Text(
            message,
            style: TextStyle(
              color: isMe ? Colors.blue : Colors.black,
            ),
          ),
          SizedBox(height: 3.0),
          Text(
            datetime,
            style: TextStyle(
              fontSize: 10.0,
              color: isMe ? Colors.blue : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
