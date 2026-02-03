import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/tenant_api_service.dart';

// Import your page files
import 'rental_page.dart';
import 'tenant_payment_page.dart';
import 'tenant_profile_page.dart';
// If you have a maintenance page, import it here. 
// If not, create a placeholder or remove the navigation case.
import 'maintenance_page.dart'; 

class TenantDashboard extends StatefulWidget {
  const TenantDashboard({super.key});

  @override
  State<TenantDashboard> createState() => _TenantDashboardState();
}

class _TenantDashboardState extends State<TenantDashboard> {
  int _currentIndex = 0;
  Map<String, dynamic> _userProfile = {};
  Map<String, dynamic> _leaseData = {};
  Map<String, dynamic> _tenantProfile = {};
  List<dynamic> _maintenanceRequests = [];
  bool _isLoading = true;
  String _errorMessage = '';
  String _userName = 'Tenant';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // 1. Load basic user profile from storage
      final basicProfile = await TenantApiService.getUserData();
      if (!mounted) return;
      
      setState(() {
        _userProfile = basicProfile;
        _userName = basicProfile['name'] ?? 'Tenant';
      });

      // 2. Load detailed tenant profile
      try {
        _tenantProfile = await TenantApiService.getTenantProfile();
        if (_tenantProfile.isNotEmpty && _tenantProfile['name'] != null) {
          if (!mounted) return;
          setState(() {
            _userName = _tenantProfile['name'];
          });
        }
      } catch (e) {
        print('Failed to load tenant profile: $e');
      }

      // 3. Load lease details
      try {
        _leaseData = await TenantApiService.getMyLease();
      } catch (e) {
        print('Failed to load lease: $e');
      }

      // 4. Load maintenance requests
      try {
        _maintenanceRequests = await TenantApiService.getMyMaintenanceRequests();
      } catch (e) {
        print('Failed to load maintenance: $e');
      }

    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load data: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshData() async {
    await _loadUserData();
  }

