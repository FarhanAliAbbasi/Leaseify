import 'package:flutter/material.dart';

class TenantsPage extends StatefulWidget {
  const TenantsPage({super.key});

  @override
  State<TenantsPage> createState() => _TenantsPageState();
}

class _TenantsPageState extends State<TenantsPage> {
  List<Tenant> tenants = [
    Tenant(
      id: '1',
      name: 'Sarah Johnson',
      email: 'sarah.j@email.com',
      phone: '(555) 123-4567',
      property: '123 Main Street',
      rent: 2200,
      leaseStart: DateTime(2024, 1, 15),
      leaseEnd: DateTime(2024, 12, 14),
      status: TenantStatus.active,
      paymentStatus: PaymentStatus.paid,
      lastPayment: DateTime(2024, 3, 1),
      nextPayment: DateTime(2024, 4, 1),
    ),
    Tenant(
      id: '2',
      name: 'Michael Chen',
      email: 'michael.c@email.com',
      phone: '(555) 234-5678',
      property: '456 Oak Avenue',
      rent: 5500,
      leaseStart: DateTime(2024, 2, 1),
      leaseEnd: DateTime(2025, 1, 31),
      status: TenantStatus.active,
      paymentStatus: PaymentStatus.paid,
      lastPayment: DateTime(2024, 3, 1),
      nextPayment: DateTime(2024, 4, 1),
    ),
    Tenant(
      id: '3',
      name: 'Emily Davis',
      email: 'emily.d@email.com',
      phone: '(555) 345-6789',
      property: '789 Pine Road',
      rent: 1800,
      leaseStart: DateTime(2024, 3, 10),
      leaseEnd: DateTime(2024, 9, 9),
      status: TenantStatus.active,
      paymentStatus: PaymentStatus.overdue,
      lastPayment: DateTime(2024, 2, 1),
      nextPayment: DateTime(2024, 3, 10),
    ),
  ];

  TenantStatus _filterStatus = TenantStatus.all;
  String _searchQuery = '';

  // Prevent multiple SnackBars
  bool _isShowingSnackBar = false;

