import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:live_location/destination_places.dart';
import 'package:live_location/search_places.dart';

class HomeScreen extends StatefulWidget {
  final double? targetLat;
  final double? targetLong;
  final double lat;
  final double long;
  const HomeScreen({super.key, this.lat = 34.9526, this.long = 72.3311 , this.targetLat,this.targetLong});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  
String address = "Address will appear here";

TextEditingController my2Controller = TextEditingController();
  late GoogleMapController mapController;
 final Set<Polyline> _polylines = {};
  LatLng? _currentLocation;
  TextEditingController myController = TextEditingController();
  LatLng? _targetLocation ; // Example target (Landikotal)


  Future<void> _getCurrentLocation() async {
  try {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude, position.longitude);
    setState(() {
      _currentLocation = LatLng(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        address =
            "${place.subLocality}, ${place.locality}, ${place.administrativeArea}, ${place.country}, ${place.postalCode}";
        myController.text = address; // Update the controller's text
      } else {
        address = "Unable to determine address.";
        myController.text = address; // Update the controller's text
      }
    });

    // Animate the camera to the current position
    final GoogleMapController controller = await _controllers.future;
    controller.animateCamera(
      CameraUpdate.newLatLng(
        LatLng(position.latitude, position.longitude),
      ),
    );

    if (_targetLocation != null) {
      _addPolyline(); // Add polyline only if target location exists
    }
  } catch (e) {
    setState(() {
      address = "Error: $e";
      myController.text = address; // Update the controller's text
    });
  }
}



void _addPolyline() {
  if (_currentLocation != null && _targetLocation != null) {
    final polyline = Polyline(
      polylineId: const PolylineId('route'),
      points: [_currentLocation!, _targetLocation!],
      color: Colors.blue,
      width: 5,
    );
    setState(() {
      _polylines.clear(); // Remove existing polylines
      _polylines.add(polyline); // Add the new polyline
    });
  } else {
    _clearPolyline(); // Clear polylines if either location is invalid
  }
}


void _clearPolyline() {
  setState(() {
    _polylines.clear();
  });
}


  Future<Uint8List> getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(),
        targetWidth: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!
        .buffer
        .asUint8List();
  }

  final Completer<GoogleMapController> _controllers = Completer();
  // static const CameraPosition myPosition =
  //     CameraPosition(target: LatLng(34.9526, 72.3311), zoom: 17);

  Future<Position> getCurrentLocation() async {
    // Check if location services are enabled
    bool isServiceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!isServiceEnabled) {
      throw Exception('Location services are disabled. Please enable them.');
    }

    // Check location permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.deniedForever) {
      throw Exception(
          'Location permissions are permanently denied. Cannot request permissions.');
    }

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied.');
      }
    }

    // Get the current position
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  final List<Marker> _markers = [];
  final List<Marker> _list = [
    const Marker(
        markerId: MarkerId('1'),
        position: LatLng(34.9526, 72.3311),
        infoWindow: InfoWindow(title: 'Khyber Pakhtunkhwa')),
  ];

// Update CameraPosition with the received latitude and longitude
  CameraPosition myPosition = const CameraPosition(
      target: LatLng(34.9526, 72.3311), zoom: 17); // Default location
 
  @override
  void initState() {
    _markers.addAll(_list);
    _getCurrentLocation();
   _targetLocation = LatLng(widget.targetLat ?? 0, widget.targetLong ?? 0);
    //  myController = TextEditingController(text: address);
    // Update camera position when widget.lat and widget.long are available
    myPosition =
        CameraPosition(target: LatLng(widget.lat, widget.long), zoom: 17);
    
  
    }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          GoogleMap(
            polylines: _polylines,
            markers: Set<Marker>.of(_markers),
            mapType: MapType.hybrid,
            initialCameraPosition: myPosition,
            onMapCreated: (GoogleMapController controller) {
              _controllers.complete(controller);
            },
          ),
          Positioned(
              top: 50,
              right: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                 Column(
                  children: [
                    Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SizedBox(
              width: MediaQuery.of(context).size.height * .33,
              child: TextFormField(
                readOnly: true, 
                controller: myController,
                decoration: InputDecoration(
                  labelText: 'Current...',
                  labelStyle:const TextStyle(color: Colors.black),
                  hintText: address,
                   hintStyle:const TextStyle(color: Colors.black),
                  prefixIcon: const Icon(Icons.location_searching_outlined, color: Colors.black),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  filled: true,
                  fillColor: Colors.white60,
                ),
                style: const TextStyle(fontSize: 16, color: Colors.black),
              ),
            ),
          ),
          const SizedBox(height: 10,),
          /////////////////// second text fie /////////////////
                 Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: InkWell(
  onTap: () async {
  final result = await Navigator.of(context).push(
    MaterialPageRoute(builder: (context) => const DestinationPlacesScreen()),
  );
  if (result != null && result is LatLng) {
    setState(() {
      _targetLocation = result; // Update the target location
      _addPolyline(); // Add polyline after setting the destination
    });
  } else {
    setState(() {
      _targetLocation = null; // Clear the target location if no result
      _clearPolyline(); // Clear the polyline
    });
  }
},

  child: SizedBox(
    height: 60,
    width: MediaQuery.of(context).size.height * .33,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.white60,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.black, width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_city_sharp, color: Colors.black),
          const SizedBox(width: 8.0),
          Expanded(
            child: Text(
              my2Controller.text.isEmpty
                  ? 'Destination Location..'
                  : my2Controller.text,
              style: const TextStyle(fontSize: 16, color: Colors.black),
            ),
          ),
        ],
      ),
    ),
  ),
),

          ),  
                  ],
                 ),
                  Column(
                    children: [
                      IconButton(
                          onPressed: () {
                            Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) => const SearchPlaces()));
                          },
                          icon: const Icon(
                            Icons.search,
                            color: Colors.white,
                            size: 30,
                          )),
                          ElevatedButton(
          onPressed: () {
          },
          style: OutlinedButton.styleFrom(
            side:const BorderSide(color: Colors.blue, width: 2.0), // Blue border
            foregroundColor: Colors.white, // Text color
            backgroundColor: Colors.blue,
            padding:const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5), // No rounded corners
            ),
          ),
          child:const Text(
            'GO',
            style: TextStyle(fontSize: 18.0),
          ),
        ),
                    ],
                  ),
                ],
              ))
        ],
      ),

      // this code is just for the testing purpose

      // floatingActionButton: FloatingActionButton(
      //     child: const Icon(Icons.circle),
      //     onPressed: () async {
      //       final GoogleMapController controller = await _controllers.future;
      //       Position position = await getCurrentLocation();
      //       controller.animateCamera(CameraUpdate.newLatLng(
      //           LatLng(position.latitude, position.longitude)));
      //       final Uint8List markerIcon =
      //           await getBytesFromAsset('assets/images/custom-logo.png', 150);
      //       setState(() {
      //         // Add the new marker to the map
           
      //         setState(() {
      //           _markers.clear(); // Optionally clear previous markers
      //           _markers.add(Marker(
      //             markerId: const MarkerId('current_location'),
      //             position: LatLng(position.latitude, position.longitude),
      //             infoWindow: const InfoWindow(title: 'Current Location'),

      //             icon: BitmapDescriptor.fromBytes(
      //                 markerIcon), // Optional custom marker color
      //           ));
      //         });
      //       });
      //     }),
    );
  }
}
