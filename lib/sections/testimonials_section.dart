import 'package:flutter/material.dart';
import 'dart:async'; // Required for Timer

// ====================================================================
// DATA MODEL
// ====================================================================

class Testimonial {
  final String quote;
  final String author;
  final String role;
  final String avatarUrl;

  const Testimonial({
    required this.quote,
    required this.author,
    required this.role,
    required this.avatarUrl,
  });
}

// ====================================================================
// SECTION 4: TESTIMONIALS (AUTO-SCROLL CAROUSEL)
// ====================================================================

class TestimonialSection extends StatefulWidget {
  const TestimonialSection({super.key});

  @override
  State<TestimonialSection> createState() => _TestimonialSectionState();
}

class _TestimonialSectionState extends State<TestimonialSection> {
  int _currentIndex = 0;
  late Timer _timer; 

  final List<Testimonial> _testimonials = const [
    Testimonial(
        quote:
            "“The payment tracking alone is worth it. I know exactly who has paid and who is late without ever having to check my bank statement or send an awkward text. It has completely streamlined my cash flow.”",
        author: 'David Chen, Owner, 3 Properties',
        role: 'Landlord',
        avatarUrl: 'https://placehold.co/100x100/3A305B/ffffff/png?text=DC'),
    Testimonial(
        quote:
            "“Submitting maintenance requests used to be a nightmare, but with Leaseify, it's a one-tap process. I love having my lease documents available instantly.”",
        author: 'David R. - Tenant',
        role: 'Tenant',
        avatarUrl: 'https://placehold.co/100x100/3A305B/ffffff/png?text=DR'),
    Testimonial(
        quote:
            "“The centralized property sheet is a game-changer. I finally feel organized and in control of my entire portfolio. This tool pays for itself in time saved.”",
        author: 'Mark K. - Property Manager',
        role: 'Property Manager',
        avatarUrl: 'https://placehold.co/100x100/3A305B/ffffff/png?text=MK'),
  ];

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
  }

  @override
  void dispose() {
    _timer.cancel(); // Stop the timer when the widget is removed
    super.dispose();
  }

  // Start the timer to cycle testimonials every 5 seconds
  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        _nextTestimonial();
      }
    });
  }

  void _nextTestimonial() {
    setState(() {
      _currentIndex = (_currentIndex + 1) % _testimonials.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    const startColor = Color(0xFF130D2E);
    const endColor = Color(0xFF090616);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 20),
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
            'Trusted by Landlords and Tenants Like You.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Colors.white),
          ),
          const SizedBox(height: 8),
          const Text(
            'Real stories from people who have simplified their rental world.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.white70),
          ),
          const SizedBox(height: 60),

          // Main Testimonial Card (Animated for transition)
          // Wrapped in ConstrainedBox to keep it from getting too wide on desktop
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(opacity: animation, child: child);
              },
              child: _TestimonialCard(
                // Key forces the AnimatedSwitcher to recognize a change
                key: ValueKey<int>(_currentIndex),
                testimonial: _testimonials[_currentIndex],
              ),
            ),
          ),
          
          const SizedBox(height: 30),

          // Dot Indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: _testimonials.asMap().entries.map((entry) {
              return GestureDetector(
                onTap: () => setState(() => _currentIndex = entry.key),
                child: Container(
                  width: 10.0,
                  height: 10.0,
                  margin: const EdgeInsets.symmetric(horizontal: 6.0),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentIndex == entry.key
                        ? Colors.white
                        : Colors.white.withOpacity(0.2),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _TestimonialCard extends StatelessWidget {
  final Testimonial testimonial;

  const _TestimonialCard({required this.testimonial, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(40),
      margin: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0B1E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF3A305B), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Profile Image
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white54, width: 2),
            ),
            child: ClipOval(
              child: Image.network(
                testimonial.avatarUrl,
                fit: BoxFit.cover,
                loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      color: Colors.white54,
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.person, size: 40, color: Colors.white70),
              ),
            ),
          ),
          const SizedBox(height: 30),

          // Quote Text
          Text(
            testimonial.quote,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 18,
                fontStyle: FontStyle.italic,
                color: Colors.white70,
                height: 1.6),
          ),
          const SizedBox(height: 20),

          // Author and Role
          Text(
            '— ${testimonial.author}',
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white),
          ),
        ],
      ),
    );
  }
}