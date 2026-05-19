import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
 
class VerificationDetailsScreen extends StatefulWidget {
  final String billingId;
  final Map<String, dynamic> billingData;
  final String shopId;
  final String shopName;
 
  const VerificationDetailsScreen({
    super.key,
    required this.billingId,
    required this.billingData,
    required this.shopId,
    required this.shopName,
  });
 
  @override
  State<VerificationDetailsScreen> createState() =>
      _VerificationDetailsScreenState();
}
 
class _VerificationDetailsScreenState
    extends State<VerificationDetailsScreen> {
  static const Color kOrange = Color(0xFFFF6B00);
  static const Color kNavy = Color(0xFF0D1B3E);
 
  bool _processing = false;
  String? _selectedRejectionReason;
 
  final _rejectionReasons = [
    'Fake Receipt Uploaded',
    'Blurry Screenshot',
    'Incomplete Payment',
    'Invalid Transaction ID',
  ];
 
  Future<void> _approvePayment() async {
    setState(() => _processing = true);
    try {
      await FirebaseFirestore.instance
          .collection('billing')
          .doc(widget.billingId)
          .update({
        'payment_status': 'verified',
        'verified_at': FieldValue.serverTimestamp(),
      });
 
      // Reactivate shop
      await FirebaseFirestore.instance
          .collection('shops')
          .doc(widget.shopId)
          .update({'status': 'verified'});
 
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Payment approved! Shop reactivated.'),
          backgroundColor: Colors.green,
        ));
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _processing = false);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')));
    }
  }
 
  Future<void> _rejectPayment() async {
    if (_selectedRejectionReason == null) {
      _showRejectionDialog();
      return;
    }
    setState(() => _processing = true);
    try {
      await FirebaseFirestore.instance
          .collection('billing')
          .doc(widget.billingId)
          .update({
        'payment_status': 'rejected',
        'rejection_reason': _selectedRejectionReason,
        'rejected_at': FieldValue.serverTimestamp(),
      });
 
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Payment rejected: $_selectedRejectionReason'),
          backgroundColor: Colors.red,
        ));
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _processing = false);
    }
  }
 
  Future<void> _suspendShop() async {
    setState(() => _processing = true);
    try {
      await FirebaseFirestore.instance
          .collection('shops')
          .doc(widget.shopId)
          .update({'status': 'suspended'});
 
      await FirebaseFirestore.instance
          .collection('billing')
          .doc(widget.billingId)
          .update({'payment_status': 'rejected'});
 
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Shop suspended successfully.'),
          backgroundColor: Colors.red,
        ));
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _processing = false);
    }
  }
 
  void _showRejectionDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Select Rejection Reason',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _rejectionReasons
              .map((r) => ListTile(
                    title: Text(r, style: const TextStyle(fontSize: 14)),
                    leading: Radio<String>(
                      value: r,
                      groupValue: _selectedRejectionReason,
                      activeColor: Colors.red,
                      onChanged: (v) {
                        setState(() => _selectedRejectionReason = v);
                        Navigator.pop(context);
                        _rejectPayment();
                      },
                    ),
                  ))
              .toList(),
        ),
      ),
    );
  }
 
  @override
  Widget build(BuildContext context) {
    final data = widget.billingData;
    final receiptUrl = data['receipt_url'];
    final fee = data['total_platform_fee'] ?? 0;
    final monthLabel = data['month_label'] ?? '-';
    final method = data['payment_method'] ?? '-';
    final txnId = data['transaction_id'] ?? '-';
    final note = data['note'];
 
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: kNavy,
        elevation: 0,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios,
                color: Colors.white, size: 18),
            onPressed: () => Navigator.pop(context)),
        title: const Text('Verification Details',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Shop Details Card
            _buildCard(
              title: 'Shop Details',
              icon: Icons.store,
              children: [
                _infoRow('Shop Name', widget.shopName),
                _infoRow('Shop ID', widget.shopId),
              ],
            ),
            const SizedBox(height: 14),
 
            // Billing Summary Card
            _buildCard(
              title: 'Billing Summary',
              icon: Icons.receipt_long,
              children: [
                _infoRow('Billing Month', monthLabel),
                _infoRow('Platform Fee', 'Rs. $fee'),
                _infoRow('Payment Method', method),
                _infoRow('Transaction ID', txnId),
                if (note != null && note.isNotEmpty)
                  _infoRow('Note', note),
                if (data['submitted_at'] != null)
                  _infoRow('Submitted At', _fmtTs(data['submitted_at'])),
              ],
            ),
            const SizedBox(height: 14),
 
            // Receipt Preview Card
            if (receiptUrl != null)
              _buildCard(
                title: 'Uploaded Receipt',
                icon: Icons.image_outlined,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      receiptUrl,
                      height: 260,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      loadingBuilder: (_, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const SizedBox(
                          height: 200,
                          child: Center(child: CircularProgressIndicator()),
                        );
                      },
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 20),
 
            // Action Buttons
            if (!_processing) ...[
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _approvePayment,
                  icon: const Icon(Icons.check_circle_outline,
                      color: Colors.white),
                  label: const Text('Approve Payment',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _rejectPayment,
                      icon: Icon(Icons.cancel_outlined,
                          color: Colors.red.shade600, size: 18),
                      label: Text('Reject',
                          style: TextStyle(
                              color: Colors.red.shade600,
                              fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.red.shade300),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _suspendShop,
                      icon: const Icon(Icons.block, color: Colors.red, size: 18),
                      label: const Text('Suspend Shop',
                          style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ] else
              const Center(child: CircularProgressIndicator()),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
 
  Widget _buildCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: kOrange, size: 20),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Color(0xFF0D1B3E))),
            ],
          ),
          const Divider(height: 20),
          ...children,
        ],
      ),
    );
  }
 
  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 13, color: Colors.grey)),
          const SizedBox(width: 8),
          Expanded(
              child: Text(value,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0D1B3E)),
                  textAlign: TextAlign.right)),
        ],
      ),
    );
  }
 
  String _fmtTs(dynamic ts) {
    if (ts is Timestamp) {
      final dt = ts.toDate();
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return '-';
  }
}
 
