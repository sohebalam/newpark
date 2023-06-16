import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sparepark/models/booking_model.dart';
import 'package:sparepark/models/car_park_space.dart';
import 'dart:math' as math;
import 'package:geolocator/geolocator.dart';

class DB_Booking {
  static Stream<List<BookingModel>> read() {
    final userCollection = FirebaseFirestore.instance.collection("bookings");
    return userCollection.snapshots().map((querySnapshot) =>
        querySnapshot.docs.map((e) => BookingModel.fromSnapshot(e)).toList());
  }

  static Future create(BookingModel book, userId) async {
    final carpark_spaceCollection =
        FirebaseFirestore.instance.collection("bookings");

    final bookid = carpark_spaceCollection.doc().id;
    final docRef = carpark_spaceCollection.doc(bookid);

    final booking = BookingModel(
      u_id: userId,
      p_id: book.p_id,
      b_total: book.b_total,
      end_date_time: book.end_date_time,
      start_date_time: book.start_date_time,
      reg_date: book.reg_date,
    ).toJson();

    try {
      await docRef.set(booking);
    } catch (e) {
      print("some error occured $e");
    }
  }
}
