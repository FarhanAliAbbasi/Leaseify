import 'package:flutter/material.dart';
import '../services/tenant_api_service.dart';
import 'maintenance_page.dart';

class TenantProfilePage extends StatefulWidget {
  const TenantProfilePage({super.key});

  @override
  State<TenantProfilePage> createState() => _TenantProfilePageState();
}

class _TenantProfilePageState extends State<TenantProfilePage> {
  Map<String, dynamic> _tenantProfile = {};
  Map<String, dynamic> _leaseData = {};
  bool _isLoading = true;
  String _errorMessage = '';
  
  // For editing
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _emergencyNameController = TextEditingController();
  final TextEditingController _emergencyPhoneController = TextEditingController();
  final TextEditingController _emergencyEmailController = TextEditingController();
  final TextEditingController _emergencyRelationshipController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Load tenant profile - now returns Map with 'success' and 'data'
      final profileResponse = await TenantApiService.getTenantProfile();
      
      if (profileResponse['success'] == true) {
        setState(() {
          _tenantProfile = profileResponse['data'] ?? {};
        });
      } else {
        setState(() {
          _errorMessage = profileResponse['error']?.toString() ?? 'Failed to load profile';
        });
      }
      
      // Load lease data
      final lease = await TenantApiService.getMyLease();
      
