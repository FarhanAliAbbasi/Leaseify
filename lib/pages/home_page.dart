import 'package:flutter/material.dart';
import '../sections/hero_section.dart';
import '../sections/gradient_features_section.dart';
import '../sections/pricing_section.dart';
import '../sections/testimonials_section.dart';
import '../sections/cta_section.dart';

// ====================================================================
// MAIN PAGE LAYOUT
// ====================================================================

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Keys for scrolling to sections
  final GlobalKey _pricingKey = GlobalKey(); 
  final GlobalKey _testimonialsKey = GlobalKey();
  final ScrollController _scrollController = ScrollController();

  // Utility function to scroll to a specific section
  void _scrollToSection(GlobalKey key) {
    if (key.currentContext != null) {
      Scrollable.ensureVisible(
        key.currentContext!,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Helper method to build the mobile header bar with L/C/R alignment
  Widget _buildHeaderBar(BuildContext context) {
    // Shared styling for TextButtons
    final navButtonStyle = TextButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      minimumSize: Size.zero,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      foregroundColor: Colors.white, // Ensure text is white
    );
    
    // Shared text style for TextButtons
    const navTextStyle = TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500);

    // Styling for the Sign Up Button (White background, Black text)
    final signUpButton = ElevatedButton(
      onPressed: () {
        Navigator.pushNamed(context, '/signup');
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        minimumSize: Size.zero, // Compact sizing
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      child: const Text('Sign Up',
          style: TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.bold)), 
    );

    // Login Button
    final loginButton = TextButton(
      onPressed: () {
        Navigator.pushNamed(context, '/login');
      },
      style: navButtonStyle,
      child: const Text('Login', style: navTextStyle), 
    );
    
    // Pricing Button
    final pricingButton = TextButton(
      onPressed: () => _scrollToSection(_pricingKey),
      style: navButtonStyle,
      child: const Text('Pricing', style: navTextStyle),
    );

    // Reviews Button
    final testimonialsButton = TextButton(
      onPressed: () => _scrollToSection(_testimonialsKey),
      style: navButtonStyle,
      child: const Text('Reviews', style: navTextStyle),
    );

    // Using Row with MainAxisAlignment.spaceBetween and Spacers to position elements
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // LEFT: Logo
        GestureDetector(
          onTap: () {
            // Scroll to top when logo is clicked
            _scrollController.animateTo(
              0,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
            );
          },
          child: const Row(
            children: [
              Icon(Icons.apartment, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('Leaseify',
                  style: TextStyle(
                      fontSize: 20, 
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
            ],
          ),
        ),
        
        // CENTER: Nav Links (Pushed by Spacers)
        const Spacer(),
        if (MediaQuery.of(context).size.width > 600) ...[
           pricingButton,
           testimonialsButton,
        ],
        const Spacer(),

        // RIGHT: Auth Buttons
        Row(
          children: [
            loginButton,
            const SizedBox(width: 8), 
            signUpButton,
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D19), // Consistent dark background
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            SliverAppBar(
              floating: true,
              pinned: true,
              snap: false,
              toolbarHeight: 50, // Compact height for mobile
              backgroundColor: const Color(0xFF1E1E1E), 
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: EdgeInsets.zero,
                centerTitle: false, 
                title: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: Align( 
                    alignment: Alignment.center, 
                    child: _buildHeaderBar(context),
                  ),
                ),
              ),
            ),
          ];
        },
        body: SingleChildScrollView(
          child: Column(
            children: [
              // Section 1: Hero Content
              const HeroContent(),
              // Section 2: Features (Gradient Background)
              const GradientSection(),
              // Section 3: Pricing/Platform Section (Dynamic/Stateful)
              PricingSection(key: _pricingKey),
              // Section 4: Testimonials (Carousel Layout)
              TestimonialSection(key: _testimonialsKey),
              // Section 5: Final CTA
              const CallToActionSection(),
            ],
          ),
        ),
      ),
    );
  }
}