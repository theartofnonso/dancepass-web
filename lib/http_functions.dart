import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:dancepassweb/dotos/event.dart';

import 'dotos/geocoordinates.dart';

class HttpFunctions {
  static const String eventsEndpoint = "https://cdcrlw6hxs23wmvx6ky7synrym0jsdst.lambda-url.eu-west-2.on.aws/";
  static const String _urlWithAddress = 'https://maps.googleapis.com/maps/api/geocode/json?address=';
  static const String _googleMapsAPIKey = "AIzaSyDgImwhuHPwYhD0i4YQNgzMuu_CC-rxnnA";

  /// Make get call
  static Future<Map<String, dynamic>?> get(String endpoint) async {
    Map<String, dynamic>? jsonResponse;

    final url = Uri.parse(endpoint);

    final response = await http.get(url);
    if (response.statusCode == 200) {
      jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
    }

    return jsonResponse;
  }

  static Future<Event?> getEvent({required String id}) async {
    Event? event;
    final url = "$eventsEndpoint/$id";
    final response = await get(url);
    final data = response?["data"];
    if(data != null) {
      final item = data["getEvent"];
      event = Event.fromJson(item);
    }
    return event;
  }

  static Future<bool> updateEvent({required String id, required String payload}) async {
    final url = Uri.parse("$eventsEndpoint/$id");
    final response = await http.post(url, body: payload);
    return response.statusCode == 200;
  }

  static Future<String?> createEventDraft({required String payload}) async {
    String? createdEventId;
    final url = Uri.parse(eventsEndpoint);
    final response = await http.post(url, body: payload);
    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      final data = responseBody["data"];
      final operation = data["createEvent"];
      createdEventId = operation["id"];
    }
    return createdEventId;
  }

  /// Get the latitude and longitude of an address using Google Maps API
  static Future<GeoCoordinates> addressToGeoCoordinates(String address) async {
    final url = '$_urlWithAddress$address&key=$_googleMapsAPIKey';

    GeoCoordinates coordinates;

    final response = await get(url);
    final results = response?['results'] ?? List<dynamic>;
    if (results.isNotEmpty) {
      final location = results.first['geometry']['location'];
      final latitude = location['lat'] as double;
      final longitude = location['lng'] as double;
      coordinates = GeoCoordinates(latitude: latitude, longitude: longitude);
    } else {
      coordinates = GeoCoordinates(latitude: 0.0, longitude: 0.0);
    }

    return coordinates;
  }
}
