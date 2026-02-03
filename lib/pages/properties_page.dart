import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/landlord_api_service.dart';

class PropertiesPage extends StatefulWidget {
  const PropertiesPage({super.key});

  @override
  State<PropertiesPage> createState() => _PropertiesPageState();
}

class _PropertiesPageState extends State<PropertiesPage> {
  List<dynamic> _properties = [];
  int _totalProperties = 0;
  int _occupiedProperties = 0;
  int _vacantProperties = 0;
  double _totalMonthlyRevenue = 0;
  
  bool _isLoading = true;
  bool _isRefreshing = false;
  
  // Filter states
  String _filterStatus = 'All';
  String _searchQuery = '';
  String _selectedType = 'All';
  
  // Pagination
  int _currentPage = 1;
  int _totalPages = 1;
  
  final List<String> _statusOptions = ['All', 'Occupied', 'Vacant', 'Maintenance'];
  final List<String> _typeOptions = ['All', 'House', 'Apartment', 'Condo', 'Townhouse', 'Studio'];
  
  bool _isShowingSnackBar = false;

  @override
  void initState() {
    super.initState();
    _loadProperties();
  }

  Future<void> _loadProperties({int page = 1}) async {
    if (!_isRefreshing) {
      setState(() => _isLoading = true);
    }
    
    try {
      // Use the existing getProperties method from your service
      // Note: Your service returns List<dynamic>, not a Map with pagination metadata yet.
      // We adapt the UI to handle the List directly.
      final data = await LandlordApiService.getProperties(limit: 100); 
      
      if (mounted) {
        setState(() {
          _properties = data;
          // Mocking pagination since current API returns a simple list
          _currentPage = 1;
          _totalPages = 1;
          _totalProperties = data.length;
          
          _calculateStats();
          
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    } catch (e) {
      print('Error loading properties: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    }
  }

  void _calculateStats() {
    int occupied = 0;
    int vacant = 0;
    double revenue = 0;
    
    for (var property in _properties) {
      final status = (property['status'] ?? '').toString();
      final rent = (property['rentAmount'] ?? 0).toDouble();
      
      if (status.toLowerCase() == 'occupied') {
        occupied++;
        revenue += rent;
      } else if (status.toLowerCase() == 'vacant') {
        vacant++;
      }
    }
    
    _occupiedProperties = occupied;
    _vacantProperties = vacant;
    _totalMonthlyRevenue = revenue;
  }

  Future<void> _refreshData() async {
    setState(() => _isRefreshing = true);
    await _loadProperties();
  }

  List<dynamic> _getFilteredProperties() {
    List<dynamic> filtered = List.from(_properties);
    
    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((property) {
        final address = property['address'] ?? {};
        final street = address['street']?.toString().toLowerCase() ?? '';
        final city = address['city']?.toString().toLowerCase() ?? '';
        final description = property['description']?.toString().toLowerCase() ?? '';
        final propertyType = property['propertyType']?.toString().toLowerCase() ?? '';
        
        return street.contains(_searchQuery.toLowerCase()) ||
               city.contains(_searchQuery.toLowerCase()) ||
               description.contains(_searchQuery.toLowerCase()) ||
               propertyType.contains(_searchQuery.toLowerCase());
      }).toList();
    }
    
    // Apply status filter
    if (_filterStatus != 'All') {
      filtered = filtered.where((property) {
        final status = (property['status'] ?? '').toString();
        return status.toLowerCase() == _filterStatus.toLowerCase();
      }).toList();
    }
    
    // Apply type filter
    if (_selectedType != 'All') {
      filtered = filtered.where((property) {
        final propertyType = (property['propertyType'] ?? '').toString();
        return propertyType.toLowerCase() == _selectedType.toLowerCase();
      }).toList();
    }
    
    return filtered;
  }

  void _showSingleSnackBar(String message) {
    if (!_isShowingSnackBar) {
      _isShowingSnackBar = true;
      
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

  void _showPropertyActions(BuildContext context, dynamic property) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.visibility, color: Colors.blue),
                title: const Text('View Details', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _viewPropertyDetails(property);
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.green),
                title: const Text('Edit Property', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _showSingleSnackBar('Edit functionality coming soon!');
                },
              ),
              ListTile(
                leading: const Icon(Icons.switch_account, color: Colors.amber),
                title: const Text('Manage Tenants', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _showSingleSnackBar('Tenant management coming soon!');
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete Property', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation(property);
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteConfirmation(dynamic property) {
    final address = property['address'] ?? {};
    final street = address['street'] ?? 'this property';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Delete Property', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to delete $street? This action cannot be undone.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteProperty(property['_id'] ?? property['id']);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteProperty(String propertyId) async {
    try {
      final success = await LandlordApiService.deleteProperty(propertyId);
      if (success) {
        _showSingleSnackBar('Property deleted successfully');
        await _loadProperties(); // Refresh the list
      } else {
        _showSingleSnackBar('Failed to delete property');
      }
    } catch (e) {
      _showSingleSnackBar('Error deleting property');
    }
  }

  void _viewPropertyDetails(dynamic property) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return PropertyDetailsSheet(property: property);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredProperties = _getFilteredProperties();
    
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D19),
      body: Column(
        children: [
          _buildHeaderStats(),
          _buildSearchFilterBar(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF5A2A9A)))
                : filteredProperties.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _refreshData,
                        color: const Color(0xFF5A2A9A),
                        backgroundColor: const Color(0xFF1A1A2E),
                        child: _buildPropertiesList(filteredProperties),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showSingleSnackBar('Add property functionality coming soon!');
        },
        backgroundColor: const Color(0xFF5A2A9A),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildHeaderStats() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.1))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('My Properties', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Total', _totalProperties.toString(), Icons.home_work),
              _buildStatItem('Occupied', _occupiedProperties.toString(), Icons.people),
              _buildStatItem('Vacant', _vacantProperties.toString(), Icons.home),
              _buildStatItem('Revenue', '\$${_totalMonthlyRevenue.toInt()}', Icons.attach_money),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF5A2A9A)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.white70)),
      ],
    );
  }

  Widget _buildSearchFilterBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: const Color(0xFF0D0D19),
      child: Column(
        children: [
          TextField(
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: 'Search properties...',
              hintStyle: const TextStyle(color: Colors.white54),
              prefixIcon: const Icon(Icons.search, color: Colors.white70),
              filled: true,
              fillColor: const Color(0xFF1A1A2E),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Status Filter
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: const Color(0xFF1A1A2E), borderRadius: BorderRadius.circular(20)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _filterStatus,
                      icon: Icon(Icons.arrow_drop_down, color: Colors.white.withOpacity(0.7)),
                      dropdownColor: const Color(0xFF1A1A2E),
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      onChanged: (newValue) => setState(() => _filterStatus = newValue!),
                      items: _statusOptions.map((status) {
                        return DropdownMenuItem(
                          value: status,
                          child: Row(
                            children: [
                              Container(width: 8, height: 8, decoration: BoxDecoration(color: _getStatusColor(status), shape: BoxShape.circle)),
                              const SizedBox(width: 8),
                              Text(status),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Type Filter
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: const Color(0xFF1A1A2E), borderRadius: BorderRadius.circular(20)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedType,
                      icon: Icon(Icons.arrow_drop_down, color: Colors.white.withOpacity(0.7)),
                      dropdownColor: const Color(0xFF1A1A2E),
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      onChanged: (newValue) => setState(() => _selectedType = newValue!),
                      items: _typeOptions.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Row(
                            children: [
                              Icon(_getTypeIcon(type), size: 16, color: Colors.white70),
                              const SizedBox(width: 8),
                              Text(type),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: const Color(0xFF5A2A9A).withOpacity(0.2), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFF5A2A9A).withOpacity(0.3))),
                  child: Text('${_getFilteredProperties().length} Properties', style: const TextStyle(color: Color(0xFF5A2A9A), fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertiesList(List<dynamic> properties) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: properties.length + (_totalPages > 1 ? 1 : 0),
      itemBuilder: (context, index) {
        if (_totalPages > 1 && index == properties.length) {
          return _buildPagination();
        }
        return _buildPropertyCard(properties[index]);
      },
    );
  }

  Widget _buildPropertyCard(dynamic property) {
    final address = property['address'] ?? {};
    final street = address['street'] ?? '';
    final city = address['city'] ?? '';
    final status = property['status'] ?? 'Vacant';
    final rentAmount = property['rentAmount'] ?? 0;
    final bedrooms = property['bedrooms'] ?? 0;
    final bathrooms = property['bathrooms'] ?? 0;
    final propertyType = property['propertyType'] ?? '';
    final description = property['description'] ?? '';
    final imageUrl = property['imageUrl'] ?? '';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(color: const Color(0xFF1A1A2E), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withOpacity(0.1))),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 60, height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: const Color(0xFF5A2A9A).withOpacity(0.2),
                    image: imageUrl.isNotEmpty ? DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover) : null,
                  ),
                  child: imageUrl.isEmpty ? const Icon(Icons.home, color: Color(0xFF5A2A9A), size: 30) : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(_getTypeIcon(propertyType), size: 16, color: Colors.white70),
                          const SizedBox(width: 6),
                          Text(propertyType, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(color: _getStatusColor(status).withOpacity(0.2), borderRadius: BorderRadius.circular(12), border: Border.all(color: _getStatusColor(status))),
                            child: Text(status, style: TextStyle(color: _getStatusColor(status), fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('$street, $city', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text(description, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(color: Colors.white.withOpacity(0.1), height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Monthly Rent', style: TextStyle(color: Colors.white54, fontSize: 12)),
                        Text('\$$rentAmount', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Row(
                      children: [
                        _buildDetailChip('$bedrooms Beds', Icons.bed),
                        const SizedBox(width: 8),
                        _buildDetailChip('$bathrooms Baths', Icons.bathtub),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _viewPropertyDetails(property),
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.white70, side: BorderSide(color: Colors.white.withOpacity(0.3)), padding: const EdgeInsets.symmetric(vertical: 12)),
                        child: const Text('View Details'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _showPropertyActions(context, property),
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5A2A9A), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
                        child: const Text('Manage'),
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

  Widget _buildDetailChip(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [Icon(icon, size: 14, color: Colors.white70), const SizedBox(width: 4), Text(text, style: const TextStyle(color: Colors.white70, fontSize: 12))],
      ),
    );
  }

  Widget _buildPagination() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(onPressed: _currentPage > 1 ? () => _loadProperties(page: _currentPage - 1) : null, icon: const Icon(Icons.chevron_left, color: Colors.white70)),
          const SizedBox(width: 12),
          Text('Page $_currentPage of $_totalPages', style: const TextStyle(color: Colors.white70)),
          const SizedBox(width: 12),
          IconButton(onPressed: _currentPage < _totalPages ? () => _loadProperties(page: _currentPage + 1) : null, icon: const Icon(Icons.chevron_right, color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120, height: 120,
            decoration: BoxDecoration(color: const Color(0xFF1A1A2E), shape: BoxShape.circle, border: Border.all(color: const Color(0xFF5A2A9A).withOpacity(0.3))),
            child: const Icon(Icons.home_work_outlined, size: 60, color: Color(0xFF5A2A9A)),
          ),
          const SizedBox(height: 24),
          const Text('No Properties Found', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 12),
          Text(_searchQuery.isNotEmpty ? 'Try adjusting your filters' : 'Add your first property to get started', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => _showSingleSnackBar('Add property functionality coming soon!'),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5A2A9A), padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('Add Property', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'occupied': return Colors.green;
      case 'vacant': return Colors.blue;
      case 'maintenance': return Colors.orange;
      default: return Colors.grey;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'house': return Icons.house;
      case 'apartment': return Icons.apartment;
      case 'condo': return Icons.home_work; // Standard icon
      case 'townhouse': return Icons.home_work;
      default: return Icons.home;
    }
  }
}

// Property Details Bottom Sheet
class PropertyDetailsSheet extends StatelessWidget {
  final dynamic property;
  
  const PropertyDetailsSheet({super.key, required this.property});

  @override
  Widget build(BuildContext context) {
    final address = property['address'] ?? {};
    final street = address['street'] ?? '';
    final city = address['city'] ?? '';
    final state = address['state'] ?? '';
    final zipCode = address['zipCode'] ?? '';
    final status = property['status'] ?? 'Vacant';
    final rentAmount = property['rentAmount'] ?? 0;
    final bedrooms = property['bedrooms'] ?? 0;
    final bathrooms = property['bathrooms'] ?? 0;
    final propertyType = property['propertyType'] ?? '';
    final description = property['description'] ?? '';
    final imageUrl = property['imageUrl'] ?? '';
    final isListed = property['isListed'] ?? false;
    
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Property Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.white70)),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            height: 200, width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: const Color(0xFF5A2A9A).withOpacity(0.2),
              image: imageUrl.isNotEmpty ? DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover) : null,
            ),
            child: imageUrl.isEmpty ? const Center(child: Icon(Icons.home, size: 60, color: Color(0xFF5A2A9A))) : null,
          ),
          const SizedBox(height: 20),
          GridView.count(
            crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), childAspectRatio: 3,
            children: [
              _buildDetailItem('Property Type', propertyType, Icons.category),
              _buildDetailItem('Status', status, Icons.circle, color: _getStatusColor(status)),
              _buildDetailItem('Monthly Rent', '\$$rentAmount', Icons.attach_money),
              _buildDetailItem('Listed', isListed ? 'Yes' : 'No', Icons.visibility),
              _buildDetailItem('Bedrooms', '$bedrooms', Icons.bed),
              _buildDetailItem('Bathrooms', '$bathrooms', Icons.bathtub),
            ],
          ),
          const SizedBox(height: 20),
          const Text('Address', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 8),
          Text('$street\n$city, $state $zipCode', style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 20),
          const Text('Description', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 8),
          Text(description, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 30),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () { Navigator.pop(context); },
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.blue, side: BorderSide(color: Colors.blue.withOpacity(0.3)), padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.edit, size: 18), SizedBox(width: 8), Text('Edit')]),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () { Navigator.pop(context); },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5A2A9A), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.people, size: 18), SizedBox(width: 8), Text('Manage Tenants')]),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon, {Color? color}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFF0D0D19), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color ?? Colors.white70),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.5))),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'occupied': return Colors.green;
      case 'vacant': return Colors.blue;
      case 'maintenance': return Colors.orange;
      default: return Colors.grey;
    }
  }
}