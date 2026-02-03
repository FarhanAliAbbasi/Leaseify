import 'package:flutter/material.dart';

// ====================================================================
// MODELS AND ENUMS
// ====================================================================

enum UserType { landlord, tenant }

class LandlordFeature {
  final String text;
  final IconData icon;

  const LandlordFeature({required this.text, required this.icon});
}

// ====================================================================
// SECTION 3: PRICING/PLATFORM (RESPONSIVE DUAL-COLUMN LAYOUT)
// ====================================================================

class PricingSection extends StatefulWidget {
  const PricingSection({super.key});

  @override
  State<PricingSection> createState() => _PricingSectionState();
}

class _PricingSectionState extends State<PricingSection> {
  UserType _selectedUserType = UserType.landlord;
  final double _desktopBreakpoint = 800; // Define breakpoint for dual column layout

  // Landlord Feature Data
  final List<LandlordFeature> _landlordFeatures = const [
    LandlordFeature(
        text: 'See portfolio health at a glance with a powerful mission control dashboard.',
        icon: Icons.grid_view_outlined),
    LandlordFeature(
        text: 'Streamline your application workflow from submission to lease generation.',
        icon: Icons.description_outlined),
    LandlordFeature(
        text: 'Track finances effortlessly with online payments and automated overdue alerts.',
        icon: Icons.credit_card_outlined),
    LandlordFeature(
        text: 'Manage all maintenance requests in one organized, easy-to-track log.',
        icon: Icons.build_outlined),
  ];

  // Tenant Feature Data
  final List<LandlordFeature> _tenantFeatures = const [
    LandlordFeature(
        text: 'Pay rent in seconds through a secure, trusted online payment portal powered by Stripe.',
        icon: Icons.credit_card_outlined),
    LandlordFeature(
        text: 'Submit maintenance requests with descriptions and see their status anytime.',
        icon: Icons.build_outlined),
    LandlordFeature(
        text: 'Access all your key lease information and payment history in a secure home hub.',
        icon: Icons.check_circle_outline),
  ];

