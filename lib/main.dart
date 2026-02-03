import 'package:flutter/material.dart';
import 'pages/home_page.dart';
import 'pages/login_page.dart';
import 'pages/signup_page.dart';
import 'pages/landlord_dashboard.dart';
import 'pages/tenant_dashboard.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Leaseify',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF5A2A9A),
        primarySwatch: Colors.deepPurple,
        scaffoldBackgroundColor: const Color(0xFF0D0D19),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(fontFamily: 'Roboto', color: Colors.white70),
          headlineLarge: TextStyle(
            fontFamily: 'Roboto',
            fontWeight: FontWeight.w900,
            color: Colors.white,
            fontSize: 48,
          ),
        ),
        useMaterial3: true,
      ),
      home: const HomePage(),
      routes: {
        '/home': (context) => const HomePage(),
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignupPage(),
        '/dashboard': (context) => const LandlordDashboard(),
        '/tenant-dashboard': (context) => const TenantDashboard(),
      },
    );
  }
}