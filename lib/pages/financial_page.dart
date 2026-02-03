// import 'package:flutter/material.dart';

// class FinancialPage extends StatefulWidget {
//   const FinancialPage({super.key});

//   @override
//   State<FinancialPage> createState() => _FinancialPageState();
// }

// class _FinancialPageState extends State<FinancialPage> {
//   int _selectedTimeframe = 0; // 0: Monthly, 1: Quarterly, 2: Yearly
//   final List<String> _timeframes = ['Monthly', 'Quarterly', 'Yearly'];

//   // Sample financial data
//   final Map<String, double> monthlyRevenue = {
//     'Jan': 12500,
//     'Feb': 13800,
//     'Mar': 15200,
//     'Apr': 14500,
//     'May': 16200,
//     'Jun': 15800,
//   };

//   final List<FinancialTransaction> transactions = [
//     FinancialTransaction(
//       id: '1',
//       type: TransactionType.rent,
//       amount: 2200,
//       description: 'Rent - Sarah Johnson',
//       date: DateTime(2024, 3, 1),
//       status: TransactionStatus.completed,
//       property: '123 Main Street',
//     ),
//     FinancialTransaction(
//       id: '2',
//       type: TransactionType.rent,
//       amount: 5500,
//       description: 'Rent - Michael Chen',
//       date: DateTime(2024, 3, 1),
//       status: TransactionStatus.completed,
//       property: '456 Oak Avenue',
//     ),
//     FinancialTransaction(
//       id: '3',
//       type: TransactionType.expense,
//       amount: -350,
//       description: 'Maintenance - Plumbing Repair',
//       date: DateTime(2024, 3, 5),
//       status: TransactionStatus.completed,
//       property: '789 Pine Road',
//     ),
//     FinancialTransaction(
//       id: '4',
//       type: TransactionType.rent,
//       amount: 1800,
//       description: 'Rent - Emily Davis',
//       date: DateTime(2024, 3, 10),
//       status: TransactionStatus.overdue,
//       property: '789 Pine Road',
//     ),
//     FinancialTransaction(
//       id: '5',
//       type: TransactionType.expense,
//       amount: -120,
//       description: 'Insurance Premium',
//       date: DateTime(2024, 3, 15),
//       status: TransactionStatus.completed,
//       property: 'All Properties',
//     ),
//     FinancialTransaction(
//       id: '6',
//       type: TransactionType.rent,
//       amount: 3200,
//       description: 'Rent - Robert Wilson',
//       date: DateTime(2024, 3, 1),
//       status: TransactionStatus.pending,
//       property: '321 Elm Street',
//     ),
//   ];

//   double get totalRevenue => transactions
//       .where((t) => t.type == TransactionType.rent && t.status == TransactionStatus.completed)
//       .fold(0, (sum, t) => sum + t.amount);

//   double get totalExpenses => transactions
//       .where((t) => t.type == TransactionType.expense && t.status == TransactionStatus.completed)
//       .fold(0, (sum, t) => sum + t.amount);

//   double get netIncome => totalRevenue + totalExpenses;

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFF0D0D19),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Header
//             const Text(
//               'Financial Overview',
//               style: TextStyle(
//                 fontSize: 24,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.white,
//               ),
//             ),
//             const SizedBox(height: 16),

//             // Timeframe Selector
//             _buildTimeframeSelector(),
//             const SizedBox(height: 24),

//             // Financial Summary Cards
//             _buildFinancialSummary(),
//             const SizedBox(height: 24),

//             // Revenue Chart Section
//             _buildRevenueChart(),
//             const SizedBox(height: 24),

//             // Recent Transactions
//             _buildRecentTransactions(),
//           ],
//         ),
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: _addTransaction,
//         backgroundColor: const Color(0xFF5A2A9A),
//         child: const Icon(Icons.add, color: Colors.white),
//       ),
//     );
//   }

