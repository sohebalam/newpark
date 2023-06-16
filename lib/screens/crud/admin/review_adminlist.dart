import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';
import 'package:sparepark/screens/crud/reviews/edit_review.dart';
import 'package:sparepark/screens/crud/reviews/view_review.dart';
import 'package:sparepark/shared/auth_service.dart';
import 'package:sparepark/shared/widgets/app_bar.dart';

class ReviewAdminListPage extends StatefulWidget {
  ReviewAdminListPage();

  @override
  _ReviewAdminListPageState createState() => _ReviewAdminListPageState();
}

class _ReviewAdminListPageState extends State<ReviewAdminListPage> {
  late Stream<QuerySnapshot> _reviewStream;

  @override
  void initState() {
    super.initState();

    _reviewStream =
        FirebaseFirestore.instance.collection('reviews').snapshots();
  }

  Future<DocumentSnapshot> getParkingSpace(String parkingSpaceId) {
    return FirebaseFirestore.instance
        .collection('parking_spaces')
        .doc(parkingSpaceId)
        .get();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final isLoggedInStream = authService.user!.map((user) => user != null);

    return Scaffold(
      key: _scaffoldMessengerKey,
      appBar: CustomAppBar(
        title: 'Reviews',
        isLoggedInStream: isLoggedInStream,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _reviewStream,
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

          final reviews = snapshot.data!.docs;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView.builder(
              itemCount: reviews.length,
              itemBuilder: (BuildContext context, int index) {
                final review = reviews[index];

                return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('bookings')
                      .doc(review['b_id'])
                      .get(),
                  builder: (BuildContext context,
                      AsyncSnapshot<DocumentSnapshot> snapshot) {
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

                    final booking = snapshot.data!;

                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FutureBuilder<DocumentSnapshot>(
                              future: getParkingSpace(booking['p_id']),
                              builder: (BuildContext context,
                                  AsyncSnapshot<DocumentSnapshot> snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return CircularProgressIndicator();
                                }

                                if (snapshot.hasError || !snapshot.hasData) {
                                  return Text(
                                      'Error: Unable to retrieve parking space information');
                                }

                                final parkingSpaceData = snapshot.data!.data()
                                    as Map<String, dynamic>?;
                                final address = parkingSpaceData?['address'];

                                if (address == null) {
                                  return Text('Address not available');
                                }

                                return Text('Address: $address');
                              },
                            ),
                            Text('Description: ${review['description']}'),
                            Text('Review Space id: ${review['b_id']}'),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () {
                                    String bookingId = review['b_id'];

                                    // Use async/await instead of chaining promises
                                    // to make the code more readable
                                    _viewParkingSpace(bookingId, review);
                                  },
                                  child: Text('View'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            EditReviewPage(review: review),
                                      ),
                                    );
                                  },
                                  child: Text('Edit'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    String reviewId = review.id;
                                    _deleteReview(context, reviewId);
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
                );
              },
            ),
          );
        },
      ),
    );
  }

  // Define a separate method to handle the "view" action
  // so that the build method is not too cluttered
  void _viewParkingSpace(String bookingId, review) async {
    // Query the bookings collection using the booking id
    final booking = await FirebaseFirestore.instance
        .collection('bookings')
        .doc(bookingId)
        .get();

    // Get the parking id from the booking
    // print(booking?.id);
    final parkingId = booking['p_id'];

    // Query the parking spaces collection using the parking id
    final parking = await FirebaseFirestore.instance
        .collection('parking_spaces')
        .doc(parkingId)
        .get();

    // Print the id of the parking space to the console
    print(parking.id);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReviewItem(
          review: review,
          reviewId: review.id,
          bookingId: bookingId,
          parkingId: parkingId,
        ),
      ),
    );
  }
}

final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

void _deleteReview(BuildContext context, String reviewId) async {
  try {
    // Delete the review from the 'reviews' collection
    await FirebaseFirestore.instance
        .collection('reviews')
        .doc(reviewId)
        .delete();

    // Show a success message
    _scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text('Review deleted successfully'),
      ),
    );
  } catch (error) {
    // Show an error message
    _scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text('Error deleting the review: $error'),
      ),
    );
  }
}
