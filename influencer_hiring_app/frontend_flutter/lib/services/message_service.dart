import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class MessageService {

  Future<List<dynamic>> fetchConversation(int otherUserId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");

    final url = Uri.parse(
        "${ApiConfig.baseUrl}/message/conversation/$otherUserId");

    final response = await http.get(
      url,
      headers: {
        "Authorization": "Bearer $token"
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    return [];
  }

  Future<bool> sendTextMessage(int receiverId, String message) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");

    final url = Uri.parse("${ApiConfig.baseUrl}/message/send");

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      },
      body: jsonEncode({
        "receiver_id": receiverId,
        "message": message
      }),
    );

    print("TEXT STATUS: ${response.statusCode}");
    print("TEXT BODY: ${response.body}");

    return response.statusCode == 201;
  }

  Future<bool> sendImageMessage(int receiverId, File imageFile) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");

    var uri = Uri.parse("${ApiConfig.baseUrl}/message/send");

    var request = http.MultipartRequest('POST', uri);

    request.headers['Authorization'] = "Bearer $token";
    request.fields['receiver_id'] = receiverId.toString();

    request.files.add(
      await http.MultipartFile.fromPath(
        'file', // MUST match backend field name
        imageFile.path,
      ),
    );

    try {
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print("IMAGE STATUS: ${response.statusCode}");
      print("IMAGE BODY: ${response.body}");

      return response.statusCode == 201;

    } catch (e) {
      print("UPLOAD ERROR: $e");
      return false;
    }
  }
}