import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sparepark/screens/crud/bookings/view_booking.dart';
import 'package:sparepark/screens/crud/bookings/edit_booking.dart';
import 'package:sparepark/screens/crud/reviews/create_review.dart';
import 'package:sparepark/shared/auth_service.dart';
import 'package:sparepark/shared/widgets/app_bar.dart';

class BookingAdminListPage extends StatefulWidget {
  BookingAdminListPage();

  @override
  _BookingAdminListPageState createState() => _BookingAdminListPageState();
}

class _BookingAdminListPageState extends State<BookingAdminListPage> {
  late Stream<QuerySnapshot> _bookingsStream;

  @override
  void initState() {
    super.initState();

    _bookingsStream =
        FirebaseFirestore.instance.collection('bookings').snapshots();
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
      appBar:
          CustomAppBar(title: 'Bookings', isLoggedInStream: isLoggedInStream),
      body: StreamBuilder<QuerySnapshot>(
        stream: _bookingsStream,
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

          final bookings = snapshot.data!.docs;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView.builder(
              itemCount: bookings.length,
              itemBuilder: (BuildContext context, int index) {
                final booking = bookings[index];
                final bookingDate = DateFormat('HH:mm a dd MMM yyyy')
                    .format(booking['reg_date'].toDate());
                final bookingStart = DateFormat('HH:mm a dd MMM yyyy')
                    .format(booking['start_date_time'].toDate());
                final bookingEnd = DateFormat('HH:mm a dd MMM yyyy')
                    .format(booking['end_date_time'].toDate());

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

                            final parkingSpaceData =
                                snapshot.data!.data() as Map<String, dynamic>?;
                            final address = parkingSpaceData?['address'];

                            if (address == null) {
                              return Text('Address not available');
                            }

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Address: $address'),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => EditBooking(
                                              bookingId: booking['b_id'],
                                              cpsId: booking['p_id'],
                                              endDateTime:
                                                  booking['end_date_time']
                                                      .toDate(),
                                              startDateTime:
                                                  booking['start_date_time']
                                                      .toDate(),
                                              address: address,
                                              postcode:
                                                  parkingSpaceData?['postcode'],
                                              image:
                                                  parkingSpaceData?['p_image'],
                                            ),
                                          ),
                                        );
                                      },
                                      child: Text('Edit'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        String bookingId = booking.id;
                                        // _deleteBooking(context, bookingId);
                                        _deleteBooking(context, bookingId);
                                      },
                                      child: Text('Delete'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => ReviewPage(
                                              b_id: booking['b_id'],
                                            ),
                                          ),
                                        );
                                      },
                                      child: Text('Add Review'),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
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

  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  void _deleteBooking(BuildContext context, String bookingId) async {
    try {
      // Delete the review from the 'reviews' collection
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .delete();

      // Delete the reviews connected to the booking
      await FirebaseFirestore.instance
          .collection('reviews')
          .where('b_id', isEqualTo: bookingId)
          .get()
          .then((querySnapshot) {
        querySnapshot.docs.forEach((reviewDoc) {
          reviewDoc.reference.delete();
        });
      });

      // Show a success message
      _scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text('Booking deleted successfully'),
        ),
      );
    } catch (error) {
      // Show an error message
      _scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text('Error deleting the Booking: $error'),
        ),
      );
    }
  }
}
