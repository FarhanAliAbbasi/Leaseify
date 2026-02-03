import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class LandlordApiService {
  static const String baseUrl = 'https://leasify.onrender.com';

  // ============ AUTHENTICATION HELPERS ============

  // Get JWT token from storage
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // Clear token (on logout or token expiry)
  static Future<void> _clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  // Get headers with JWT token
  static Future<Map<String, String>> _getHeaders() async {
    final token = await getToken();
    final headers = {
      'Content-Type': 'application/json',
    };
    
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    
    return headers;
  }

  // ============ DASHBOARD & PROFILE ============

  // 1. Get Dashboard Stats
  static Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/landlord/dashboard/stats'),
        headers: headers,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse is Map) {
          return jsonResponse.cast<String, dynamic>();
        }
      } else if (response.statusCode == 401) {
        await _clearToken();
      }
      return {};
    } catch (e) {
      print('Error loading dashboard stats: $e');
      return {};
    }
  }

  // 2. Get Landlord Profile
  static Future<Map<String, dynamic>> getLandlordProfile() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/landlord/profile'),
        headers: headers,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse is Map) {
          return jsonResponse.cast<String, dynamic>();
        }
      } else if (response.statusCode == 401) {
        await _clearToken();
      }
      return {};
    } catch (e) {
      print('Error loading landlord profile: $e');
      return {};
    }
  }

  // ============ PROPERTY MANAGEMENT APIS ============

  // 3. Get Landlord Properties with Pagination
  static Future<List<dynamic>> getProperties({int page = 1, int limit = 10}) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/landlord/properties?page=$page&limit=$limit'),
        headers: headers,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is List) return decoded;
        if (decoded is Map && decoded['data'] is List) return decoded['data'] as List;
        if (decoded is Map && decoded['properties'] is List) return decoded['properties'] as List;
      } else if (response.statusCode == 401) {
        await _clearToken();
      }
      return [];
    } catch (e) {
      print('Error loading landlord properties: $e');
      return [];
    }
  }

  // 4. Get Property Details
  static Future<Map<String, dynamic>> getPropertyDetails(String propertyId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/landlord/properties/$propertyId'),
        headers: headers,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse is Map) {
          return jsonResponse.cast<String, dynamic>();
        }
      } else if (response.statusCode == 401) {
        await _clearToken();
      }
      return {};
    } catch (e) {
      print('Error loading property details: $e');
      return {};
    }
  }

  // 5. Create New Property
  static Future<Map<String, dynamic>> createProperty(Map<String, dynamic> propertyData) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/api/landlord/properties'),
        headers: headers,
        body: json.encode(propertyData),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse is Map) {
          return jsonResponse.cast<String, dynamic>();
        }
        return {'success': true};
      } else if (response.statusCode == 401) {
        await _clearToken();
      }
      return {'success': false, 'message': 'Failed to create property'};
    } catch (e) {
      print('Error creating property: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // 6. Update Property
  static Future<bool> updateProperty(String propertyId, Map<String, dynamic> propertyData) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/api/landlord/properties/$propertyId'),
        headers: headers,
        body: json.encode(propertyData),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 401) await _clearToken();
      return response.statusCode == 200;
    } catch (e) {
      print('Error updating property: $e');
      return false;
    }
  }

  // 7. Delete Property
  static Future<bool> deleteProperty(String propertyId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/api/landlord/properties/$propertyId'),
        headers: headers,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 401) await _clearToken();
      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting property: $e');
      return false;
    }
  }

  // ============ MAINTENANCE APIS ============

  // 8. Get Maintenance Requests (Fixed)
  static Future<List<dynamic>> getMaintenanceRequests() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/landlord/maintenance-requests'),
        headers: headers,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is List) return decoded;
        if (decoded is Map && decoded['data'] is List) return decoded['data'] as List;
        return [];
      } else if (response.statusCode == 401) {
        await _clearToken();
      }
      return [];
    } catch (e) {
      print('Error fetching maintenance requests: $e');
      return [];
    }
  }

  // 9. Update Maintenance Request Status (Fixed Placement)
  static Future<bool> updateMaintenanceStatus(String requestId, String status) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/api/landlord/maintenance-requests/$requestId/status'),
        headers: headers,
        body: json.encode({'status': status}),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 401) await _clearToken();
      return response.statusCode == 200;
    } catch (e) {
      print('Error updating maintenance status: $e');
      return false;
    }
  }

  // ============ FINANCIAL & NOTIFICATIONS ============

  // 10. Get Payment History
  static Future<List<dynamic>> getPaymentHistory({int limit = 20}) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/landlord/payments/history?limit=$limit'),
        headers: headers,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is List) return decoded;
        if (decoded is Map && decoded['data'] is List) return decoded['data'] as List;
      } else if (response.statusCode == 401) {
        await _clearToken();
      }
      return [];
    } catch (e) {
      print('Error fetching payment history: $e');
      return [];
    }
  }

  // 11. Get Financial Summary
  static Future<Map<String, dynamic>> getFinancialSummary() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/landlord/financial/summary'),
        headers: headers,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
      return {};
    } catch (e) {
      print('Error fetching financial summary: $e');
      return {};
    }
  }

  // 12. Get Notifications
  static Future<List<dynamic>> getNotifications({bool unreadOnly = false}) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/landlord/notifications?unread=$unreadOnly'),
        headers: headers,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is List) return decoded;
        if (decoded is Map && decoded['data'] is List) return decoded['data'] as List;
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // 13. Mark Notification as Read
  static Future<bool> markNotificationAsRead(String id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/api/landlord/notifications/$id/read'),
        headers: headers,
      ).timeout(const Duration(seconds: 30));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ============ AUTHENTICATION ============

  // 14. Logout
  static Future<void> logout() async {
    try {
      final headers = await _getHeaders();
      await http.post(
        Uri.parse('$baseUrl/api/auth/logout'),
        headers: headers,
      ).timeout(const Duration(seconds: 10));
    } catch (e) {
      print("Logout API error: $e");
    } finally {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    }
  }
}