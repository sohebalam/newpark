import 'dart:ui' as ui;

import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:sparepark/screens/chat/chat_page.dart';
// import 'package:sparepark/screens/auth/login.dart';
// import 'package:sparepark/screens/chat/chat_page.dart';
// import 'package:sparepark/screens/crud/bookings/create_booking.dart';
import 'package:sparepark/screens/mapscreens/directions_page.dart';
import 'package:sparepark/shared/auth_service.dart';
import 'package:sparepark/shared/functions.dart';
import 'package:sparepark/shared/widgets/app_bar.dart';
import 'package:sparepark/shared/widgets/drawer.dart';

class ResultsPage extends StatefulWidget {
  final LatLng location;
  final List<List<dynamic>> results;
  final double? latitude;
  final double? longitude;

  const ResultsPage({
    Key? key,
    required this.location,
    required this.results,
    this.latitude,
    this.longitude,
    required this.startdatetime,
    required this.enddatetime,
  }) : super(key: key);

  final DateTime startdatetime;
  final DateTime enddatetime;

  @override
  _ResultsPageState createState() => _ResultsPageState();
}

class _ResultsPageState extends State<ResultsPage> {
  final Set<Marker> _markers = {};
  late String? cpsId;
  GoogleMapController? controller;
  late List<List<dynamic>> filteredResults;

  User? _currentUser;
  late String _currentUserId;
  @override
  void initState() {
    super.initState();

    filteredResults = removeDuplicates(widget.results);
    FirebaseAuth.instance.authStateChanges().listen((user) {
      setState(() {
        // _currentUser = user;
        if (user != null) {
          _currentUser = user;
          _currentUserId = _currentUser!.uid;
        } else {
          _currentUser = null;
          _currentUserId = '';
        }
      });
    });
  }

  List<List<dynamic>> removeDuplicates(List<List<dynamic>> list) {
    Map<dynamic, List<dynamic>> map = {};
    List<List<dynamic>> result = [];
    for (List<dynamic> item in list) {
      if (!map.containsKey(item[0])) {
        map[item[0]] = item;
        result.add(item);
      }
    }
    return result;
  }

  Future<void> _onMapCreated(GoogleMapController controller) async {
    // Add a marker for the location
    final locationMarker = Marker(
      markerId: MarkerId("location"),
      position: widget.location,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      infoWindow: InfoWindow(title: "Location"),
    );
    setState(() {
      _markers.add(locationMarker);
    });

    for (int i = 0; i < filteredResults.length; i++) {
      final item = filteredResults[i];
      final marker = Marker(
        markerId: MarkerId(i.toString()),
        position: LatLng(item[1], item[2]),
        icon: BitmapDescriptor.fromBytes(
          await _getBytesFromCanvas(item[3].toString()),
        ),
        infoWindow: InfoWindow(
          title: "${i + 1}",
        ),
      );
      setState(() {
        _markers.add(marker);
      });
    }
  }

