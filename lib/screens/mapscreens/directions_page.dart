import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:sparepark/shared/auth_service.dart';
import 'package:sparepark/shared/style/contstants.dart';
import 'package:sparepark/shared/widgets/app_bar.dart';
import 'package:url_launcher/url_launcher.dart';

class DirectionsPage extends StatefulWidget {
  final LatLng currentLocation;
  final LatLng selectedLocation;
  String? cpsId;

  DirectionsPage({
    required this.currentLocation,
    required this.selectedLocation,
    required cpsId,
  });

  @override
  _DirectionsPageState createState() => _DirectionsPageState();
}

class _DirectionsPageState extends State<DirectionsPage> {
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  final bool isLoggedIn = FirebaseAuth.instance.currentUser != null;

  @override
  void initState() {
    super.initState();

    // Add markers for current location and selected location
    _markers.add(
      Marker(
        markerId: MarkerId('current_location'),
        position: widget.currentLocation,
      ),
    );
    _markers.add(
      Marker(
        markerId: MarkerId('selected_location'),
        position: widget.selectedLocation,
      ),
    );

    // Fetch directions from Google Maps API
    _fetchDirections();
  }

  List<LatLng> decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0;
    int len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      lat += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      lng += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      points.add(LatLng(lat / 1e5, lng / 1e5));
    }
    return points;
  }

  void _fetchDirections() async {
    print('fetching directions');
    print(widget.cpsId);
    final apiKey = 'AIzaSyCY8J7h0Q-5Q1UDP9aY0EOy_WZBPESNBBg';
    final origin =
        '${widget.currentLocation.latitude},${widget.currentLocation.longitude}';
    final destination =
        '${widget.selectedLocation.latitude},${widget.selectedLocation.longitude}';
    final url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=$origin&destination=$destination&key=$apiKey';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final points = data['routes'][0]['overview_polyline']['points'];
      final decodedPoints = decodePolyline(points);

      final polyline = Polyline(
        polylineId: PolylineId('route'),
        color: Colors.blue,
        width: 5,
        points: decodedPoints,
      );

      setState(() {
        _polylines.add(polyline);
      });
    } else {
      throw Exception('Failed to fetch directions');
    }
  }

  void _launchNavigation() async {
    final url = Uri.parse(
        'google.navigation:q=${widget.selectedLocation.latitude},${widget.selectedLocation.longitude}');
    // await launchUrl(Uri.parse(url));
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'Could not launch navigation';
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final isLoggedInStream = authService.user!.map((user) => user != null);
    return Scaffold(
        appBar: CustomAppBar(
          title: 'Directions',
          isLoggedInStream: isLoggedInStream,
        ),
        body: Stack(
          children: [
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: widget.currentLocation,
                zoom: 12.0,
              ),
              markers: _markers,
              polylines: _polylines,
            ),
            Positioned(
              bottom: 10,
              right: 10,
              child: GestureDetector(
                onTap: _launchNavigation,
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Constants().primaryColor,
                  ),
                  child: Center(
                    child: Icon(
                      Icons.navigation_outlined,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ));
  }
}
