import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:custom_map_markers/custom_map_markers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:ui' as ui;

import 'package:intl/intl.dart';
import 'package:sparepark/models/booking_model.dart';
import 'package:sparepark/screens/crud/bookings/payment.dart';
import 'package:sparepark/shared/functions.dart';
import 'package:sparepark/shared/style/contstants.dart';

class EditBooking extends StatefulWidget {
  EditBooking({
    Key? key,
    required this.cpsId,
    required this.image,
    required this.postcode,
    required this.address,
    required this.startDateTime,
    required this.endDateTime,
    required this.bookingId,
  }) : super(key: key);

  final String cpsId;
  final String image;
  final String postcode;
  final String address;
  final String bookingId;
  DateTime startDateTime;
  DateTime endDateTime;

  @override
  State<EditBooking> createState() => _EditBookingState();
}

class _EditBookingState extends State<EditBooking> {
  late List<MarkerData> _customMarkers = [];
  late GoogleMapController _mapController;
  double _hourlyRate = 10;
  late User? currentUser;
  bool isLoading = false;

  double get total {
    final hours = widget.endDateTime.difference(widget.startDateTime).inHours;
    return hours * _hourlyRate;
  }

  @override
  void initState() {
    super.initState();
    currentUser = FirebaseAuth.instance.currentUser;
    _fetchMarkerData();
  }

