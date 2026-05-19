import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'cart_screen.dart';
 
// ═══════════════════════════════════════════════
//  DoorBuy Brand Colors
// ═══════════════════════════════════════════════
class AppColors {
  static const Color primary = Color(0xFFE8541A);
  static const Color primaryDark = Color(0xFFC8401A);
  static const Color navy = Color(0xFF1A2B4A);
  static const Color navyLight = Color(0xFF243556);
  static const Color surface = Color(0xFFFFF8F5);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1A2B4A);
  static const Color textSecondary = Color(0xFF6B7A8D);
  static const Color accent = Color(0xFFFF7A45);
  static const Color success = Color(0xFF2ECC71);
  static const Color divider = Color(0xFFEEEEEE);
}
 
class ShopProductsScreen extends StatefulWidget {
  final String shopId;
  final String shopName;
 
  const ShopProductsScreen(
      {super.key, required this.shopId, required this.shopName});
 
  @override
  State<ShopProductsScreen> createState() => _ShopProductsScreenState();
}
 
class _ShopProductsScreenState extends State<ShopProductsScreen>
    with SingleTickerProviderStateMixin {
  String _searchText = "";
  double _userRating = 0;
  final TextEditingController _commentController = TextEditingController();
  final user = FirebaseAuth.instance.currentUser;
  double _avgRating = 0;
  bool isFavorite = false;
  int _cartCount = 0;
  late TabController _tabController;
 
  @override
  void initState() {
    super.initState();
    _calculateAverageRating();
    checkIfFavorite();
    _listenCartCount();
    _tabController = TabController(length: 2, vsync: this);
  }
 
  @override
  void dispose() {
    _tabController.dispose();
    _commentController.dispose();
    super.dispose();
  }
 
  void _listenCartCount() {
    FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('cart')
        .where('shopId', isEqualTo: widget.shopId)
        .snapshots()
        .listen((snapshot) {
      int total = 0;
      for (var doc in snapshot.docs) {
        total += (doc.data()['quantity'] ?? 1) as int;
      }
      if (mounted) setState(() => _cartCount = total);
    });
  }
 
  Future<void> _addToCart(
      Map<String, dynamic> productData, String productId) async {
    final cartRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('cart')
        .doc('${widget.shopId}_$productId');
 
    final existing = await cartRef.get();
    if (existing.exists) {
      await cartRef
          .update({'quantity': (existing.data()!['quantity'] ?? 1) + 1});
    } else {
      await cartRef.set({
        'shopId': widget.shopId,
        'shopName': widget.shopName,
        'productId': productId,
        'name': productData['name'],
        'price': productData['price'],
        'image_url': productData['image_url'] ?? '',
        'quantity': 1,
        'addedAt': FieldValue.serverTimestamp(),
      });
    }
 
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${productData['name']} added to cart'),
        duration: const Duration(seconds: 2),
        backgroundColor: AppColors.navy,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        action: SnackBarAction(
          label: 'View Cart',
          textColor: AppColors.accent,
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CartScreen(
                  shopId: widget.shopId, shopName: widget.shopName),
            ),
          ),
        ),
      ),
    );
  }
 
  void checkIfFavorite() async {
    var doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('favorites')
        .doc(widget.shopId)
        .get();
    if (mounted) setState(() => isFavorite = doc.exists);
  }
 
  void toggleFavorite() async {
    if (isFavorite) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('favorites')
          .doc(widget.shopId)
          .delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Removed from favorites"),
          backgroundColor: AppColors.textSecondary,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } else {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('favorites')
          .doc(widget.shopId)
          .set({
        'shopId': widget.shopId,
        'shopName': widget.shopName,
        'timestamp': FieldValue.serverTimestamp(),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Added to favorites ❤️"),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
    setState(() => isFavorite = !isFavorite);
  }
 
  void _calculateAverageRating() {
    FirebaseFirestore.instance
        .collection('shops')
        .doc(widget.shopId)
        .collection('reviews')
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isEmpty) {
        if (mounted) setState(() => _avgRating = 0);
        return;
      }
      double total = 0;
      for (var doc in snapshot.docs) {
        total += (doc.data()['rating'] ?? 0).toDouble();
      }
      if (mounted) setState(() => _avgRating = total / snapshot.docs.length);
    });
  }
 
  void _submitReview() async {
    if (_userRating == 0 || _commentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Please provide rating and comment"),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }
    await FirebaseFirestore.instance
        .collection('shops')
        .doc(widget.shopId)
        .collection('reviews')
        .add({
      'rating': _userRating,
      'comment': _commentController.text,
      'userId': user?.uid,
      'userName': user?.email ?? "Anonymous",
      'timestamp': FieldValue.serverTimestamp(),
    });
    _commentController.clear();
    setState(() => _userRating = 0);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Review submitted! Thank you 🙏"),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            backgroundColor: AppColors.navy,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new,
                  color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              title: Text(
                widget.shopName,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.navy, AppColors.navyLight],
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    key: ValueKey(isFavorite),
                    color: isFavorite ? Colors.redAccent : Colors.white,
                  ),
                ),
                onPressed: toggleFavorite,
              ),
              Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart_outlined,
                        color: Colors.white),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CartScreen(
                            shopId: widget.shopId, shopName: widget.shopName),
                      ),
                    ),
                  ),
                  if (_cartCount > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$_cartCount',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              labelColor: AppColors.primary,
              unselectedLabelColor: Colors.white70,
              labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 14),
              tabs: const [
                Tab(text: "Products"),
                Tab(text: "Reviews"),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            // ── Tab 1: Products ──
            _buildProductsTab(),
            // ── Tab 2: Reviews ──
            _buildReviewsTab(),
          ],
        ),
      ),
    );
  }
 
  Widget _buildProductsTab() {
    return Column(
      children: [
        // Rating Summary Bar
        Container(
          color: AppColors.cardBg,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star_rounded,
                        color: Colors.amber, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      _avgRating.toStringAsFixed(1),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                          fontSize: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('shops')
                    .doc(widget.shopId)
                    .collection('reviews')
                    .snapshots(),
                builder: (context, snapshot) {
                  final count = snapshot.data?.docs.length ?? 0;
                  return Text(
                    "$count ratings",
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 13),
                  );
                },
              ),
              const Spacer(),
              RatingBarIndicator(
                rating: _avgRating,
                itemBuilder: (context, _) =>
                    const Icon(Icons.star_rounded, color: Colors.amber),
                itemCount: 5,
                itemSize: 18,
              ),
            ],
          ),
        ),
 
        // Search Bar
        Container(
          color: AppColors.cardBg,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: TextField(
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText: "Search products...",
              hintStyle: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13),
              prefixIcon:
                  const Icon(Icons.search, color: AppColors.primary, size: 20),
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            ),
            onChanged: (val) =>
                setState(() => _searchText = val.toLowerCase()),
          ),
        ),
 
        // Products list
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('shops')
                .doc(widget.shopId)
                .collection('products')
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                    child:
                        CircularProgressIndicator(color: AppColors.primary));
              }
              final products = snapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final name = data['name']?.toString().toLowerCase() ?? "";
                return name.contains(_searchText);
              }).toList();
 
              if (products.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inventory_2_outlined,
                          size: 64,
                          color:
                              AppColors.textSecondary.withOpacity(0.4)),
                      const SizedBox(height: 12),
                      const Text("No products found",
                          style: TextStyle(color: AppColors.textSecondary)),
                    ],
                  ),
                );
              }
 
              return ListView.builder(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final data =
                      products[index].data() as Map<String, dynamic>;
                  final productId = products[index].id;
 
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
                          // Product Image
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: data['image_url'] != null
                                ? Image.network(
                                    data['image_url'],
                                    width: 70,
                                    height: 70,
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    width: 70,
                                    height: 70,
                                    decoration: BoxDecoration(
                                      color: AppColors.surface,
                                      borderRadius:
                                          BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.image_outlined,
                                        color: AppColors.textSecondary),
                                  ),
                          ),
                          const SizedBox(width: 14),
                          // Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data['name'] ?? "Product",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Rs. ${data['price'] ?? '0'}",
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                                if (data['description'] != null &&
                                    data['description']
                                        .toString()
                                        .isNotEmpty)
                                  Text(
                                    data['description'],
                                    style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 12),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                          // Add Button
                          GestureDetector(
                            onTap: () => _addToCart(data, productId),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.add_shopping_cart_outlined,
                                      color: Colors.white, size: 16),
                                  SizedBox(width: 4),
                                  Text("Add",
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold)),
                                ],
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
        ),
      ],
    );
  }
 
  Widget _buildReviewsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rate Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: AppColors.navy.withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Rate this Shop",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: RatingBar.builder(
                    initialRating: 0,
                    minRating: 1,
                    direction: Axis.horizontal,
                    allowHalfRating: true,
                    itemCount: 5,
                    itemSize: 40,
                    itemPadding:
                        const EdgeInsets.symmetric(horizontal: 6),
                    itemBuilder: (context, _) =>
                        const Icon(Icons.star_rounded, color: Colors.amber),
                    onRatingUpdate: (rating) =>
                        setState(() => _userRating = rating),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _commentController,
                  maxLines: 3,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: "Share your experience...",
                    hintStyle: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 13),
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _submitReview,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text(
                      "Submit Review",
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
 
          // Reviews List
          const Text(
            "Customer Reviews",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 17,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
 
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('shops')
                .doc(widget.shopId)
                .collection('reviews')
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox();
              final reviews = snapshot.data!.docs;
              if (reviews.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(Icons.rate_review_outlined,
                            size: 52,
                            color: AppColors.textSecondary.withOpacity(0.4)),
                        const SizedBox(height: 10),
                        const Text("No reviews yet. Be the first!",
                            style: TextStyle(
                                color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                );
              }
 
              return ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: reviews.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final data =
                      reviews[index].data() as Map<String, dynamic>;
                  final name =
                      data['userName'] ?? data['userId'] ?? "Anonymous";
 
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.navy.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: AppColors.navy,
                          child: Text(
                            name[0].toUpperCase(),
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                    fontSize: 14),
                              ),
                              const SizedBox(height: 4),
                              RatingBarIndicator(
                                rating: (data['rating'] ?? 0).toDouble(),
                                itemBuilder: (context, _) => const Icon(
                                    Icons.star_rounded,
                                    color: Colors.amber),
                                itemCount: 5,
                                itemSize: 16,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                data['comment'] ?? "",
                                style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
