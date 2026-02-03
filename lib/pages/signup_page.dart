import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:async'; // Added this import for TimeoutException
import 'package:shared_preferences/shared_preferences.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  String _userType = 'tenant'; // 'tenant' or 'landlord'
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeToTerms = false;
  bool _isLoading = false;
  String _errorMessage = '';
  bool _hasNetworkConnection = true;

  // API Configuration
  final String _baseUrl = 'https://leasify.onrender.com';
  
  // Function to save token after successful registration
  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  // Function to test network connectivity
  Future<bool> _testNetworkConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com').timeout(
        const Duration(seconds: 3),
      );
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        return true;
      }
      return false;
    } on SocketException catch (_) {
      return false;
    } on TimeoutException catch (_) {
      return false;
    } catch (_) {
      return false;
    }
  }

  // Helper function to handle network errors
  void _handleNetworkError(String message) {
    setState(() {
      _errorMessage = message;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'RETRY',
          textColor: Colors.white,
          onPressed: () {
            _handleSignup();
          },
        ),
      ),
    );
  }

  // Helper function to handle error responses
  void _handleErrorResponse(http.Response response) {
    try {
      final errorData = json.decode(response.body);
      String errorMsg = 'Registration failed (Status: ${response.statusCode})';
      
      if (errorData['message'] != null) {
        errorMsg = errorData['message'];
      } else if (errorData['error'] != null) {
        errorMsg = errorData['error'];
      } else if (response.body.isNotEmpty) {
        errorMsg = 'Server Error: ${response.body}';
      }
      
      // Common HTTP status code messages
      switch (response.statusCode) {
        case 400:
          errorMsg = 'Bad Request: $errorMsg';
          break;
        case 401:
          errorMsg = 'Unauthorized: $errorMsg';
          break;
        case 403:
          errorMsg = 'Forbidden: $errorMsg';
          break;
        case 404:
          errorMsg = 'API endpoint not found. Please check the URL.';
          break;
        case 409:
          errorMsg = 'Conflict: User already exists with this email.';
          break;
        case 422:
          errorMsg = 'Validation Error: $errorMsg';
          break;
        case 500:
          errorMsg = 'Server Error: Internal server error. Please try again later.';
          break;
        case 502:
          errorMsg = 'Bad Gateway: Server is temporarily unavailable.';
          break;
        case 503:
          errorMsg = 'Service Unavailable: Server is under maintenance.';
          break;
      }
      
      setState(() {
        _errorMessage = errorMsg;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      // If JSON parsing fails
      _handleNetworkError('Server returned invalid response (Status: ${response.statusCode})');
    }
  }

  // Updated _handleSignup function with better error handling
  void _handleSignup() async {
    if (_formKey.currentState!.validate() && _agreeToTerms) {
      // Check network connection first
      final hasConnection = await _testNetworkConnection();
      if (!hasConnection) {
        setState(() {
          _hasNetworkConnection = false;
          _errorMessage = 'No internet connection. Please check your network and try again.';
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No internet connection. Please check your network.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }

      setState(() {
        _isLoading = true;
        _errorMessage = '';
        _hasNetworkConnection = true;
      });

      try {
        // Combine first and last name
        String fullName = '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}';
        
        // Prepare request body
        Map<String, dynamic> requestBody = {
          "name": fullName,
          "email": _emailController.text.trim(),
          "password": _passwordController.text,
          "role": _userType,
        };

        // Show connection testing message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Connecting to server...'),
            duration: Duration(seconds: 2),
          ),
        );

        // Make API call with timeout
        final response = await http.post(
          Uri.parse('$_baseUrl/api/auth/register'),
          headers: {
            'Content-Type': 'application/json',
          },
          body: json.encode(requestBody),
        ).timeout(const Duration(seconds: 30));

        // Parse response
        if (response.statusCode == 200 || response.statusCode == 201) {
          final responseData = json.decode(response.body);
          
          // Check if token is returned
          if (responseData['token'] != null) {
            // Save the token
            await _saveToken(responseData['token']);
            
            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Welcome ${responseData['user']?['name'] ?? fullName}!'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );
            
            // Navigate to appropriate dashboard
            await Future.delayed(const Duration(milliseconds: 500));
            if (!mounted) return; // Check mounted before navigation

            if (_userType == 'landlord') {
              Navigator.pushReplacementNamed(context, '/dashboard');
            } else {
              Navigator.pushReplacementNamed(context, '/tenant-dashboard');
            }
          } else {
            // If no token but registration successful
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Registration successful! Please login to continue.'),
                backgroundColor: Colors.orange,
              ),
            );
            await Future.delayed(const Duration(milliseconds: 500));
            if (!mounted) return;
            Navigator.pushReplacementNamed(context, '/login');
          }
        } else {
          // Handle error response
          _handleErrorResponse(response);
        }
      } on SocketException catch (e) {
        _handleNetworkError('Network Error: No internet connection. Please check your connection.\n\nDetails: ${e.message}');
      } on http.ClientException catch (e) {
        _handleNetworkError('Connection Error: Unable to reach the server.\n\nDetails: ${e.message}');
      } on TimeoutException catch (e) {
        _handleNetworkError('Timeout Error: Server is taking too long to respond. Please try again.\n\nDetails: ${e.message}');
      } on FormatException catch (e) {
        _handleNetworkError('Data Error: Invalid response from server.\n\nDetails: ${e.message}');
      } catch (e) {
        _handleNetworkError('Unexpected Error: ${e.toString()}');
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please agree to the Terms of Service and Privacy Policy'),
          backgroundColor: Colors.orange,
        ),
      );
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
              
              // Network Status Banner
              if (!_hasNetworkConnection)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.wifi_off, color: Colors.orange, size: 20),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'No internet connection. Please check your network.',
                          style: TextStyle(color: Colors.orange),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, size: 16, color: Colors.orange),
                        onPressed: () async {
                          final hasConnection = await _testNetworkConnection();
                          setState(() {
                            _hasNetworkConnection = hasConnection;
                            if (hasConnection) {
                              _errorMessage = '';
                            }
                          });
                        },
                      ),
                    ],
                  ),
                ),
              
              const SizedBox(height: 20),
              
              // Logo and Title
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
                "Create Your Account",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Join Leaseify as a tenant or landlord",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 40),

              // Detailed Error Display
              if (_errorMessage.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Registration Failed',
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 20, color: Colors.red),
                            onPressed: () {
                              setState(() {
                                _errorMessage = '';
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _errorMessage,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.refresh, size: 18),
                              label: const Text('Try Again'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                              ),
                              onPressed: _handleSignup,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.wifi, size: 18),
                              label: const Text('Check Network'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.blue,
                                side: const BorderSide(color: Colors.blue),
                              ),
                              onPressed: () async {
                                final hasInternet = await _testNetworkConnection();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      hasInternet 
                                        ? 'Internet connection is available'
                                        : 'No internet connection detected',
                                    ),
                                    backgroundColor: hasInternet ? Colors.green : Colors.red,
                                  ),
                                );
                                setState(() {
                                  _hasNetworkConnection = hasInternet;
                                });
                              },
                            ),
                          ),
                        ],
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
                      "I want to join as a",
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
                            'Find and rent properties',
                            Icons.person,
                            'tenant',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildUserTypeCard(
                            'Landlord',
                            'Manage rental properties',
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

              // Signup Form
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2E),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _firstNameController,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'First Name',
                                labelStyle: const TextStyle(color: Colors.white70),
                                prefixIcon: const Icon(Icons.person, color: Colors.white70),
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
                                  return 'Please enter your first name';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _lastNameController,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'Last Name',
                                labelStyle: const TextStyle(color: Colors.white70),
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
                                  return 'Please enter your last name';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
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
                          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                            return 'Please enter a valid email';
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
                          if (value.length < 8) {
                            return 'Password must be at least 8 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Confirm Password',
                          labelStyle: const TextStyle(color: Colors.white70),
                          prefixIcon: const Icon(Icons.lock_outline, color: Colors.white70),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                              color: Colors.white70,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPassword = !_obscureConfirmPassword;
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
                            return 'Please confirm your password';
                          }
                          if (value != _passwordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Theme(
                            data: ThemeData(
                              unselectedWidgetColor: Colors.white70,
                            ),
                            child: Checkbox(
                              value: _agreeToTerms,
                              onChanged: (value) {
                                setState(() {
                                  _agreeToTerms = value!;
                                });
                              },
                              checkColor: Colors.white,
                              fillColor: MaterialStateProperty.resolveWith<Color>((states) {
                                if (states.contains(MaterialState.selected)) {
                                  return const Color(0xFF5A2A9A);
                                }
                                return Colors.transparent;
                              }),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                // Add navigation to terms and privacy policy pages here
                              },
                              child: RichText(
                                text: TextSpan(
                                  style: const TextStyle(color: Colors.white70),
                                  children: [
                                    const TextSpan(text: 'I agree to the '),
                                    TextSpan(
                                      text: 'Terms of Service',
                                      style: const TextStyle(
                                        color: Color(0xFF5A2A9A),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const TextSpan(text: ' and '),
                                    TextSpan(
                                      text: 'Privacy Policy',
                                      style: const TextStyle(
                                        color: Color(0xFF5A2A9A),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
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
                                  backgroundColor: _agreeToTerms ? const Color(0xFF5A2A9A) : Colors.grey.shade700,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: _agreeToTerms ? _handleSignup : null,
                                child: const Text(
                                  'Create Account',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                ),
                              ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Already have an account?",
                            style: TextStyle(color: Colors.white70),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/login');
                            },
                            child: const Text('Sign In', style: TextStyle(color: Color(0xFF5A2A9A), fontWeight: FontWeight.w600)),
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
              style: const TextStyle(
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
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}