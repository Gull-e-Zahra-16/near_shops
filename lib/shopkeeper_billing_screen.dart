import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'upload_receipt_screen.dart';
import 'billing_history_screen.dart';
import 'suspended_shop_screen.dart';
 
class ShopkeeperBillingScreen extends StatefulWidget {
  const ShopkeeperBillingScreen({super.key});
 
// shopkeeper_billing_screen.dart

import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class ShopkeeperBillingScreen extends StatefulWidget {
  final String shopId;
  const ShopkeeperBillingScreen({super.key, required this.shopId});

  @override
  State<ShopkeeperBillingScreen> createState() =>
      _ShopkeeperBillingScreenState();
}

class _ShopkeeperBillingScreenState extends State<ShopkeeperBillingScreen> {
  static const Color kOrange = Color(0xFFFF6B00);
  static const Color kNavy = Color(0xFF0D1B3E);
 
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
 
  Map<String, dynamic>? _shopData;
  Map<String, dynamic>? _billingData;
  bool _loading = true;
 
  @override
  void initState() {
    super.initState();
    _loadData();
  }
 
  Future<void> _loadData() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
 
    final shopSnap = await _firestore
        .collection('shops')
        .where('owner_email', isEqualTo: _auth.currentUser!.email)
        .limit(1)
        .get();
 
    if (shopSnap.docs.isEmpty) {
      setState(() => _loading = false);
      return;
    }
 
    final shop = shopSnap.docs.first;
    final shopId = shop.id;
    final now = DateTime.now();
 
    final billingSnap = await _firestore
        .collection('billing')
        .where('shopId', isEqualTo: shopId)
        .where('month', isEqualTo: now.month)
        .where('year', isEqualTo: now.year)
        .limit(1)
        .get();
 
    setState(() {
      _shopData = {'id': shopId, ...shop.data()};
      _billingData = billingSnap.docs.isNotEmpty
          ? billingSnap.docs.first.data()
          : null;
      _loading = false;
    });
  }
 
  String get _billingStatus {
    if (_shopData == null) return 'active';
    final shopStatus = _shopData!['status'] ?? 'verified';
    if (shopStatus == 'suspended') return 'Suspended';
    if (_billingData == null) return 'Active';
    final ps = _billingData!['payment_status'] ?? 'pending';
    if (ps == 'verified') return 'Active';
    if (ps == 'rejected') return 'Overdue';
    return 'Warning';
  }
 
  Color get _statusColor {
    switch (_billingStatus) {
      case 'Active':
        return Colors.green;
      case 'Warning':
        return kOrange;
      case 'Overdue':
        return Colors.red;
      case 'Suspended':
        return Colors.red.shade900;
      default:
        return Colors.green;
    }
  }
 
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
 
    final fee = _billingData?['total_platform_fee'] ?? 0;
    final payStatus = _billingData?['payment_status'] ?? 'pending';
    final monthLabel = _billingData?['month_label'] ??
        DateFormat('MMMM yyyy').format(DateTime.now());
    final shopStatus = _shopData?['status'] ?? 'verified';
 
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: kNavy,
        elevation: 0,
        title: const Text('Billing Dashboard',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadData,
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Shop Info Header
              _buildShopHeader(),
              const SizedBox(height: 16),
 
              // Warning Banner
              if (payStatus == 'pending' && fee > 0)
                _buildWarningBanner(),
 
              if (shopStatus == 'suspended')
                _buildSuspensionBanner(context),
 
              const SizedBox(height: 8),
 
              // Status Chip Row
              _buildStatusChip(),
              const SizedBox(height: 16),
 
              // Billing Summary Cards
              _buildSummaryGrid(fee, monthLabel),
              const SizedBox(height: 20),
 
              // Quick Actions
              _buildQuickActions(context, fee),
              const SizedBox(height: 20),
 
              // Reminder Section
              _buildReminderSection(payStatus, fee),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }
 