      setState(() {
        _leaseData = lease;
        
        // Initialize controllers with current data
        _nameController.text = _tenantProfile['name']?.toString() ?? '';
        _phoneController.text = _tenantProfile['phone']?.toString() ?? '';
        _bioController.text = _tenantProfile['bio']?.toString() ?? '';
        
        // Initialize emergency contact
        final emergency = _tenantProfile['emergencyContact'] ?? {};
        _emergencyNameController.text = emergency['name']?.toString() ?? '';
        _emergencyPhoneController.text = emergency['phone']?.toString() ?? '';
        _emergencyEmailController.text = emergency['email']?.toString() ?? '';
        _emergencyRelationshipController.text = emergency['relationship']?.toString() ?? '';
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load profile: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateProfile() async {
    final updatedData = {
      'name': _nameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'bio': _bioController.text.trim(),
      'emergencyContact': {
        'name': _emergencyNameController.text.trim(),
        'phone': _emergencyPhoneController.text.trim(),
        'email': _emergencyEmailController.text.trim(),
        'relationship': _emergencyRelationshipController.text.trim(),
      }
    };

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await TenantApiService.updateProfile(updatedData);
      
      if (result['success'] == true) {
        _showSnackBar('Profile updated successfully!');
        await _loadProfileData(); // Refresh data
      } else {
        _showSnackBar('Failed to update profile: ${result['error']}');
      }
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF5A2A9A),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return '${date.month}/${date.day}/${date.year}';
    } catch (e) {
      return 'Invalid date';
    }
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFF5A2A9A)),
          SizedBox(height: 20),
          Text(
            'Loading profile...',
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 20),
            Text(
              _errorMessage,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadProfileData,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5A2A9A),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return _buildLoading();
    if (_errorMessage.isNotEmpty) return _buildError();

    final name = _tenantProfile['name']?.toString() ?? 'Tenant';
    final email = _tenantProfile['email']?.toString() ?? '';
    final phone = _tenantProfile['phone']?.toString() ?? '';
    final bio = _tenantProfile['bio']?.toString() ?? 'No bio available';
    final emergency = _tenantProfile['emergencyContact'] ?? {};
    final emergencyName = emergency['name']?.toString() ?? 'Not provided';
    final emergencyRelationship = emergency['relationship']?.toString() ?? 'Not specified';
    final emergencyPhone = emergency['phone']?.toString() ?? 'Not provided';
    final emergencyEmail = emergency['email']?.toString() ?? 'Not provided';

    // Extract lease data
    final leaseStart = _leaseData['startDate'];
    final leaseEnd = _leaseData['endDate'];
    final daysUntilLeaseEnd = leaseEnd != null 
        ? DateTime.parse(leaseEnd).difference(DateTime.now()).inDays
        : 0;
    final rentAmount = _leaseData['rentAmount'] ?? 0;
    final property = _leaseData['property'] ?? {};
    final propertyName = property['description']?.toString() ?? 'Current Rental';
    final bedrooms = property['bedrooms']?.toString() ?? 'N/A';
    final bathrooms = property['bathrooms']?.toString() ?? 'N/A';

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D19),
      body: RefreshIndicator(
        onRefresh: _loadProfileData,
        backgroundColor: const Color(0xFF1A1A2E),
        color: const Color(0xFF5A2A9A),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Profile Header
              _buildProfileHeader(name, email, phone, bio),
              const SizedBox(height: 24),

              // Lease Information (only if lease exists)
              if (_leaseData.isNotEmpty) ...[
                _buildLeaseInfo(propertyName, rentAmount, leaseStart, leaseEnd, daysUntilLeaseEnd, bedrooms, bathrooms),
                const SizedBox(height: 24),
              ],

              // Contact Information
              _buildContactInfo(email, phone),
              const SizedBox(height: 24),

              // Emergency Contact
              _buildEmergencyContact(emergencyName, emergencyRelationship, emergencyPhone, emergencyEmail),
              const SizedBox(height: 24),

              // Account Settings
              _buildAccountSettings(),
              const SizedBox(height: 24),

              // Support Section
              _buildSupportSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(String name, String email, String phone, String bio) {
    final initials = name.isNotEmpty 
        ? name.split(' ').map((n) => n[0]).take(2).join().toUpperCase()
        : 'TN';

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
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      phone.isNotEmpty ? phone : 'Phone not provided',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
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
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaseInfo(String propertyName, dynamic rentAmount, String? leaseStart, 
      String? leaseEnd, int daysUntilLeaseEnd, String bedrooms, String bathrooms) {
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
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Lease Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Icon(Icons.home, color: Color(0xFF5A2A9A)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildLeaseStat('Monthly Rent', '\$$rentAmount', Icons.attach_money),
              _buildLeaseStat('Lease Ends', '$daysUntilLeaseEnd days', Icons.calendar_today),
              _buildLeaseStat('Bed/Bath', '$bedrooms/$bathrooms', Icons.bathtub),
            ],
          ),
          const SizedBox(height: 16),
          _buildLeaseDetailItem('Current Property', propertyName),
          _buildLeaseDetailItem('Lease Period', '${_formatDate(leaseStart)} - ${_formatDate(leaseEnd)}'),
          _buildLeaseDetailItem('Status', _leaseData['status']?.toString() ?? 'Active'),
        ],
      ),
    );
  }

  Widget _buildLeaseStat(String label, String value, IconData icon) {
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
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildLeaseDetailItem(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfo(String email, String phone) {
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
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Contact Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Icon(Icons.contact_mail, color: Color(0xFF5A2A9A)),
            ],
          ),
          const SizedBox(height: 16),
          _buildContactItem('Email', email, Icons.email),
          _buildContactItem('Phone', phone.isNotEmpty ? phone : 'Not provided', Icons.phone),
        ],
      ),
    );
  }

  Widget _buildContactItem(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF5A2A9A),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyContact(String name, String relationship, String phone, String email) {
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
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Emergency Contact',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Icon(Icons.emergency, color: Colors.red),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0D0D19),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                _buildEmergencyDetail('Name', name),
                _buildEmergencyDetail('Relationship', relationship),
                _buildEmergencyDetail('Phone', phone),
                _buildEmergencyDetail('Email', email),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyDetail(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white54,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
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
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          _buildSettingItem(
            'Personal Information',
            'Update your profile details',
            Icons.person,
            _editProfile,
          ),
          _buildSettingItem(
            'Security',
            'Change password and 2FA settings',
            Icons.security,
            _openSecuritySettings,
          ),
          _buildSettingItem(
            'Payment Methods',
            'Manage your payment options',
            Icons.payment,
            _managePaymentMethods,
          ),
          _buildSettingItem(
            'Notification Preferences',
            'Manage email and push notifications',
            Icons.notifications,
            _manageNotifications,
          ),
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
            title: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              subtitle,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white70),
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
          ),
        ),
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
          const Text(
            'Support & Resources',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          _buildSupportItem(
            'Help Center',
            'Find answers to common questions',
            Icons.help,
            _openHelpCenter,
          ),
          _buildSupportItem(
            'Contact Landlord',
            'Get in touch with your landlord',
            Icons.support_agent,
            _contactLandlord,
          ),
          _buildSupportItem(
            'Maintenance Requests',
            'Submit and track maintenance issues',
            Icons.build,
            _openMaintenance,
          ),
          _buildSupportItem(
            'Lease Documents',
            'View your lease agreement',
            Icons.description,
            _viewLeaseDocuments,
          ),
        ],
      ),
    );
  }

  Widget _buildSupportItem(String title, String subtitle, IconData icon, VoidCallback onTap) {
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
            title: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              subtitle,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white70),
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
          ),
        ),
      ),
    );
  }

  void _editProfile() {
    _showEditProfileDialog();
  }

  void _showEditProfileDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1A1A2E),
            title: const Text(
              'Edit Profile',
              style: TextStyle(color: Colors.white),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildEditField('Full Name', _nameController),
                  _buildEditField('Phone Number', _phoneController),
                  _buildEditField('Bio', _bioController, maxLines: 3),
                  
                  const SizedBox(height: 16),
                  const Text(
                    'Emergency Contact',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _buildEditField('Contact Name', _emergencyNameController),
                  _buildEditField('Relationship', _emergencyRelationshipController),
                  _buildEditField('Phone Number', _emergencyPhoneController),
                  _buildEditField('Email', _emergencyEmailController),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _updateProfile();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5A2A9A),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Save Changes'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEditField(String label, TextEditingController controller, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 4),
          TextField(
            controller: controller,
            maxLines: maxLines,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF0D0D19),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
        ],
      ),
    );
  }

  void _openSecuritySettings() {
    _showSnackBar('Security Settings functionality coming soon!');
  }

  void _managePaymentMethods() {
    _showSnackBar('Payment Methods functionality coming soon!');
  }

  void _manageNotifications() {
    _showSnackBar('Notification Preferences functionality coming soon!');
  }

  void _openHelpCenter() {
    _showSnackBar('Help Center functionality coming soon!');
  }

  void _contactLandlord() {
    _showSnackBar('Contact Landlord functionality coming soon!');
  }

 void _openMaintenance() {
  // Navigate to maintenance page using MaterialPageRoute
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => const MaintenancePage(),
    ),
  );
  }

  void _viewLeaseDocuments() {
    _showSnackBar('Lease Documents functionality coming soon!');
  }
}