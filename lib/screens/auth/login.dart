// import 'package:auth_buttons/auth_buttons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter_platform_interface/src/types/location.dart';
import 'package:provider/provider.dart';
import 'package:sparepark/main.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sparepark/screens/auth/register_screen.dart';
import 'package:sparepark/screens/chat/chat_page.dart';
// import 'package:sparepark/screens/crud/bookings/create_booking.dart';
// import 'package:sparepark/screens/booking/booking.dart';
// import 'package:sparepark/screens/booking/create_booking.dart';
import 'package:sparepark/screens/mapscreens/map_home.dart';
import 'package:sparepark/screens/mapscreens/results_page.dart';
import 'package:sparepark/shared/auth_service.dart';
import 'package:sparepark/shared/style/contstants.dart';
import 'package:sparepark/shared/widgets/app_bar.dart';

class AuthScreen extends StatefulWidget {
  late DateTime? startdatetime;
  late DateTime? enddatetime;
  late String? cpsId;
  late String? routePage;
  late String? address;
  late String? image;
  late String? postcode;

  late String? u_id;

  AuthScreen({
    super.key,
    this.startdatetime,
    this.enddatetime,
    this.cpsId,
    this.routePage,
    this.address,
    this.image,
    this.postcode,
    this.u_id,
  });

  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  GoogleSignIn googleSignIn = GoogleSignIn();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _obscureText = true;
  String _errorMessage = '';
  bool redirectToChat = false;

  @override
  void initState() {
    super.initState();
    print('widget.routePage');
    print(widget.routePage);

    redirectToChat = widget.routePage == 'chat_page';
  }

  Future<void> signInFunction(BuildContext context, String? routePage,
      {required DateTime startDateTime,
      required DateTime endDateTime,
      required String cpsId,
      String? address,
      String? postcode,
      String? image}) async {
    GoogleSignInAccount? googleUser = await googleSignIn.signIn();
    if (googleUser == null) {
      return;
    }
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken, idToken: googleAuth.idToken);
    UserCredential userCredential =
        await FirebaseAuth.instance.signInWithCredential(credential);

    DocumentSnapshot userExist =
        await firestore.collection('users').doc(userCredential.user!.uid).get();
    DocumentSnapshot userEmailExist = await firestore
        .collection('users')
        .doc(userCredential.user!.email)
        .get();

    if (userExist.exists || userEmailExist.exists) {
      print("User Already Exists in Database");
    } else {
      await firestore.collection('users').doc(userCredential.user!.uid).set({
        'email': userCredential.user!.email,
        'name': userCredential.user!.displayName,
        'image': userCredential.user!.photoURL,
        'uid': userCredential.user!.uid,
        'date': DateTime.now(),
      });
    }

