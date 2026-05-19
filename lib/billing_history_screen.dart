import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
 
class BillingHistoryScreen extends StatelessWidget {
  final String shopId;
  const BillingHistoryScreen({super.key, required this.shopId});
 
  static const Color kOrange = Color(0xFFFF6B00);
  static const Color kNavy = Color(0xFF0D1B3E);
 
  Color _statusColor(String status) {
    switch (status) {
      case 'verified':
        return Colors.green;
      case 'pending':
        return kOrange;
      case 'rejected':
        return Colors.red;
      case 'suspended':
        return Colors.red.shade900;
      default:
        return Colors.grey;
    }
  }
 
  String _statusLabel(String status) {
    switch (status) {
      case 'verified':
        return 'Approved';
      case 'pending':
        return 'Pending Verification';
      case 'rejected':
        return 'Rejected';
      case 'suspended':
        return 'Suspended';
      default:
        return status.toUpperCase();
    }
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: kNavy,
        elevation: 0,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios,
                color: Colors.white, size: 18),
            onPressed: () => Navigator.pop(context)),
        title: const Text('Billing History',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18)),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('billing')
            .where('shopId', isEqualTo: shopId)
            .orderBy('year', descending: true)
            .orderBy('month', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
 
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long_outlined,
                      size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text('No billing records found',
                      style: TextStyle(
                          color: Colors.grey.shade500, fontSize: 16)),
                ],
              ),
            );
          }
 
          final docs = snapshot.data!.docs;
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              final status = data['payment_status'] ?? 'pending';
              final color = _statusColor(status);
              final label = _statusLabel(status);
              final fee = data['total_platform_fee'] ?? 0;
              final monthLabel = data['month_label'] ?? 'Month';
              final receiptUrl = data['receipt_url'];
              final rejectionReason = data['rejection_reason'];
 
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 3))
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(monthLabel,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Color(0xFF0D1B3E))),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                              border:
                                  Border.all(color: color.withOpacity(0.4)),
                            ),
                            child: Text(label,
                                style: TextStyle(
                                    color: color,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      const SizedBox(height: 12),
                      _infoRow('Platform Fee', 'Rs. $fee'),
                      _infoRow('Payment Method',
                          data['payment_method'] ?? '-'),
                      if (data['transaction_id'] != null)
                        _infoRow('Transaction ID',
                            data['transaction_id'] ?? '-'),
                      if (data['submitted_at'] != null)
                        _infoRow(
                            'Submitted', _formatTs(data['submitted_at'])),
                      if (data['verified_at'] != null)
                        _infoRow(
                            'Verified', _formatTs(data['verified_at'])),
 
                      // Rejection reason
                      if (status == 'rejected' && rejectionReason != null)
                        Container(
                          margin: const EdgeInsets.only(top: 10),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline,
                                  color: Colors.red.shade600, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Reason: $rejectionReason',
                                  style: TextStyle(
                                      color: Colors.red.shade700,
                                      fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
 
                      // View Receipt Button
                      if (receiptUrl != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () => _showReceiptDialog(
                                  context, receiptUrl),
                              icon: const Icon(Icons.image_outlined,
                                  size: 16),
                              label: const Text('View Receipt'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: kOrange,
                                side: const BorderSide(color: kOrange),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
 
  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(label,
              style:
                  const TextStyle(fontSize: 13, color: Colors.grey)),
          const Spacer(),
          Text(value,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0D1B3E))),
        ],
      ),
    );
  }
 
  String _formatTs(dynamic ts) {
    if (ts == null) return '-';
    if (ts is Timestamp) {
      final dt = ts.toDate();
      return '${dt.day}/${dt.month}/${dt.year}';
    }
    return '-';
  }
 
  void _showReceiptDialog(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.network(url, fit: BoxFit.contain),
        ),
      ),
    );
  }
}
