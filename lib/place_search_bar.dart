import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PlaceSearchBar extends StatefulWidget {
  final Function(String) onPlaceSelected;
  final VoidCallback onClear;

  PlaceSearchBar({
    required this.onPlaceSelected,
    required this.onClear,
  });

  @override
  _PlaceSearchBarState createState() => _PlaceSearchBarState();
}

class _PlaceSearchBarState extends State<PlaceSearchBar> {
  TextEditingController _searchController = TextEditingController();
  List<dynamic> _suggestions = [];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _searchController,
          onChanged: (value) {
            _getPlaceSuggestions(value);
          },
          decoration: InputDecoration(
            labelText: 'Search',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        _searchController.clear();
                        _suggestions = [];
                        widget.onClear();
                      });
                    },
                  )
                : null,
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          itemCount: _suggestions.length,
          itemBuilder: (context, index) {
            return Container(
              color: Colors
                  .white, // Change the background color of the suggestion item
              child: ListTile(
                title: Text(
                  _suggestions[index]['description'],
                  style: TextStyle(
                    fontSize: 16, // Increase the font size
                    color: Colors.black, // Change the font color
                  ),
                ),
                onTap: () {
                  _handlePlaceSelection(index);
                },
              ),
            );
          },
        ),
      ],
    );
  }

  void _getPlaceSuggestions(String input) async {
    if (input.length < 3) {
      setState(() {
        _suggestions = [];
      });
      return;
    }

    // Replace 'YOUR_API_KEY' with your actual Google Maps API key.
    String url =
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&key=AIzaSyDDlmwTCMvvjrUkJybVLYZnoIOvYxOHq-E';

    http.Response response = await http.get(Uri.parse(url));
    Map<String, dynamic> jsonResponse = jsonDecode(response.body);

    if (jsonResponse['status'] == 'OK') {
      setState(() {
        _suggestions = jsonResponse['predictions'];
      });
    } else {
      print('Error: ${jsonResponse['status']}');
    }
  }

  void _handlePlaceSelection(int index) {
    // Store the selected place ID
    String selectedPlaceId = _suggestions[index]['place_id'];

    // Set the search box text to the selected place's description
    _searchController.text = _suggestions[index]['description'];

    // Clear the suggestions list
    setState(() {
      _suggestions = [];
    });

    // Call the onPlaceSelected callback with the stored place ID
    widget.onPlaceSelected(selectedPlaceId);
  }
}