  void _handleLogout() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          title: const Text('Logout', style: TextStyle(color: Colors.white)),
          content: const Text('Are you sure you want to logout?', style: TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await TenantApiService.logout();
                if (mounted) {
                  Navigator.pushReplacementNamed(context, '/login');
                }
              },
              child: const Text('Logout', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D19),
      appBar: _currentIndex == 0 ? _buildAppBar() : null, // Only show custom AppBar on Dashboard tab
      body: _isLoading
          ? _buildLoading()
          : _errorMessage.isNotEmpty
              ? _buildError()
              : _buildCurrentPage(),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: Colors.transparent,
          selectedItemColor: const Color(0xFF5A2A9A),
          unselectedItemColor: Colors.white70,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Rentals'),
            BottomNavigationBarItem(icon: Icon(Icons.build), label: 'Fixes'),
            BottomNavigationBarItem(icon: Icon(Icons.payment), label: 'Pay'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF1A1A2E),
      elevation: 0,
      title: Row(
        children: [
          const Icon(Icons.apartment, color: Color(0xFF5A2A9A)),
          const SizedBox(width: 8),
          Text(
            'Leasify',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white70),
          onPressed: _refreshData,
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white70),
          color: const Color(0xFF252540),
          onSelected: (value) {
            if (value == 'logout') _handleLogout();
            if (value == 'profile') setState(() => _currentIndex = 4);
          },
          itemBuilder: (BuildContext context) => [
            const PopupMenuItem(value: 'profile', child: Text('Profile', style: TextStyle(color: Colors.white))),
            const PopupMenuItem(value: 'logout', child: Text('Logout', style: TextStyle(color: Colors.redAccent))),
          ],
        ),
      ],
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFF5A2A9A)),
          SizedBox(height: 20),
          Text('Loading dashboard...', style: TextStyle(color: Colors.white70)),
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
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 20),
            Text(_errorMessage, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5A2A9A), foregroundColor: Colors.white),
              onPressed: _refreshData,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentPage() {
    switch (_currentIndex) {
      case 0: return _buildDashboard();
      case 1: return const RentalPage();
      case 2: return const MaintenancePage(); 
      case 3: return const TenantPaymentPage();
      case 4: return const TenantProfilePage();
      default: return _buildDashboard();
    }
  }

  Widget _buildDashboard() {
    // Extract Lease Data
    final rentAmount = _leaseData['rentAmount'] ?? 0;
    final propertyData = _leaseData['property'] ?? {};
    final propertyName = propertyData['description'] ?? 'Current Rental';
    final propertyAddress = _formatAddress(propertyData['address']);
    
    // Extract Tenant Data
    final email = _tenantProfile['email'] ?? _userProfile['email'] ?? '';
    final joinDate = _tenantProfile['createdAt'];

    return RefreshIndicator(
      onRefresh: _refreshData,
      color: const Color(0xFF5A2A9A),
      backgroundColor: const Color(0xFF1A1A2E),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Welcome Card
            _buildWelcomeCard(email, joinDate),
            
            const SizedBox(height: 24),

            // 2. Quick Stats Grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.5, // Adjusts height of cards
              children: [
                _buildStatCard('Next Payment', '\$$rentAmount', 'Due Apr 1', Icons.calendar_today, Colors.green),
                _buildStatCard('Requests', _maintenanceRequests.length.toString(), 'Active issues', Icons.build, Colors.orange),
                _buildStatCard('Lease', _leaseData.isEmpty ? 'Inactive' : 'Active', _leaseData.isEmpty ? 'Apply Now' : 'View Details', Icons.description, Colors.blue),
                _buildStatCard('Profile', 'Verified', 'View settings', Icons.verified_user, Colors.purple),
              ],
            ),

            const SizedBox(height: 24),

            // 3. Current Property or "No Lease"
            if (_leaseData.isNotEmpty) 
              _buildPropertyCard(propertyName, propertyAddress, rentAmount, propertyData)
            else 
              _buildNoLeaseCard(),

            const SizedBox(height: 24),

            // 4. Recent Maintenance (if any)
            if (_maintenanceRequests.isNotEmpty) _buildRecentMaintenance(),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(String email, String? joinDate) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5A2A9A), Color(0xFF7B3FE4)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: const Color(0xFF5A2A9A).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white,
            child: Text(
              _userName.isNotEmpty ? _userName[0].toUpperCase() : 'T',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF5A2A9A)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Welcome, $_userName!', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 4),
                Text(email, style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13)),
                if (joinDate != null)
                  Text('Member since ${_formatDate(joinDate)}', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, String subtitle, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: color),
              const Spacer(),
              Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            ],
          ),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontSize: 14, color: Colors.white70)),
          Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.5))),
        ],
      ),
    );
  }

  Widget _buildPropertyCard(String name, String address, int rent, Map<String, dynamic> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Current Rental', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 60, height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFF252540),
                      borderRadius: BorderRadius.circular(12),
                      image: (data['images'] != null && (data['images'] as List).isNotEmpty)
                          ? DecorationImage(image: NetworkImage(data['images'][0]), fit: BoxFit.cover)
                          : null,
                    ),
                    child: (data['images'] == null || (data['images'] as List).isEmpty)
                        ? const Icon(Icons.home, color: Colors.white54) : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text(address, style: const TextStyle(color: Colors.white54, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('\$$rent', style: const TextStyle(color: Color(0xFF5A2A9A), fontWeight: FontWeight.bold, fontSize: 16)),
                      const Text('/mo', style: TextStyle(color: Colors.white38, fontSize: 12)),
                    ],
                  )
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildAmenity(Icons.bed, '${data['bedrooms'] ?? '-'} Beds'),
                  _buildAmenity(Icons.bathtub, '${data['bathrooms'] ?? '-'} Baths'),
                  _buildAmenity(Icons.square_foot, '${data['squareFeet'] ?? '-'} sqft'),
                ],
              )
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAmenity(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.white54),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
      ],
    );
  }

  Widget _buildNoLeaseCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          const Icon(Icons.home_work_outlined, size: 48, color: Colors.white24),
          const SizedBox(height: 16),
          const Text('No Active Lease', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Browse listings to find your next home.', style: TextStyle(color: Colors.white54), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => setState(() => _currentIndex = 1), // Go to rentals
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5A2A9A), foregroundColor: Colors.white),
            child: const Text('View Rentals'),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentMaintenance() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Recent Maintenance', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            TextButton(
              onPressed: () => setState(() => _currentIndex = 2), // Go to maintenance
              child: const Text('View All', style: TextStyle(color: Color(0xFF5A2A9A))),
            )
          ],
        ),
        const SizedBox(height: 8),
        ..._maintenanceRequests.take(3).map((req) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getStatusColor(req['status']),
              radius: 4,
            ),
            title: Text(req['description'] ?? 'Issue', style: const TextStyle(color: Colors.white, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(_formatDate(req['createdAt']), style: const TextStyle(color: Colors.white38, fontSize: 12)),
            trailing: Icon(Icons.chevron_right, color: Colors.white24, size: 18),
          ),
        )),
      ],
    );
  }

  String _formatAddress(dynamic address) {
    if (address == null) return 'Address unavailable';
    if (address is Map) {
      return '${address['street'] ?? ''}, ${address['city'] ?? ''}';
    }
    return address.toString();
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM d, yyyy').format(date);
    } catch (e) {
      return '';
    }
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'completed': return Colors.green;
      case 'in_progress': return Colors.blue;
      case 'pending': return Colors.orange;
      default: return Colors.grey;
    }
  }
}