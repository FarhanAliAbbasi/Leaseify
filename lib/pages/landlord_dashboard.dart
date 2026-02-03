import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/landlord_api_service.dart';

// Ensure these page files exist or import placeholders
import 'properties_page.dart';
import 'landlord_maintenance_page.dart';
import 'profile_page.dart';

class LandlordDashboard extends StatefulWidget {
  const LandlordDashboard({super.key});

  @override
  State<LandlordDashboard> createState() => _LandlordDashboardState();
}

class _LandlordDashboardState extends State<LandlordDashboard> {
  int _currentIndex = 0;
  String _landlordName = 'Landlord';
  String _email = '';
  
  // Data containers
  Map<String, dynamic> _dashboardData = {}; 
  List<dynamic> _recentProperties = [];
  List<dynamic> _maintenanceRequests = [];
  
  bool _isLoading = true;
  bool _isRefreshing = false;
  
  final List<Widget> _pages = [
    Container(), // Dashboard Content (index 0)
    const PropertiesPage(),
    const LandlordMaintenancePage(),
    const ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    if (!_isRefreshing) {
      setState(() => _isLoading = true);
    }
    
    try {
      final profile = await LandlordApiService.getLandlordProfile();
      final stats = await LandlordApiService.getDashboardStats();
      final properties = await LandlordApiService.getProperties(limit: 5);
      final maintenance = await LandlordApiService.getMaintenanceRequests();

      if (mounted) {
        setState(() {
          // 1. Robust Name Extraction
          // Try to find the most likely map containing user info
          Map<String, dynamic> userMap = profile;
          if (profile['user'] is Map) {
            userMap = profile['user'];
          } else if (profile['data'] is Map) {
            userMap = profile['data'];
            // Check if data has a user object inside
            if (userMap['user'] is Map) {
              userMap = userMap['user'];
            }
          }

          // Extract Name Strategy: name -> fullName -> firstName+lastName -> email
          String? name = userMap['name'] ?? userMap['fullName'];
          if (name == null || name.trim().isEmpty) {
             String first = userMap['firstName'] ?? '';
             String last = userMap['lastName'] ?? '';
             if (first.isNotEmpty) {
               name = "$first $last".trim();
             }
          }
          
          // Fallback to email username if name is still missing
          if (name == null || name.trim().isEmpty) {
             String emailStr = userMap['email'] ?? '';
             if (emailStr.isNotEmpty) {
               name = emailStr.split('@')[0];
             }
          }

          _landlordName = (name != null && name.isNotEmpty) ? name : 'Landlord';
          _email = userMap['email'] ?? '';

          // 2. Robust Stats Extraction
          _dashboardData = stats;
          // If root doesn't have 'kpis', check if it's wrapped in 'data'
          if (_dashboardData['kpis'] == null) {
             if (_dashboardData['data'] is Map && _dashboardData['data']['kpis'] != null) {
               _dashboardData = _dashboardData['data'];
             }
          }

          _recentProperties = properties;
          _maintenanceRequests = maintenance;
          
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    } catch (e) {
      print('Error loading dashboard data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    }
  }

  Future<void> _refreshData() async {
    setState(() => _isRefreshing = true);
    await _loadDashboardData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D19),
      appBar: _currentIndex == 0 ? _buildAppBar() : null,
      body: _isLoading 
          ? _buildLoading() 
          : _currentIndex == 0 
              ? RefreshIndicator(
                  onRefresh: _refreshData,
                  color: const Color(0xFF5A2A9A),
                  backgroundColor: const Color(0xFF1A1A2E),
                  child: _buildDashboardContent(),
                )
              : _pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: Colors.transparent,
          selectedItemColor: const Color(0xFF5A2A9A),
          unselectedItemColor: Colors.white70,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard, size: 24),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.home_work, size: 24),
              label: 'Properties',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.build, size: 24),
              label: 'Maintenance',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person, size: 24),
              label: 'Profile',
            ),
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
          const Icon(Icons.admin_panel_settings, color: Color(0xFF5A2A9A)),
          const SizedBox(width: 8),
          Text(
            'Leaseify Admin',
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
          icon: const Icon(Icons.notifications, color: Colors.white70),
          onPressed: () {},
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white70),
          color: const Color(0xFF252540),
          onSelected: (value) {
            if (value == 'logout') _showLogoutDialog();
            if (value == 'profile') setState(() => _currentIndex = 3);
          },
          itemBuilder: (BuildContext context) => [
            const PopupMenuItem(
              value: 'profile', 
              child: Text('Profile', style: TextStyle(color: Colors.white)),
            ),
            const PopupMenuItem(
              value: 'logout', 
              child: Text('Logout', style: TextStyle(color: Colors.redAccent)),
            ),
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

  Widget _buildDashboardContent() {
    final kpis = _dashboardData['kpis'] ?? {};
    final charts = _dashboardData['charts'] ?? {};
    final rentCollection = charts['rentCollection'] as List<dynamic>? ?? [];
    final occupancyData = charts['occupancy'] as List<dynamic>? ?? [];

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Card
          _buildWelcomeCard(),
          const SizedBox(height: 24),
          
          // Key Performance Indicators
          _buildKPISection(kpis),
          const SizedBox(height: 24),
          
          // Financial Overview
          if (rentCollection.isNotEmpty) ...[
            _buildFinancialChart(rentCollection),
            const SizedBox(height: 24),
          ],
          
          // Occupancy Chart
          if (occupancyData.isNotEmpty) ...[
            _buildOccupancyChart(occupancyData),
            const SizedBox(height: 24),
          ],
          
          // Maintenance Section
          if (_maintenanceRequests.isNotEmpty) ...[
            _buildMaintenanceSection(),
            const SizedBox(height: 24),
          ],
          
          // Recent Properties (if any)
          if (_recentProperties.isNotEmpty) ...[
            _buildRecentProperties(),
            const SizedBox(height: 24),
          ],
          
          // Bottom padding for navigation
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard() {
    final initial = _landlordName.isNotEmpty ? _landlordName[0].toUpperCase() : 'L';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5A2A9A), Color(0xFF7B3FE4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5A2A9A).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white,
            child: Text(
              initial,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF5A2A9A),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome, $_landlordName!',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                if (_email.isNotEmpty)
                  Text(
                    _email,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 13,
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  'Here\'s your property management overview',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKPISection(Map<String, dynamic> kpis) {
    final totalProperties = kpis['totalProperties'] ?? 0;
    // Safe formatting for currency values which might be int/double
    final collectedVal = kpis['collectedThisMonth'] ?? 0;
    final collected = NumberFormat.compactCurrency(symbol: '\$').format(collectedVal);
    
    final occupancy = kpis['occupancyRate'] ?? 0;
    final vacant = kpis['vacantUnits'] ?? 0;
    final openMaintenance = kpis['openMaintenanceCount'] ?? 0;
    
    final upcomingVal = kpis['upcomingPayments'] ?? 0;
    final upcomingPayments = NumberFormat.compactCurrency(symbol: '\$').format(upcomingVal);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Key Performance Indicators',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        
        // First row of KPIs
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.4, 
          children: [
            _buildKPIItem(
              'Total Properties',
              '$totalProperties',
              Icons.home_work,
              Colors.blue,
              'Managed units',
            ),
            _buildKPIItem(
              'Monthly Revenue',
              collected,
              Icons.attach_money,
              const Color(0xFF5A2A9A),
              'Collected this month',
            ),
            _buildKPIItem(
              'Occupancy Rate',
              '$occupancy%',
              Icons.pie_chart,
              Colors.green,
              'Current rate',
            ),
            _buildKPIItem(
              'Vacant Units',
              '$vacant',
              Icons.door_front_door_outlined,
              Colors.orange,
              'Available for rent',
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        // Second row for additional KPIs
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.4, 
          children: [
            _buildMiniKPIItem('Open Maintenance', '$openMaintenance', Icons.build, Colors.red),
            _buildMiniKPIItem('Upcoming Payments', upcomingPayments, Icons.schedule, Colors.blue),
          ],
        ),
      ],
    );
  }

  Widget _buildKPIItem(String title, String value, IconData icon, Color color, String subtitle) {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Flexible(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniKPIItem(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                 padding: const EdgeInsets.all(6),
                 decoration: BoxDecoration(
                   color: color.withOpacity(0.1),
                   borderRadius: BorderRadius.circular(8),
                 ),
                 child: Icon(icon, color: color, size: 20),
              ),
              Flexible(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialChart(List<dynamic> data) {
    final chartData = data.length > 6 ? data.sublist(data.length - 6) : data;
    double maxVal = 100;
    for (var item in chartData) {
      final due = (item['totalDue'] ?? 0).toDouble();
      final paid = (item['totalPaid'] ?? 0).toDouble();
      if (due > maxVal) maxVal = due;
      if (paid > maxVal) maxVal = paid;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rent Collection History',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          const Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _ChartLegend(color: Color(0xFF5A2A9A), label: 'Paid'),
              SizedBox(width: 12),
              _ChartLegend(color: Colors.white24, label: 'Due'),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 150,
            child: Row(
              children: [
                // Chart Body Only (No Y-Axis)
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: chartData.map((item) {
                      final due = (item['totalDue'] ?? 0).toDouble();
                      final paid = (item['totalPaid'] ?? 0).toDouble();
                      final label = item['name'] ?? '';
                      final dueHeight = (due / maxVal * 120).clamp(4.0, 120.0);
                      final paidHeight = (paid / maxVal * 120).clamp(4.0, 120.0);

                      return Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              _Bar(height: paidHeight, color: const Color(0xFF5A2A9A)),
                              const SizedBox(width: 4),
                              _Bar(height: dueHeight, color: Colors.white24),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            label,
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOccupancyChart(List<dynamic> data) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Occupancy Rate Trend',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: Row(
              children: [
                // Chart Body Only (No Y-Axis)
                Expanded(
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: data.length,
                    itemBuilder: (context, index) {
                      final item = data[index];
                      final rate = (item['occupancyRate'] ?? 0).toDouble();
                      final month = item['name'] ?? '';
                      final height = (rate / 100 * 100).clamp(4.0, 100.0);
                      
                      return Container(
                        width: 50,
                        margin: const EdgeInsets.only(right: 8),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              width: 30,
                              height: height,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    Colors.green.withOpacity(0.8),
                                    Colors.green.withOpacity(0.4),
                                  ],
                                ),
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              month,
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaintenanceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Maintenance',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            TextButton(
              onPressed: () => setState(() => _currentIndex = 2),
              child: const Text(
                'View All',
                style: TextStyle(color: Color(0xFF5A2A9A)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ..._maintenanceRequests.take(3).map((request) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.build, color: Colors.orange, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request['description'] ?? 'Maintenance Request',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        request['status']?.toString().toUpperCase() ?? 'PENDING',
                        style: const TextStyle(
                          color: Colors.orange,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  _formatDate(request['createdAt']),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildRecentProperties() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Properties',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            TextButton(
              onPressed: () => setState(() => _currentIndex = 1),
              child: const Text(
                'View All',
                style: TextStyle(color: Color(0xFF5A2A9A)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 140,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _recentProperties.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final property = _recentProperties[index];
              final address = property['address'] ?? {};
              
              return Container(
                width: 200,
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
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF5A2A9A).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.home, color: Color(0xFF5A2A9A), size: 20),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            address['city'] ?? 'Unknown',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      address['street'] ?? 'No Address',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${property['rentAmount'] ?? 0}/mo',
                      style: const TextStyle(
                        color: Color(0xFF5A2A9A),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          title: const Text(
            'Logout',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'Are you sure you want to logout?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await LandlordApiService.logout();
                if (mounted) {
                  Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                }
              },
              child: const Text('Logout', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM d').format(date);
    } catch (e) {
      return '';
    }
  }
}

class _Bar extends StatelessWidget {
  final double height;
  final Color color;
  const _Bar({required this.height, required this.color});
  
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
      ),
    );
  }
}

class _ChartLegend extends StatelessWidget {
  final Color color;
  final String label;
  const _ChartLegend({required this.color, required this.label});
  
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}