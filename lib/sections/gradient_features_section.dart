import 'package:flutter/material.dart';

// ====================================================================
// MODELS
// ====================================================================

class LandlordFeature {
  final String text;
  final IconData icon;

  const LandlordFeature({required this.text, required this.icon});
}


// ====================================================================
// SECTION 2: GRADIENT FEATURES
// ====================================================================

class GradientSection extends StatelessWidget {
  const GradientSection({super.key});

  @override
  Widget build(BuildContext context) {
    const startColor = Color(0xFF1A0A3A);
    const endColor = Color(0xFF0A0A1A);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 80),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [startColor, endColor],
        ),
      ),
      child: Column(
        children: [
          const Text(
            'Your business deserves better than chaos.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Colors.white),
          ),
          const SizedBox(height: 5),
          const Text(
            'We’re here to help you take back control, and focus on what matters.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.white60),
          ),
          const SizedBox(height: 60),
          Column(
            children: [
              FeatureCard(
                title: 'Centralized Information',
                icon: Icons.dashboard,
                description:
                    'Keep track of all your essential documents, communications, and data in one secure location.',
              ),
              const SizedBox(height: 30.0),
              FeatureCard(
                title: 'The Property Sheet',
                icon: Icons.house,
                description:
                    'A single source of truth for every property you manage. Never lose track of a detail again.',
              ),
              const SizedBox(height: 30.0),
              FeatureCard(
                title: 'Communication Broadcasts',
                icon: Icons.message,
                description:
                    'Easily send urgent updates, maintenance notices, and reminders to all your tenants at once.',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class FeatureCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String description;

  const FeatureCard({
    required this.title,
    required this.icon,
    required this.description,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    const cardColor = Color(0xFF1D1535);

    return SizedBox(
      width: double.infinity, // Always full width on mobile
      child: Card(
        color: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: Color(0xFF3A305B), width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: Colors.blueAccent, size: 30),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              const SizedBox(height: 10),
              Text(
                description,
                style: const TextStyle(fontSize: 14, color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