  // Helper to build the feature list widget
  Widget _buildFeatureList(String title, String subtitle, List<LandlordFeature> features) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
              fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 16, color: Colors.white70),
        ),
        const SizedBox(height: 30),
        ...features
            .map((feature) => _BulletPoint(
                text: feature.text, icon: feature.icon))
            .toList(),
      ],
    );
  }

  // Content for the Landlord tab
  Widget _buildLandlordContent(bool isDesktop) {
    final featureList = _buildFeatureList(
      "Your Calm Command Center",
      "Get a bird's-eye view of your entire portfolio and manage every task with ease.",
      _landlordFeatures,
    );

    final dashboardCard = const _LandlordDashboardCard();

    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 3, child: featureList),
          const SizedBox(width: 40),
          Expanded(flex: 2, child: dashboardCard),
        ],
      );
    } else {
      // Mobile Layout: Features on top, Dashboard Card below
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          featureList,
          const SizedBox(height: 40),
          dashboardCard,
        ],
      );
    }
  }

  // Content for the Tenant tab
  Widget _buildTenantContent(bool isDesktop) {
    final featureList = _buildFeatureList(
      "Your Simple, Secure Home Hub",
      "Enjoy a modern, professional rental experience with everything you need right at your fingertips.",
      _tenantFeatures,
    );

    final tenantPortalCard = const _TenantPortalCard();

    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 3, child: featureList),
          const SizedBox(width: 40),
          Expanded(flex: 2, child: tenantPortalCard),
        ],
      );
    } else {
      // Mobile Layout: Features on top, Payment Card below
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          featureList,
          const SizedBox(height: 40),
          tenantPortalCard,
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Theme.of(context).primaryColor;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > _desktopBreakpoint;

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 20),
          child: Column(
            children: [
              const Text(
                'One Platform. A Perfect Fit for Everyone.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Colors.white),
              ),
              const SizedBox(height: 30),

              // The Segmented Button for Role Switching
              Center(
                child: SegmentedButton<UserType>(
                  selected: {_selectedUserType},
                  onSelectionChanged: (Set<UserType> newSelection) {
                    setState(() {
                      _selectedUserType = newSelection.first;
                    });
                  },
                  multiSelectionEnabled: false,
                  emptySelectionAllowed: false,
                  segments: const <ButtonSegment<UserType>>[
                    ButtonSegment<UserType>(
                      value: UserType.landlord,
                      label: Text('For Landlords'),
                      icon: Icon(Icons.business_center_outlined),
                    ),
                    ButtonSegment<UserType>(
                      value: UserType.tenant,
                      label: Text('For Tenants'),
                      icon: Icon(Icons.person_outline),
                    ),
                  ],
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.resolveWith<Color>(
                      (Set<MaterialState> states) {
                        if (states.contains(MaterialState.selected)) {
                          return primaryColor.withOpacity(0.15);
                        }
                        return const Color(0xFF181825);
                      },
                    ),
                    foregroundColor: MaterialStateProperty.resolveWith<Color>(
                      (Set<MaterialState> states) {
                        if (states.contains(MaterialState.selected)) {
                          return Colors.white;
                        }
                        return Colors.white60;
                      },
                    ),
                    side: MaterialStateProperty.all(
                        BorderSide(color: primaryColor.withOpacity(0.5))),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Main Content Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: const Color(0xFF181825),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.white10),
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  child: KeyedSubtree(
                    key: ValueKey<UserType>(_selectedUserType),
                    child: _selectedUserType == UserType.landlord
                        ? _buildLandlordContent(isDesktop)
                        : _buildTenantContent(isDesktop),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ====================================================================
// HELPER WIDGETS
// ====================================================================

// Helper for the features list (used by Tenant AND Landlord)
class _BulletPoint extends StatelessWidget {
  final String text;
  final IconData? icon;

  const _BulletPoint({required this.text, this.icon, super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Use the provided icon with better color/size
          Icon(icon ?? Icons.check_circle_outline,
              color: Colors.white, size: 28),
          const SizedBox(width: 20),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 16, color: Colors.white70, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

// LANDLORD DASHBOARD WIDGET
class _LandlordDashboardCard extends StatelessWidget {
  const _LandlordDashboardCard();

  @override
  Widget build(BuildContext context) {
    const cardColor = Color(0xFF13131E); // Slightly darker for contrast

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF13131E),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Properties & Occupancy
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: _DashboardStatCard(
                  title: 'Properties',
                  value: '4',
                  icon: Icons.business_center_outlined,
                ),
              ),
              SizedBox(width: 10), // Fixed spacing between the cards
              Expanded(
                child: _DashboardStatCard(
                  title: 'Occupancy',
                  value: '95%',
                  icon: Icons.people_alt_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Bottom Card: Maintenance Queue
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Maintenance Queue',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                const Divider(color: Colors.white10, height: 25),
                _MaintenanceItem(
                  issue: 'Leaky Faucet - Unit 3',
                  status: 'Pending',
                  color: Colors.amber, // Use a clear amber for pending
                ),
                const SizedBox(height: 15),
                _MaintenanceItem(
                  issue: 'Dryer Repair - Unit 1',
                  status: 'Completed',
                  color: Colors.green,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// TENANT PORTAL WIDGET
class _TenantPortalCard extends StatelessWidget {
  const _TenantPortalCard();

  @override
  Widget build(BuildContext context) {
    const cardColor = Color(0xFF13131E);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          const Text(
            'Rent Due',
            style: TextStyle(fontSize: 16, color: Colors.white70),
          ),
          const SizedBox(height: 5),
          const Text(
            '\$1,850.00',
            style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Pay Rent Securely',
                style: TextStyle(color: Colors.black, fontSize: 16)),
          ),
          const SizedBox(height: 15),
          TextButton(
            onPressed: () {},
            child: const Text('or Submit Maintenance Request',
                style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    decoration: TextDecoration.underline,
                    decorationColor: Colors.white70)),
          ),
        ],
      ),
    );
  }
}

// Helper for the small stat cards
class _DashboardStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _DashboardStatCard(
      {required this.title,
      required this.value,
      required this.icon,
      super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D19),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible( // Prevent text overflow
                child: Text(title,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white70)),
              ),
              const SizedBox(width: 8),
              Icon(icon, color: Colors.blueGrey, size: 20),
            ],
          ),
          const SizedBox(height: 8),
          Text(value,
              style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  color: Colors.white)),
        ],
      ),
    );
  }
}

// Helper for the maintenance list items
class _MaintenanceItem extends StatelessWidget {
  final String issue;
  final String status;
  final Color color;

  const _MaintenanceItem(
      {required this.issue, required this.status, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded( // Prevent text overflow for long descriptions
          child: Text(issue,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 16, color: Colors.white70)),
        ),
        const SizedBox(width: 10), // Spacing between text and status
        Row(
          mainAxisSize: MainAxisSize.min, // Keep row tight to children
          children: [
            Icon(Icons.circle, color: color, size: 10),
            const SizedBox(width: 8),
            Text(status,
                style: TextStyle(
                    fontSize: 16,
                    color: color.withOpacity(0.9),
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }
}