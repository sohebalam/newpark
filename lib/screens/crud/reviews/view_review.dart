import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sparepark/shared/auth_service.dart';
import 'package:sparepark/shared/style/contstants.dart';
import 'package:sparepark/shared/widgets/app_bar.dart';

class ReviewItem extends StatefulWidget {
  final String reviewId;
  final QueryDocumentSnapshot<Object?> review;

  ReviewItem(
      {required this.reviewId,
      required bookingId,
      required parkingId,
      required this.review});

  @override
  _ReviewItemState createState() => _ReviewItemState();
}

class _ReviewItemState extends State<ReviewItem> {
  late Future<DocumentSnapshot> _reviewFuture;
  late Future<DocumentSnapshot> _bookingFuture;
  late Future<DocumentSnapshot> _parkingSpaceFuture;

  final _formKey = GlobalKey<FormState>();
  late String _description;
  int _safetyRating = 0;
  int _rating = 0;
  bool _isLoading = false;
  late User? currentUser;

  @override
  void initState() {
    super.initState();

    _reviewFuture = FirebaseFirestore.instance
        .collection('reviews')
        .doc(widget.reviewId)
        .get();
    print('_reviewFuture ${_reviewFuture}');

    _bookingFuture = _reviewFuture.then((reviewSnapshot) {
      return FirebaseFirestore.instance
          .collection('bookings')
          .doc(reviewSnapshot['b_id'])
          .get();
    });
    print('_bookingFuture ${_bookingFuture}');

    _parkingSpaceFuture = _bookingFuture.then((bookingSnapshot) {
      return FirebaseFirestore.instance
          .collection('parking_spaces')
          .doc(bookingSnapshot['p_id'])
          .get();
    });
    print(_parkingSpaceFuture);
    print('_parkingSpaceFuture ${_parkingSpaceFuture}');
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
          title: 'Review Details', isLoggedInStream: isLoggedInStream),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder(
          future: Future.wait([
            _reviewFuture,
            _bookingFuture,
            _parkingSpaceFuture,
          ]),
          builder: (BuildContext context,
              AsyncSnapshot<List<DocumentSnapshot>> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(),
              );
            }

            if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            }

            final reviewSnapshot = snapshot.data![0];
            final bookingSnapshot = snapshot.data![1];
            final parkingSpaceSnapshot = snapshot.data![2];

            final bookingStart = DateFormat('HH:mm a dd MMM yyyy')
                .format(bookingSnapshot['start_date_time'].toDate());
            final bookingEnd = DateFormat('HH:mm a dd MMM yyyy')
                .format(bookingSnapshot['end_date_time'].toDate());

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 16.0),
                Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            'Parking Space Address: ${parkingSpaceSnapshot['address']}'),
                        Text('Booking start time and date: ${bookingStart}'),
                        Text('Booking end time and date: ${bookingEnd}'),
                      ],
                    )),
                _isLoading
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
                                    half: Icon(Icons.star_half,
                                        color: Colors.amber),
                                    empty: Icon(Icons.star_border,
                                        color: Colors.amber),
                                  ),
                                  itemPadding:
                                      EdgeInsets.symmetric(horizontal: 4.0),
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
                                    half: Icon(Icons.star_half,
                                        color: Colors.amber),
                                    empty: Icon(Icons.star_border,
                                        color: Colors.amber),
                                  ),
                                  itemPadding:
                                      EdgeInsets.symmetric(horizontal: 4.0),
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
                                // SizedBox(
                                //   child: ElevatedButton(
                                //       onPressed: () {
                                //         if (_formKey.currentState!.validate()) {
                                //           _formKey.currentState!.save();
                                //           // _editReview();
                                //         }
                                //       },
                                //       child: Text('Submit'),
                                //       style: ButtonStyle(
                                //         backgroundColor:
                                //             MaterialStateProperty.all<Color>(
                                //           Constants().primaryColor,
                                //         ),
                                //       )),
                                //   width: double.infinity,
                                // ),
                              ],
                            ),
                          ),
                        ),
                      ),
              ],
            );
          },
        ),
      ),
    );
  }
}
