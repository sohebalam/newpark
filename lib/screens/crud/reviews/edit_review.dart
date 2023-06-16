import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:provider/provider.dart';
import 'package:sparepark/shared/auth_service.dart';
import 'package:sparepark/shared/style/contstants.dart';
import 'package:sparepark/shared/widgets/app_bar.dart';

class EditReviewPage extends StatefulWidget {
  final QueryDocumentSnapshot<Object?> review;

  EditReviewPage({required this.review});

  @override
  _EditReviewPageState createState() => _EditReviewPageState();
}

class _EditReviewPageState extends State<EditReviewPage> {
  final _formKey = GlobalKey<FormState>();
  late String _description;
  int _safetyRating = 0;
  int _rating = 0;
  bool _isLoading = false;
  late User? currentUser;

  @override
  void initState() {
    super.initState();
    // Get the current user when the widget is first created
    currentUser = FirebaseAuth.instance.currentUser;
    _initializeFields();
  }

  void _initializeFields() {
    final review = widget.review;

    _description = review.get('description') ?? '';
    _safetyRating = review.get('safety_rating') ?? 0;
    _rating = review.get('rating') ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final isLoggedInStream = authService.user!.map((user) => user != null);
    return Scaffold(
      appBar: CustomAppBar(
          title: 'Update Review', isLoggedInStream: isLoggedInStream),
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
                        initialValue: _description,
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
                      SizedBox(height: 16.0),
                      SizedBox(
                        child: ElevatedButton(
                            onPressed: () {
                              if (_formKey.currentState!.validate()) {
                                _formKey.currentState!.save();
                                _editReview();
                              }
                            },
                            child: Text('Submit'),
                            style: ButtonStyle(
                              backgroundColor: MaterialStateProperty.all<Color>(
                                Constants().primaryColor,
                              ),
                            )),
                        width: double.infinity,
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Future<void> _editReview() async {
    setState(() {
      _isLoading = true;
    });
    try {
      // Perform the actual editing of the review using the provided data
      final review = widget.review;
      await review.reference.update({
        'description': _description,
        'safety_rating': _safetyRating, // updated field
        'rating': _rating, // updated field
      });

      // Show a success message and navigate back to the previous screen
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Success'),
            content: Text('Review edited successfully'),
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
            content: Text('Failed to edit the review. Please try again.'),
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
