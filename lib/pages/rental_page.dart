import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/tenant_api_service.dart';

// ====================================================================
// 1. DATA MODEL (Strong Typing)
// ====================================================================

class Property {
  final String id;
  final String description;
  final String street;
  final String city;
  final int bedrooms;
  final int bathrooms;
  final String type;
  final double rentAmount;
  final List<String> images;

  Property({
    required this.id,
    required this.description,
    required this.street,
    required this.city,
    required this.bedrooms,
    required this.bathrooms,
    required this.type,
    required this.rentAmount,
    required this.images,
  });

  factory Property.fromJson(Map<String, dynamic> json) {
    final address = json['address'] ?? {};
    return Property(
      id: json['id']?.toString() ?? '',
      description: json['description'] ?? 'Unknown Property',
      street: address['street'] ?? 'Unknown Street',
      city: address['city'] ?? 'Unknown City',
      bedrooms: json['bedrooms'] ?? 0,
      bathrooms: json['bathrooms'] ?? 0,
      type: json['propertyType'] ?? 'Apartment',
      rentAmount: (json['rentAmount'] is int) 
          ? (json['rentAmount'] as int).toDouble() 
          : (json['rentAmount'] as double? ?? 0.0),
      images: (json['images'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}

// ====================================================================
// 2. MAIN PAGE
// ====================================================================

class RentalPage extends StatefulWidget {
  const RentalPage({super.key});

  @override
  State<RentalPage> createState() => _RentalPageState();
}

class _RentalPageState extends State<RentalPage> {
  // Formatters
  final _currencyFormat = NumberFormat.simpleCurrency();
  final _dateFormat = DateFormat('MMM dd, yyyy');

  Map<String, dynamic> _myLease = {};
  List<Property> _availableProperties = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final leaseData = await TenantApiService.getMyLease();
      final propertiesList = await TenantApiService.getPublicProperties();
      
      // Parse list into safe Property objects
      final parsedProperties = propertiesList.map((json) => Property.fromJson(json)).toList();

      setState(() {
        _myLease = leaseData;
        _availableProperties = parsedProperties;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load data: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // ==================================================================
  // APPLICATION LOGIC (Updated)
  // ==================================================================
  Future<void> _applyForProperty(String propertyId) async {
    // 1. Confirm Intent
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Confirm Application', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to apply for this property? The landlord will review your profile.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5A2A9A)),
            child: const Text('Apply Now', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // 2. Show Loading
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: Color(0xFF5A2A9A))),
    );

    try {
      // 3. Call API
      final result = await TenantApiService.applyForProperty(propertyId);
      
      // 4. Hide Loading
      if (!mounted) return;
      Navigator.pop(context); // Pop loading dialog

      // 5. Handle Result
      if (result['success'] == true) {
        _showSnackBar('Application submitted successfully!', isError: false);
      } else {
        final errorMsg = result['error']?.toString() ?? 'Failed to apply';
        _showSnackBar(errorMsg, isError: true);
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Pop loading dialog
      _showSnackBar('Error: $e', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red[700] : Colors.green[700],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D19),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        title: const Text('My Rentals', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoading()
          : _errorMessage.isNotEmpty
              ? _buildError()
              : _buildContent(),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFF5A2A9A)),
          SizedBox(height: 20),
          Text('Loading rentals...', style: TextStyle(color: Colors.white70)),
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
            Text(_errorMessage, 
              style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadData,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5A2A9A)),
              child: const Text('Retry', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return RefreshIndicator(
      onRefresh: _loadData,
      backgroundColor: const Color(0xFF1A1A2E),
      color: const Color(0xFF5A2A9A),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_myLease.isNotEmpty) _buildCurrentLease(),
            _buildAvailableProperties(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentLease() {
    final property = _myLease['property'] ?? {};
    final address = property['address'] ?? {};
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Active Lease', 
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1A1A2E), Color(0xFF252540)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF5A2A9A).withOpacity(0.3)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))]
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 50, height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFF5A2A9A).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.home_filled, color: Color(0xFF5A2A9A), size: 28),
                ),
                title: Text(property['description'] ?? 'Property', 
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                subtitle: Text('${address['street'] ?? ''}, ${address['city'] ?? ''}', 
                  style: const TextStyle(color: Colors.white70)),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.green.withOpacity(0.5)),
                  ),
                  child: Text(_myLease['status'] ?? 'Active', 
                    style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ),
              const Divider(color: Colors.white10),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildLeaseDetail('Start Date', _formatDate(_myLease['startDate'])),
                  _buildLeaseDetail('End Date', _formatDate(_myLease['endDate'])),
                  _buildLeaseDetail('Rent', _currencyFormat.format(_myLease['rentAmount'] ?? 0)),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _viewLeaseDetails,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: const Text('View Full Details'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAvailableProperties() {
    if (_availableProperties.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: const Column(
          children: [
            Icon(Icons.house_siding_rounded, size: 48, color: Colors.white24),
            SizedBox(height: 16),
            Text('No new listings found', style: TextStyle(color: Colors.white, fontSize: 16)),
            Text('Check back later for new properties.', style: TextStyle(color: Colors.white54, fontSize: 12)),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Available Properties', 
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 12),
        ..._availableProperties.map((property) => _buildPropertyCard(property)),
      ],
    );
  }

  Widget _buildPropertyCard(Property property) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4, offset: const Offset(0, 2))]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Section
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Container(
              height: 160,
              width: double.infinity,
              color: const Color(0xFF252540),
              child: property.images.isNotEmpty
                ? Image.network(
                    property.images.first,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => const Center(child: Icon(Icons.broken_image, color: Colors.white24)),
                  )
                : const Center(child: Icon(Icons.image, size: 48, color: Colors.white24)),
            ),
          ),
          
          // Details Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(property.description, 
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 14, color: Colors.white54),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text('${property.street}, ${property.city}', 
                                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(_currencyFormat.format(property.rentAmount), 
                      style: const TextStyle(color: Color(0xFF5A2A9A), fontWeight: FontWeight.bold, fontSize: 18)),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Amenities Row
                Row(
                  children: [
                    _buildAmenityBadge(Icons.bed, '${property.bedrooms} Beds'),
                    const SizedBox(width: 8),
                    _buildAmenityBadge(Icons.bathtub, '${property.bathrooms} Baths'),
                    const SizedBox(width: 8),
                    _buildAmenityBadge(Icons.home_work, property.type),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _applyForProperty(property.id),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5A2A9A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Apply Now'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmenityBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.white70),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildLeaseDetail(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ],
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return _dateFormat.format(date);
    } catch (e) {
      return dateString;
    }
  }

  void _viewLeaseDetails() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Lease Details', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDialogRow('Property', _myLease['property']?['description'] ?? 'N/A'),
              _buildDialogRow('Address', '${_myLease['property']?['address']?['street'] ?? ''}'),
              const Divider(color: Colors.white24),
              _buildDialogRow('Rent Amount', _currencyFormat.format(_myLease['rentAmount'] ?? 0)),
              _buildDialogRow('Start Date', _formatDate(_myLease['startDate'])),
              _buildDialogRow('End Date', _formatDate(_myLease['endDate'])),
              _buildDialogRow('Status', _myLease['status'] ?? 'Active'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Color(0xFF5A2A9A))),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          Flexible(
            child: Text(value, 
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}