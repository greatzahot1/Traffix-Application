import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'place_search_bar.dart';

class RoutePlanningPage extends StatefulWidget {
  @override
  _RoutePlanningPageState createState() => _RoutePlanningPageState();
}

class _RoutePlanningPageState extends State<RoutePlanningPage> {
  late GoogleMapController _mapController;
  LatLng _currentPosition = LatLng(0, 0);
  Set<Polyline> _polylines = Set<Polyline>();
  TextEditingController _destinationController = TextEditingController();
  String? _destinationPlaceId = '';
  String? _estimatedTime = '';

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  void _getUserLocation() async {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _currentPosition = LatLng(position.latitude, position.longitude);
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  void _clearPolylines() {
    setState(() {
      _polylines.clear();
    });
  }

  void _handleAlternativeRouteSelection(String placeId) {
    setState(() {
      _destinationPlaceId = placeId;
    });
  }

  void _getRoutes({bool isAlternativeRoute = false}) async {
    String origin =
        '${_currentPosition.latitude},${_currentPosition.longitude}';
    String destination = 'place_id:$_destinationPlaceId';

    // Check if the destination place ID is set
    if (_destinationPlaceId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a destination from the suggestions.'),
        ),
      );
      return;
    }

    // Replace 'YOUR_API_KEY' with your actual Google Maps API key.
    String url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=$origin&destination=$destination&alternatives=$isAlternativeRoute&key=AIzaSyDDlmwTCMvvjrUkJybVLYZnoIOvYxOHq-E';

    http.Response response = await http.get(Uri.parse(url));
    Map<String, dynamic> jsonResponse = jsonDecode(response.body);
    if (jsonResponse['status'] == 'OK') {
      List<dynamic> routes = jsonResponse['routes'];
      List<Polyline> polylines = [];

      for (int i = 0; i < routes.length; i++) {
        String encodedPoints = routes[i]['overview_polyline']['points'];
        Polyline polyline = _createPolyline(encodedPoints);
        polylines.add(polyline);
      }

      setState(() {
        _polylines.clear();
        _polylines.addAll(polylines);
      });
      if (isAlternativeRoute) {
        // Display a dialog to allow the user to choose a route
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Choose a Route'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int i = 0; i < routes.length; i++)
                    ListTile(
                      title: Text('Route ${i + 1}'),
                      subtitle: Text(
                        'Duration: ${routes[i]['legs'][0]['duration']['text']} | Distance: ${routes[i]['legs'][0]['distance']['text']}',
                      ),
                      onTap: () {
                        setState(() {
                          _polylines.clear();
                          _polylines.add(polylines[i]);
                        });

                        // Calculate the predicted arrival time for the chosen route
                        int estimatedTime =
                            routes[i]['legs'][0]['duration']['value'];
                        DateTime currentTime = DateTime.now();
                        DateTime predictedArrivalTime =
                            currentTime.add(Duration(seconds: estimatedTime));
                        String formattedArrivalTime =
                            _formatArrivalTime(predictedArrivalTime);

                        // Store the selected placeId in a temporary variable
                        String? tempDestinationPlaceId = _destinationPlaceId;

                        // Display a SnackBar message with the predicted arrival time
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                'Predicted arrival time (Thailand time): $formattedArrivalTime'),
                          ),
                        );

                        Navigator.of(context).pop();

                        // Pass the temporary placeId to the new method
                        _handleAlternativeRouteSelection(
                            tempDestinationPlaceId!);
                      },
                    ),
                ],
              ),
            );
          },
        );
      } else {
        // Get the estimated time to arrive from the API response
        int estimatedTime =
            jsonResponse['routes'][0]['legs'][0]['duration']['value'];

        // Calculate the predicted arrival time
        DateTime currentTime = DateTime.now();
        DateTime predictedArrivalTime =
            currentTime.add(Duration(seconds: estimatedTime));
        String formattedArrivalTime = _formatArrivalTime(predictedArrivalTime);
        // Display a SnackBar message with the predicted arrival time
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Predicted arrival time (Thailand time): $formattedArrivalTime'),
          ),
        );
      }
    } else {
      print('Error: ${jsonResponse['status']}');
    }
  }

  Polyline _createPolyline(String encodedPolyline) {
    List<LatLng> polylinePoints = _decodePolyline(encodedPolyline);
    return Polyline(
      polylineId: PolylineId('route'),
      points: polylinePoints,
      color: Colors.red,
      width: 5,
    );
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;
    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;
      LatLng point = LatLng(lat / 1E5, lng / 1E5);
      points.add(point);
    }
    return points;
  }

  String _formatArrivalTime(DateTime arrivalTime) {
    initializeDateFormatting();
    int offsetInHours = 7; // Timezone offset for Thailand (GMT+7)
    Duration timeZoneOffset = Duration(hours: offsetInHours);
    DateTime thailandTime = arrivalTime.toUtc().add(timeZoneOffset);
    final localTimeFormatter = DateFormat("yyyy-MM-dd HH:mm:ss");
    return localTimeFormatter.format(thailandTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Route Planning")),
      body: _currentPosition == LatLng(0, 0)
          ? Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                GoogleMap(
                  onMapCreated: (controller) {
                    _mapController = controller;
                  },
                  initialCameraPosition: CameraPosition(
                    target: _currentPosition,
                    zoom: 12,
                  ),
                  polylines: _polylines,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                ),
                Positioned(
                  top: 20,
                  left: 15,
                  right: 15,
                  child: Column(
                    children: [
                      PlaceSearchBar(
                        onPlaceSelected: (String placeId) {
                          setState(() {
                            _destinationPlaceId = placeId;
                          });
                        },
                        onClear: _clearPolylines, // Add this line
                      ),
                      SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () {
                          _getRoutes();
                        },
                        child: Text("Get Route"),
                      ),
                      SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () {
                          _getRoutes(isAlternativeRoute: true);
                        },
                        child: Text("Get Alternative Routes"),
                      ),
                      SizedBox(height: 10),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
