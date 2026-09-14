import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://10.153.225.20:3000/api';

  // ============================================================
  // REGISTER
  // ============================================================

  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    String phoneNumber = '',
    String password = '',
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/register'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'name': name,
        'email': email,
        'phoneNumber': phoneNumber,
        'password': password,
      }),
    );

    return jsonDecode(response.body);
  }

  // ============================================================
  // LOGIN
  // ============================================================

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/login'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    return jsonDecode(response.body);
  }

  // ============================================================
  // GET ALL USERS
  // ============================================================

  static Future<Map<String, dynamic>> getUsers() async {
    final response = await http.get(
      Uri.parse('$baseUrl/users'),
    );

    return jsonDecode(response.body);
  }

  // ============================================================
  // CREATE CALL HISTORY
  // POST /api/calls
  // ============================================================

  static Future<Map<String, dynamic>> createCallHistory({
    required String callId,
    required String callerId,
    required String receiverId,
    required String callerName,
    required String receiverName,
    required String callType,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/calls'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'callId': callId,
        'callerId': callerId,
        'receiverId': receiverId,
        'callerName': callerName,
        'receiverName': receiverName,
        'callType': callType,
      }),
    );

    return jsonDecode(response.body);
  }

  // ============================================================
  // UPDATE CALL HISTORY
  // PATCH /api/calls/:callId
  // ============================================================

  static Future<Map<String, dynamic>> updateCallHistory({
    required String callId,
    String? status,
    DateTime? startedAt,
    DateTime? endedAt,
    int? duration,
  }) async {
    final Map<String, dynamic> data = {};

    if (status != null) {
      data['status'] = status;
    }

    if (startedAt != null) {
      data['startedAt'] = startedAt.toIso8601String();
    }

    if (endedAt != null) {
      data['endedAt'] = endedAt.toIso8601String();
    }

    if (duration != null) {
      data['duration'] = duration;
    }

    final response = await http.patch(
      Uri.parse('$baseUrl/calls/$callId'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data),
    );

    return jsonDecode(response.body);
  }

  // ============================================================
  // GET CALL HISTORY
  // GET /api/calls/user/:userId
  // ============================================================

  static Future<Map<String, dynamic>> getCallHistory({
    required String userId,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/calls/user/$userId'),
    );

    return jsonDecode(response.body);
  }
}