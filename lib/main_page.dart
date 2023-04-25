import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'route_planning_page.dart';
import 'traffic_alerts_page.dart';
import 'settings_page.dart';
import 'package:provider/provider.dart';
import 'settings_data.dart';
import 'package:http/http.dart' as http;
import 'package:geocoding/geocoding.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'traffic_message.dart';
import 'package:permission_handler/permission_handler.dart';

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  User? user;
  LatLng? currentLocation;
  GoogleMapController? mapController; // Make it nullable
  Set<Marker> _markers = {};
  String? weatherDescription;
  String? weatherIconCode;
  TextEditingController _trafficMessageController = TextEditingController();
  Future<String> _getUsername(String userId) async {
    DocumentSnapshot userSnapshot =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    Map<String, dynamic> userData = userSnapshot.data() as Map<String, dynamic>;
    return userData['username'] ?? 'Unknown User';
  }

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
    _getCurrentLocation();
    _fetchWeather();
    _showTrafficMessagesOnMap();
    requestLocationPermission();
  }

  void _getCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best);
    setState(() {
      currentLocation = LatLng(position.latitude, position.longitude);
    });
    _markers.add(Marker(
      markerId: MarkerId('currentLocation'),
      position: currentLocation!,
    ));
    if (mapController != null) {
      // The check remains the same
      mapController!.animateCamera(
        // Add the null-aware operator here
        CameraUpdate.newCameraPosition(
          CameraPosition(target: currentLocation!, zoom: 13.0),
        ),
      );
    }
    _fetchWeather(); // Fetch weather data after setting the currentLocation
  }

  Future<void> requestLocationPermission() async {
    PermissionStatus status = await Permission.location.request();
    if (status.isDenied || status.isRestricted || status.isPermanentlyDenied) {
      // Show an alert or message to the user to grant location permission
    }
  }

  Future<void> _searchLocation(String value) async {
    try {
      List<Location> locations = await locationFromAddress(value);
      if (locations.isNotEmpty) {
        Location location = locations.first;
        LatLng target = LatLng(location.latitude, location.longitude);
        mapController?.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: target, zoom: 13.0),
          ),
        );
        setState(() {
          currentLocation = target; // Update the currentLocation value
          _markers.add(
            Marker(
              markerId: MarkerId('searchedLocation'),
              position: target,
              infoWindow: InfoWindow(title: value),
            ),
          );
        });
        _fetchWeather(); // Fetch the weather data again for the new location
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No results found')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _submitTrafficMessage(String message) async {
    if (message.trim().isEmpty || currentLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please provide a valid traffic message')),
      );
      return;
    }

    final _firestore = FirebaseFirestore.instance;

    await _firestore.collection('traffic_messages').add({
      'user_id': user?.uid,
      'message': message,
      'location':
          GeoPoint(currentLocation!.latitude, currentLocation!.longitude),
      'timestamp': FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Traffic message submitted')),
    );
  }

  Future<List<TrafficMessage>> _getTrafficMessages() async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('traffic_messages')
        .orderBy('timestamp', descending: true)
        .get();

    return querySnapshot.docs
        .map((doc) => TrafficMessage.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<void> _showTrafficMessagesOnMap() async {
    List<TrafficMessage> trafficMessages = await _getTrafficMessages();

    for (TrafficMessage message in trafficMessages) {
      if (message.latitude != null && message.longitude != null) {
        String username = await _getUsername(message.userId!);
        setState(() {
          _markers.add(
            Marker(
              markerId: MarkerId(message.id!),
              position: LatLng(message.latitude!, message.longitude!),
              infoWindow: InfoWindow(title: message.message, snippet: username),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueOrange,
              ),
            ),
          );
        });
      }
    }
  }

  void _showTrafficMessageDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Submit Traffic Message'),
          content: TextField(
            controller: _trafficMessageController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Enter traffic information here...',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await _submitTrafficMessage(_trafficMessageController.text);
                _trafficMessageController.clear();
                Navigator.of(context).pop();
                _showTrafficMessagesOnMap();
              },
              child: Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  void _fetchWeather() async {
    if (currentLocation != null) {
      String url =
          'https://api.openweathermap.org/data/2.5/weather?lat=${currentLocation!.latitude}&lon=${currentLocation!.longitude}&appid=80b7cb59d32883215b9a46d35e2ccc45';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        Map<String, dynamic> data = jsonDecode(response.body);
        setState(() {
          weatherDescription = data['weather'][0]['description'];
          weatherIconCode = data['weather'][0]['icon'];
        });
      } else {
        print('Failed to fetch weather data');
      }
    }
  }

  String getWeatherIcon(String? iconCode) {
    if (iconCode == null) {
      return '';
    }

    switch (iconCode) {
      case '01d':
      case '01n':
        return '☀️'; // Clear sky
      case '02d':
      case '02n':
        return '🌤️'; // Few clouds
      case '03d':
      case '03n':
        return '⛅'; // Scattered clouds
      case '04d':
      case '04n':
        return '🌥️'; // Broken clouds
      case '09d':
      case '09n':
        return '🌧️'; // Shower rain
      case '10d':
      case '10n':
        return '🌦️'; // Rain
      case '11d':
      case '11n':
        return '⛈️'; // Thunderstorm
      case '13d':
      case '13n':
        return '❄️'; // Snow
      case '50d':
      case '50n':
        return '🌫️'; // Mist
      default:
        return ''; // No icon available
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0.0,
        title: Text(
          'Traffix',
          style: TextStyle(color: Colors.black, fontSize: 24),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              Icons.menu,
              color: Colors.black,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsPage()),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: LatLng(13.7563, 100.5018), // Bangkok, Thailand
              zoom: 13.0,
            ),
            markers: _markers,
            trafficEnabled:
                Provider.of<SettingsData>(context, listen: true).trafficEnabled,
            mapType: Provider.of<SettingsData>(context, listen: true).mapType,
          ),
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    blurRadius: 5,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: TextField(
                        controller: _trafficMessageController,
                        decoration: InputDecoration.collapsed(
                          hintText: 'Enter traffic information here...',
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.send),
                    onPressed: () async {
                      await _submitTrafficMessage(
                          _trafficMessageController.text);
                      _trafficMessageController.clear();
                      _showTrafficMessagesOnMap();
                    },
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 110,
            right: 10,
            child: FloatingActionButton(
              onPressed: () {
                _getCurrentLocation();
              },
              child: Icon(Icons.my_location),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  weatherDescription != null
                      ? Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.white.withOpacity(0.8),
                          ),
                          child: RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Current weather: ',
                                  style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold),
                                ),
                                TextSpan(
                                  text: getWeatherIcon(weatherIconCode),
                                  style: TextStyle(fontSize: 24),
                                ),
                                TextSpan(
                                  text: ' $weatherDescription',
                                  style: TextStyle(
                                      fontSize: 16, color: Colors.black),
                                ),
                              ],
                            ),
                          ),
                        )
                      : Container(),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => RoutePlanningPage()),
                      );
                    },
                    child: Text('Route Planning'),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => TrafficAlertsPage()),
                      );
                    },
                    child: Text('Traffic Alerts'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
