import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
 
class UploadReceiptScreen extends StatefulWidget {
  final String shopId;
  final int fee;
  const UploadReceiptScreen(
      {super.key, required this.shopId, required this.fee});
 
  @override
  State<UploadReceiptScreen> createState() => _UploadReceiptScreenState();
}
 
class _UploadReceiptScreenState extends State<UploadReceiptScreen> {
  static const Color kOrange = Color(0xFFFF6B00);
  static const Color kNavy = Color(0xFF0D1B3E);
 
  final _txnCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  String _selectedMethod = 'JazzCash';
  File? _receiptImage;
  bool _uploading = false;
  String? _validationMsg;
 
  final _methods = ['JazzCash', 'Easypaisa', 'Bank Transfer'];
 
  Future<void> _pickImage() async {
    final picked =
        await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (picked != null) {
      setState(() {
        _receiptImage = File(picked.path);
        _validationMsg = null;
      });
    }
  }
 
  Future<void> _submit() async {
    if (_txnCtrl.text.trim().isEmpty) {
      setState(() => _validationMsg = 'Please enter Transaction ID');
      return;
    }
    if (_receiptImage == null) {
      setState(() => _validationMsg = 'Please upload receipt image');
      return;
    }
 
    setState(() => _uploading = true);
 
    try {
      // Upload image to Firebase Storage
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('receipts/${widget.shopId}/${DateTime.now().millisecondsSinceEpoch}.jpg');
 
      final uploadTask = await storageRef.putFile(_receiptImage!);
      final receiptUrl = await uploadTask.ref.getDownloadURL();
 
      final now = DateTime.now();
 
      // Check if billing doc exists for this month
      final billingSnap = await FirebaseFirestore.instance
          .collection('billing')
          .where('shopId', isEqualTo: widget.shopId)
          .where('month', isEqualTo: now.month)
          .where('year', isEqualTo: now.year)
          .limit(1)
          .get();
 
      if (billingSnap.docs.isNotEmpty) {
        // Update existing billing record
        await billingSnap.docs.first.reference.update({
          'receipt_url': receiptUrl,
          'payment_status': 'pending',
          'submitted_at': FieldValue.serverTimestamp(),
          'transaction_id': _txnCtrl.text.trim(),
          'payment_method': _selectedMethod,
          'note': _noteCtrl.text.trim(),
        });
      } else {
        // Create new billing record
        await FirebaseFirestore.instance.collection('billing').add({
          'shopId': widget.shopId,
          'month': now.month,
          'year': now.year,
          'month_label': DateFormat('MMMM yyyy').format(now),
          'total_platform_fee': widget.fee,
          'receipt_url': receiptUrl,
          'payment_status': 'pending',
          'submitted_at': FieldValue.serverTimestamp(),
          'transaction_id': _txnCtrl.text.trim(),
          'payment_method': _selectedMethod,
          'note': _noteCtrl.text.trim(),
        });
      }
 
      // Notify admin
      await FirebaseFirestore.instance.collection('admin_notifications').add({
        'shopId': widget.shopId,
        'type': 'billing_receipt',
        'message':
            'New $_selectedMethod receipt submitted for ${DateFormat('MMMM yyyy').format(now)}. Fee: Rs. ${widget.fee}',
        'fee': widget.fee,
        'month_label': DateFormat('MMMM yyyy').format(now),
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
 
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Receipt submitted for verification!'),
          backgroundColor: Colors.green,
        ));
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _validationMsg = 'Upload failed. Please try again.';
        _uploading = false;
      });
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
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
            onPressed: () => Navigator.pop(context)),
        title: const Text('Upload Receipt',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Payable amount card
            _buildAmountCard(),
            const SizedBox(height: 16),
 
            // Info box
            _buildInfoBox(),
            const SizedBox(height: 16),
 
            // Form card
            _buildFormCard(),
            const SizedBox(height: 16),
 
            // Receipt upload area
            _buildReceiptUpload(),
            const SizedBox(height: 16),
 
            // Validation message
            if (_validationMsg != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade600, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(_validationMsg!,
                            style: TextStyle(
                                color: Colors.red.shade700, fontSize: 13))),
                  ],
                ),
              ),
 
            const SizedBox(height: 20),
 
            // Submit button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _uploading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kOrange,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 4,
                ),
                child: _uploading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Submit For Verification',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
 
  Widget _buildAmountCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6B00), Color(0xFFFF8C42)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFFFF6B00).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.account_balance_wallet, color: Colors.white, size: 36),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Payable Amount',
                  style: TextStyle(color: Colors.white70, fontSize: 13)),
              Text('Rs. ${widget.fee}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
 
  Widget _buildInfoBox() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Receipt must be clear and full payment amount must match the payable amount.',
              style: TextStyle(color: Colors.blue.shade800, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
 
  Widget _buildFormCard() {
    return Container(
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
          const Text('Payment Details',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D1B3E))),
          const SizedBox(height: 16),
 
          // Transaction ID
          _buildTextField(
            controller: _txnCtrl,
            label: 'Transaction ID',
            hint: 'Enter transaction ID',
            icon: Icons.confirmation_number_outlined,
          ),
          const SizedBox(height: 14),
 
          // Payment Method Dropdown
          DropdownButtonFormField<String>(
            value: _selectedMethod,
            decoration: InputDecoration(
              labelText: 'Payment Method',
              prefixIcon:
                  const Icon(Icons.payment, color: Color(0xFFFF6B00)),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: Color(0xFFFF6B00), width: 1.5)),
              filled: true,
              fillColor: const Color(0xFFF8F9FA),
            ),
            items: _methods
                .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                .toList(),
            onChanged: (v) => setState(() => _selectedMethod = v!),
          ),
          const SizedBox(height: 14),
 
          // Optional Note
          _buildTextField(
            controller: _noteCtrl,
            label: 'Note (Optional)',
            hint: 'Any additional info...',
            icon: Icons.note_outlined,
            maxLines: 2,
          ),
        ],
      ),
    );
  }
 
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFFFF6B00)),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: Color(0xFFFF6B00), width: 1.5)),
        filled: true,
        fillColor: const Color(0xFFF8F9FA),
      ),
    );
  }
 
  Widget _buildReceiptUpload() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: double.infinity,
        height: _receiptImage != null ? 220 : 160,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _receiptImage != null
                ? const Color(0xFFFF6B00)
                : Colors.grey.shade300,
            width: _receiptImage != null ? 2 : 1,
            style: BorderStyle.solid,
          ),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: _receiptImage != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(_receiptImage!, fit: BoxFit.cover),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () => setState(() => _receiptImage = null),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                              color: Colors.red, shape: BoxShape.circle),
                          child: const Icon(Icons.close,
                              color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B00).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.upload_file,
                        color: Color(0xFFFF6B00), size: 32),
                  ),
                  const SizedBox(height: 12),
                  const Text('Tap to Upload Receipt',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Color(0xFF0D1B3E))),
                  const SizedBox(height: 4),
                  Text('JPG, PNG supported',
                      style:
                          TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                ],
              ),
      ),
    );
  }
 
  @override
  void dispose() {
    _txnCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }
}
