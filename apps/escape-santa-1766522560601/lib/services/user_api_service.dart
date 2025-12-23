import 'dart:convert';
import 'package:http/http.dart' as http;
import 'app_config.dart';

class UserApiService {
  static UserApiService? _instance;
  late String _baseUrl;
  
  UserApiService._();

  static Future<UserApiService> getInstance() async {
    if (_instance == null) {
      _instance = UserApiService._();
      await _instance!._initialize();
    }
    return _instance!;
  }

  Future<void> _initialize() async {
    final config = await AppConfig.getInstance();
    // You can add backendApiUrl to your config.json
    // For now, using a default value
    _baseUrl = 'http://localhost:3000/api'; // Change this to your production URL
  }

  /// Save user details to backend API
  Future<bool> saveUserDetails({
    required String gender,
    required String fullName,
    required String email,
    String? appId,
    String? packageName,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/users');
      
      final requestBody = {
        'gender': gender,
        'fullName': fullName,
        'email': email,
        'appId': appId ?? 'unknown',
        'packageName': packageName,
      };
      
      print('DEBUG: Sending request to: $url');
      print('DEBUG: Request body: ${jsonEncode(requestBody)}');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('User details saved: ${data['message']}');
        return data['success'] ?? false;
      } else {
        print('Failed to save user details: ${response.statusCode}');
        print('Response: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error saving user details: $e');
      return false;
    }
  }

  /// Get user details from backend API
  Future<Map<String, dynamic>?> getUserDetails(String email) async {
    try {
      final url = Uri.parse('$_baseUrl/users/${Uri.encodeComponent(email)}');
      
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] as Map<String, dynamic>?;
      } else if (response.statusCode == 404) {
        print('User not found');
        return null;
      } else {
        print('Failed to get user details: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error getting user details: $e');
      return null;
    }
  }
}
