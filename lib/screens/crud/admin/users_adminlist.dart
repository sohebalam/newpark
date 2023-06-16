import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';
import 'package:sparepark/screens/crud/reviews/edit_review.dart';
import 'package:sparepark/screens/crud/reviews/view_review.dart';
import 'package:sparepark/screens/crud/user/admin_profile.dart';
import 'package:sparepark/shared/auth_service.dart';
import 'package:sparepark/shared/widgets/app_bar.dart';

class UsersAdminListPage extends StatefulWidget {
  UsersAdminListPage();

  @override
  _UsersAdminListPageState createState() => _UsersAdminListPageState();
}

class _UsersAdminListPageState extends State<UsersAdminListPage> {
  late Stream<QuerySnapshot> _usersStream;
  User? currentUser;
  bool isLoading = true;
  bool canDelete = true;

  @override
  void initState() {
    super.initState();

    _usersStream = FirebaseFirestore.instance.collection('users').snapshots();
  }

  Future<void> retrieveUserData(String userId) async {
    if (currentUser!.providerData[0].providerId == 'password') {
      // Custom user login, retrieve the user document
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      // Get the value of the 'name' and 'image' fields from the user document
    }
  }

  Future<void> checkBookedParkingSpaces(String userId) async {
    setState(() {
      isLoading = true;
    });

    // Check if the user has any parking spaces associated with their user ID in the parking_spaces collection
    final QuerySnapshot parkingSpacesSnapshot = await FirebaseFirestore.instance
        .collection('parking_spaces')
        .where('u_id', isEqualTo: userId)
        .get();

    // Check if any of the parking spaces associated with the user have been booked in the bookings collection
    for (final DocumentSnapshot parkingSpaceDoc in parkingSpacesSnapshot.docs) {
      final String parkingSpaceId = parkingSpaceDoc.id;
      final QuerySnapshot bookingsSnapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('p_id', isEqualTo: parkingSpaceId)
          .limit(1)
          .get();

      // If a booking exists for the parking space, the user cannot be deleted
      if (bookingsSnapshot.docs.isNotEmpty) {
        setState(() {
          canDelete = false;
          isLoading = false;
        });
        return;
      }
    }

    // If no bookings are found for any parking spaces associated with the user, the user can be deleted
    setState(() {
      canDelete = true;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final isLoggedInStream = authService.user!.map((user) => user != null);

    return Scaffold(
      key: _scaffoldMessengerKey,
      appBar: CustomAppBar(
        title: 'Users',
        isLoggedInStream: isLoggedInStream,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _usersStream,
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }

          final users = snapshot.data!.docs;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView.builder(
              itemCount: users.length,
              itemBuilder: (BuildContext context, int index) {
                final user = users[index];

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('User ID: ${user.id}'),
                        Text('Name: ${user['name']}'),
                        Text('Email: ${user['email']}'),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        AdminUserProfilePage(userId: user.id),
                                  ),
                                );
                              },
                              child: Text('Edit'),
                            ),
                            TextButton(
                              onPressed: () async {
                                String userId = user.id;
                                await checkBookedParkingSpaces(userId);
                                canDelete
                                    ? _deleteUser(context, userId)
                                    : showDeleteDialog(context, userId);
                              },
                              child: Text('Delete'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

void showDeleteDialog(BuildContext context, String userId) async {
  final bool canDelete = await showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Delete User'),
        content: Text(
            'This user has a booked parking space. Are you sure you want to delete?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false); // User chose to cancel
            },
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(true); // User chose to delete
            },
            child: Text('OK'),
          ),
        ],
      );
    },
  );

  if (canDelete != null && canDelete) {
    _deleteUser(context, userId);
  }
}

final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

void _deleteUser(BuildContext context, String userId) async {
  try {
    // Delete the user from the 'users' collection
    await FirebaseFirestore.instance.collection('users').doc(userId).delete();

// Delete the bookings from the 'bookings'  collection for the user
    await FirebaseFirestore.instance
        .collection('parking_spaces')
        .where('u_id', isEqualTo: userId)
        .get()
        .then((QuerySnapshot snapshot) {
      snapshot.docs.forEach((DocumentSnapshot doc) {
        doc.reference.delete();
      });
    });
    await FirebaseFirestore.instance
        .collection('bookings')
        .where('u_id', isEqualTo: userId)
        .get()
        .then((QuerySnapshot snapshot) {
      snapshot.docs.forEach((DocumentSnapshot doc) {
        doc.reference.delete();
      });
    });
    await FirebaseFirestore.instance
        .collection('reviews')
        .where('u_id', isEqualTo: userId)
        .get()
        .then((QuerySnapshot snapshot) {
      snapshot.docs.forEach((DocumentSnapshot doc) {
        doc.reference.delete();
      });
    });

    // Show a success message
    _scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text('User deleted successfully'),
      ),
    );
  } catch (error) {
    // Show an error message
    _scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text('Error deleting the user: $error'),
      ),
    );
  }
}
