import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

GoogleSignIn googleSignIn = GoogleSignIn();
FirebaseFirestore firestore = FirebaseFirestore.instance;

Future signInFunction() async {
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

  if (userExist.exists) {
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
}

final _auth = FirebaseAuth.instance;
Future<void> disconnect() async {
// User? get user => _auth.currentUser;
  await _auth.signOut();
}

DateTime roundToNearest15Minutes(DateTime dateTime) {
  final minutes = dateTime.minute;
  final roundedMinutes = (minutes / 15).round() * 15;
  return DateTime(dateTime.year, dateTime.month, dateTime.day, dateTime.hour,
      roundedMinutes);
}

bool isEmailValid(String email) {
  final emailRegex = RegExp(r'^[\w-]+(.[\w-]+)*@([\w-]+.)+[a-zA-Z]{2,7}$');
  return emailRegex.hasMatch(email);
}

String formatDateTime(DateTime dateTime) {
  String day = dateTime.day.toString().padLeft(2, '0');
  String month = dateTime.month.toString().padLeft(2, '0');
  String year = dateTime.year.toString();
  String hour = dateTime.hour.toString().padLeft(2, '0');
  String minute = dateTime.minute.toString().padLeft(2, '0');
  return '$day/$month/$year $hour:$minute';
}

List<DocumentSnapshot> findClosestParkingSpaces(
    double latitude, double longitude, List<DocumentSnapshot> parkingSpaces) {
  // Convert degrees to radians
  double degToRad(double deg) => deg * (pi / 180);

  // Calculate the distance between two points using the Haversine formula
  double distance(double lat1, double lon1, double lat2, double lon2) {
    const double R = 6371.0; // Earth radius in km
    double dLat = degToRad(lat2 - lat1);
    double dLon = degToRad(lon2 - lon1);
    double a = pow(sin(dLat / 2), 2) +
        cos(degToRad(lat1)) * cos(degToRad(lat2)) * pow(sin(dLon / 2), 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  // Sort parkingSpaces by distance from the given location
  parkingSpaces.sort((a, b) {
    double distanceA =
        distance(latitude, longitude, a['latitude'], a['longitude']);
    double distanceB =
        distance(latitude, longitude, b['latitude'], b['longitude']);
    return distanceA.compareTo(distanceB);
  });

  // Return the closest 5 parking spaces
  return parkingSpaces.take(2).toList();
}
