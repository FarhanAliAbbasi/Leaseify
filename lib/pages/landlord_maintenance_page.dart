import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/landlord_api_service.dart';

class LandlordMaintenancePage extends StatefulWidget {
  const LandlordMaintenancePage({super.key});

  @override
  State<LandlordMaintenancePage> createState() => _LandlordMaintenancePageState();
}

class _LandlordMaintenancePageState extends State<LandlordMaintenancePage> {
  List<dynamic> _requests = [];
  bool _isLoading = true;
  String _errorMessage = '';
  
  // Filters
  String _filterStatus = 'All'; // All, Pending, In Progress, Completed
  String _searchQuery = '';
  final List<String> _statusOptions = ['All', 'Pending', 'In Progress', 'Completed'];

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final data = await LandlordApiService.getMaintenanceRequests();
      if (mounted) {
        setState(() {
          _requests = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load requests: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateRequestStatus(String id, String newStatus) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator(color: Color(0xFF5A2A9A))),
      );

      final success = await LandlordApiService.updateMaintenanceStatus(id, newStatus);
      
      if (mounted) Navigator.pop(context); // Close loading

      if (success) {
        _showSnackBar('Status updated to $newStatus');
        _loadRequests(); // Refresh list
        if (mounted && Navigator.canPop(context)) {
           Navigator.pop(context); // Close details dialog if open
        }
      } else {
        _showSnackBar('Failed to update status', isError: true);
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      _showSnackBar('Error: $e', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: isError ? Colors.red : const Color(0xFF5A2A9A),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  List<dynamic> get filteredRequests {
    return _requests.where((req) {
      final status = req['status']?.toString() ?? 'Pending';
      final description = req['description']?.toString().toLowerCase() ?? '';
      final tenantName = req['tenant']?['name']?.toString().toLowerCase() ?? '';
      // Handle nested property address safely
      String street = '';
      if (req['property'] != null && req['property']['address'] != null) {
        street = req['property']['address']['street']?.toString().toLowerCase() ?? '';
      }
      
      final matchesSearch = _searchQuery.isEmpty || 
          description.contains(_searchQuery.toLowerCase()) ||
          tenantName.contains(_searchQuery.toLowerCase()) ||
          street.contains(_searchQuery.toLowerCase());

      // Normalize status for comparison (e.g., "in_progress" vs "In Progress")
      String normalizedStatus = status.toLowerCase().replaceAll('_', ' ');
      String normalizedFilter = _filterStatus.toLowerCase();
      
      final matchesFilter = _filterStatus == 'All' || normalizedStatus == normalizedFilter;

      return matchesSearch && matchesFilter;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D19),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchAndFilter(),
            Expanded(
              child: _isLoading 
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF5A2A9A)))
                  : _errorMessage.isNotEmpty
                      ? _buildErrorState()
                      : _buildRequestList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.1))),
      ),
      child: const Row(
        children: [
          Icon(Icons.build_circle, color: Color(0xFF5A2A9A), size: 32),
          SizedBox(width: 12),
          Text(
            'Maintenance Requests',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: const Color(0xFF0D0D19),
      child: Column(
        children: [
          TextField(
            onChanged: (val) => setState(() => _searchQuery = val),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search property, tenant, or issue...',
              hintStyle: const TextStyle(color: Colors.white54),
              prefixIcon: const Icon(Icons.search, color: Colors.white54),
              filled: true,
              fillColor: const Color(0xFF1A1A2E),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _statusOptions.map((status) {
                final isSelected = _filterStatus == status;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(status),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _filterStatus = status),
                    backgroundColor: const Color(0xFF1A1A2E),
                    selectedColor: const Color(0xFF5A2A9A),
                    checkmarkColor: Colors.white,
                    labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.white70),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide.none),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestList() {
    final list = filteredRequests;
    
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_turned_in_outlined, size: 64, color: Colors.white.withOpacity(0.2)),
            const SizedBox(height: 16),
            const Text('No requests found', style: TextStyle(color: Colors.white54)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRequests,
      color: const Color(0xFF5A2A9A),
      backgroundColor: const Color(0xFF1A1A2E),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        separatorBuilder: (ctx, i) => const SizedBox(height: 16),
        itemBuilder: (context, index) => _buildRequestCard(list[index]),
      ),
    );
  }

  Widget _buildRequestCard(dynamic request) {
    final status = request['status']?.toString() ?? 'Pending';
    final date = _formatDate(request['createdAt']);
    final tenant = request['tenant']?['name'] ?? 'Unknown Tenant';
    
    // Robust address parsing
    String address = 'Address Unknown';
    if (request['property'] != null && request['property']['address'] != null) {
      final addr = request['property']['address'];
      address = "${addr['street']}, ${addr['city']}";
    }

    return GestureDetector(
      onTap: () => _showRequestDetails(request),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatusBadge(status),
                Text(date, style: const TextStyle(color: Colors.white38, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              request['description'] ?? 'No description',
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            const Divider(color: Colors.white10),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.white54),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(address, style: const TextStyle(color: Colors.white70, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.person, size: 16, color: Colors.white54),
                const SizedBox(width: 4),
                Text(tenant, style: const TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label = status.toUpperCase().replaceAll('_', ' ');
    
    if (label.contains('COMPLETED') || label.contains('RESOLVED')) {
      color = Colors.green;
    } else if (label.contains('PROGRESS')) {
      color = Colors.blue;
    } else {
      color = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(_errorMessage, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadRequests,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5A2A9A)),
            child: const Text('Retry', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showRequestDetails(dynamic request) {
    final status = request['status']?.toString() ?? 'Pending';
    final id = request['_id']?.toString() ?? request['id']?.toString() ?? '';
    
    String propertyAddr = 'N/A';
    if (request['property'] != null && request['property']['address'] != null) {
      propertyAddr = "${request['property']['address']['street'] ?? ''}, ${request['property']['address']['city'] ?? ''}";
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Request Details', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Status', status, isStatus: true),
              const Divider(color: Colors.white10),
              _buildDetailRow('Description', request['description']),
              const SizedBox(height: 16),
              const Text('Property', style: TextStyle(color: Colors.white54, fontSize: 12)),
              const SizedBox(height: 4),
              Text(
                propertyAddr,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
              const SizedBox(height: 16),
              _buildDetailRow('Tenant', request['tenant']?['name']),
              _buildDetailRow('Email', request['tenant']?['email']),
              _buildDetailRow('Date', _formatDate(request['createdAt'])),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Colors.white70)),
          ),
          // Action Buttons based on current status
          // Note: Status strings from API might be "Pending" or "In Progress"
          if (status.toLowerCase() == 'pending')
            ElevatedButton(
              onPressed: () => _updateRequestStatus(id, 'In Progress'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
              child: const Text('Mark In Progress'),
            ),
          if (!status.toLowerCase().contains('completed'))
            ElevatedButton(
              onPressed: () => _updateRequestStatus(id, 'Completed'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
              child: const Text('Mark Complete'),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String? value, {bool isStatus = false}) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 4),
          if (isStatus)
            _buildStatusBadge(value)
          else
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 14)),
        ],
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM d, yyyy • h:mm a').format(date);
    } catch (e) {
      return dateStr;
    }
  }
}