    if (redirectToChat) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ChatPage(
            u_id: widget.u_id!,
            currentUserId: userCredential.user!.uid,
          ),
        ),
      );
    } else if (widget.routePage == 'booking_page') {
      // Navigator.pushReplacement(
      //   context,
      //   MaterialPageRoute(
      //     builder: (context) => Booking(
      //       startDateTime: startDateTime,
      //       endDateTime: endDateTime,
      //       cpsId: cpsId,
      //       address: address!,
      //       image: image!,
      //       postcode: postcode!,
      //     ),
      //   ),
      // );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MapHome(),
        ),
      );
    }
  }

  Future<void> signInFunc(BuildContext context, [String? u_id]) async {
    GoogleSignInAccount? googleUser = await googleSignIn.signIn();
    if (googleUser == null) {
      return;
    }
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken, idToken: googleAuth.idToken);
    UserCredential userCredential =
        await FirebaseAuth.instance.signInWithCredential(credential);

    DocumentSnapshot userExist =
        await firestore.collection('users').doc(userCredential.user!.uid).get();
    DocumentSnapshot userEmailExist = await firestore
        .collection('users')
        .doc(userCredential.user!.email)
        .get();

    if (userExist.exists || userEmailExist.exists) {
      print("User Already Exists in Database");
    } else {
      await firestore.collection('users').doc(userCredential.user!.uid).set({
        'email': userCredential.user!.email,
        'name': userCredential.user!.displayName,
        'image': userCredential.user!.photoURL,
        'uid': userCredential.user!.uid,
        'date': DateTime.now(),
      });
    }

    if (userCredential != null) {
      if (widget.routePage == 'chat_page') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ChatPage(
              u_id: u_id!,
              currentUserId: userCredential.user!.uid,
            ),
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MapHome(),
          ),
        );
      }
    }
  }

  void _login({required String routePage}) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );
      if (routePage == 'booking_page') {
        // Navigator.push(
        //   context,
        //   MaterialPageRoute(
        //     builder: (context) => Booking(
        //       startDateTime: widget.startdatetime!,
        //       endDateTime: widget.enddatetime!,
        //       cpsId: widget.cpsId!,
        //       address: '',
        //       image: '',
        //       postcode: '',
        //     ),
        //   ),
        // );
      } else if (redirectToChat) {
        if (widget.u_id != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatPage(
                u_id: widget.u_id!,
                currentUserId: userCredential.user!.uid,
              ),
            ),
          );
        }
      }
      print('User logged in: ${userCredential.user!.email}');
    } catch (error) {
      setState(() {
        _errorMessage = error.toString();
      });
      print('Error: $_errorMessage');
    }
    // }
  }

  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final isLoggedInStream = authService.user!.map((user) => user != null);
    print('results:');
    // print(widget.results);
    return Scaffold(
      appBar: CustomAppBar(title: 'Login', isLoggedInStream: isLoggedInStream),
      // drawer: AppDrawer(),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              SizedBox(height: 80),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 180, // Adjust the width as needed
                    height: 180, // Adjust the height as needed
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/parking.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  SizedBox(height: 16), // Add space between the image and text
                  Padding(
                    padding: EdgeInsets.only(
                        right: 15), // Adjust the left padding as needed
                    child: Text(
                      'Spare Park',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      controller: emailController,
                      decoration: InputDecoration(
                        labelText: "Email",
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      controller: passwordController,
                      decoration: InputDecoration(
                          labelText: "Password",
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureText
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: _obscureText
                                  ? Colors.grey
                                  : Constants().primaryColor,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureText = !_obscureText;
                              });
                            },
                          )),
                      obscureText: _obscureText,
                    ),
                  ),
                  SizedBox(height: 20),

                  //                   SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Constants()
                          .primaryColor, // Set a different color for the button
                    ),
                    onPressed: () {
                      if (emailController.text.length > 6 &&
                          passwordController.text.length > 6) {
                        _login(routePage: widget.routePage!);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              "Email and password must be at least 6 characters long.",
                            ),
                          ),
                        );
                      }
                    },
                    child: Text(
                      'Login',
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RegisterScreen(
                            // prior_page: widget.prior_page,
                            // location: widget.location,
                            // results: widget.results,
                            startdatetime: widget.startdatetime,
                            enddatetime: widget.enddatetime,
                          ),
                        ),
                      );
                    },
                    child: Text('Register',
                        style: TextStyle(
                          color: Constants().primaryColor,
                        )),
                  ),

                  SizedBox(height: 10),
                  _errorMessage.isNotEmpty
                      ? Text(
                          _errorMessage,
                          style: TextStyle(
                            color: Colors.red,
                          ),
                        )
                      : Container(),
                ],
              ),
              SizedBox(height: 50),
              Padding(
                padding: EdgeInsets.fromLTRB(15, 0, 15, 30),
                child: Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      if (widget.routePage == 'booking_page') {
                        await signInFunction(
                          context,
                          widget.routePage,
                          startDateTime: widget.startdatetime!,
                          endDateTime: widget.enddatetime!,
                          cpsId: widget.cpsId!,
                          address: widget.address,
                          postcode: widget.postcode,
                          image: widget.image,
                        );
                      } else {
                        if (widget.u_id != null) {
                          await signInFunc(context, widget.u_id!);
                        }
                        await signInFunc(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      minimumSize: Size(350, 60),
                      textStyle: TextStyle(
                        fontSize: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                        side: BorderSide(color: Colors.black),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/google.png', // Replace with the path to your local asset image
                          width: 24,
                          height: 24,
                          errorBuilder: (BuildContext context, Object exception,
                              StackTrace? stackTrace) {
                            return Icon(Icons
                                .ac_unit); // Display the fallback icon if the image fails to load
                          },
                        ),
                        SizedBox(width: 10),
                        Text("Sign In with Google"),
                      ],
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
