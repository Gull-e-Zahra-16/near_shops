import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'order_confirmation_screen.dart';
 
class AppColors {
  static const Color primary = Color(0xFFE8541A);
  static const Color primaryDark = Color(0xFFC8401A);
  static const Color navy = Color(0xFF1A2B4A);
  static const Color navyLight = Color(0xFF243556);
  static const Color surface = Color(0xFFFFF8F5);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1A2B4A);
  static const Color textSecondary = Color(0xFF6B7A8D);
  static const Color success = Color(0xFF10B981);
  static const Color divider = Color(0xFFEEEEEE);
}
 
class CartScreen extends StatefulWidget {
  final String shopId;
  final String shopName;
 
  const CartScreen({super.key, required this.shopId, required this.shopName});
 
  @override
  State<CartScreen> createState() => _CartScreenState();
}
 
class _CartScreenState extends State<CartScreen> {
  final user = FirebaseAuth.instance.currentUser;
  static const double platformFeePercent = 0.05;
 
  Stream<QuerySnapshot> _cartStream() {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('cart')
        .where('shopId', isEqualTo: widget.shopId)
        .snapshots();
  }
 
  double _calculateSubtotal(List<QueryDocumentSnapshot> items) {
    double total = 0;
    for (var item in items) {
      final data = item.data() as Map<String, dynamic>;
      total += (data['price'] ?? 0) * (data['quantity'] ?? 1);
    }
    return total;
  }
 
