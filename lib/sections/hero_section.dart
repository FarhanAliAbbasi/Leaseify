import 'package:flutter/material.dart';

// ====================================================================
// SECTION 1: HERO CONTENT
// ====================================================================

class HeroContent extends StatelessWidget {
  const HeroContent({super.key});

  @override
  Widget build(BuildContext context) {
    const padding = EdgeInsets.symmetric(vertical: 40, horizontal: 20);

    return Container(
      padding: padding.copyWith(top: 10),
      child: Column(
        children: [
          const SizedBox(height: 40),

          // Main Headline (Mobile Size)
          Text(
            'Leasify, Rental\nManagement\nWithout the\nMess.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontSize: 40,
                  height: 1.1,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 20),

          // Subtext
          const SizedBox(
            width: double.infinity,
            child: Text(
              'A platform that automates your rental lifecycle, making renting, lease administration, and tenant management simple and seamless.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
          ),
          const SizedBox(height: 40),

          // CTA Buttons
          Wrap(
            spacing: 15,
            runSpacing: 15,
            alignment: WrapAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                ),
                child: const Text('Get Started',
                    style: TextStyle(color: Colors.black, fontSize: 16)),
              ),
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white70),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                ),
                child: const Text('Book a Demo',
                    style: TextStyle(color: Colors.white70, fontSize: 16)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
