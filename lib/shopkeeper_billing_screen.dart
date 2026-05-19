import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'upload_receipt_screen.dart';
import 'billing_history_screen.dart';
import 'suspended_shop_screen.dart';
 
class ShopkeeperBillingScreen extends StatefulWidget {
  const ShopkeeperBillingScreen({super.key});
 
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
