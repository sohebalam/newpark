import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:sparepark/models/car_park_space.dart';
import 'package:sparepark/shared/auth_service.dart';
import 'package:sparepark/shared/carpark_space_db_helper.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
// import 'package:auth_buttons/auth_buttons.dart';
import 'package:sparepark/shared/functions.dart';
import 'package:sparepark/shared/style/contstants.dart';
import 'package:sparepark/shared/widgets/loginDialog.dart';
import 'package:sparepark/shared/widgets/app_bar.dart';

class ViewParkingSpace extends StatefulWidget {
  final QueryDocumentSnapshot parking;
  final User user;

  ViewParkingSpace({required this.parking, required this.user});

  @override
  _ViewParkingSpaceState createState() => _ViewParkingSpaceState();
}

class _ViewParkingSpaceState extends State<ViewParkingSpace> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _postcodeController = TextEditingController();
  final _hourlyRateController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _postcodeOptions = <String>[];
  final picker = ImagePicker();
  bool _isLoading = false;

  File? _image;
  late String imageUrl;
  String? displayName;
  late Future<DocumentSnapshot> _userFuture;

  @override
  void initState() {
    super.initState();
    _addressController.text = widget.parking['address'];
    _postcodeController.text = widget.parking['postcode'];
    _hourlyRateController.text = widget.parking['hourlyRate'].toString();
    _descriptionController.text = widget.parking['description'];
    // _image = File(widget.parking['p_image']);
    imageUrl = widget.parking['p_image'];
    super.didChangeDependencies();

    _userFuture = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.parking['u_id'])
        .get();
  }

  void _fetchPostcodeOptions(String input) async {
    final url =
        Uri.parse('https://api.postcodes.io/postcodes/$input/autocomplete');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['result'] != null) {
        final options = List<String>.from(data['result']);
        setState(() {
          _postcodeOptions.clear();
          _postcodeOptions.addAll(options);
        });
      }
    }
  }

  Future<void> _getImage() async {
    final action = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select Image Source'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Choose an option:'),
                ListTile(
                  leading: Icon(Icons.camera),
                  title: Text('Camera'),
                  onTap: () {
                    Navigator.pop(context, 'camera');
                  },
                ),
                ListTile(
                  leading: Icon(Icons.image),
                  title: Text('Gallery'),
                  onTap: () {
                    Navigator.pop(context, 'gallery');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
    if (action != null) {
      final pickedFile = await picker.pickImage(
        source: action == 'camera' ? ImageSource.camera : ImageSource.gallery,
      );
      setState(() {
        if (pickedFile != null) {
          _image = File(pickedFile.path);
        }
      });
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // Perform form submission logic here
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    _postcodeController.dispose();
    _hourlyRateController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final isLoggedInStream = authService.user!.map((user) => user != null);
    return Scaffold(
      appBar: CustomAppBar(
          title: 'Parking Space', isLoggedInStream: isLoggedInStream),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              child: Container(
                padding: EdgeInsets.all(16.0),
                child: Stack(
                  children: [
                    FutureBuilder<DocumentSnapshot>(
                        future: _userFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Center(
                              child: CircularProgressIndicator(),
                            );
                          } else if (snapshot.hasError) {
                            return Center(
                              child: Text('Error occurred: ${snapshot.error}'),
                            );
                          } else if (snapshot.hasData) {
                            final userSnapshot = snapshot.data!;
                            displayName = userSnapshot['name'] as String?;
                            // Continue building the rest of your UI with the retrieved displayName
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                SizedBox(height: 16.0),
                                Text(
                                    'To change the address, postcode or user, delete the record and add a new space'),
                                SizedBox(height: 30.0),
                                Text('User: ${displayName}' ??
                                    'No display name found'),
                                SizedBox(height: 16.0),
                                Text('Address: ${widget.parking['address']}'),
                                SizedBox(height: 16.0),
                                Text('Postcode: ${widget.parking['postcode']}'),
                                SizedBox(height: 16.0),
                                Form(
                                  key: _formKey,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [],
                                      ),
                                      TextFormField(
                                        controller: _hourlyRateController,
                                        decoration: InputDecoration(
                                          labelText: 'Hourly Rate',
                                          suffixText: 'GBP',
                                        ),
                                        keyboardType: TextInputType.number,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter an hourly rate';
                                          }
                                          return null;
                                        },
                                      ),
                                      SizedBox(height: 16.0),
                                      TextFormField(
                                        controller: _descriptionController,
                                        decoration: InputDecoration(
                                          labelText: 'Description',
                                        ),
                                        maxLines: 3,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter a description';
                                          }
                                          return null;
                                        },
                                      ),
                                      SizedBox(height: 46.0),
                                      Column(
                                        children: [
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
                                            )
                                          else if (imageUrl.isNotEmpty)
                                            SizedBox(
                                              height: 250,
                                              child: Image.network(
                                                imageUrl,
                                                fit: BoxFit.cover,
                                                loadingBuilder:
                                                    (BuildContext context,
                                                        Widget child,
                                                        ImageChunkEvent?
                                                            loadingProgress) {
                                                  if (loadingProgress == null) {
                                                    return child; // Image is fully loaded
                                                  } else {
                                                    return Center(
                                                      child:
                                                          CircularProgressIndicator(), // Show loading spinner
                                                    );
                                                  }
                                                },
                                                errorBuilder: (BuildContext
                                                        context,
                                                    Object exception,
                                                    StackTrace? stackTrace) {
                                                  return Image.asset(
                                                    'assets/parking1.png', // Placeholder asset image
                                                    fit: BoxFit.cover,
                                                  );
                                                },
                                              ),
                                            ),
                                        ],
                                      ),
                                      SizedBox(height: 16.0),
                                      // GestureDetector(
                                      //   onTap: _getImage,
                                      //   child: Container(
                                      //     height: 40.0,
                                      //     decoration: BoxDecoration(
                                      //       color: Colors.grey[200],
                                      //       borderRadius:
                                      //           BorderRadius.circular(8.0),
                                      //     ),
                                      //     child: Row(
                                      //       mainAxisAlignment:
                                      //           MainAxisAlignment.center,
                                      //       children: [
                                      //         Icon(Icons.camera_alt),
                                      //         SizedBox(width: 8.0),
                                      //         Text('Change Image'),
                                      //       ],
                                      //     ),
                                      //   ),
                                      // ),
                                      // ElevatedButton(
                                      //   style: ElevatedButton.styleFrom(
                                      //       backgroundColor:
                                      //           Constants().primaryColor),
                                      //   onPressed: _ViewParkingSpace,
                                      //   child: Text('Save Changes'),
                                      // ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          } else {
                            return Center(
                              child: Text('No user data found'),
                            );
                          }
                        }),
                  ],
                ),
              ),
            ),
    );
  }

  Future<void> _ViewParkingSpace() async {
    setState(() {
      _isLoading = true;
    });
    try {
      // Perform the actual editing of the parking space using the provided data
      final parkingSpace = widget.parking;
      await parkingSpace.reference.update({
        'hourlyRate': _hourlyRateController.text,
        'description': _descriptionController.text,
        // Add other fields that you want to update
      });

      if (_image != null) {
        final storageRef = firebase_storage.FirebaseStorage.instance
            .ref()
            .child('parking_spaces')
            .child(parkingSpace.id);
        final uploadTask = storageRef.putFile(_image!);
        final snapshot = await uploadTask.whenComplete(() {});
        final imageUrl = await snapshot.ref.getDownloadURL();
        await parkingSpace.reference.update({'p_image': imageUrl});
      }

      // Show a success message and navigate back to the previous screen
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Success'),
            content: Text('Parking space edited successfully'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    } catch (error) {
      // Show an error message if editing fails
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Error'),
            content:
                Text('Failed to edit the parking space. Please try again.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