//   Widget _buildTimeframeSelector() {
//     return Container(
//       padding: const EdgeInsets.all(4),
//       decoration: BoxDecoration(
//         color: const Color(0xFF1A1A2E),
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Row(
//         children: List.generate(_timeframes.length, (index) {
//           return Expanded(
//             child: GestureDetector(
//               onTap: () => setState(() => _selectedTimeframe = index),
//               child: Container(
//                 padding: const EdgeInsets.symmetric(vertical: 8),
//                 decoration: BoxDecoration(
//                   color: _selectedTimeframe == index
//                       ? const Color(0xFF5A2A9A)
//                       : Colors.transparent,
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: Text(
//                   _timeframes[index],
//                   textAlign: TextAlign.center,
//                   style: TextStyle(
//                     color: _selectedTimeframe == index ? Colors.white : Colors.white70,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//               ),
//             ),
//           );
//         }),
//       ),
//     );
//   }

//   Widget _buildFinancialSummary() {
//     return GridView.count(
//       shrinkWrap: true,
//       physics: const NeverScrollableScrollPhysics(),
//       crossAxisCount: 2,
//       crossAxisSpacing: 16,
//       mainAxisSpacing: 16,
//       children: [
//         _buildSummaryCard('Total Revenue', totalRevenue, Icons.trending_up, Colors.green),
//         _buildSummaryCard('Total Expenses', totalExpenses, Icons.trending_down, Colors.red),
//         _buildSummaryCard('Net Income', netIncome, Icons.account_balance, Colors.blue),
//         _buildSummaryCard('Pending Payments', 5000, Icons.pending, Colors.orange),
//       ],
//     );
//   }

//   Widget _buildSummaryCard(String title, double amount, IconData icon, Color color) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: const Color(0xFF1A1A2E),
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: Colors.white.withOpacity(0.1)),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Container(
//                 padding: const EdgeInsets.all(8),
//                 decoration: BoxDecoration(
//                   color: color.withOpacity(0.2),
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: Icon(icon, size: 20, color: color),
//               ),
//               Text(
//                 '\$${amount.abs().toStringAsFixed(0)}',
//                 style: const TextStyle(
//                   fontSize: 20,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.white,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 12),
//           Text(
//             title,
//             style: TextStyle(
//               color: Colors.white70,
//               fontSize: 14,
//             ),
//           ),
//           const SizedBox(height: 4),
//           Text(
//             amount >= 0 ? 'Positive' : 'Negative',
//             style: TextStyle(
//               color: amount >= 0 ? Colors.green : Colors.red,
//               fontSize: 12,
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildRevenueChart() {
//     final maxRevenue = monthlyRevenue.values.reduce((a, b) => a > b ? a : b);
    
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: const Color(0xFF1A1A2E),
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: Colors.white.withOpacity(0.1)),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text(
//             'Revenue Trend',
//             style: TextStyle(
//               fontSize: 18,
//               fontWeight: FontWeight.bold,
//               color: Colors.white,
//             ),
//           ),
//           const SizedBox(height: 16),
//           SizedBox(
//             height: 200,
//             child: Row(
//               crossAxisAlignment: CrossAxisAlignment.end,
//               mainAxisAlignment: MainAxisAlignment.spaceAround,
//               children: monthlyRevenue.entries.map((entry) {
//                 final height = (entry.value / maxRevenue) * 150;
//                 return Column(
//                   children: [
//                     Text(
//                       '\$${entry.value.toStringAsFixed(0)}',
//                       style: const TextStyle(
//                         color: Colors.white70,
//                         fontSize: 10,
//                       ),
//                     ),
//                     const SizedBox(height: 4),
//                     Container(
//                       width: 20,
//                       height: height,
//                       decoration: BoxDecoration(
//                         gradient: const LinearGradient(
//                           colors: [Color(0xFF5A2A9A), Color(0xFF7B3FE4)],
//                           begin: Alignment.bottomCenter,
//                           end: Alignment.topCenter,
//                         ),
//                         borderRadius: BorderRadius.circular(4),
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     Text(
//                       entry.key,
//                       style: const TextStyle(
//                         color: Colors.white70,
//                         fontSize: 12,
//                       ),
//                     ),
//                   ],
//                 );
//               }).toList(),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildRecentTransactions() {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: const Color(0xFF1A1A2E),
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: Colors.white.withOpacity(0.1)),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text(
//                 'Recent Transactions',
//                 style: TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.white,
//                 ),
//               ),
//               Text(
//                 'View All',
//                 style: TextStyle(
//                   color: Color(0xFF5A2A9A),
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 16),
//           ...transactions.map((transaction) => _buildTransactionItem(transaction)),
//         ],
//       ),
//     );
//   }

//   Widget _buildTransactionItem(FinancialTransaction transaction) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 12),
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: const Color(0xFF0D0D19),
//         borderRadius: BorderRadius.circular(8),
//       ),
//       child: Row(
//         children: [
//           Container(
//             width: 40,
//             height: 40,
//             decoration: BoxDecoration(
//               color: _getTransactionColor(transaction.type).withOpacity(0.2),
//               borderRadius: BorderRadius.circular(8),
//             ),
//             child: Icon(
//               _getTransactionIcon(transaction.type),
//               size: 20,
//               color: _getTransactionColor(transaction.type),
//             ),
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   transaction.description,
//                   style: const TextStyle(
//                     color: Colors.white,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   transaction.property,
//                   style: TextStyle(
//                     color: Colors.white70,
//                     fontSize: 12,
//                   ),
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   _formatDate(transaction.date),
//                   style: TextStyle(
//                     color: Colors.white54,
//                     fontSize: 11,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.end,
//             children: [
//               Text(
//                 '\$${transaction.amount.abs().toStringAsFixed(0)}',
//                 style: TextStyle(
//                   color: transaction.amount >= 0 ? Colors.green : Colors.red,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               const SizedBox(height: 4),
//               Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
//                 decoration: BoxDecoration(
//                   color: _getStatusColor(transaction.status).withOpacity(0.2),
//                   borderRadius: BorderRadius.circular(4),
//                   border: Border.all(color: _getStatusColor(transaction.status)),
//                 ),
//                 child: Text(
//                   transaction.status.displayName,
//                   style: TextStyle(
//                     color: _getStatusColor(transaction.status),
//                     fontSize: 10,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Color _getTransactionColor(TransactionType type) {
//     switch (type) {
//       case TransactionType.rent:
//         return Colors.green;
//       case TransactionType.expense:
//         return Colors.red;
//     }
//   }

//   IconData _getTransactionIcon(TransactionType type) {
//     switch (type) {
//       case TransactionType.rent:
//         return Icons.payment;
//       case TransactionType.expense:
//         return Icons.money_off;
//     }
//   }

//   Color _getStatusColor(TransactionStatus status) {
//     switch (status) {
//       case TransactionStatus.completed:
//         return Colors.green;
//       case TransactionStatus.pending:
//         return Colors.orange;
//       case TransactionStatus.overdue:
//         return Colors.red;
//     }
//   }

//   String _formatDate(DateTime date) {
//     return '${date.month}/${date.day}/${date.year}';
//   }

//   void _addTransaction() {
//     // TODO: Implement add transaction functionality
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(
//         content: Text('Add Transaction functionality coming soon!'),
//         backgroundColor: Color(0xFF5A2A9A),
//       ),
//     );
//   }
// }

// // ====================================================================
// // FINANCIAL TRANSACTION MODEL
// // ====================================================================

// class FinancialTransaction {
//   final String id;
//   final TransactionType type;
//   final double amount;
//   final String description;
//   final DateTime date;
//   final TransactionStatus status;
//   final String property;

//   FinancialTransaction({
//     required this.id,
//     required this.type,
//     required this.amount,
//     required this.description,
//     required this.date,
//     required this.status,
//     required this.property,
//   });
// }

// // ====================================================================
// // TRANSACTION TYPE ENUM
// // ====================================================================

// enum TransactionType {
//   rent('Rent'),
//   expense('Expense');

//   const TransactionType(this.displayName);
//   final String displayName;
// }

// // ====================================================================
// // TRANSACTION STATUS ENUM
// // ====================================================================

// enum TransactionStatus {
//   completed('Completed'),
//   pending('Pending'),
//   overdue('Overdue');

//   const TransactionStatus(this.displayName);
//   final String displayName;
// }