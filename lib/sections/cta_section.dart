import 'package:flutter/material.dart';

// ====================================================================
// SECTION 5: FINAL CALL TO ACTION
// ====================================================================

class CallToActionSection extends StatelessWidget {
  const CallToActionSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
      margin: const EdgeInsets.symmetric(vertical: 50, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0), // Light gray background
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          const Text(
            'Ready to Simplify Your Rental World?',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black),
          ),
          const SizedBox(height: 10),
          const Text(
            'Get started for free today. No credit card required. Start your 30-day trial and experience the difference.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.black87),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () {
              // Redirect to signup page
              Navigator.pushNamed(context, '/signup');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5A2A9A), // A dark purple for CTA
              padding:
                  const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Start Your Free Trial',
                style: TextStyle(color: Colors.white, fontSize: 16)),
          ),
        ],
      ),
    );
  }
}