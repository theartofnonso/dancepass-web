import 'dart:convert';

import 'package:http/http.dart' as http;

class HttpFunctions {
  static const String eventsEndpoint = "https://cdcrlw6hxs23wmvx6ky7synrym0jsdst.lambda-url.eu-west-2.on.aws/";

  static Future<void> get(String path) async {
    var url = Uri.parse("$eventsEndpoint/$path");
    var response = await http.get(url);
    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');
  }

  static Future<bool> postLiveEvent({String? path, required String payload}) async {
    var url = path != null ? Uri.parse("$eventsEndpoint/$path") : Uri.parse(eventsEndpoint);
    var response = await http.post(url, body: payload);
    return response.statusCode == 200;
  }

  static Future<String?> createEventDraft({String? path, required String payload}) async {
    String? createdEventId;
    var url = path != null ? Uri.parse("$eventsEndpoint/$path") : Uri.parse(eventsEndpoint);
    var response = await http.post(url, body: payload);
    if(response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      final data = responseBody["data"];
      final operation = data["createEvent"];
      createdEventId = operation["id"];
    }
    return createdEventId;
  }
}
