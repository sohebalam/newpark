import 'package:flutter/material.dart';

Widget buildErrorMessage(BuildContext context, _errorMessage) {
  if (_errorMessage != null) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        _errorMessage!,
        style: TextStyle(
          color: Colors.red,
        ),
      ),
    );
  } else {
    return SizedBox.shrink();
  }
}