  Future<Uint8List> _getBytesFromCanvas(String text) async {
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    const double width = 75;
    const double height = 50;

    // Draw the background shape
    final Paint paint = Paint()..color = Colors.black;
    const Radius radius = Radius.circular(20);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, width, height),
        radius,
      ),
      paint,
    );

    // Add the price text
    TextPainter painter = TextPainter(textDirection: TextDirection.ltr);
    painter.text = TextSpan(
      text: text,
      style: TextStyle(fontSize: 20, color: Colors.white),
    );
    painter.layout();
    painter.paint(
      canvas,
      Offset((width - painter.width) / 2, (height - painter.height) / 2),
    );

    // Draw the arrow
    const double arrowSize = 20.0;
    const double arrowHeadLength = 10.0;
    final Path path = Path()
      ..moveTo(width / 2 - arrowSize / 2, height)
      ..lineTo(width / 2 + arrowSize / 2, height)
      ..lineTo(width / 2, height + arrowHeadLength)
      ..close();
    canvas.drawPath(path, paint);

    final img = await recorder
        .endRecording()
        .toImage(width.floor(), (height + 10).floor());
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  }

  @override
  Widget build(BuildContext context) {
    // print('results: ${widget.results}');
    final authService = Provider.of<AuthService>(context);
    final isLoggedInStream = authService.user!.map((user) => user != null);
    return Scaffold(
      drawer: AppDrawer(),
      appBar: CustomAppBar(
          title: 'Results',
          isLoggedInStream: isLoggedInStream,
          padding: EdgeInsets.fromLTRB(0, 0, 1, 0)),
      body: Column(
        children: [
          Expanded(
            child: GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: widget.location,
                zoom: 12.0,
              ),
              markers: _markers,
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 10, 0),
                  child: Text(
                    'Availability at: ${formatDateTime(widget.startdatetime)} and ${formatDateTime(widget.enddatetime)}',
                    style: TextStyle(fontSize: 15),
                  ),
                ),
                ListView.builder(
                  itemCount: filteredResults.length,
                  itemBuilder: (context, index) {
                    final result = filteredResults[index];
                    final lat = result[1];
                    final lng = result[2];
                    return Card(
                      child: ListTile(
                        title: Text("£${(result[3].toString())}"),
                        subtitle:
                            Text("Closest space ${(index + 1).toString()}"),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 80,
                              child: TextButton(
                                onPressed: () {
                                  // Show directions to  the selected space
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => DirectionsPage(
                                        currentLocation: LatLng(
                                            widget.latitude!,
                                            widget.longitude!),
                                        selectedLocation:
                                            LatLng(result[1], result[2]),
                                        cpsId: result[0],
                                      ),
                                    ),
                                  );
                                },
                                child: Column(
                                  children: [
                                    Icon(Icons.directions),
                                    SizedBox(height: 4),
                                    Text("Navigate",
                                        style: TextStyle(fontSize: 10)),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 80,
                              child: TextButton(
                                onPressed: () {
                                  // Book the selected space

                                  if (_currentUser == null) {
                                    // Navigator.push(
                                    //   context,
                                    //   MaterialPageRoute(
                                    //     builder: (context) => AuthScreen(
                                    //       routePage: 'booking_page',
                                    //       startdatetime: widget.startdatetime,
                                    //       enddatetime: widget.enddatetime,
                                    //       cpsId: result[0],
                                    //       address: result[4],
                                    //       postcode: result[5],
                                    //       image: result[6],
                                    //     ),
                                    //   ),
                                    // );
                                  } else {
                                    // Navigator.pushReplacement(
                                    //   context,
                                    //   MaterialPageRoute(
                                    //     builder: (context) => Booking(
                                    //       startDateTime: widget.startdatetime,
                                    //       endDateTime: widget.enddatetime,
                                    //       cpsId: result[0],
                                    //       address: result[4],
                                    //       postcode: result[5],
                                    //       image: result[6],
                                    //     ),
                                    //   ),
                                    // );
                                  }
                                },
                                child: Column(
                                  children: [
                                    Icon(Icons.bookmark),
                                    SizedBox(height: 4),
                                    Text("Book Now",
                                        style: TextStyle(fontSize: 10)),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 80,
                              child: TextButton(
                                onPressed: () {
                                  print('Book');
                                  if (_currentUser == null) {
                                    // Navigator.push(
                                    //   context,
                                    //   MaterialPageRoute(
                                    //     builder: (context) => AuthScreen(
                                    //       routePage: 'chat_page',
                                    //       startdatetime: widget.startdatetime,
                                    //       enddatetime: widget.enddatetime,
                                    //       cpsId: result[0],
                                    //       address: result[4],
                                    //       postcode: result[5],
                                    //       image: result[6],
                                    //       u_id: result[7],
                                    //     ),
                                    //   ),
                                    // );
                                  } else {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ChatPage(
                                          u_id: result[7],
                                          currentUserId: _currentUserId,
                                        ),
                                      ),
                                    );
                                  }
                                },
                                child: Column(
                                  children: [
                                    Icon(Icons.email),
                                    SizedBox(height: 4),
                                    Text("Message",
                                        style: TextStyle(fontSize: 10)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
