import 'package:flutter/material.dart';
import '../services/tenant_api_service.dart';

class MaintenancePage extends StatefulWidget {
  const MaintenancePage({super.key});

  @override
  State<MaintenancePage> createState() => _MaintenancePageState();
}

class _MaintenancePageState extends State<MaintenancePage> {
  List<dynamic> _maintenanceRequests = [];
  bool _isLoading = true;
  String _errorMessage = '';
  MaintenanceStatus _filterStatus = MaintenanceStatus.all;
  String _searchQuery = '';

  // For new request dialog
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadMaintenanceRequests();
  }

  Future<void> _loadMaintenanceRequests() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final requests = await TenantApiService.getMyMaintenanceRequests();
      setState(() {
        _maintenanceRequests = requests;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load maintenance requests: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _submitNewRequest() async {
    if (_descriptionController.text.isEmpty) {
      _showSnackBar('Please enter a description');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await TenantApiService.createMaintenanceRequest(
        _descriptionController.text,
      );

      if (success) {
        _showSnackBar('Maintenance request submitted successfully!');
        _descriptionController.clear();
        Navigator.pop(context); // Close dialog
        await _loadMaintenanceRequests(); // Refresh list
      } else {
        _showSnackBar('Failed to submit request. Please try again.');
      }
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<dynamic> get filteredRequests {
    return _maintenanceRequests.where((request) {
      final matchesSearch = _searchQuery.isEmpty ||
          (request['description']?.toString().toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      
      final matchesFilter = _filterStatus == MaintenanceStatus.all ||
          _getRequestStatus(request['status']) == _filterStatus;
      
      return matchesSearch && matchesFilter;
    }).toList();
  }

  MaintenanceStatus _getRequestStatus(String? status) {
    if (status == null) return MaintenanceStatus.submitted;
    
    switch (status.toLowerCase()) {
      case 'in_progress':
      case 'in progress':
        return MaintenanceStatus.inProgress;
      case 'completed':
      case 'resolved':
        return MaintenanceStatus.completed;
      default:
        return MaintenanceStatus.submitted;
    }
  }

  void _showSnackBar(String message) {
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
    );
  }

  void _showNewRequestDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text(
          'New Maintenance Request',
          style: TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Describe the issue',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _descriptionController,
                maxLines: 4,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'e.g., Kitchen faucet is leaking, AC not cooling...',
                  hintStyle: const TextStyle(color: Colors.white54),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.white30),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF5A2A9A)),
                  ),
                  filled: true,
                  fillColor: const Color(0xFF0D0D19),
                ),
              ),
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
            onPressed: _isLoading ? null : _submitNewRequest,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5A2A9A),
              foregroundColor: Colors.white,
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Submit Request'),
          ),
        ],
      ),
    );
  }

  void _showRequestDetails(dynamic request) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text(
          'Request Details',
          style: TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getStatusColor(_getRequestStatus(request['status'])).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _getStatusColor(_getRequestStatus(request['status'])),
                  ),
                ),
                child: Text(
                  request['status']?.toString().toUpperCase() ?? 'SUBMITTED',
                  style: TextStyle(
                    color: _getStatusColor(_getRequestStatus(request['status'])),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Description
              const Text(
                'Description',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                request['description'] ?? 'No description',
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
              const SizedBox(height: 16),
              
              // Details
              const Text(
                'Details',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              _buildDetailItem('Request ID', request['id']?.toString() ?? 'N/A'),
              _buildDetailItem('Submitted', _formatDate(request['createdAt'])),
              if (request['updatedAt'] != null)
                _buildDetailItem('Last Updated', _formatDate(request['updatedAt'])),
              
              // Notes (if any)
              if (request['notes'] != null && request['notes'].isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Notes',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D0D19),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    request['notes'],
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(color: Color(0xFF5A2A9A)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D19),
      body: Column(
        children: [
          // Header Section
          _buildHeader(),
          
          // Search and Filter Section
          _buildSearchFilterBar(),
          
          // Maintenance Requests List
          Expanded(
            child: _isLoading
                ? _buildLoading()
                : _errorMessage.isNotEmpty
                    ? _buildError()
                    : _buildMaintenanceList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showNewRequestDialog,
        backgroundColor: const Color(0xFF5A2A9A),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFF5A2A9A)),
          SizedBox(height: 20),
          Text(
            'Loading maintenance requests...',
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
              onPressed: _loadMaintenanceRequests,
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

  Widget _buildHeader() {
    final pendingRequests = _maintenanceRequests.where((r) => 
      _getRequestStatus(r['status']) == MaintenanceStatus.submitted ||
      _getRequestStatus(r['status']) == MaintenanceStatus.inProgress).length;
    
    final completedRequests = _maintenanceRequests.where((r) => 
      _getRequestStatus(r['status']) == MaintenanceStatus.completed).length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A2E),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Maintenance',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Track and request maintenance issues',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Active', pendingRequests.toString(), Icons.build),
              _buildStatItem('Completed', completedRequests.toString(), Icons.check_circle),
              _buildStatItem('Total', _maintenanceRequests.length.toString(), Icons.list),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF5A2A9A),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: Colors.white),
        ),
        const SizedBox(height: 4),
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

  Widget _buildSearchFilterBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: const Color(0xFF0D0D19),
      child: Column(
        children: [
          // Search Bar
          TextField(
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: 'Search maintenance requests...',
              hintStyle: const TextStyle(color: Colors.white54),
              prefixIcon: const Icon(Icons.search, color: Colors.white70),
              filled: true,
              fillColor: const Color(0xFF1A1A2E),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 12),
          
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: MaintenanceStatus.values.map((status) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(
                      status.displayName,
                      style: TextStyle(
                        color: _filterStatus == status ? Colors.white : Colors.white70,
                      ),
                    ),
                    selected: _filterStatus == status,
                    onSelected: (selected) => setState(() => _filterStatus = status),
                    backgroundColor: const Color(0xFF1A1A2E),
                    selectedColor: const Color(0xFF5A2A9A),
                    checkmarkColor: Colors.white,
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaintenanceList() {
    final filteredRequests = this.filteredRequests;

    if (filteredRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.build, size: 64, color: Colors.white.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty ? 'No maintenance requests' : 'No requests match your search',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the + button to submit a new request',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMaintenanceRequests,
      backgroundColor: const Color(0xFF1A1A2E),
      color: const Color(0xFF5A2A9A),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredRequests.length,
        itemBuilder: (context, index) {
          final request = filteredRequests[index];
          return _buildMaintenanceCard(request);
        },
      ),
    );
  }

  Widget _buildMaintenanceCard(dynamic request) {
    final status = _getRequestStatus(request['status']);
    final createdAt = request['createdAt'] != null 
        ? DateTime.parse(request['createdAt'])
        : DateTime.now();
    final daysAgo = DateTime.now().difference(createdAt).inDays;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          // Request Header
          ListTile(
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFF5A2A9A),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.build,
                color: Colors.white,
                size: 24,
              ),
            ),
            title: Text(
              'Maintenance Request',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  'Submitted ${daysAgo == 0 ? 'today' : '$daysAgo days ago'}',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getStatusColor(status).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _getStatusColor(status)),
              ),
              child: Text(
                status.displayName,
                style: TextStyle(
                  color: _getStatusColor(status),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          // Divider
          Divider(color: Colors.white.withOpacity(0.1), height: 1),

          // Request Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Description
                Text(
                  request['description'] ?? 'No description provided',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),

                // Details Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildDetailItem('Request ID', '#${request['id']?.toString().substring(0, 8) ?? 'N/A'}'),
                    _buildDetailItem('Submitted', _formatDate(request['createdAt'])),
                  ],
                ),

                // Action Buttons
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _showRequestDetails(request),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white70,
                          side: BorderSide(color: Colors.white.withOpacity(0.3)),
                        ),
                        child: const Text('View Details'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _showSnackBar('Feature coming soon!'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5A2A9A),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Contact'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(MaintenanceStatus status) {
    switch (status) {
      case MaintenanceStatus.submitted:
        return Colors.orange;
      case MaintenanceStatus.inProgress:
        return Colors.blue;
      case MaintenanceStatus.completed:
        return Colors.green;
      case MaintenanceStatus.all:
        return Colors.grey;
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Invalid date';
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _noteController.dispose();
    super.dispose();
  }
}

// ====================================================================
// MAINTENANCE STATUS ENUM
// ====================================================================

enum MaintenanceStatus {
  all('All'),
  submitted('Submitted'),
  inProgress('In Progress'),
  completed('Completed');

  const MaintenanceStatus(this.displayName);
  final String displayName;
}