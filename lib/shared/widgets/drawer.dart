import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// import 'package:sparepark/screens/auth/login.dart';
// import 'package:sparepark/screens/auth/register_screen.dart';
// import 'package:sparepark/screens/chat/chat_list.dart';
// import 'package:sparepark/screens/crud/admin/booking_adminlist.dart';
// import 'package:sparepark/screens/crud/admin/parking_adminlist.dart';
// import 'package:sparepark/screens/crud/admin/review_adminlist.dart';
// import 'package:sparepark/screens/crud/admin/users_adminlist.dart';
// import 'package:sparepark/screens/crud/bookings/booking_list.dart';
// import 'package:sparepark/screens/crud/parking/parking_list.dart';
// import 'package:sparepark/screens/crud/parking/register_car_parking.dart';
// import 'package:sparepark/screens/crud/reviews/review_list.dart';
// import 'package:sparepark/screens/crud/user/profile.dart';
import 'package:sparepark/screens/mapscreens/map_home.dart';
import 'package:sparepark/shared/auth_service.dart';
import 'package:sparepark/shared/functions.dart';
import 'package:sparepark/shared/style/contstants.dart';
// import 'package:your_app_name/utils/constants.dart';
// import 'package:your_app_name/views/register_parking_space.dart';

class AppDrawer extends StatefulWidget {
  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  // Define messageCount and currentUser at the class level
  int messageCount = 0;
  User? currentUser;

  late Stream<QuerySnapshot> _bookingsStream;
  late Stream<QuerySnapshot> _ParkingStream;
  late Stream<QuerySnapshot> _ReviewStream;
  String userName = '';
  String userPhoto = '';
  late Stream<bool> isLoggedInStream;

  Future<int> countReceivedChats(String userId) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('messages')
        .get();

    int totalCount = 0;

    for (final doc in querySnapshot.docs) {
      final chatSnapshot = await doc.reference.collection('chats').get();
      final receivedChats = chatSnapshot.docs
          .where((chat) => chat['receiverId'] == userId)
          .toList();
      totalCount += receivedChats.length;
    }

