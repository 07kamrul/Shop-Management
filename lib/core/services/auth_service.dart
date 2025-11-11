import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class AuthService {
  // Register new user
  static Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String name,
    required String shopName,
    String? phone,
  }) async {
    try {
      final data = {
        'email': email,
        'password': password,
        'name': name,
        'shopName': shopName,
        'phone': phone,
      };

      final response = await ApiService.post('/auth/register', data);

      // Save token and user data
      if (response['token'] != null) {
        await _saveAuthData(response);
      }

      return response;
    } catch (e) {
      // Re-throw with more context
      throw Exception('Registration failed: $e');
    }
  }

  // Login user
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final data = {'email': email, 'password': password};

      final response = await ApiService.post('/auth/login', data);

      // Save token and user data
      if (response['token'] != null) {
        await _saveAuthData(response);
      }

      return response;
    } catch (e) {
      // Re-throw with more context
      throw Exception('Login failed: $e');
    }
  }

  // Refresh token
  static Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    try {
      final response = await ApiService.post('/auth/refresh-token', {'refreshToken': refreshToken});

      // Update token
      if (response['token'] != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', response['token']);
        await prefs.setString('refreshToken', response['refreshToken']);
      }

      return response;
    } catch (e) {
      throw Exception('Token refresh failed: $e');
    }
  }

  // Logout user
  static Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token != null) {
        try {
          await ApiService.post('/auth/logout', {});
        } catch (e) {
          // Continue with logout even if API call fails
          print('Logout API call failed: $e');
        }
      }

      // Clear local storage
      await prefs.remove('token');
      await prefs.remove('refreshToken');
      await prefs.remove('userId');
      await prefs.remove('userEmail');
      await prefs.remove('userName');
      await prefs.remove('shopName');
      await prefs.remove('userPhone');
    } catch (e) {
      throw Exception('Logout failed: $e');
    }
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      return token != null && token.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Get current user data
  static Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null || token.isEmpty) return null;

      final userId = prefs.getString('userId');
      final userEmail = prefs.getString('userEmail');
      final userName = prefs.getString('userName');
      final shopName = prefs.getString('shopName');
      final userPhone = prefs.getString('userPhone');

      // Only return if we have basic user info
      if (userId == null || userEmail == null || userName == null) {
        return null;
      }

      return {
        'id': userId,
        'email': userEmail,
        'name': userName,
        'shopName': shopName,
        'phone': userPhone,
      };
    } catch (e) {
      return null;
    }
  }

  // Save authentication data to shared preferences
  static Future<void> _saveAuthData(Map<String, dynamic> response) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString('token', response['token'] ?? '');
      await prefs.setString('refreshToken', response['refreshToken'] ?? '');
      await prefs.setString('userId', response['id']?.toString() ?? '');
      await prefs.setString('userEmail', response['email'] ?? '');
      await prefs.setString('userName', response['name'] ?? '');
      await prefs.setString('shopName', response['shopName'] ?? '');

      if (response['phone'] != null) {
        await prefs.setString('userPhone', response['phone'] ?? '');
      }
    } catch (e) {
      throw Exception('Failed to save auth data: $e');
    }
  }

  // Get stored token
  static Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('token');
    } catch (e) {
      return null;
    }
  }
}