  Widget _buildShopHeader() {
  // ── Brand Colors ──
  static const Color primaryNavy = Color(0xFF0E2A47);
  static const Color accentOrange = Color(0xFFFF6A1A);
  static const Color bgColor = Color(0xFFF8FAFC);

  final user = FirebaseAuth.instance.currentUser;
  bool _uploading = false;

  int _cachedTotalOrders = 0;
  double _cachedTotalFee = 0;
  double _cachedTotalSubtotal = 0;
  bool _ordersLoaded = false;

  final int _currentMonth = DateTime.now().month;
  final int _currentYear = DateTime.now().year;

  final List<String> _monthNames = [
    '',
    'January', 'February', 'March', 'April',
    'May', 'June', 'July', 'August',
    'September', 'October', 'November', 'December'
  ];

  String get _monthLabel => '${_monthNames[_currentMonth]} $_currentYear';

  // ── Stream: delivered orders for current month ──
  Stream<QuerySnapshot> _ordersStream() {
    final start = DateTime(_currentYear, _currentMonth, 1);
    final end = DateTime(_currentYear, _currentMonth + 1, 1);

    return FirebaseFirestore.instance
        .collection('orders')
        .where('shopId', isEqualTo: widget.shopId)
        .where('status', isEqualTo: 'delivered')
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('createdAt', isLessThan: Timestamp.fromDate(end))
        .snapshots();
  }

  // ── Stream: billing document for current month ──
  Stream<DocumentSnapshot> _billingStream() {
    final docId = '${widget.shopId}_${_currentYear}_$_currentMonth';
    return FirebaseFirestore.instance
        .collection('billing')
        .doc(docId)
        .snapshots();
  }

  // ── Save/update billing record in Firestore ──
  Future<void> _saveBillingRecord(List<QueryDocumentSnapshot> orders) async {
    final docId = '${widget.shopId}_${_currentYear}_$_currentMonth';

    double totalPlatformFee = 0;
    for (var o in orders) {
      totalPlatformFee +=
          ((o.data() as Map)['platformFee'] ?? 0).toDouble();
    }

    final billingRef =
        FirebaseFirestore.instance.collection('billing').doc(docId);
    final existing = await billingRef.get();

    // Only update if unpaid or rejected (don't overwrite pending/verified)
    if (!existing.exists ||
        existing['payment_status'] == 'unpaid' ||
        existing['payment_status'] == 'rejected') {
      await billingRef.set({
        'shopId': widget.shopId,
        'month': _currentMonth,
        'year': _currentYear,
        'month_label': _monthLabel,
        'total_orders': orders.length,
        'total_platform_fee': totalPlatformFee,
        'payment_status':
            existing.exists ? existing['payment_status'] : 'unpaid',
        'receipt_url':
            existing.exists ? existing['receipt_url'] ?? '' : '',
        'submitted_at':
            existing.exists ? existing['submitted_at'] : null,
        'verified_at': null,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  // ── Upload receipt image to Cloudinary, then update Firestore ──
  Future<void> _uploadReceipt(double totalFee) async {
    final picked =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    setState(() => _uploading = true);

    try {
      // Upload to Cloudinary
      var request = http.MultipartRequest(
          'POST',
          Uri.parse(
              'https://api.cloudinary.com/v1_1/dxzaqavfj/image/upload'));
      request.fields['upload_preset'] = 'nearbuy_preset';
      request.files
          .add(await http.MultipartFile.fromPath('file', picked.path));

      var response = await request.send();

      if (response.statusCode == 200) {
        var jsonRes = jsonDecode(
            String.fromCharCodes(await response.stream.toBytes()));

        final docId =
            '${widget.shopId}_${_currentYear}_$_currentMonth';

        // Update billing doc with receipt URL and pending status
        await FirebaseFirestore.instance
            .collection('billing')
            .doc(docId)
            .set({
          'shopId': widget.shopId,
          'month': _currentMonth,
          'year': _currentYear,
          'month_label': _monthLabel,
          'total_platform_fee': totalFee,
          'receipt_url': jsonRes['secure_url'],
          'payment_status': 'pending_verification',
          'submitted_at': FieldValue.serverTimestamp(),
          'verified_at': null,
        }, SetOptions(merge: true));

        // Notify admin
        await FirebaseFirestore.instance
            .collection('admin_notifications')
            .add({
          'type': 'billing_receipt',
          'shopId': widget.shopId,
          'month_label': _monthLabel,
          'message':
              'New JazzCash receipt submitted for $_monthLabel',
          'createdAt': FieldValue.serverTimestamp(),
          'read': false,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content:
                Text('Receipt submitted! Admin will verify soon.'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Upload failed. Try again.'),
            backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  // ── Payment status banner ──
  Widget _paymentStatusBanner(String status) {
    final map = {
      'pending_verification': (
        Colors.orange.shade50,
        Colors.orange.shade700,
        Icons.hourglass_top_rounded,
        'Receipt submitted. Waiting for admin verification.'
      ),
      'verified': (
        Colors.green.shade50,
        Colors.green.shade700,
        Icons.check_circle_rounded,
        'Payment verified! Your shop is active for next month.'
      ),
      'rejected': (
        Colors.red.shade50,
        Colors.red.shade700,
        Icons.cancel_rounded,
        'Receipt rejected. Re-upload correct JazzCash screenshot.'
      ),
    };

    final entry = map[status];
    final bg = entry?.$1 ?? Colors.blue.shade50;
    final txtColor = entry?.$2 ?? Colors.blue.shade700;
    final icon = entry?.$3 ?? Icons.info_outline;
    final msg = entry?.$4 ??
        'Please pay the platform fee and upload JazzCash receipt.';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D1B3E), Color(0xFF1A3A6B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B00).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.store, color: Color(0xFFFF6B00), size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _shopData?['shop_name'] ?? 'My Shop',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
                Text(
                  _shopData?['shop_category'] ?? '',
                  style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Reg: ${_shopData?['registration_no'] ?? ''}',
                  style: const TextStyle(color: Colors.white70, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
 
  Widget _buildWarningBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        border: Border.all(color: Colors.orange.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.timer_outlined, color: Colors.orange.shade700, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Upload payment receipt within 20 minutes to avoid temporary suspension.',
              style: TextStyle(
                  color: Colors.orange.shade800,
                  fontSize: 13,
                  fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
 
  Widget _buildSuspensionBanner(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => SuspendedShopScreen(shopData: _shopData!))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          border: Border.all(color: Colors.red.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.block, color: Colors.red.shade700, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Your shop is temporarily suspended. Tap to view details.',
                style: TextStyle(
                    color: Colors.red.shade800,
                    fontSize: 13,
                    fontWeight: FontWeight.w600),
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.red.shade400, size: 14),
          ],
        ),
      ),
    );
  }
 
  Widget _buildStatusChip() {
    return Row(
      children: [
        const Text('Billing Status:',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0D1B3E))),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: _statusColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _statusColor.withOpacity(0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                      color: _statusColor, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text(_billingStatus,
                  style: TextStyle(
                      color: _statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }
 
  Widget _buildSummaryGrid(dynamic fee, String monthLabel) {
    final cards = [
      {
        'title': 'Pending Platform Fee',
        'value': 'Rs. $fee',
        'icon': Icons.account_balance_wallet_outlined,
        'color': const Color(0xFFFF6B00)
      },
      {
        'title': 'Billing Month',
        'value': monthLabel,
        'icon': Icons.calendar_month_outlined,
        'color': const Color(0xFF0D1B3E)
      },
      {
        'title': 'Payment Status',
        'value': (_billingData?['payment_status'] ?? 'Pending').toString().toUpperCase(),
        'icon': Icons.payment_outlined,
        'color': Colors.green
      },
      {
        'title': 'Receipt Submitted',
        'value': _billingData?['submitted_at'] != null ? 'Yes' : 'No',
        'icon': Icons.receipt_long_outlined,
        'color': Colors.purple
      },
    ];
 
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.5,
      ),
      itemCount: cards.length,
      itemBuilder: (_, i) {
        final c = cards[i];
        return Container(
          padding: const EdgeInsets.all(14),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: (c['color'] as Color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(c['icon'] as IconData,
                    color: c['color'] as Color, size: 20),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c['value'] as String,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: c['color'] as Color)),
                  Text(c['title'] as String,
                      style: const TextStyle(
                          fontSize: 11, color: Colors.grey)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
 
  Widget _buildQuickActions(BuildContext context, dynamic fee) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Quick Actions',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0D1B3E))),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _actionBtn(
                icon: Icons.upload_file,
                label: 'Upload Receipt',
                color: const Color(0xFFFF6B00),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => UploadReceiptScreen(
                        shopId: _shopData?['id'] ?? '',
                        fee: fee ?? 0),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _actionBtn(
                icon: Icons.history,
                label: 'Billing History',
                color: const Color(0xFF0D1B3E),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        BillingHistoryScreen(shopId: _shopData?['id'] ?? ''),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
 
  Widget _actionBtn(
      {required IconData icon,
      required String label,
      required Color color,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(height: 6),
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12)),
          ],
        ),
      ),
    );
  }
 
  Widget _buildReminderSection(String payStatus, dynamic fee) {
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: txtColor.withOpacity(0.3)),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: txtColor.withOpacity(0.15),
              shape: BoxShape.circle),
          child: Icon(icon, color: txtColor, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(msg,
              style: TextStyle(
                  color: txtColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 13)),
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: primaryNavy,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Monthly Billing',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _ordersStream(),
        builder: (context, ordersSnap) {
          // Cache order totals when data arrives
          if (ordersSnap.hasData) {
            final orders = ordersSnap.data!.docs;
            double fee = 0, subtotal = 0;
            for (var o in orders) {
              final d = o.data() as Map<String, dynamic>;
              fee += (d['platformFee'] ?? 0).toDouble();
              subtotal += (d['subtotal'] ?? 0).toDouble();
            }
            if (!_ordersLoaded ||
                _cachedTotalOrders != orders.length ||
                _cachedTotalFee != fee) {
              _cachedTotalOrders = orders.length;
              _cachedTotalFee = fee;
              _cachedTotalSubtotal = subtotal;
              _ordersLoaded = true;
              if (orders.isNotEmpty) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) _saveBillingRecord(orders);
                });
              }
            }
          }

          if (!_ordersLoaded &&
              ordersSnap.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(
                    color: Color(0xFFFF6A1A)));
          }

          final totalOrders = _cachedTotalOrders;
          final totalFee = _cachedTotalFee;
          final totalSubtotal = _cachedTotalSubtotal;
          final orders = ordersSnap.data?.docs ?? [];

          return StreamBuilder<DocumentSnapshot>(
            stream: _billingStream(),
            builder: (context, billingSnap) {
              final billingData =
                  billingSnap.data?.exists == true
                      ? billingSnap.data!.data() as Map<String, dynamic>
                      : null;
              final paymentStatus =
                  billingData?['payment_status'] ?? 'unpaid';
              final receiptUrl = billingData?['receipt_url'] ?? '';

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // ── Month header card ──
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [primaryNavy, Color(0xFF1A3A5C)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius:
                            BorderRadius.all(Radius.circular(18)),
                      ),
                      child: Row(children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.calendar_month,
                              color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_monthLabel,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold)),
                            const Text('Billing Summary',
                                style: TextStyle(
                                    color: Colors.white60,
                                    fontSize: 13)),
                          ],
                        ),
                      ]),
                    ),
                    const SizedBox(height: 14),

                    // ── Status banner ──
                    _paymentStatusBanner(paymentStatus),
                    const SizedBox(height: 14),

                    // ── Stats row ──
                    Row(children: [
                      Expanded(
                        child: _statCard(
                            'Delivered Orders',
                            '$totalOrders',
                            Icons.shopping_bag_outlined,
                            primaryNavy),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _statCard(
                            'Total Sales',
                            'Rs. ${totalSubtotal.toStringAsFixed(0)}',
                            Icons.trending_up,
                            Colors.green.shade600),
                      ),
                    ]),
                    const SizedBox(height: 12),

                    // ── Platform fee card ──
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: accentOrange,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(children: [
                        const Icon(Icons.account_balance_wallet,
                            color: Colors.white, size: 32),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Platform Fee Due (5%)',
                                style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13)),
                            Text(
                                'Rs. ${totalFee.toStringAsFixed(2)}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold)),
                            const Text(
                                'Pay via JazzCash & upload receipt',
                                style: TextStyle(
                                    color: Colors.white60,
                                    fontSize: 12)),
                          ],
                        ),
                      ]),
                    ),
                    const SizedBox(height: 14),

                    // ── JazzCash payment details card ──
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2))
                        ],
                      ),
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                  color: const Color(0xFF0E2A47)
                                      .withOpacity(0.08),
                                  borderRadius:
                                      BorderRadius.circular(10)),
                              child: const Icon(Icons.payment,
                                  color: primaryNavy, size: 20),
                            ),
                            const SizedBox(width: 10),
                            const Text('JazzCash Payment Details',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: primaryNavy)),
                          ]),
                          Divider(
                              height: 20,
                              color: Colors.grey.shade100),
                          _infoRow('Account Name', 'NearBuy Admin'),
                          const SizedBox(height: 8),
                          _infoRow(
                              'JazzCash Number', '03XX-XXXXXXX'),
                          const SizedBox(height: 8),
                          _infoRow('Amount to Pay',
                              'Rs. ${totalFee.toStringAsFixed(2)}'),
                          const SizedBox(height: 8),
                          _infoRow('Reference',
                              widget.shopId.substring(0, 8)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ── Submitted receipt preview ──
                    if (receiptUrl.isNotEmpty) ...[
                      Container(
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 8)
                            ]),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Submitted Receipt:',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: primaryNavy)),
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(receiptUrl,
                                  width: double.infinity,
                                  height: 200,
                                  fit: BoxFit.cover),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // ── Upload receipt button (only if unpaid or rejected) ──
                    if (paymentStatus == 'unpaid' ||
                        paymentStatus == 'rejected') ...[
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentOrange,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(14)),
                          ),
                          icon: _uploading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2))
                              : const Icon(Icons.upload_file,
                                  color: Colors.white),
                          label: Text(
                              _uploading
                                  ? 'Uploading...'
                                  : 'Upload JazzCash Receipt',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold)),
                          onPressed: _uploading
                              ? null
                              : () => _uploadReceipt(totalFee),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                            'Take screenshot of JazzCash transaction & upload',
                            style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 12)),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // ── Delivered orders list ──
                    if (orders.isNotEmpty) ...[
                      Row(children: [
                        Container(
                          width: 4,
                          height: 18,
                          decoration: BoxDecoration(
                              color: accentOrange,
                              borderRadius: BorderRadius.circular(2)),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                            'Delivered Orders This Month:',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: primaryNavy)),
                      ]),
                      const SizedBox(height: 10),
                      ...orders.map((o) {
                        final d =
                            o.data() as Map<String, dynamic>;
                        Timestamp? ts = d['createdAt'];
                        String dateStr = '';
                        if (ts != null) {
                          final dt = ts.toDate();
                          dateStr =
                              '${dt.day}/${dt.month}  ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
                        }
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius:
                                  BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black
                                        .withOpacity(0.04),
                                    blurRadius: 6)
                              ]),
                          child: ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                  color: const Color(0xFF0E2A47)
                                      .withOpacity(0.07),
                                  borderRadius:
                                      BorderRadius.circular(10)),
                              child: const Icon(
                                  Icons.receipt_long,
                                  color: primaryNavy,
                                  size: 20),
                            ),
                            title: Text(
                                d['customerEmail'] ?? 'Customer',
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: primaryNavy)),
                            subtitle: Text(dateStr,
                                style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 12)),
                            trailing: Column(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              crossAxisAlignment:
                                  CrossAxisAlignment.end,
                              children: [
                                Text(
                                    'Rs. ${(d['totalAmount'] ?? 0).toStringAsFixed(0)}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: primaryNavy)),
                                Text(
                                    'Fee: Rs. ${(d['platformFee'] ?? 0).toStringAsFixed(2)}',
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFFFF6A1A))),
                              ],
                            ),
                          ),
                        );
                      }),
                    ] else ...[
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 20),
                          child: Text(
                              'No delivered orders this month yet.',
                              style: TextStyle(
                                  color: Colors.grey.shade500)),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ── Stat card widget ──
  Widget _statCard(
      String label, String value, IconData icon, Color color) {
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
          const Text('Billing Reminders',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D1B3E))),
          const SizedBox(height: 12),
          _reminderItem(Icons.auto_mode, 'Platform fee generated automatically each month'),
          _reminderItem(Icons.timer, 'Upload receipt within 20 minutes of fee generation'),
          _reminderItem(Icons.admin_panel_settings,
              'Admin manually verifies every payment submission'),
          _reminderItem(Icons.check_circle_outline,
              'Shop reactivates after successful verification'),
        ],
      ),
    );
  }
 
  Widget _reminderItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFFFF6B00), size: 18),
          const SizedBox(width: 10),
          Expanded(
              child: Text(text,
                  style: const TextStyle(fontSize: 13, color: Colors.black87))),
        ],
      ),
    );
  }
 
  Widget _buildBottomNav(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, -3))
        ],
      ),
      child: BottomNavigationBar(
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFFFF6B00),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        currentIndex: 2,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_outlined), label: 'Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_outlined), label: 'Billing'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05), blurRadius: 8)
        ],
      ),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: color)),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(
                color: Colors.grey.shade500, fontSize: 12),
            textAlign: TextAlign.center),
      ]),
    );
  }

  // ── Info row (label + value) ──
  Widget _infoRow(String label, String value) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  color: Colors.grey.shade500, fontSize: 13)),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: primaryNavy)),
        ],
      );
}
