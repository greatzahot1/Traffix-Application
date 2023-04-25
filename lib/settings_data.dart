import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class SettingsData extends ChangeNotifier {
  MapType _mapType = MapType.normal;
  bool _trafficEnabled = false;

  MapType get mapType => _mapType;
  bool get trafficEnabled => _trafficEnabled;

  void setMapType(MapType newMapType) {
    _mapType = newMapType;
    notifyListeners();
  }

  void setTrafficEnabled(bool isEnabled) {
    _trafficEnabled = isEnabled;
    notifyListeners();
  }
}
