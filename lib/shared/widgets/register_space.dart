import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sparepark/shared/auth_service.dart';

class RegisterSpace extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Register Your Space'),
        centerTitle: true,
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(vertical: 20, horizontal: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StreamBuilder(
              stream: authService.user,
              builder: (BuildContext context, AsyncSnapshot snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                } else if (snapshot.hasData) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'You are logged in.',
                        style: TextStyle(fontSize: 20),
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        child: Text('Logout'),
                        onPressed: () async {
                          await authService.logout();
                        },
                      ),
                    ],
                  );
                } else {
                  return Text(
                    'Please login to register your space.',
                    style: TextStyle(fontSize: 20),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