  Future<void> _updateQuantity(String docId, int newQty) async {
    if (newQty <= 0) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('cart')
          .doc(docId)
          .delete();
    } else {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('cart')
          .doc(docId)
          .update({'quantity': newQty});
    }
  }
 
  Future<void> _removeItem(String docId) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('cart')
        .doc(docId)
        .delete();
  }
 
  Future<void> _placeOrder(
      List<QueryDocumentSnapshot> cartItems, double subtotal) async {
    final platformFee = subtotal * platformFeePercent;
    final totalAmount = subtotal + platformFee;
 
    final List<Map<String, dynamic>> orderItems = cartItems.map((item) {
      final data = item.data() as Map<String, dynamic>;
      return {
        'productId': data['productId'],
        'name': data['name'],
        'price': data['price'],
        'quantity': data['quantity'],
        'image_url': data['image_url'] ?? '',
      };
    }).toList();
 
    final orderRef =
        await FirebaseFirestore.instance.collection('orders').add({
      'customerId': user!.uid,
      'customerEmail': user!.email,
      'shopId': widget.shopId,
      'shopName': widget.shopName,
      'items': orderItems,
      'subtotal': subtotal,
      'platformFee': platformFee,
      'totalAmount': totalAmount,
      'paymentMethod': 'Cash on Delivery',
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
 
    final cartDocs = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('cart')
        .where('shopId', isEqualTo: widget.shopId)
        .get();
    for (var doc in cartDocs.docs) {
      await doc.reference.delete();
    }
 
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => OrderConfirmationScreen(
            orderId: orderRef.id,
            shopName: widget.shopName,
            totalAmount: totalAmount,
          ),
        ),
      );
    }
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "My Cart",
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.navy, AppColors.navyLight],
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _cartStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.primary));
          }
 
          final cartItems = snapshot.data!.docs;
 
          if (cartItems.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.shopping_cart_outlined,
                        size: 60, color: AppColors.primary),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Your cart is empty",
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Add items from the shop to get started",
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 14),
                  ),
                ],
              ),
            );
          }
 
          final subtotal = _calculateSubtotal(cartItems);
          final platformFee = subtotal * platformFeePercent;
          final totalAmount = subtotal + platformFee;
 
          return Column(
            children: [
              // Shop Header
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                color: AppColors.primary.withOpacity(0.08),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.store_rounded,
                          color: AppColors.primary, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      widget.shopName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppColors.navy,
                      ),
                    ),
                  ],
                ),
              ),
 
              // Cart Items
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(14),
                  itemCount: cartItems.length,
                  itemBuilder: (context, index) {
                    final data =
                        cartItems[index].data() as Map<String, dynamic>;
                    final docId = cartItems[index].id;
                    final qty = data['quantity'] ?? 1;
                    final price = (data['price'] ?? 0).toDouble();
                    final itemTotal = price * qty;
 
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: AppColors.cardBg,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.navy.withOpacity(0.06),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            // Image
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: data['image_url'] != null &&
                                      data['image_url'] != ''
                                  ? Image.network(
                                      data['image_url'],
                                      width: 68,
                                      height: 68,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      width: 68,
                                      height: 68,
                                      decoration: BoxDecoration(
                                        color: AppColors.surface,
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                      child: const Icon(Icons.image_outlined,
                                          color: AppColors.textSecondary),
                                    ),
                            ),
                            const SizedBox(width: 12),
 
                            // Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    data['name'] ?? '',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: AppColors.textPrimary),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Rs. ${price.toStringAsFixed(0)} each',
                                    style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 12),
                                  ),
                                  const SizedBox(height: 10),
                                  // Qty Controls
                                  Row(
                                    children: [
                                      _qtyBtn(
                                        icon: Icons.remove,
                                        onTap: () =>
                                            _updateQuantity(docId, qty - 1),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 14),
                                        child: Text(
                                          '$qty',
                                          style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.textPrimary),
                                        ),
                                      ),
                                      _qtyBtn(
                                        icon: Icons.add,
                                        onTap: () =>
                                            _updateQuantity(docId, qty + 1),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
 
                            // Total + Delete
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Rs. ${itemTotal.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: AppColors.primary),
                                ),
                                const SizedBox(height: 10),
                                GestureDetector(
                                  onTap: () => _removeItem(docId),
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.red.withOpacity(0.1),
                                      borderRadius:
                                          BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                        Icons.delete_outline_rounded,
                                        color: Colors.red,
                                        size: 18),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
 
              // Order Summary Bottom Sheet
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.navy.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Order Summary",
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 14),
                    _summaryRow("Subtotal",
                        "Rs. ${subtotal.toStringAsFixed(0)}"),
                    const SizedBox(height: 8),
                    _summaryRow(
                      "Platform Fee (5%)",
                      "Rs. ${platformFee.toStringAsFixed(0)}",
                      valueColor: Colors.orange.shade600,
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Divider(color: AppColors.divider),
                    ),
                    _summaryRow(
                      "Total",
                      "Rs. ${totalAmount.toStringAsFixed(0)}",
                      bold: true,
                      valueColor: AppColors.primary,
                    ),
                    const SizedBox(height: 12),
                    // Payment badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppColors.success.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.payments_rounded,
                              color: AppColors.success, size: 17),
                          SizedBox(width: 6),
                          Text(
                            "Cash on Delivery",
                            style: TextStyle(
                                color: AppColors.success,
                                fontWeight: FontWeight.w600,
                                fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (_) => Dialog(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20)),
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary
                                            .withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                          Icons.shopping_bag_outlined,
                                          color: AppColors.primary,
                                          size: 32),
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      "Confirm Order",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                          color: AppColors.textPrimary),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      "Place order of Rs. ${totalAmount.toStringAsFixed(0)} from ${widget.shopName}?\n\nPayment: Cash on Delivery",
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 14),
                                    ),
                                    const SizedBox(height: 20),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton(
                                            onPressed: () =>
                                                Navigator.pop(context, false),
                                            style: OutlinedButton.styleFrom(
                                              side: const BorderSide(
                                                  color: AppColors.divider),
                                              shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          12)),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 14),
                                            ),
                                            child: const Text("Cancel",
                                                style: TextStyle(
                                                    color: AppColors
                                                        .textSecondary)),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: ElevatedButton(
                                            onPressed: () =>
                                                Navigator.pop(context, true),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  AppColors.primary,
                                              shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          12)),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 14),
                                              elevation: 0,
                                            ),
                                            child: const Text("Confirm",
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight:
                                                        FontWeight.bold)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                          if (confirm == true) {
                            await _placeOrder(cartItems, subtotal);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: const Text(
                          "Place Order",
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
 
  Widget _qtyBtn(
      {required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
 
  Widget _summaryRow(String label, String value,
      {bool bold = false, Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: bold ? 15 : 14,
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: bold ? 17 : 14,
            fontWeight: bold ? FontWeight.bold : FontWeight.w600,
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
