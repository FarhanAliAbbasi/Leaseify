import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class TenantApiService {
  static const String baseUrl = 'https://leasify.onrender.com';
  
  // Get JWT token from storage
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }
  
  // Get user data from storage
  static Future<Map<String, dynamic>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'id': prefs.getString('user_id') ?? '',
      'name': prefs.getString('user_name') ?? 'Tenant',
      'email': prefs.getString('user_email') ?? '',
      'role': prefs.getString('user_role') ?? 'tenant',
    };
  }
  
  // Get headers with JWT token
  static Future<Map<String, String>> _getHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }
  
  // ============ TENANT SPECIFIC APIS ============
  
  // 1. Get tenant's lease details
  static Future<Map<String, dynamic>> getMyLease() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/tenant/lease/my-lease'),
        headers: headers,
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {}; // Return empty if no lease
      }
    } catch (e) {
      print('Error getting lease: $e');
      return {};
    }
  }
  
  // 2. Get tenant's maintenance requests
  static Future<List<dynamic>> getMyMaintenanceRequests() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/tenant/maintenance-requests'),
        headers: headers,
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is List) return decoded;
        if (decoded is Map && decoded['data'] is List) return decoded['data'];
        return [];
      } else {
        return [];
      }
    } catch (e) {
      print('Error getting maintenance: $e');
      return [];
    }
  }

  // 3. Create maintenance request
  static Future<bool> createMaintenanceRequest(String description) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/api/tenant/maintenance-requests'),
        headers: headers,
        body: json.encode({'description': description}),
      ).timeout(const Duration(seconds: 30));
      
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Error creating maintenance: $e');
      return false;
    }
  }

  // ============ PROPERTY APIS ============
  
  // 4. Get public properties (for browsing)
  static Future<List<dynamic>> getPublicProperties() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/properties/public'),
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is List) return decoded;
        if (decoded is Map && decoded['data'] is List) return decoded['data'];
        return [];
      } else {
        return [];
      }
    } catch (e) {
      print('Error getting properties: $e');
      return [];
    }
  }

  // 5. Apply for a property
  static Future<Map<String, dynamic>> applyForProperty(String propertyId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/api/tenant/properties/$propertyId/apply'),
        headers: headers,
        body: json.encode({}),
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': json.decode(response.body)};
      } else {
        return {
          'success': false,
          'error': 'Application failed: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error applying for property: $e',
      };
    }
  }
  
  // ============ PAYMENT APIS ============
  
  // 6. Get tenant's payment history (UPDATED URL)
  static Future<List<dynamic>> getMyPayments() async {
    try {
      final headers = await _getHeaders();
      
      // UPDATED ENDPOINT
      const endpoint = '$baseUrl/api/tenant/payments/my-payments';
      print('Fetching payments from: $endpoint'); 
      
      final response = await http.get(
        Uri.parse(endpoint),
        headers: headers,
      ).timeout(const Duration(seconds: 30));
      
      print('Payments API Response: ${response.statusCode}');
      print('Payments API Body: ${response.body}'); 

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        
        // Handle List directly: [ {...}, {...} ]
        if (decoded is List) {
          return decoded;
        } 
        // Handle "data" wrapper: { "data": [ ... ] }
        else if (decoded is Map && decoded['data'] is List) {
          return decoded['data'];
        }
        // Handle "payments" wrapper: { "payments": [ ... ] }
        else if (decoded is Map && decoded['payments'] is List) {
          return decoded['payments'];
        }
        
        return [];
      } else {
        return [];
      }
    } catch (e) {
      print('Error getting payments: $e');
      return [];
    }
  }
  
  // 7. Make a payment
  static Future<bool> makePayment(String paymentId, String paymentMethod) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/api/tenant/payments/$paymentId/pay'),
        headers: headers,
        body: json.encode({
          'payment_method': paymentMethod,
        }),
      ).timeout(const Duration(seconds: 30));
      
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Error making payment: $e');
      return false;
    }
  }
  
  // 8. Get payment receipt
  static Future<String?> getPaymentReceipt(String paymentId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/tenant/payments/$paymentId/receipt'),
        headers: headers,
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['receipt_url']?.toString();
      } else {
        return null;
      }
    } catch (e) {
      print('Error getting receipt: $e');
      return null;
    }
  }
  
  // ============ PROFILE APIS ============
  
  // 9. Get tenant profile
static Future<Map<String, dynamic>> getTenantProfile() async {
  try {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/api/tenant/profile'),
      headers: headers,
    ).timeout(const Duration(seconds: 30));
    
    if (response.statusCode == 200) {
      try {
        final data = json.decode(response.body);
        return {'success': true, 'data': data};
      } catch (e) {
        // If profile API doesn't exist, return basic user data
        final userData = await getUserData();
        return {
          'success': true,
          'data': {
            'name': userData['name'],
            'email': userData['email'],
            'phone': '',
            'bio': '',
            'emergencyContact': {},
          }
        };
      }
    } else {
      // If profile API doesn't exist, return basic user data
      final userData = await getUserData();
      return {
        'success': true,
        'data': {
          'name': userData['name'],
          'email': userData['email'],
          'phone': '',
          'bio': '',
          'emergencyContact': {},
        }
      };
    }
  } catch (e) {
    print('Error getting profile: $e');
    // Return basic user data as fallback
    final userData = await getUserData();
    return {
      'success': false,
      'error': 'Failed to load profile',
      'data': {
        'name': userData['name'],
        'email': userData['email'],
        'phone': '',
        'bio': '',
        'emergencyContact': {},
      }
    };
  }
}
  
  // 10. Update tenant profile (FIXED - returns Map instead of bool)
static Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> profileData) async {
  try {
    final headers = await _getHeaders();
    final response = await http.put(
      Uri.parse('$baseUrl/api/tenant/profile'),
      headers: headers,
      body: json.encode(profileData),
    ).timeout(const Duration(seconds: 30));
    
    if (response.statusCode == 200) {
      // Update local storage if name changed
      if (profileData['name'] != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_name', profileData['name'].toString());
      }
      
      try {
        final responseData = json.decode(response.body);
        return {'success': true, 'data': responseData};
      } catch (e) {
        return {'success': true, 'data': {}};
      }
    } else {
      return {
        'success': false,
        'error': 'Failed to update profile: ${response.statusCode}',
        'message': response.body,
      };
    }
  } catch (e) {
    return {
      'success': false,
      'error': 'Error updating profile: $e',
    };
  }
}
  
  // ============ UTILITY METHODS ============
  
  // Logout
  static Future<void> logout() async {
    try {
      final headers = await _getHeaders();
      await http.post(
        Uri.parse('$baseUrl/api/auth/logout'),
        headers: headers,
      ).timeout(const Duration(seconds: 10));
    } finally {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('user_id');
      await prefs.remove('user_name');
      await prefs.remove('user_email');
      await prefs.remove('user_role');
    }
  }
  
  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
  
  // Clear all user data
  static Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_id');
    await prefs.remove('user_name');
    await prefs.remove('user_email');
    await prefs.remove('user_role');
    await prefs.remove('remember_email');
    await prefs.remove('remember_user_type');
    await prefs.remove('remember_me');
  }
  
  // Network connectivity check
  static Future<bool> checkNetwork() async {
    try {
      final result = await InternetAddress.lookup('google.com').timeout(
        const Duration(seconds: 3),
      );
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}