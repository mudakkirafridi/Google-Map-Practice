import 'dart:convert';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:live_location/home.dart';
import 'package:uuid/uuid.dart';

class DestinationPlacesScreen extends StatefulWidget {
  const DestinationPlacesScreen({super.key});

  @override
  State<DestinationPlacesScreen> createState() => _DestinationPlacesScreenState();
}

class _DestinationPlacesScreenState extends State<DestinationPlacesScreen> {
    TextEditingController _controller = TextEditingController();
  ///////////
// places api
  var uuid = const Uuid();
  String _sessionToken = '1234567890';
  List<dynamic> _placeList = [];

  _onChanged() {
    if (_sessionToken == null) {
      setState(() {
        _sessionToken = uuid.v4();
      });
    }
    getSuggestion(_controller.text);
  }

  void getSuggestion(String input) async {
    const String PLACES_API_KEY = "AlzaSyo5c62KwqCMp4B8aiukUv842m8eTLloTNy";

    try {
      String baseURL =
          'https://maps.gomaps.pro/maps/api/place/autocomplete/json';
      String request =
          '$baseURL?input=$input&key=$PLACES_API_KEY&sessiontoken=$_sessionToken';
      var response = await http.get(Uri.parse(request));
      var data = json.decode(response.body);
      if (kDebugMode) {
        print('mydata');
        print(data);
      }
      if (response.statusCode == 200) {
        setState(() {
          _placeList = json.decode(response.body)['predictions'];
        });
      } else {
        throw Exception('Failed to load predictions');
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  void initState() {
    _controller.addListener(() {
      _onChanged();
    });
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * .05,
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextFormField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Target Place',
                prefixIcon: const Icon(Icons.search, color: Colors.blue),
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
                fillColor: Colors.grey[200],
              ),
              style: const TextStyle(fontSize: 16, color: Colors.black),
            ),
          ),
          Expanded(
              child: ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: _placeList.length,
                  itemBuilder: (context, index) {
                    return InkWell(
                      onTap: () async {
                        List<Location> locations = await locationFromAddress(
                            _placeList[index]['description'].toString());
                        double lat = locations[0].latitude;
                        double long = locations[0].longitude;
                        Navigator.of(context).push(MaterialPageRoute(builder: (context)=> HomeScreen(targetLat: lat,targetLong: long,)));
                      },
                      child: ListTile(
                        title: Text(_placeList[index]['description']),
                      ),
                    );
                  }))
        ],
      ),
    );
  }
}