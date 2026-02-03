import 'package:flutter/material.dart';
import '../services/tenant_api_service.dart';

class TenantPaymentPage extends StatefulWidget {
  const TenantPaymentPage({super.key});

  @override
  State<TenantPaymentPage> createState() => _TenantPaymentPageState();
}

class _TenantPaymentPageState extends State<TenantPaymentPage> {
  List<dynamic> _payments = [];
  bool _isLoading = true;
  String _errorMessage = '';
  PaymentStatus _filterStatus = PaymentStatus.all;
  String _searchQuery = '';

  // For payment dialog
  String? _selectedPaymentMethod;
  final List<String> _paymentMethods = [
    'Credit Card',
    'Debit Card',
    'Bank Transfer',
    'UPI',
    'Net Banking'
  ];

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  Future<void> _loadPayments() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final payments = await TenantApiService.getMyPayments();
      if (!mounted) return;
      setState(() {
        _payments = payments;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load payments: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _makeSpecificPayment(dynamic payment) async {
    _selectedPaymentMethod = null;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1A1A2E),
            title: const Text(
              'Make Payment',
              style: TextStyle(color: Colors.white),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Use safe dialog rows (No Expanded)
                  _buildDialogDetailRow('Amount', '\$${_getPaymentAmount(payment)}'),
                  _buildDialogDetailRow('Property', _getPropertyAddress(payment)),
                  _buildDialogDetailRow('Due Date', _formatDateString(payment['dueDate'] ?? payment['paymentDate'])),
                  
                  const SizedBox(height: 20),
                  const Text(
                    'Select Payment Method',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  
                  ..._paymentMethods.map((method) {
                    return RadioListTile<String>(
                      title: Text(
                        method,
                        style: const TextStyle(color: Colors.white70),
                      ),
                      value: method,
                      groupValue: _selectedPaymentMethod,
                      onChanged: (value) => setState(() => _selectedPaymentMethod = value),
                      activeColor: const Color(0xFF5A2A9A),
                    );
                  }).toList(),
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
                onPressed: _selectedPaymentMethod == null
                    ? null
                    : () async {
                        Navigator.pop(context);
                        await _processPayment(payment, _selectedPaymentMethod!);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5A2A9A),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Confirm Payment'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _processPayment(dynamic payment, String method) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final paymentId = payment['_id']?.toString() ?? payment['id']?.toString();
      if (paymentId == null) {
        _showSnackBar('Payment ID not found');
        return;
      }

      final success = await TenantApiService.makePayment(paymentId, method);
      
      if (success) {
        _showSnackBar('Payment successful!');
        await _loadPayments(); // Refresh list
      } else {
        _showSnackBar('Payment failed. Please try again.');
      }
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _viewReceipt(dynamic payment) async {
    final paymentId = payment['_id']?.toString() ?? payment['id']?.toString();
    if (paymentId == null) {
      _showSnackBar('Receipt not available');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final receiptUrl = await TenantApiService.getPaymentReceipt(paymentId);
      
      if (receiptUrl != null && receiptUrl.isNotEmpty) {
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF1A1A2E),
            title: const Text('Payment Receipt', style: TextStyle(color: Colors.white)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDialogDetailRow('Payment ID', paymentId),
                  _buildDialogDetailRow('Amount', '\$${_getPaymentAmount(payment)}'),
                  _buildDialogDetailRow('Date', _formatDateString(payment['paymentDate'])),
                  _buildDialogDetailRow('Method', payment['method'] ?? 'Online'),
                  
                  if (receiptUrl.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text('Receipt:', style: TextStyle(color: Colors.white70, fontSize: 14)),
                    const SizedBox(height: 8),
                    SelectableText(
                      receiptUrl,
                      style: const TextStyle(color: Color(0xFF5A2A9A), decoration: TextDecoration.underline),
                    ),
                  ],
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
      } else {
        _showSnackBar('Receipt not available for this payment');
      }
    } catch (e) {
      _showSnackBar('Failed to load receipt: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<dynamic> get filteredPayments {
    return _payments.where((payment) {
      final matchesSearch = _searchQuery.isEmpty ||
          (_getPropertyAddress(payment).toLowerCase().contains(_searchQuery.toLowerCase())) ||
          ((payment['method'] ?? '').toString().toLowerCase().contains(_searchQuery.toLowerCase()));
      
      final status = _getPaymentStatus(payment);
      final matchesFilter = _filterStatus == PaymentStatus.all || status == _filterStatus;
      
      return matchesSearch && matchesFilter;
    }).toList();
  }

  // --- UPDATED LOGIC: ALL PAYMENTS ARE TREATED AS PAID ---
  PaymentStatus _getPaymentStatus(dynamic payment) {
    // Force all payments to show as Paid, effectively removing Overdue and Pending statuses
    return PaymentStatus.paid;
  }

  double get totalPaidThisYear {
    return _payments.where((p) {
      final status = _getPaymentStatus(p);
      if (status != PaymentStatus.paid || p['paymentDate'] == null) return false;
      try {
        return DateTime.parse(p['paymentDate']).year == DateTime.now().year;
      } catch (_) {
        return false;
      }
    }).fold(0.0, (sum, p) {
      final amount = p['amount'];
      if (amount is int) return sum + amount.toDouble();
      if (amount is double) return sum + amount;
      if (amount is String) return sum + (double.tryParse(amount) ?? 0.0);
      return sum;
    });
  }

  String _getPropertyAddress(dynamic payment) {
    final property = payment['property'];
    if (property == null || property is! Map) return 'Property Info N/A';
    
    final address = property['address'];
    if (address == null || address is! Map) return property['description'] ?? 'Property';

    final street = address['street'] ?? '';
    final city = address['city'] ?? '';
    
    if (street.isNotEmpty && city.isNotEmpty) {
      return '$street, $city'.trim();
    } else {
      return street.isNotEmpty ? street : (property['description'] ?? 'Property');
    }
  }

  String _getPaymentAmount(dynamic payment) {
    final amount = payment['amount'];
    if (amount == null) return '0.00';
    
    if (amount is int) return amount.toStringAsFixed(2);
    if (amount is double) return amount.toStringAsFixed(2);
    if (amount is String) {
      final parsed = double.tryParse(amount);
      return parsed?.toStringAsFixed(2) ?? '0.00';
    }
    
    return '0.00';
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF5A2A9A),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pendingPayments = _payments.where((p) => _getPaymentStatus(p) == PaymentStatus.pending).toList();
    final overduePayments = _payments.where((p) => _getPaymentStatus(p) == PaymentStatus.overdue).toList();
    
    final upcomingPayment = pendingPayments.isNotEmpty ? pendingPayments.first : 
                          overduePayments.isNotEmpty ? overduePayments.first : null;

    final paidCount = _payments.where((p) => _getPaymentStatus(p) == PaymentStatus.paid).length;
    
    final totalPaid = _payments.where((p) => _getPaymentStatus(p) == PaymentStatus.paid)
      .fold(0.0, (sum, p) {
         final amount = p['amount'];
         if (amount is int) return sum + amount.toDouble();
         if (amount is double) return sum + amount;
         if (amount is String) return sum + (double.tryParse(amount) ?? 0.0);
         return sum;
      });

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D19),
      body: SafeArea(
        child: _isLoading
            ? _buildLoading()
            : _errorMessage.isNotEmpty
                ? _buildError()
                : RefreshIndicator(
                    onRefresh: _loadPayments,
                    backgroundColor: const Color(0xFF1A1A2E),
                    color: const Color(0xFF5A2A9A),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        children: [
                          _buildHeader(upcomingPayment, paidCount, totalPaid),
                          _buildSearchFilterBar(),
                          _buildPaymentsList(),
                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (upcomingPayment != null) {
            _makeSpecificPayment(upcomingPayment);
          } else {
            _showSnackBar('No pending payments');
          }
        },
        backgroundColor: const Color(0xFF5A2A9A),
        child: const Icon(Icons.payment, color: Colors.white),
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
          Text('Loading payments...', style: TextStyle(color: Colors.white70)),
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
            Text(_errorMessage, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadPayments,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5A2A9A)),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(dynamic upcomingPayment, int paidCount, double totalPaid) {
    final isOverdue = upcomingPayment != null && _getPaymentStatus(upcomingPayment) == PaymentStatus.overdue;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(color: Color(0xFF1A1A2E)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Payment History', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 8),
          const Text('Manage your rent payments', style: TextStyle(color: Colors.white70, fontSize: 16)),
          const SizedBox(height: 16),
          
          if (upcomingPayment != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isOverdue ? [Colors.red[700]!, Colors.red[900]!] : [const Color(0xFF5A2A9A), const Color(0xFF7B3FE4)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(isOverdue ? 'Overdue Payment' : 'Next Payment Due', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text('\$${_getPaymentAmount(upcomingPayment).split('.')[0]}', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(_getPropertyAddress(upcomingPayment), style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isOverdue ? Colors.red.withOpacity(0.2) : Colors.green.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isOverdue ? Colors.red : Colors.green),
                        ),
                        child: Text(isOverdue ? 'OVERDUE' : 'Due now', style: TextStyle(color: isOverdue ? Colors.white : Colors.green, fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ],
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0D0D19),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white30),
              ),
              child: const Column(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 48),
                  SizedBox(height: 12),
                  Text('All payments are up to date!', style: TextStyle(color: Colors.white, fontSize: 16)),
                ],
              ),
            ),
          
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Paid', paidCount.toString(), Icons.check_circle),
              _buildStatItem('Total Paid', '\$${totalPaid.toStringAsFixed(0)}', Icons.attach_money),
              _buildStatItem('YTD', '\$${totalPaidThisYear.toStringAsFixed(0)}', Icons.calendar_today),
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
          decoration: BoxDecoration(color: const Color(0xFF5A2A9A), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 20, color: Colors.white),
        ),
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
              hintText: 'Search payments...',
              hintStyle: const TextStyle(color: Colors.white54),
              prefixIcon: const Icon(Icons.search, color: Colors.white70),
              filled: true,
              fillColor: const Color(0xFF1A1A2E),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
            ),
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: PaymentStatus.values.map((status) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(status.displayName, style: TextStyle(color: _filterStatus == status ? Colors.white : Colors.white70)),
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

  Widget _buildPaymentsList() {
    final filtered = filteredPayments;

    if (filtered.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        height: 200,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.payment, size: 64, color: Colors.white.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty ? 'No payments found' : 'No payments match your search',
              style: const TextStyle(color: Colors.white70, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: filtered.map((payment) => 
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: _buildPaymentCard(payment),
        )
      ).toList(),
    );
  }

  Widget _buildPaymentCard(dynamic payment) {
    final status = _getPaymentStatus(payment);
    final hasReceipt = payment['receiptUrl'] != null && payment['receiptUrl'].toString().isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          ListTile(
            leading: Container(
              width: 60, height: 60,
              decoration: BoxDecoration(color: _getStatusColor(status), borderRadius: BorderRadius.circular(8)),
              child: Icon(_getStatusIcon(status), color: Colors.white, size: 24),
            ),
            title: Text(_getPropertyAddress(payment), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ID: ${(payment['_id'] ?? payment['id'] ?? '').toString().substring(0, 8)}...', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 4),
                Text('Date: ${_formatDateString(payment['paymentDate'] ?? payment['dueDate'])}', style: const TextStyle(color: Colors.white54, fontSize: 11)),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('\$${_getPaymentAmount(payment).split('.')[0]}', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _getStatusColor(status)),
                  ),
                  child: Text(status.displayName.toUpperCase(), style: TextStyle(color: _getStatusColor(status), fontSize: 10, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          Divider(color: Colors.white.withOpacity(0.1), height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildExpandedDetailItem('Method', payment['method'] ?? 'Online'),
                    _buildExpandedDetailItem('Amount', '\$${_getPaymentAmount(payment)}'),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (hasReceipt && status == PaymentStatus.paid) ...[
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _viewReceipt(payment),
                          icon: const Icon(Icons.receipt, size: 16),
                          label: const Text('Receipt'),
                          style: OutlinedButton.styleFrom(foregroundColor: Colors.white70, side: BorderSide(color: Colors.white.withOpacity(0.3))),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (status != PaymentStatus.paid) ...[
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _makeSpecificPayment(payment),
                          icon: const Icon(Icons.payment, size: 16),
                          label: const Text('Pay Now'),
                          style: ElevatedButton.styleFrom(backgroundColor: status == PaymentStatus.overdue ? Colors.red : const Color(0xFF5A2A9A), foregroundColor: Colors.white),
                        ),
                      ),
                    ] else ...[
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _viewReceipt(payment),
                          icon: const Icon(Icons.info, size: 16),
                          label: const Text('Details'),
                          style: OutlinedButton.styleFrom(foregroundColor: Colors.white70, side: BorderSide(color: Colors.white.withOpacity(0.3))),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildExpandedDetailItem(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildDialogDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 14)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Color _getStatusColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.paid: return Colors.green;
      case PaymentStatus.pending: return Colors.orange;
      case PaymentStatus.overdue: return Colors.red;
      case PaymentStatus.all: return Colors.grey;
    }
  }

  IconData _getStatusIcon(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.paid: return Icons.check_circle;
      case PaymentStatus.pending: return Icons.pending;
      case PaymentStatus.overdue: return Icons.warning;
      case PaymentStatus.all: return Icons.payment;
    }
  }

  String _formatDateString(dynamic date) {
    if (date == null) return 'N/A';
    final dateStr = date.toString();
    try {
      final dateTime = DateTime.parse(dateStr);
      return '${dateTime.month}/${dateTime.day}/${dateTime.year}';
    } catch (e) {
      return dateStr;
    }
  }
}

enum PaymentStatus {
  all('All'),
  paid('Paid'),
  pending('Pending'),
  overdue('Overdue');

  const PaymentStatus(this.displayName);
  final String displayName;
}