import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:sparepark/shared/auth_service.dart';
import 'package:sparepark/shared/style/contstants.dart';
import 'package:sparepark/shared/widgets/app_bar.dart';

class UserProfilePage extends StatefulWidget {
  @override
  _UserProfilePageState createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  User? currentUser;
  bool isLoading = true;
  bool canDelete = true;
  String userName = '';
  String userPhoto = '';

  @override
  void initState() {
    super.initState();
    // Retrieve the current user when the widget is first created
    currentUser = FirebaseAuth.instance.currentUser;
    // Check if the user has any booked parking spaces
    checkBookedParkingSpaces();
    retrieveUserData();
  }

  Future<void> retrieveUserData() async {
    if (currentUser!.providerData[0].providerId == 'password') {
      // Custom user login, retrieve the user document
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .get();

      // Get the value of the 'name' and 'image' fields from the user document
      final userData = userDoc.data() as Map<String, dynamic>?;
      setState(() {
        userName = userData?['name'] ?? '';
        userPhoto = userData?['image'] ?? '';
      });
    } else {
      // Social login, use 'displayName' field
      setState(() {
        userName = currentUser!.displayName ?? '';
        userPhoto = currentUser!.photoURL ?? '';
      });
    }
  }

  Future<void> checkBookedParkingSpaces() async {
    setState(() {
      isLoading = true;
    });

    // Check if the user has any parking spaces associated with their user ID in the parking_spaces collection
    final QuerySnapshot parkingSpacesSnapshot = await FirebaseFirestore.instance
        .collection('parking_spaces')
        .where('u_id', isEqualTo: currentUser!.uid)
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

  Future<void> deleteUser() async {
    // Delete the user document
    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser!.uid)
        .delete();

    // Delete the user authentication record
    await currentUser!.delete();

    // Show a success message and navigate to the login screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('User deleted successfully'),
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final isLoggedInStream = authService.user!.map((user) => user != null);

    return Scaffold(
      appBar:
          CustomAppBar(title: 'Profile', isLoggedInStream: isLoggedInStream),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Center(
              child: Transform.translate(
                offset: Offset(0, -60),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: 16),
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: NetworkImage(userPhoto ?? ''),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Name: $userName',
                      style: TextStyle(fontSize: 18),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Email: ${currentUser!.email}',
                      style: TextStyle(fontSize: 18),
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: canDelete ? deleteUser : null,
                      child: Text('Delete Account'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Constants()
                            .primaryColor, // Set a different color for the button
                      ),
                    ),
                    if (canDelete == false)
                      Padding(
                          padding: EdgeInsets.fromLTRB(30, 20, 20, 0),
                          child: const Text(
                            'You have a booked parking space, please cancel the booking or contact admin to delete your account',
                            style: TextStyle(fontSize: 18),
                          ))
                  ],
                ),
              ),
            ),
    );
  }
}