    return totalCount;
  }

  @override
  void initState() {
    super.initState();

    // Get the current user when the widget is first created
    currentUser = FirebaseAuth.instance.currentUser;
    // Call getMessageCount to get message count for current user
    getMessageCount();
    _bookingsStream = FirebaseFirestore.instance
        .collection('bookings')
        .where('u_id', isEqualTo: currentUser?.uid)
        .snapshots();
    _ParkingStream = FirebaseFirestore.instance
        .collection('parking_spaces')
        .where('u_id', isEqualTo: currentUser?.uid)
        .snapshots();
    _ReviewStream = FirebaseFirestore.instance
        .collection('reviews')
        .where('u_id', isEqualTo: currentUser?.uid)
        .snapshots();

    if (currentUser != null) {
      countReceivedChats(currentUser!.uid);
      retrieveUserData();
    }
  }

  Future<void> getMessageCount() async {
    print("Finding messages for current user");
    if (currentUser != null) {
      int count = await countReceivedChats(
        currentUser!.uid,
      );

      setState(() {
        messageCount = count;
      });
    }
  }

  Stream<DocumentSnapshot> getUserStream(String userId) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .snapshots();
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

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final isLoggedInStream = authService.user!.map((user) => user != null);

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Constants().primaryColor,
            ),
            child: StreamBuilder<bool>(
              stream: isLoggedInStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child:
                        CircularProgressIndicator(), // Replace with your loading spinner widget
                  );
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else if (snapshot.data == true) {
                  return Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 45,
                          backgroundImage: NetworkImage(userPhoto ?? ''),
                        ),
                        SizedBox(height: 15),
                        Text(
                          '$userName',
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                      ],
                    ),
                  );
                } else {
                  return Text('');
                }
              },
            ),
          ),
          ListTile(
            title: const Text('Home'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MapHome(),
                ),
              );
            },
          ),
          StreamBuilder<bool>(
            stream: isLoggedInStream,
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data!) {
                return Container();
              }

              return ListTile(
                title: const Text('Login'),
                onTap: () {
                  // Navigator.push(
                  //   context,
                  //   MaterialPageRoute(
                  //     builder: (context) => AuthScreen(
                  //       routePage: 'Drawer',
                  //     ),
                  //   ),
                  // );
                },
              );
            },
          ),
          StreamBuilder<bool>(
            stream: isLoggedInStream,
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data!) {
                return const Text('');
              }
              return ListTile(
                title: const Text('Register'),
                onTap: () {
                  // Navigator.push(
                  //   context,
                  //   MaterialPageRoute(
                  //     builder: (context) => RegisterScreen(),
                  //   ),
                  // );
                },
              );
            },
          ),
          ListTile(
            title: const Text('Register Parking Space'),
            onTap: () {
              // Navigator.push(
              //   context,
              //   MaterialPageRoute(
              //     builder: (context) => RegisterParkingSpace(),
              //   ),
              // );
            },
          ),
          StreamBuilder<bool>(
            stream: isLoggedInStream,
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data!) {
                return Column(
                  children: [
                    ListTile(
                      title: Row(
                        children: [
                          const Text('Profile'),
                          SizedBox(width: 8),
                        ],
                      ),
                      onTap: () {
                        // Navigator.push(
                        //   context,
                        //   MaterialPageRoute(
                        //     builder: (context) => UserProfilePage(),
                        //   ),
                        // );
                      },
                    ),
                    ListTile(
                      title: Row(
                        children: [
                          const Text('Messages'),
                          SizedBox(width: 8),
                          MessageAvatar(messageCount: messageCount),
                        ],
                      ),
                      onTap: () {
                        // Navigator.push(
                        //   context,
                        //   MaterialPageRoute(
                        //     builder: (context) => ChatList(),
                        //   ),
                        // );
                      },
                    ),
                    StreamBuilder<QuerySnapshot>(
                      stream: _bookingsStream,
                      builder: (context, snapshot) {
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return Container();
                        }
                        return ListTile(
                          title: const Text('My Bookings'),
                          onTap: () {
                            if (currentUser != null) {
                              // Navigator.push(
                              //   context,
                              //   MaterialPageRoute(
                              //     builder: (context) => BookingsPage(
                              //       userId: currentUser!.uid.toString(),
                              //     ),
                              //   ),
                              // );
                            }
                          },
                        );
                      },
                    ),
                    StreamBuilder<QuerySnapshot>(
                      stream: _ParkingStream,
                      builder: (context, snapshot) {
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return Container();
                        }
                        return ListTile(
                          title: const Text('My Parking Spaces'),
                          onTap: () {
                            // Navigator.push(
                            //   context,
                            //   MaterialPageRoute(
                            //     builder: (context) => ParkingPage(
                            //       userId: currentUser!.uid.toString(),
                            //     ),
                            //   ),
                            // );
                          },
                        );
                      },
                    ),
                    StreamBuilder<QuerySnapshot>(
                      stream: _ReviewStream,
                      builder: (context, snapshot) {
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return Container();
                        }
                        return ListTile(
                          title: const Text('My Reviews'),
                          onTap: () {
                            // Navigator.push(
                            //   context,
                            //   MaterialPageRoute(
                            //     builder: (context) => ReviewListPage(
                            //       userId: currentUser!.uid.toString(),
                            //     ),
                            //   ),
                            // );
                          },
                        );
                      },
                    ),
                    StreamBuilder<DocumentSnapshot>(
                      stream: currentUser != null
                          ? getUserStream(currentUser!.uid)
                          : null,
                      builder: (context, snapshot) {
                        if (!snapshot.hasData || !snapshot.data!.exists) {
                          return Container();
                        }
                        final userDoc = snapshot.data!;
                        final userData =
                            userDoc.data() as Map<String, dynamic>?;
                        final isUserAdmin = userData?['isAdmin'] ?? false;

                        if (isUserAdmin) {
                          return Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.grey,
                                width: 1.0,
                              ),
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                            margin: EdgeInsets.only(
                              left: 16.0,
                              right: 16.0,
                              top: 8.0,
                            ),
                            child: Column(
                              children: [
                                Padding(
                                  padding: EdgeInsets.fromLTRB(0, 15, 0, 0),
                                  child: Center(
                                    child: Text(
                                      'Admin',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),
                                ListTile(
                                  title: const Text('Users List'),
                                  onTap: () {
                                    // Navigator.push(
                                    //   context,
                                    //   MaterialPageRoute(
                                    //     builder: (context) =>
                                    //         UsersAdminListPage(),
                                    //   ),
                                    // );
                                  },
                                ),
                                ListTile(
                                  title: const Text('Parking Spaces List'),
                                  onTap: () {
                                    // Navigator.push(
                                    //   context,
                                    //   MaterialPageRoute(
                                    //     builder: (context) =>
                                    //         ParkingAdminListPage(),
                                    //   ),
                                    // );
                                  },
                                ),
                                ListTile(
                                  title: const Text('Bookings List'),
                                  onTap: () {
                                    // Navigator.push(
                                    //   context,
                                    //   MaterialPageRoute(
                                    //     builder: (context) =>
                                    //         BookingAdminListPage(),
                                    //   ),
                                    // );
                                  },
                                ),
                                ListTile(
                                  title: const Text('Reviews List'),
                                  onTap: () {
                                    // Navigator.push(
                                    //   context,
                                    //   MaterialPageRoute(
                                    //     builder: (context) =>
                                    //         ReviewAdminListPage(),
                                    //   ),
                                    // );
                                  },
                                ),
                              ],
                            ),
                          );
                        } else {
                          return Container();
                        }
                      },
                    ),
                    StreamBuilder<bool>(
                      stream: isLoggedInStream,
                      builder: (context, snapshot) {
                        if (snapshot.hasData && snapshot.data!) {
                          return Column(
                            children: [
                              ListTile(
                                title: Row(
                                  children: [
                                    const Text('Logout'),
                                    SizedBox(width: 8),
                                  ],
                                ),
                                onTap: () {
                                  disconnect();
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => MapHome(),
                                    ),
                                  );
                                },
                              ),
                            ],
                          );
                        }
                        return Container();
                      },
                    ),
                  ],
                );
              }
              return Container();
            },
          ),
        ],
      ),
    );
  }
}

class MessageAvatar extends StatelessWidget {
  final int messageCount;

  const MessageAvatar({required this.messageCount});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 8),
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Constants().primaryColor,
          ),
          padding: EdgeInsets.all(5),
          child: Text(
            '$messageCount',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