  void editBooking() async {
    // Round the startDateTime and endDateTime to the nearest 15 minutes
    final roundedStartDateTime = roundToNearest15Minutes(widget.startDateTime);
    final roundedEndDateTime = roundToNearest15Minutes(widget.endDateTime);
    print('herebefore');

    Future<void> checkBookingOverlap() async {
      final QuerySnapshot bookingsSnapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('p_id', isEqualTo: widget.cpsId)
          .get();

      final List<DocumentSnapshot> bookings = bookingsSnapshot.docs;

      print('here');

      // Loop through each booking and check for overlap
      for (final booking in bookings) {
        final DateTime existingStartDateTime =
            booking['start_date_time'].toDate();
        final DateTime existingEndDateTime = booking['end_date_time'].toDate();

        if (roundedStartDateTime.isBefore(existingEndDateTime) &&
            roundedEndDateTime.isAfter(existingStartDateTime)) {
          // Overlapping booking found
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'There is already a booking with the given date and time.'),
            ),
          );
          return; // Break out of the function
        }
      }

      // No overlapping booking found, continue with booking process
      // ... Your booking logic goes here ...
      final QuerySnapshot bookingSnapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('b_id', isEqualTo: widget.bookingId)
          .limit(1)
          .get();

      if (bookingSnapshot.docs.isNotEmpty) {
        final DocumentSnapshot bookingDoc = bookingSnapshot.docs.first;

        // Update the booking fields
        await bookingDoc.reference.update({
          'start_date_time': roundedStartDateTime,
          'end_date_time': roundedEndDateTime,
          'b_total': total,
          'reg_date': DateTime.now(),
        });

        // Show a success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Booking ${widget.bookingId} updated successfully'),
          ),
        );
      }
    }

    // Call the checkBookingOverlap function to perform the overlap check
    await checkBookingOverlap();
  }

  Future<void> _fetchMarkerData() async {
    final spaceDoc = await FirebaseFirestore.instance
        .collection('parking_spaces')
        .doc(widget.cpsId)
        .get();

    final spaceData = spaceDoc.data() as Map<String, dynamic>;

    final latitude = spaceData['latitude'] as double;
    final longitude = spaceData['longitude'] as double;
    final hourlyRate =
        spaceData['hourlyRate'] as double; // Fetch hourlyRate from database

    setState(() {
      _hourlyRate = hourlyRate; // Update the hourlyRate value
    });

    final markerId = MarkerId(widget.cpsId);
    final marker = Marker(
      markerId: markerId,
      position: LatLng(latitude, longitude),
      icon: BitmapDescriptor.defaultMarker,
      infoWindow: InfoWindow(
        title: widget.address,
        snippet: widget.postcode,
      ),
    );

    final resizedBytes = await _loadImageData(widget.image);
    final customMarker = MarkerData(
      marker: marker,
      child: _customMarker(resizedBytes, Constants().primaryColor),
    );

    setState(() {
      _customMarkers = [customMarker];
    });
  }

  Future<Uint8List> _loadImageData(String imagePath) async {
    if (imagePath.isEmpty) {
      // Load a local image instead
      final ByteData localImageData =
          await rootBundle.load('assets/carpark1.jpg');
      return localImageData.buffer.asUint8List();
    }

    try {
      final response = await http.get(Uri.parse(imagePath));
      final data = response.bodyBytes;
      final compressedData = await FlutterImageCompress.compressWithList(
        data,
        minHeight: 200,
        minWidth: 150,
        quality: 90,
      );
      return Uint8List.fromList(compressedData);
    } catch (e) {
      // Handle the exception and return an empty marker
      print('Error loading image: $e');
      return Uint8List(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    widget.startDateTime = roundToNearest15Minutes(widget.startDateTime);
    widget.endDateTime = roundToNearest15Minutes(widget.endDateTime);

    TextEditingController startDateController = TextEditingController(
      text: DateFormat('HH:mm, dd MMM yy').format(widget.startDateTime),
    );
    TextEditingController endDateController = TextEditingController(
      text: DateFormat('HH:mm, dd MMM yy').format(widget.endDateTime),
    );

    startDateController.text =
        DateFormat('HH:mm, dd MMM yy').format(widget.startDateTime);
    endDateController.text =
        DateFormat('HH:mm, dd MMM yy').format(widget.endDateTime);

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: CustomGoogleMapMarkerBuilder(
              customMarkers: _customMarkers,
              builder: (BuildContext context, Set<Marker>? markers) {
                if (markers == null) {
                  return const Center(child: CircularProgressIndicator());
                }
                return GoogleMap(
                  initialCameraPosition: const CameraPosition(
                    target: LatLng(51.654827, -0.083599),
                    zoom: 14.4746,
                  ),
                  markers: markers,
                  onMapCreated: (GoogleMapController controller) {
                    _mapController = controller;
                    _animateToMarker();
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(6.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Text(
                              'Start',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            padding: EdgeInsets.symmetric(
                                vertical: 0, horizontal: 16),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: startDateController,
                                    decoration: InputDecoration(
                                      border: InputBorder.none,
                                      // labelText: 'Start Date',
                                    ),
                                    onTap: () async {
                                      final DateTime? picked =
                                          await showDatePicker(
                                        context: context,
                                        initialDate: DateTime.now()
                                                .isBefore(widget.startDateTime)
                                            ? widget.startDateTime
                                            : DateTime.now(),
                                        firstDate: DateTime.now(),
                                        lastDate: DateTime.now()
                                            .add(Duration(days: 365)),
                                      );

                                      if (picked != null) {
                                        final TimeOfDay? pickedTime =
                                            await showTimePicker(
                                          context: context,
                                          initialTime: TimeOfDay.fromDateTime(
                                              widget.startDateTime),
                                        );

                                        if (pickedTime != null) {
                                          setState(() {
                                            widget.startDateTime = DateTime(
                                              picked.year,
                                              picked.month,
                                              picked.day,
                                              pickedTime.hour,
                                              pickedTime.minute,
                                            );
                                            startDateController.text =
                                                DateFormat('HH:mm dd MMM yy')
                                                    .format(
                                                        widget.startDateTime);

                                            // Set the endDateTime as one hour after the startDateTime
                                            widget.endDateTime = widget
                                                .startDateTime
                                                .add(Duration(hours: 1));
                                            endDateController.text =
                                                DateFormat('HH:mm dd MMM yy')
                                                    .format(widget.endDateTime);
                                          });
                                        }
                                      }
                                    },
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () async {
                                    final DateTime? picked =
                                        await showDatePicker(
                                      context: context,
                                      initialDate: widget.startDateTime,
                                      firstDate: widget.startDateTime,
                                      lastDate: DateTime.now()
                                          .add(Duration(days: 365)),
                                    );

                                    if (picked != null) {
                                      final TimeOfDay? pickedTime =
                                          await showTimePicker(
                                        context: context,
                                        initialTime: TimeOfDay.fromDateTime(
                                            widget.startDateTime),
                                      );

                                      if (pickedTime != null) {
                                        setState(() {
                                          widget.startDateTime = DateTime(
                                            picked.year,
                                            picked.month,
                                            picked.day,
                                            pickedTime.hour,
                                            pickedTime.minute,
                                          );
                                          startDateController.text =
                                              DateFormat('HH:mm dd MMM yy')
                                                  .format(widget.startDateTime);

                                          // Set the endDateTime as one hour after the startDateTime
                                          widget.endDateTime = widget
                                              .startDateTime
                                              .add(Duration(hours: 1));
                                          endDateController.text =
                                              DateFormat('HH:mm dd MMM yy')
                                                  .format(widget.endDateTime);
                                        });
                                      }
                                    }
                                  },
                                  child: Icon(Icons.keyboard_arrow_down),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 8), // Adjust the spacing as desired
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Text(
                              'End',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            padding: EdgeInsets.symmetric(
                                vertical: 0, horizontal: 16),
                            child: GestureDetector(
                              onTap: () async {
                                final DateTime? picked = await showDatePicker(
                                  context: context,
                                  initialDate: widget.endDateTime,
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime(2100),
                                );

                                if (picked != null) {
                                  final TimeOfDay? pickedTime =
                                      await showTimePicker(
                                    context: context,
                                    initialTime: TimeOfDay.fromDateTime(
                                        widget.endDateTime),
                                  );

                                  if (pickedTime != null) {
                                    setState(() {
                                      widget.endDateTime = DateTime(
                                        picked.year,
                                        picked.month,
                                        picked.day,
                                        pickedTime.hour,
                                        pickedTime.minute,
                                      );
                                      endDateController.text =
                                          DateFormat('HH:mm dd MMM yy')
                                              .format(widget.endDateTime);
                                    });
                                  }
                                }
                              },
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: endDateController,
                                      decoration: InputDecoration(
                                        border: InputBorder.none,
                                        // labelText: 'End Date',
                                      ),
                                      onTap: () async {
                                        final DateTime? picked =
                                            await showDatePicker(
                                          context: context,
                                          initialDate: DateTime.now()
                                                  .isBefore(widget.endDateTime)
                                              ? widget.endDateTime
                                              : DateTime.now(),
                                          firstDate: DateTime.now(),
                                          lastDate: DateTime(2100),
                                        );

                                        if (picked != null) {
                                          final TimeOfDay? pickedTime =
                                              await showTimePicker(
                                            context: context,
                                            initialTime: TimeOfDay.fromDateTime(
                                                widget.endDateTime),
                                          );

                                          if (pickedTime != null) {
                                            setState(() {
                                              widget.endDateTime = DateTime(
                                                picked.year,
                                                picked.month,
                                                picked.day,
                                                pickedTime.hour,
                                                pickedTime.minute,
                                              );
                                              endDateController.text =
                                                  DateFormat('HH:mm dd MMM yy')
                                                      .format(
                                                          widget.endDateTime);
                                            });
                                          }
                                        }
                                      },
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () async {
                                      final DateTime? picked =
                                          await showDatePicker(
                                        context: context,
                                        initialDate: widget.endDateTime,
                                        firstDate: DateTime.now(),
                                        lastDate: DateTime(2100),
                                      );

                                      if (picked != null) {
                                        final TimeOfDay? pickedTime =
                                            await showTimePicker(
                                          context: context,
                                          initialTime: TimeOfDay.fromDateTime(
                                              widget.endDateTime),
                                        );

                                        if (pickedTime != null) {
                                          setState(() {
                                            widget.endDateTime = DateTime(
                                              picked.year,
                                              picked.month,
                                              picked.day,
                                              pickedTime.hour,
                                              pickedTime.minute,
                                            );
                                            endDateController.text =
                                                DateFormat('HH:mm dd MMM yy')
                                                    .format(widget.endDateTime);
                                          });
                                        }
                                      }
                                    },
                                    child: Icon(Icons.keyboard_arrow_down),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Text(
                  'Total: £${total.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: isLoading ? null : editBooking,
                  child: Text('Submit Booking'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _animateToMarker() {
    if (_customMarkers.isNotEmpty) {
      final marker = _customMarkers.first.marker;
      _mapController.animateCamera(
        CameraUpdate.newLatLngZoom(marker.position, 14.0),
      );
    }
  }

  Future<Uint8List> _resizeImage(
      String imagePath, int width, int height) async {
    final response = await http.get(Uri.parse(imagePath));
    final data = response.bodyBytes;
    final compressedData = await FlutterImageCompress.compressWithList(
      data,
      minHeight: height,
      minWidth: width,
      quality: 90,
    );
    return Uint8List.fromList(compressedData);
  }

  Widget _customMarker(Uint8List imageData, Color color) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Icon(
          Icons.add_location,
          color: color,
          size: 200,
        ),
        Positioned(
          left: 50,
          top: -50,
          bottom: 0,
          child: Align(
            alignment: Alignment.center,
            child: ClipOval(
              child: Image.memory(
                imageData,
                width: 100,
                height: 100,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