  void _showSingleSnackBar(String message) {
    if (!_isShowingSnackBar) {
      _isShowingSnackBar = true;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          backgroundColor: const Color(0xFF5A2A9A),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ).closed.then((reason) {
        _isShowingSnackBar = false;
      });
    }
  }

  List<Tenant> get filteredTenants {
    return tenants.where((tenant) {
      final matchesSearch = _searchQuery.isEmpty ||
          tenant.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          tenant.property.toLowerCase().contains(_searchQuery.toLowerCase());
      
      final matchesFilter = _filterStatus == TenantStatus.all ||
          tenant.status == _filterStatus;
      
      return matchesSearch && matchesFilter;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D19),
      body: Column(
        children: [
          // Header Section - COMPLETELY FIXED
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            decoration: const BoxDecoration(
              color: Color(0xFF1A1A2E),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 4),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Tenant Management',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 60,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem('Total', tenants.length.toString(), Icons.people),
                      _buildStatItem('Active', '3', Icons.check_circle),
                      _buildStatItem('Paid', '2', Icons.attach_money),
                      _buildStatItem('Overdue', '1', Icons.warning),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Search and Filter Section - COMPLETELY FIXED
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            color: const Color(0xFF0D0D19),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 45,
                  child: TextField(
                    onChanged: (value) => setState(() => _searchQuery = value),
                    decoration: InputDecoration(
                      hintText: 'Search tenants...',
                      hintStyle: const TextStyle(color: Colors.white54),
                      prefixIcon: const Icon(Icons.search, color: Colors.white70),
                      filled: true,
                      fillColor: const Color(0xFF1A1A2E),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      isDense: true,
                    ),
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 32,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: TenantStatus.values.map((status) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(
                            status.displayName,
                            style: TextStyle(
                              fontSize: 12,
                              color: _filterStatus == status ? Colors.white : Colors.white70,
                            ),
                          ),
                          selected: _filterStatus == status,
                          onSelected: (selected) => setState(() => _filterStatus = status),
                          backgroundColor: const Color(0xFF1A1A2E),
                          selectedColor: const Color(0xFF5A2A9A),
                          labelPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
          
          // Tenants List - Takes remaining space
          Expanded(
            child: _buildTenantsList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewTenant,
        backgroundColor: const Color(0xFF5A2A9A),
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF5A2A9A)),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildTenantsList() {
    final filteredTenants = this.filteredTenants;

    if (filteredTenants.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people, size: 50, color: Colors.white.withOpacity(0.3)),
            const SizedBox(height: 12),
            Text(
              _searchQuery.isEmpty ? 'No tenants found' : 'No tenants match your search',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: filteredTenants.length,
      itemBuilder: (context, index) {
        final tenant = filteredTenants[index];
        return _buildTenantCard(tenant);
      },
    );
  }

  Widget _buildTenantCard(Tenant tenant) {
    final daysUntilNextPayment = tenant.nextPayment.difference(DateTime.now()).inDays;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: const Color(0xFF1A1A2E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header Row
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFF5A2A9A),
                  child: Text(
                    tenant.name.split(' ').map((n) => n[0]).join(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        tenant.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tenant.property,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getPaymentStatusColor(tenant.paymentStatus).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: _getPaymentStatusColor(tenant.paymentStatus)),
                      ),
                      child: Text(
                        tenant.paymentStatus.displayName,
                        style: TextStyle(
                          color: _getPaymentStatusColor(tenant.paymentStatus),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${tenant.rent}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Contact Info
            Row(
              children: [
                Icon(Icons.phone, size: 14, color: Colors.white70),
                const SizedBox(width: 6),
                Text(
                  tenant.phone,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.email, size: 14, color: Colors.white70),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    tenant.email,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Lease Info
            Row(
              children: [
                _buildInfoItem('Lease End', _formatDate(tenant.leaseEnd)),
                const SizedBox(width: 16),
                _buildInfoItem('Next Payment', 
                  daysUntilNextPayment > 0 ? 'in $daysUntilNextPayment days' : 'Due now'),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _contactTenant(tenant),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: BorderSide(color: Colors.white.withOpacity(0.3)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      minimumSize: const Size(0, 36),
                    ),
                    child: const Text('Message', style: TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _viewTenantDetails(tenant),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: BorderSide(color: Colors.white.withOpacity(0.3)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      minimumSize: const Size(0, 36),
                    ),
                    child: const Text('Details', style: TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _collectPayment(tenant),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5A2A9A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      minimumSize: const Size(0, 36),
                    ),
                    child: const Text('Collect', style: TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white54,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _getPaymentStatusColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.paid:
        return Colors.green;
      case PaymentStatus.pending:
        return Colors.orange;
      case PaymentStatus.overdue:
        return Colors.red;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  void _addNewTenant() {
    _showSingleSnackBar('Add New Tenant functionality coming soon!');
  }

  void _contactTenant(Tenant tenant) {
    _showSingleSnackBar('Messaging ${tenant.name}');
  }

  void _viewTenantDetails(Tenant tenant) {
    _showSingleSnackBar('Viewing details for ${tenant.name}');
  }

  void _collectPayment(Tenant tenant) {
    _showSingleSnackBar('Collecting payment from ${tenant.name}');
  }
}

// ====================================================================
// TENANT MODEL
// ====================================================================

class Tenant {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String property;
  final int rent;
  final DateTime leaseStart;
  final DateTime leaseEnd;
  final TenantStatus status;
  final PaymentStatus paymentStatus;
  final DateTime lastPayment;
  final DateTime nextPayment;

  Tenant({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.property,
    required this.rent,
    required this.leaseStart,
    required this.leaseEnd,
    required this.status,
    required this.paymentStatus,
    required this.lastPayment,
    required this.nextPayment,
  });
}

// ====================================================================
// TENANT STATUS ENUM
// ====================================================================

enum TenantStatus {
  all('All'),
  active('Active'),
  inactive('Inactive');

  const TenantStatus(this.displayName);
  final String displayName;
}

// ====================================================================
// PAYMENT STATUS ENUM
// ====================================================================

enum PaymentStatus {
  paid('Paid'),
  pending('Pending'),
  overdue('Overdue');

  const PaymentStatus(this.displayName);
  final String displayName;
}