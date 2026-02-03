import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/landlord_api_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isLoading = true;
  
  // Data Containers
  Map<String, dynamic> _profile = {};
  Map<String, dynamic> _stats = {};

  // Prevent multiple SnackBars
  bool _isShowingSnackBar = false;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);
    
    try {
      // Fetch Profile and Stats in parallel
      final profileData = await LandlordApiService.getLandlordProfile();
      final statsData = await LandlordApiService.getDashboardStats();

      if (mounted) {
        setState(() {
          _profile = profileData;
          _stats = statsData;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error loading profile: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
          // Handle error state if necessary
        });
      }
    }
  }

  void _showSingleSnackBar(String message) {
    if (!_isShowingSnackBar) {
      _isShowingSnackBar = true;
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
          ),
          backgroundColor: const Color(0xFF5A2A9A),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ).closed.then((reason) {
        _isShowingSnackBar = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0D0D19),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF5A2A9A))),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D19),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildProfileHeader(),
            const SizedBox(height: 24),
            _buildQuickStats(),
            const SizedBox(height: 24),
            _buildAccountSettings(),
            const SizedBox(height: 24),
            _buildPreferences(),
            const SizedBox(height: 24),
            _buildSupportSection(),
            const SizedBox(height: 40), // Bottom padding
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    // Extract Data with Fallbacks
    // Check standard fields or nested 'user'/'data' objects
    String name = _profile['name'] ?? 
                  _profile['fullName'] ?? 
                  _profile['user']?['name'] ?? 
                  _profile['data']?['name'] ?? 
                  'Landlord';
                  
    // Combine first/last if single name missing
    if (name == 'Landlord') {
       String? first = _profile['firstName'] ?? _profile['user']?['firstName'];
       String? last = _profile['lastName'] ?? _profile['user']?['lastName'];
       if (first != null) name = "$first ${last ?? ''}".trim();
    }

    final email = _profile['email'] ?? _profile['user']?['email'] ?? '';
    final phone = _profile['phone'] ?? 'Phone not provided';
    final bio = _profile['bio'] ?? 'No bio available. Tap to edit profile.';
    final joinDateStr = _profile['createdAt'];
    
    // Formatting
    final initials = name.isNotEmpty ? name[0].toUpperCase() : 'L';
    String joinDate = 'Unknown';
    if (joinDateStr != null) {
      try {
        joinDate = DateFormat('MMMM yyyy').format(DateTime.parse(joinDateStr));
      } catch (_) {}
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          // Avatar and Basic Info
          Row(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: const Color(0xFF5A2A9A),
                child: Text(
                  initials,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(email, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(phone, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text('Member since $joinDate', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                  ],
                ),
              ),
              IconButton(
                onPressed: _editProfile,
                icon: const Icon(Icons.edit, color: Color(0xFF5A2A9A)),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Bio
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0D0D19),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              bio,
              style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    // Safe extraction from stats API
    // Handle direct structure or nested 'kpis'/'data'
    Map<String, dynamic> kpis = _stats['kpis'] ?? _stats['data']?['kpis'] ?? _stats;

    final totalProperties = kpis['totalProperties'] ?? 0;
    // Check both keys as API structure might vary slightly
    final activeTenants = kpis['activeTenants'] ?? kpis['totalTenants'] ?? 0;
    final monthlyRevenue = kpis['monthlyRevenue'] ?? kpis['collectedThisMonth'] ?? 0;
    
    // Format Currency
    final revenueFormatted = NumberFormat.currency(symbol: '\$', decimalDigits: 0).format(monthlyRevenue);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Portfolio Overview',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildPortfolioStat('Properties', '$totalProperties', Icons.home_work),
              _buildPortfolioStat('Tenants', '$activeTenants', Icons.people),
              _buildPortfolioStat('Revenue', revenueFormatted, Icons.attach_money),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPortfolioStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF5A2A9A),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: Colors.white),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildAccountSettings() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Account Settings',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 16),
          _buildSettingItem('Personal Information', 'Update your profile details', Icons.person, _editPersonalInfo),
          _buildSettingItem('Security', 'Change password and 2FA settings', Icons.security, _openSecuritySettings),
          _buildSettingItem('Payment Methods', 'Manage your bank accounts', Icons.payment, _managePaymentMethods),
          _buildSettingItem('Tax Information', 'Update W-9 and tax documents', Icons.receipt, _manageTaxInfo),
        ],
      ),
    );
  }

  Widget _buildSettingItem(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF0D0D19),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF5A2A9A),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 20, color: Colors.white),
            ),
            title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            subtitle: Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 12)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white70),
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
          ),
        ),
      ),
    );
  }

  Widget _buildPreferences() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Preferences', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 16),
          _buildPreferenceSwitch('Email Notifications', 'Receive updates about properties', true, (val) {}),
          _buildPreferenceSwitch('Rent Reminders', 'Automatic rent payment reminders', true, (val) {}),
          _buildPreferenceSwitch('Maintenance Updates', 'Notifications about maintenance', true, (val) {}),
        ],
      ),
    );
  }

  Widget _buildPreferenceSwitch(String title, String subtitle, bool value, Function(bool) onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(color: const Color(0xFF0D0D19), borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: const Color(0xFF5A2A9A), borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.notifications, size: 20, color: Colors.white),
        ),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: const Color(0xFF5A2A9A),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      ),
    );
  }

  Widget _buildSupportSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Support & Resources', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 16),
          _buildSupportItem('Help Center', 'Find answers to common questions', Icons.help, _openHelpCenter),
          _buildSupportItem('Contact Support', 'Get help from our support team', Icons.support_agent, _contactSupport),
          const SizedBox(height: 16),
          Center(
            child: TextButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text('Logout', style: TextStyle(color: Colors.red)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportItem(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(color: const Color(0xFF0D0D19), borderRadius: BorderRadius.circular(8)),
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: const Color(0xFF5A2A9A), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 20, color: Colors.white),
          ),
          title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          subtitle: Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white70),
          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        ),
      ),
    );
  }

  // Actions
  void _editProfile() => _showSingleSnackBar('Edit Profile functionality coming soon!');
  void _editPersonalInfo() => _showSingleSnackBar('Personal Information functionality coming soon!');
  void _openSecuritySettings() => _showSingleSnackBar('Security Settings functionality coming soon!');
  void _managePaymentMethods() => _showSingleSnackBar('Payment Methods functionality coming soon!');
  void _manageTaxInfo() => _showSingleSnackBar('Tax Information functionality coming soon!');
  void _openHelpCenter() => _showSingleSnackBar('Help Center functionality coming soon!');
  void _contactSupport() => _showSingleSnackBar('Contact Support functionality coming soon!');

  void _logout() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          title: const Text('Logout', style: TextStyle(color: Colors.white)),
          content: const Text('Are you sure you want to logout?', style: TextStyle(color: Colors.white70)),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel', style: TextStyle(color: Colors.white70))),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await LandlordApiService.logout();
                if (mounted) Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
              },
              child: const Text('Logout', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}