import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter_platform_interface/src/types/location.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:sparepark/shared/auth_service.dart';
import 'package:sparepark/shared/functions.dart';
import 'package:sparepark/shared/style/contstants.dart';
import 'package:sparepark/shared/widgets/textField.dart';
import 'package:sparepark/shared/widgets/app_bar.dart';
import 'package:sparepark/shared/widgets/errorMessage.dart';

class RegisterScreen extends StatefulWidget {
  final String? prior_page; // Added the prior_page property
  final LatLng? location;
  final List<List>? results;
  final DateTime? startdatetime;
  final DateTime? enddatetime;

  const RegisterScreen({
    Key? key,
    this.prior_page,
    this.location,
    this.results,
    this.startdatetime,
    this.enddatetime,
  }) : super(key: key);

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _isLoading = false;
  final picker = ImagePicker();
  File? _image;
  String? _error;
  String? _errorMessage;
  bool submitted = false;
  bool _obscureText = true;

  _registerUser() async {
    setState(() {
      submitted = true;
    });

    if (_image == null) {
      setState(() {
        _errorMessage = 'Please select an image.';
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true; // Set loading state
    });

    if (_image == null) {
      setState(() {
        _error = 'Please select an image.';
      });
      return;
    }
    // try {
    final authService = Provider.of<AuthService>(context, listen: false);

    try {
      final user = await authService.createUserWithEmailAndPassword(
        context,
        emailController.text,
        passwordController.text,
        _image!,
        nameController.text,
        prior_page: widget.prior_page,
        location: widget.location,
        results: widget.results,
        startdatetime: widget.startdatetime,
        enddatetime: widget.enddatetime,
      );
      if (user != null) {
        // User created successfully, show a success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('New user registered successfully!'),
          ),
        );
      } else {
        // User creation failed, show an error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Something went wrong. Please try again later.'),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      // Use e.message instead of e.toString() to show the specific error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message.toString()),
        ),
      );
    } catch (e) {
      // An unknown exception occurred, show an error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
        ),
      );
    }
    setState(() {
      _isLoading = false; // Reset loading state
    });
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final isLoggedInStream = authService.user!.map((user) => user != null);
    Future<void> _getImage() async {
      final action = await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Select Image Source'),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  GestureDetector(
                    child: Text('Camera'),
                    onTap: () {
                      Navigator.of(context).pop(ImageSource.camera);
                    },
                  ),
                  Padding(padding: EdgeInsets.all(8.0)),
                  GestureDetector(
                    child: Text('Gallery'),
                    onTap: () {
                      Navigator.of(context).pop(ImageSource.gallery);
                    },
                  ),
                ],
              ),
            ),
          );
        },
      );

      if (action == null) return;

      final pickedFile = await picker.pickImage(source: action);

      setState(() {
        if (pickedFile != null) {
          _image = File(pickedFile.path);
          _errorMessage = null;
        } else {
          print('No image selected.');
        }
      });
    }

    return Scaffold(
      appBar:
          CustomAppBar(title: 'Register', isLoggedInStream: isLoggedInStream),
      body: Container(
        margin: const EdgeInsets.only(top: 16.0, left: 16, right: 16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    errorText: !submitted || nameController.text.isNotEmpty
                        ? null
                        : 'Please enter your name.',
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    errorText: !submitted ||
                            emailController.text.isEmpty ||
                            isEmailValid(emailController.text)
                        ? null
                        : 'Please enter a valid email address.',
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  obscureText: _obscureText,
                  controller: passwordController,
                  decoration: InputDecoration(
                      labelText: 'Password',
                      errorText:
                          !submitted || passwordController.text.isNotEmpty
                              ? null
                              : 'Please enter your password.',
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
                ),
              ),
              const SizedBox(
                height: 16.0,
              ),
              GestureDetector(
                onTap: _getImage,
                child: Container(
                  height: 50.0,
                  decoration: BoxDecoration(
                    color: Constants().tertiaryColor,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                      ),
                      SizedBox(width: 8.0),
                      Text(
                        'Select Image',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(
                height: 16.0,
              ),
              if (_image != null)
                Container(
                  height: 200.0,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: FileImage(_image!),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              const SizedBox(
                height: 16.0,
              ),
              if (_isLoading) Center(child: CircularProgressIndicator()),
              buildErrorMessage(context, _errorMessage),
              Container(
                height: 40.0,
                width: double.infinity, // Span the button across the screen
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _registerUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Constants()
                        .primaryColor, // Set a different color for the button
                  ),
                  child: const Text('Register'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
