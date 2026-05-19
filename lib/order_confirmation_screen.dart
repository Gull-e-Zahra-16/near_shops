import 'package:flutter/material.dart';
import 'customer_dashboard.dart';
 
class AppColors {
  static const Color primary = Color(0xFFE8541A);
  static const Color navy = Color(0xFF1A2B4A);
  static const Color navyLight = Color(0xFF243556);
  static const Color surface = Color(0xFFFFF8F5);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1A2B4A);
  static const Color textSecondary = Color(0xFF6B7A8D);
  static const Color success = Color(0xFF10B981);
  static const Color divider = Color(0xFFEEEEEE);
}
 
class OrderConfirmationScreen extends StatefulWidget {
  final String orderId;
  final String shopName;
  final double totalAmount;
 
  const OrderConfirmationScreen({
    super.key,
    required this.orderId,
    required this.shopName,
    required this.totalAmount,
  });
 
  @override
  State<OrderConfirmationScreen> createState() =>
      _OrderConfirmationScreenState();
}
 
class _OrderConfirmationScreenState extends State<OrderConfirmationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;
 
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _scaleAnim = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
  }
 
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 30),
 
              // Animated Success Icon
              ScaleTransition(
                scale: _scaleAnim,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.success, Color(0xFF059669)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.success.withOpacity(0.35),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.check_rounded,
                      color: Colors.white, size: 64),
                ),
              ),
              const SizedBox(height: 24),
 
              FadeTransition(
                opacity: _fadeAnim,
                child: Column(
                  children: [
                    const Text(
                      "Order Confirmed!",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Your order has been placed at ${widget.shopName}.",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 15, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 28),
 
                    // Order Details Card
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.cardBg,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.navy.withOpacity(0.08),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Card Header
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [AppColors.navy, AppColors.navyLight],
                              ),
                              borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(20)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.receipt_long_rounded,
                                    color: Colors.white70, size: 20),
                                const SizedBox(width: 8),
                                const Text(
                                  "Order Details",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16),
                                ),
                                const Spacer(),
                                Text(
                                  "#${widget.orderId.substring(0, 8).toUpperCase()}",
                                  style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 12),
                                ),
                              ],
                            ),
                          ),
 
                          // Details Body
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                _detailRow(
                                  icon: Icons.store_rounded,
                                  label: "Shop",
                                  value: widget.shopName,
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  child: Divider(
                                      color: AppColors.divider, height: 1),
                                ),
                                _detailRow(
                                  icon: Icons.currency_rupee_rounded,
                                  label: "Total Paid",
                                  value:
                                      "Rs. ${widget.totalAmount.toStringAsFixed(0)}",
                                  valueColor: AppColors.primary,
                                  bold: true,
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  child: Divider(
                                      color: AppColors.divider, height: 1),
                                ),
                                _detailRow(
                                  icon: Icons.payments_rounded,
                                  label: "Payment",
                                  value: "Cash on Delivery",
                                  valueColor: AppColors.success,
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  child: Divider(
                                      color: AppColors.divider, height: 1),
                                ),
                                _detailRow(
                                  icon: Icons.pending_actions_rounded,
                                  label: "Status",
                                  value: "Pending Confirmation",
                                  valueColor: Colors.orange,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
 
                    // Info Banner
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: AppColors.primary.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.info_outline_rounded,
                              color: AppColors.primary, size: 20),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "The shopkeeper will confirm your order shortly. Please keep cash ready for delivery.",
                              style: TextStyle(
                                  fontSize: 13, color: AppColors.primary),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
 
                    // Back to Home Button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const CustomerDashboard()),
                            (route) => false,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.home_rounded,
                                color: Colors.white, size: 22),
                            SizedBox(width: 8),
                            Text(
                              "Back to Home",
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
 
  Widget _detailRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    bool bold = false,
  }) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: AppColors.textSecondary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 14)),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: bold ? FontWeight.bold : FontWeight.w600,
            fontSize: bold ? 15 : 14,
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
