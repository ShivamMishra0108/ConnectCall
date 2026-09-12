import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://localhost:3000/api';

  // Register
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

  // Login
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

  // Get all users
  static Future<Map<String, dynamic>> getUsers() async {
    final response = await http.get(
      Uri.parse('$baseUrl/users'),
    );

    return jsonDecode(response.body);
  }
}