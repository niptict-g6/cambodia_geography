import 'package:cambodia_geography/configs/route_config.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class AppHelper<T> {
  AppHelper._internal();

  static dynamic getScreenTitle(BuildContext context, {String? titleFallback}) {
    final arguments = ModalRoute.of(context)?.settings.arguments;
    if (arguments is CgRouteSetting) {
      return arguments.title;
    } else {
      return titleFallback;
    }
  }

  static String? queryParameters({required String url, required String param}) {
    return Uri.parse(url).queryParameters[param];
  }

  /// Latitude must be a number between -90 and 90
  /// Longitude must a number between -180 and 180
  static bool isLatLngValdatedStr(String? latitude, String? longitude) {
    double? lat = double.tryParse(latitude ?? "");
    double? lon = double.tryParse(longitude ?? "");

    if (lat == null || lon == null) return false;

    bool isLatitude = lat.isFinite && lat.abs() <= 90;
    bool isLongtitude = lon.isFinite && lon.abs() <= 180;
    return isLatitude && isLongtitude;
  }

  /// Latitude must be a number between -90 and 90
  /// Longitude must a number between -180 and 180
  static bool isLatLngValdated(double? latitude, double? longitude) {
    if (latitude == null || longitude == null) return false;

    bool isLatitude = latitude.isFinite && latitude.abs() <= 90;
    bool isLongtitude = longitude.isFinite && longitude.abs() <= 180;
    return isLatitude && isLongtitude;
  }

  static Map<String, dynamic> filterOutNull(Map<String, dynamic> json) {
    json.forEach((key, value) {
      dynamic value = json[key];
      if (value != null && value is List) {
        value.removeWhere((e) => e == null || e == "null");
        json[key] = value;
      }
    });
    json.removeWhere((key, value) => value == null || value == "null" || (value is List && value.isEmpty));
    return json;
  }

  static String getCompassDirection(double num, BuildContext context) {
    List<String> directions = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    List<String> directionsInKhmer = ['ជើង', 'ឦសាន្ត', 'កើត', 'អាគ្នេយ៍', 'ត្បូង', 'នីរតី', 'លិច', 'ពាយព្យ'];
    double val = (num / 45);
    int index = (val % 8).toInt();
    switch (context.locale.languageCode) {
      case "km":
        return directionsInKhmer[index];
      case "en":
        return directions[index];
      default:
        return directionsInKhmer[index];
    }
  }

  static IconData getDirectionIcon(double num) {
    List<IconData> directionIcons = [
      Icons.north,
      Icons.north_east,
      Icons.east,
      Icons.south_east,
      Icons.south,
      Icons.south_west,
      Icons.west,
      Icons.north_west,
    ];
    double val = (num / 45);
    int index = (val % 8).toInt();
    return directionIcons[index];
  }
}
