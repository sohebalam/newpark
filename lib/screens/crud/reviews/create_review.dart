import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'dart:convert';

import 'package:sparepark/models/review_model.dart';
import 'package:sparepark/shared/auth_service.dart';
import 'package:sparepark/shared/style/contstants.dart';
import 'package:sparepark/shared/widgets/app_bar.dart';

class ReviewPage extends StatefulWidget {
  final String b_id;

  ReviewPage({required this.b_id});

  @override
  _ReviewPageState createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  final _formKey = GlobalKey<FormState>();
  late String _description;
  int _safetyRating = 0;
  int _rating = 0;
  bool _isLoading = false;
  late User? currentUser;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    // Get the current user when the widget is first created
    currentUser = FirebaseAuth.instance.currentUser;
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final isLoggedInStream = authService.user!.map((user) => user != null);
    return Scaffold(
      appBar: CustomAppBar(title: 'Review', isLoggedInStream: isLoggedInStream),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 16.0),
                      Text('Select Safety Rating'),
                      RatingBar(
                        initialRating: _safetyRating.toDouble(),
                        minRating: 1,
                        direction: Axis.horizontal,
                        allowHalfRating: false,
                        itemCount: 5,
                        ratingWidget: RatingWidget(
                          full: Icon(Icons.star, color: Colors.amber),
                          half: Icon(Icons.star_half, color: Colors.amber),
                          empty: Icon(Icons.star_border, color: Colors.amber),
                        ),
                        itemPadding: EdgeInsets.symmetric(horizontal: 4.0),
                        // itemBuilder: (context, _) => Icon(
                        //   Icons.star,
                        //   color: Colors.amber,
                        // ),
                        onRatingUpdate: (rating) {
                          setState(() {
                            _safetyRating = rating.toInt();
                          });
                        },
                        itemSize: 32.0,
                      ),
                      SizedBox(height: 16.0),
                      Text('Select Overall Rating'),
                      RatingBar(
                        initialRating: _rating.toDouble(),
                        minRating: 1,
                        direction: Axis.horizontal,
                        allowHalfRating: false,
                        itemCount: 5,
                        ratingWidget: RatingWidget(
                          full: Icon(Icons.star, color: Colors.amber),
                          half: Icon(Icons.star_half, color: Colors.amber),
                          empty: Icon(Icons.star_border, color: Colors.amber),
                        ),
                        itemPadding: EdgeInsets.symmetric(horizontal: 4.0),
                        onRatingUpdate: (rating) {
                          setState(() {
                            _rating = rating.toInt();
                          });
                        },
                        itemSize: 32.0,
                      ),
                      SizedBox(height: 16.0),
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 5,
                        onSaved: (value) {
                          _description = value ?? '';
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter some text';
                          }
                          return null;
                        },
                      ),
                      // Add a submit button
                      SizedBox(height: 16.0),
                      SizedBox(
                        child: ElevatedButton(
                          onPressed: () {
                            // Validate and save the form
                            if (_formKey.currentState!.validate()) {
                              _formKey.currentState!.save();
                              isLoading ? null : _submitReview();
                            }
                          },
                          child: Text('Submit'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Constants()
                                .primaryColor, // Set a different color for the button
                          ),
                        ),
                        width: double.infinity,
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  void _submitReview() async {
    setState(() {
      _isLoading = true;
    });
    final id = FirebaseFirestore.instance.collection('reviews').doc().id;
    try {
      final review = Review(
        r_id: id,
        b_id: widget.b_id,
        u_id: currentUser!.uid,
        description: _description,
        rating: _rating,
        safetyRating: _safetyRating,
        date: DateTime.now(),
      );

      // Add the review to the "reviews" collection in Firestore
      await FirebaseFirestore.instance
          .collection('reviews')
          .add(review.toJson());

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Booking created successfully'),
        ),
      );
    } catch (e) {
      print('Error submitting review: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
