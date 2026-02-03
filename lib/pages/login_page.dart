import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String _userType = 'tenant'; // Default selection, overwritten by API response
  bool _rememberMe = false;
  bool _obscurePassword = true;
  bool _isLoading = false;
  String _errorMessage = '';
  bool _hasNetworkConnection = true;

  // API Configuration
  final String _baseUrl = 'https://leasify.onrender.com';

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  // Load saved credentials
  Future<void> _loadSavedCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedEmail = prefs.getString('remember_email');
      final savedUserType = prefs.getString('remember_user_type');
      final rememberMe = prefs.getBool('remember_me') ?? false;

      if (rememberMe && savedEmail != null) {
        setState(() {
          _emailController.text = savedEmail;
          _rememberMe = true;
        });
      }
      if (savedUserType != null) {
        setState(() {
          _userType = savedUserType;
        });
      }
    } catch (e) {
      print('Error loading credentials: $e');
    }
  }

  // Simple network test
  Future<bool> _checkNetwork() async {
    try {
      final result = await InternetAddress.lookup('google.com').timeout(
        const Duration(seconds: 3),
      );
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  // Handle login
  void _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    // Check network
    final hasNetwork = await _checkNetwork();
    if (!hasNetwork) {
      if (!mounted) return;
      setState(() {
        _hasNetworkConnection = false;
        _errorMessage = 'No internet connection';
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _hasNetworkConnection = true;
    });

    try {
      // Prepare request
      final requestBody = {
        "email": _emailController.text.trim(),
        "password": _passwordController.text,
      };

      // Make API call
      final response = await http.post(
        Uri.parse('$_baseUrl/api/auth/login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(requestBody),
      ).timeout(const Duration(seconds: 30));

      if (!mounted) return;

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        // Check for token
        if (responseData['token'] == null) {
          throw Exception('No authentication token received');
        }

        final token = responseData['token'].toString();
        
        // Extract User Data
        Map<String, dynamic> userData = {};
        if (responseData['user'] != null && responseData['user'] is Map) {
          userData = Map<String, dynamic>.from(responseData['user']);
        } else if (responseData['data'] != null && responseData['data'] is Map) {
          userData = Map<String, dynamic>.from(responseData['data']);
        } else {
          // Manual construction fallback
          userData = {
            'email': _emailController.text.trim(),
          };
        }

        // Extract Name - Check multiple locations
        String name = userData['name'] ?? 
                      userData['fullName'] ?? 
                      responseData['name'] ?? 
                      _emailController.text.trim().split('@')[0];

        // Save to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);
        
        if (userData['id'] != null) {
          await prefs.setString('user_id', userData['id'].toString());
        }
        
        // Important: Save Name and Email for Dashboard Profile
        await prefs.setString('user_name', name);
        await prefs.setString('user_email', userData['email']?.toString() ?? _emailController.text.trim());
        
        // Determine role
        String role = _userType; // Default to selected type
        
        if (userData['role'] != null) {
          role = userData['role'].toString().toLowerCase();
        } else if (responseData['role'] != null) {
          role = responseData['role'].toString().toLowerCase();
        }
        
        await prefs.setString('user_role', role);
        
        // Save remember me
        if (_rememberMe) {
          await prefs.setString('remember_email', _emailController.text.trim());
          await prefs.setString('remember_user_type', role);
          await prefs.setBool('remember_me', true);
        } else {
          await prefs.remove('remember_email');
          await prefs.remove('remember_user_type');
          await prefs.setBool('remember_me', false);
        }

        // Show success
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Welcome back, $name!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        // Navigate based on role
        await Future.delayed(const Duration(milliseconds: 500));
        
        if (!mounted) return;
        
        if (role == 'landlord') {
          Navigator.pushReplacementNamed(context, '/dashboard');
        } else {
          Navigator.pushReplacementNamed(context, '/tenant-dashboard');
        }

      } else {
        // Handle error
        String errorMsg = 'Login failed';
        try {
          final errorData = json.decode(response.body);
          if (errorData['message'] != null) {
            errorMsg = errorData['message'].toString();
          } else if (errorData['error'] != null) {
            errorMsg = errorData['error'].toString();
          }
        } catch (_) {
          errorMsg = 'Server error: ${response.statusCode}';
        }
        
        setState(() {
          _errorMessage = errorMsg;
        });
      }
      
    } on SocketException {
      setState(() {
        _errorMessage = 'No internet connection';
        _hasNetworkConnection = false;
      });
    } on TimeoutException {
      setState(() {
        _errorMessage = 'Request timeout. Please try again.';
      });
    } on http.ClientException catch (e) {
      setState(() {
        _errorMessage = 'Connection error: ${e.message}';
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Login failed: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D19),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Back Button
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, color: Colors.white70),
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Logo
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF5A2A9A),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.apartment, size: 32, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    "Leaseify",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              const Text(
                "Welcome Back",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Sign in to your account",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 40),

              // Network Error
              if (!_hasNetworkConnection)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.wifi_off, color: Colors.red, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'No internet connection',
                        style: TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                ),

              // Error Message
              if (_errorMessage.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 16, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            _errorMessage = '';
                          });
                        },
                      ),
                    ],
                  ),
                ),

              // User Type Selection
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2E),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Text(
                      "I am a",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildUserTypeCard(
                            'Tenant',
                            'Renting a property',
                            Icons.person,
                            'tenant',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildUserTypeCard(
                            'Landlord',
                            'Managing properties',
                            Icons.business,
                            'landlord',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Login Form
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2E),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _emailController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Email Address',
                          labelStyle: const TextStyle(color: Colors.white70),
                          prefixIcon: const Icon(Icons.email, color: Colors.white70),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.white30),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.white30),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF5A2A9A)),
                          ),
                          filled: true,
                          fillColor: const Color(0xFF0D0D19),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Password',
                          labelStyle: const TextStyle(color: Colors.white70),
                          prefixIcon: const Icon(Icons.lock, color: Colors.white70),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility : Icons.visibility_off,
                              color: Colors.white70,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.white30),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.white30),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF5A2A9A)),
                          ),
                          filled: true,
                          fillColor: const Color(0xFF0D0D19),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      
                      // FIXED: Use Wrap to prevent overflow on small screens
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8.0, // gap between adjacent chips
                        runSpacing: 4.0, // gap between lines
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: Checkbox(
                                  value: _rememberMe,
                                  onChanged: (value) {
                                    setState(() {
                                      _rememberMe = value ?? false;
                                    });
                                  },
                                  activeColor: const Color(0xFF5A2A9A),
                                  side: const BorderSide(color: Colors.white70),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Remember me',
                                style: TextStyle(color: Colors.white70, fontSize: 14),
                              ),
                            ],
                          ),
                          TextButton(
                            onPressed: () {},
                            child: const Text(
                              'Forgot Password?',
                              style: TextStyle(color: Color(0xFF5A2A9A)),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: _isLoading
                            ? const Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5A2A9A)),
                                ),
                              )
                            : ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF5A2A9A),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: _handleLogin,
                                child: const Text(
                                  'Sign In',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                ),
                              ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Don't have an account?",
                            style: TextStyle(color: Colors.white70),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/signup');
                            },
                            child: const Text('Sign Up', style: TextStyle(color: Color(0xFF5A2A9A), fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserTypeCard(String title, String subtitle, IconData icon, String type) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _userType = type;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _userType == type ? const Color(0xFF5A2A9A) : const Color(0xFF0D0D19),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _userType == type ? const Color(0xFF5A2A9A) : Colors.white30,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: Colors.white),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}