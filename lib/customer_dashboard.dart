import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'role_selection_screen.dart';
import 'shop_products_screen.dart';
import 'services/location_service.dart';
import 'screens/map_screen.dart';
import 'screens/my_orders_screen.dart';

//  ═══════════════════════════════════════════════
//  NearBuy Brand Colors
//  ═══════════════════════════════════════════════
class AppColors {
  static const Color primary = Color(0xFFE8541A);      // Orange
  static const Color primaryDark = Color(0xFFC8401A);  // Dark Orange
  static const Color navy = Color(0xFF1A2B4A);         // Dark Navy
  static const Color navyLight = Color(0xFF243556);    // Light Navy
  static const Color surface = Color(0xFFFFF8F5);      // Warm White
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1A2B4A);
  static const Color textSecondary = Color(0xFF6B7A8D);
  static const Color accent = Color(0xFFFF7A45);
  static const Color success = Color(0xFF2ECC71);
  static const Color divider = Color(0xFFEEEEEE);
}

class CustomerDashboard extends StatefulWidget {
  const CustomerDashboard({super.key});

  @override
  State<CustomerDashboard> createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends State<CustomerDashboard>
    with SingleTickerProviderStateMixin {
  final user = FirebaseAuth.instance.currentUser;
  String _searchText = "";
  Position? _currentPosition;
  String _locationStatus = "Fetching location...";
  String? _profileImageUrl;
  String? _displayName;
  bool _isUploading = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _displayName = user?.displayName ?? "Customer";
    _fetchCurrentLocation();
    _loadProfileData();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _loadProfileData() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user?.uid)
        .get();
    if (doc.exists) {
      setState(() {
        _profileImageUrl = doc.data()?['profile_image'];
        if (doc.data()?['name'] != null) {
          _displayName = doc.data()?['name'];
        }
      });
    }
  }

  Future<void> _updateName(String newName) async {
    try {
      await user?.updateDisplayName(newName);
      await FirebaseFirestore.instance.collection('users').doc(user?.uid).set(
        {'name': newName},
        SetOptions(merge: true),
      );
      setState(() => _displayName = newName);
    } catch (e) {
      debugPrint("Update Name Error: $e");
    }
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _isUploading = true);
      try {
        String cloudName = "your_cloud_name";
        String uploadPreset = "your_preset";
        var request = http.MultipartRequest(
          'POST',
          Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload'),
        );
        request.fields['upload_preset'] = uploadPreset;
        request.files
            .add(await http.MultipartFile.fromPath('file', pickedFile.path));
        var response = await request.send();
        if (response.statusCode == 200) {
          var responseData = await response.stream.toBytes();
          var responseString = String.fromCharCodes(responseData);
          var jsonRes = jsonDecode(responseString);
          String url = jsonRes['secure_url'];
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user?.uid)
              .set({'profile_image': url}, SetOptions(merge: true));
          setState(() => _profileImageUrl = url);
        }
      } catch (e) {
        debugPrint("Upload Error: $e");
      } finally {
        setState(() => _isUploading = false);
      }
    }
  }

  void _showProfileDialog() {
    TextEditingController nameController =
        TextEditingController(text: _displayName);
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: AppColors.cardBg,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Profile Avatar
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary, width: 3),
                    ),
                    child: CircleAvatar(
                      radius: 48,
                      backgroundColor: AppColors.surface,
                      backgroundImage: _profileImageUrl != null
                          ? NetworkImage(_profileImageUrl!)
                          : null,
                      child: _profileImageUrl == null
                          ? const Icon(Icons.person,
                              size: 48, color: AppColors.primary)
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Name Field
              TextField(
                controller: nameController,
                style: const TextStyle(
                    color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  labelText: "Full Name",
                  labelStyle: const TextStyle(color: AppColors.textSecondary),
                  prefixIcon:
                      const Icon(Icons.edit_outlined, color: AppColors.primary),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide:
                          const BorderSide(color: AppColors.divider)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                          color: AppColors.primary, width: 2)),
                  filled: true,
                  fillColor: AppColors.surface,
                ),
              ),
              const SizedBox(height: 12),
              Text(user?.email ?? "",
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 13)),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        side: const BorderSide(color: AppColors.divider),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text("Cancel"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        _updateName(nameController.text);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text("Profile Updated!"),
                            backgroundColor: AppColors.success,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                      ),
                      child: const Text("Save",
                          style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _fetchCurrentLocation() async {
    try {
      final position = await LocationService.getCurrentLocation();
      if (mounted) {
        setState(() {
          _currentPosition = position;
          _locationStatus = "Location fetched";
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _locationStatus = "Location permission denied");
      }
    }
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
        (route) => false,
      );
    }
  }

  Stream<QuerySnapshot> _getVerifiedShops() {
    return FirebaseFirestore.instance
        .collection('shops')
        .where('status', isEqualTo: 'verified')
        .snapshots();
  }

  bool _isBillingAllowed(Map<String, dynamic> data) {
    final billing = data['billing_status'];
    return billing == null || billing == 'active';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      drawer: _buildDrawer(),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: CustomScrollView(
          slivers: [
            // ── App Bar ──
            SliverAppBar(
              expandedHeight: 160,
              floating: false,
              pinned: true,
              backgroundColor: AppColors.navy,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.navy, AppColors.navyLight],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            "Hello, ${_displayName?.split(' ').first ?? 'Customer'}  👋 ",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.location_on,
                                  color: AppColors.accent, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                _locationStatus,
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.75),
                                    fontSize: 12),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Search Bar
                          Container(
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: TextField(
                              onChanged: (val) =>
                                  setState(() => _searchText = val.toLowerCase()),
                              style: const TextStyle(
                                  color: AppColors.textPrimary, fontSize: 14),
                              decoration: InputDecoration(
                                hintText: "Search shops near you...",
                                hintStyle: TextStyle(
                                    color: AppColors.textSecondary
                                        .withOpacity(0.7),
                                    fontSize: 13),
                                prefixIcon: const Icon(Icons.search,
                                    color: AppColors.primary, size: 20),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                    vertical: 12, horizontal: 4),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: GestureDetector(
                    onTap: _pickAndUploadImage,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: AppColors.primary,
                          backgroundImage: _profileImageUrl != null
                              ? NetworkImage(_profileImageUrl!)
                              : null,
                          child: _profileImageUrl == null
                              ? const Icon(Icons.person,
                                  color: Colors.white, size: 22)
                              : null,
                        ),
                        if (_isUploading)
                          const Positioned.fill(
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // ── Quick Actions ──
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  children: [
                    _quickAction(
                      icon: Icons.map_outlined,
                      label: "Map View",
                      color: AppColors.navy,
                      onTap: () {
                        if (_currentPosition != null) {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => MapScreen(
                                      latitude: _currentPosition!.latitude,
                                      longitude:
                                          _currentPosition!.longitude)));
                        }
                      },
                    ),
                    const SizedBox(width: 12),
                    _quickAction(
                      icon: Icons.receipt_long_outlined,
                      label: "My Orders",
                      color: AppColors.primary,
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const MyOrdersScreen())),
                    ),
                    const SizedBox(width: 12),
                    _quickAction(
                      icon: Icons.person_outline,
                      label: "Profile",
                      color: AppColors.navyLight,
                      onTap: _showProfileDialog,
                    ),
                  ],
                ),
              ),
            ),

            // ── Shops Near You heading ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 22,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      "Shops Near You",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // ── Shops List ──
            SliverToBoxAdapter(
              child: StreamBuilder<QuerySnapshot>(
                stream: _getVerifiedShops(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(
                            color: AppColors.primary),
                      ),
                    );
                  }

                  final shops = snapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    if (!_isBillingAllowed(data)) return false;
                    
                    // Filter matching with shop_name field
                    final name = (data['shop_name'] ?? "").toString().toLowerCase();
                    return name.contains(_searchText);
                  }).toList();

                  if (shops.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(60),
                        child: Column(
                          children: [
                            Icon(Icons.store_mall_directory_outlined,
                                size: 72,
                                color: AppColors.textSecondary.withOpacity(0.4)),
                            const SizedBox(height: 16),
                            const Text("No shops found",
                                style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 16)),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: shops.length,
                    itemBuilder: (context, index) {
                      final data = shops[index].data() as Map<String, dynamic>;
                      final shopId = shops[index].id;

                      // Exact Firestore fields integration
                      final String fetchedShopName = data['shop_name'] ?? "Shop";
                      final String fetchedLocation = data['shop_location'] ?? "Address not set";
                      final String? fetchedImageUrl = data['shop_image_url'];

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ShopProductsScreen(
                                shopId: shopId,
                                shopName: fetchedShopName,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          decoration: BoxDecoration(
                            color: AppColors.cardBg,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.navy.withOpacity(0.08),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Shop Image / Banner using shop_image_url
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(18)),
                                child: fetchedImageUrl != null && fetchedImageUrl.trim().isNotEmpty
                                    ? Image.network(
                                        fetchedImageUrl.trim(),
                                        height: 130,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return _buildFallbackBanner();
                                        },
                                      )
                                    : _buildFallbackBanner(),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(14),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Shop Name
                                          Text(
                                            fetchedShopName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              const Icon(Icons.location_pin,
                                                  size: 13,
                                                  color: AppColors.primary),
                                              const SizedBox(width: 3),
                                              // Shop Location Address
                                              Expanded(
                                                child: Text(
                                                  fetchedLocation,
                                                  style: const TextStyle(
                                                      color: AppColors.textSecondary,
                                                      fontSize: 12),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        borderRadius:
                                            BorderRadius.circular(10),
                                      ),
                                      child: const Text(
                                        "Visit",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
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

            const SliverToBoxAdapter(child: SizedBox(height: 30)),
          ],
        ),
      ),
    );
  }

  // Placeholder Banner in case image is missing
  Widget _buildFallbackBanner() {
    return Container(
      height: 130,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.navy, AppColors.navyLight],
        ),
      ),
      child: const Center(
        child: Icon(Icons.store_mall_directory, size: 52, color: Colors.white54),
      ),
    );
  }

  Widget _quickAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
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
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(icon, color: Colors.white, size: 26),
              const SizedBox(height: 6),
              Text(label,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: AppColors.cardBg,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.only(top: 60, bottom: 24, left: 20, right: 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.navy, AppColors.navyLight],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: _pickAndUploadImage,
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.primary, width: 3),
                        ),
                        child: CircleAvatar(
                          radius: 36,
                          backgroundColor: Colors.white,
                          backgroundImage: _profileImageUrl != null
                              ? NetworkImage(_profileImageUrl!)
                              : null,
                          child: _profileImageUrl == null
                              ? const Icon(Icons.person,
                                  color: AppColors.primary, size: 36)
                              : null,
                        ),
                      ),
                      if (_isUploading)
                        const Positioned.fill(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _displayName ?? "Customer",
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  user?.email ?? "",
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.7), fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _drawerItem(
            icon: Icons.person_outline,
            label: "View Profile",
            onTap: () {
              Navigator.pop(context);
              _showProfileDialog();
            },
          ),
          _drawerItem(
            icon: Icons.receipt_long_outlined,
            label: "My Orders",
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const MyOrdersScreen()));
            },
          ),
          const Divider(color: AppColors.divider, indent: 20, endIndent: 20),
          _drawerItem(
            icon: Icons.logout,
            label: "Logout",
            color: Colors.redAccent,
            onTap: _logout,
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              "NearBuy v1.0",
              style: TextStyle(
                  color: AppColors.textSecondary.withOpacity(0.5),
                  fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _drawerItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppColors.navy, size: 22),
      title: Text(
        label,
        style: TextStyle(
          color: color ?? AppColors.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
    );
  }
}