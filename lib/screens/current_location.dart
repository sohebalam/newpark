// import 'package:flutter/material.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:geolocator/geolocator.dart';

// class UserMapInfo extends StatefulWidget {
//   const UserMapInfo({Key? key}) : super(key: key);

//   @override
//   State<UserMapInfo> createState() => _UserMapInfoState();
// }

// class _UserMapInfoState extends State<UserMapInfo> {
//   late GoogleMapController mapController;

//   LatLng _currentPosition = LatLng(0, 0);
//   bool _isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     getLocation();
//   }

//   getLocation() async {
//     LocationPermission permission;
//     permission = await Geolocator.requestPermission();

//     Position position = await Geolocator.getCurrentPosition(
//         desiredAccuracy: LocationAccuracy.high);
//     double lat = position.latitude;
//     double long = position.longitude;

//     LatLng location = LatLng(lat, long);

//     setState(() {
//       _currentPosition = location;
//       _isLoading = false;
//     });
//   }

//   void _onMapCreated(GoogleMapController controller) {
//     mapController = controller;
//   }

//   @override
//   Widget build(BuildContext context) {
//     final Set<Marker> _markers = {
//       Marker(
//         markerId: MarkerId('current_location'),
//         position: _currentPosition,
//       )
//     };

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Map'),
//       ),
//       body: _isLoading
//           ? Center(child: CircularProgressIndicator())
//           : GoogleMap(
//               onMapCreated: _onMapCreated,
//               initialCameraPosition: CameraPosition(
//                 target: _currentPosition,
//                 zoom: 16.0,
//               ),
//               markers: _markers,
//             ),
//       bottomSheet: Container(
//         padding: const EdgeInsets.all(8.0),
//         color: Colors.grey[300],
//         height: MediaQuery.of(context).size.height / 4,
//         child: Column(
//           children: [
//             TextField(
//               decoration: InputDecoration(
//                 labelText: 'Current Location',
//               ),
//             ),
//             const SizedBox(height: 16.0),
//             TextField(
//               decoration: InputDecoration(
//                 labelText: 'Search for another Location',
//               ),
//             ),
//             const SizedBox(height: 16.0),
//             ElevatedButton(
//               onPressed: () {
//                 print('Button pressed');
//               },
//               child: const Text('Search'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class UserMapInfo extends StatefulWidget {
  const UserMapInfo({Key? key}) : super(key: key);

  @override
  State<UserMapInfo> createState() => _UserMapInfoState();
}

class _UserMapInfoState extends State<UserMapInfo> {
  late GoogleMapController mapController;

  LatLng _currentPosition = const LatLng(0, 0);
  bool _isLoading = true;
  String? _selectedOption;

  @override
  void initState() {
    super.initState();
    getLocation();
    _selectedOption = 'Current Location';
  }

  getLocation() async {
    LocationPermission permission;
    permission = await Geolocator.requestPermission();

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    double lat = position.latitude;
    double long = position.longitude;

    LatLng location = LatLng(lat, long);

    setState(() {
      _currentPosition = location;
      _isLoading = false;
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  void _onDropdownChanged(String? value) {
    setState(() {
      _selectedOption = value;
    });

    if (_selectedOption == 'Current Location') {
      print(
          'Current location lat: ${_currentPosition.latitude}, long: ${_currentPosition.longitude}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final Set<Marker> markers = {
      Marker(
        markerId: const MarkerId('current_location'),
        position: _currentPosition,
      )
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Map'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: _currentPosition,
                zoom: 16.0,
              ),
              markers: markers,
            ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(8.0),
        color: Colors.grey[300],
        height: MediaQuery.of(context).size.height / 3,
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: _selectedOption,
              items: <String>['Current Location'].map((String option) {
                return DropdownMenuItem(
                  value: option,
                  child: Row(
                    children: [
                      const Icon(Icons.location_pin),
                      const SizedBox(width: 8.0),
                      Text(option),
                    ],
                  ),
                );
              }).toList(),
              onChanged: _onDropdownChanged,
              decoration: const InputDecoration(
                labelText: 'Select an option',
              ),
            ),
            const SizedBox(height: 16.0),
            const TextField(
              decoration: InputDecoration(
                labelText: 'Search for another Location',
              ),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () {
                print('Button pressed');
              },
              child: const Text('Search'),
            ),
          ],
        ),
      ),
    );
  }
}
