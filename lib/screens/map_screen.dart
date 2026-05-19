import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/location_service.dart';
import '../shop_products_screen.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
 
// ═══════════════════════════════════════════════
//  DoorBuy Brand Colors
// ═══════════════════════════════════════════════
class AppColors {
  static const Color primary     = Color(0xFFE8541A);
  static const Color navy        = Color(0xFF1A2B4A);
  static const Color navyLight   = Color(0xFF243556);
  static const Color surface     = Color(0xFFFFF8F5);
  static const Color cardBg      = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1A2B4A);
  static const Color textSecondary = Color(0xFF6B7A8D);
  static const Color success     = Color(0xFF10B981);
  static const Color divider     = Color(0xFFEEEEEE);
}
 
class MapScreen extends StatefulWidget {
  final double? latitude;
  final double? longitude;

  const MapScreen({super.key, this.latitude, this.longitude});
 
  @override
  State<MapScreen> createState() => _MapScreenState();
}
 
class _MapScreenState extends State<MapScreen>
    with SingleTickerProviderStateMixin {
  GoogleMapController? mapController;
  LatLng? _currentLatLng;
  Set<Marker> _shopMarkers = {};
  bool _isLoading = true;
  int _shopCount = 0;
  String _selectedCategory = "All";
  bool _showPanel = false;
 
  final List<String> _categories = [
    "All", "Grocery", "Pharmacy", "Electronics", "Restaurant", "Clothing"
  ];
 
  @override
  void initState() {
    super.initState();
    if (widget.latitude != null && widget.longitude != null) {
      _currentLatLng = LatLng(widget.latitude!, widget.longitude!);
    }
    _getCurrentLocation();
    _fetchVerifiedShops();
  }
 
  // ---------------- CURRENT LOCATION ----------------
  void _getCurrentLocation() async {
    try {
      final position = await LocationService.getCurrentLocation();
      setState(() {
        _currentLatLng = LatLng(position.latitude, position.longitude);
        _isLoading = false;
      });
      if (mapController != null && _currentLatLng != null) {
        mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(_currentLatLng!, 15),
        );
      }
    } catch (e) {
      debugPrint("Location error: $e");
      setState(() => _isLoading = false);
    }
  }
 
  // ---------------- CATEGORY COLOR ----------------
  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'grocery':     return const Color(0xFF10B981);
      case 'pharmacy':    return const Color(0xFF3B82F6);
      case 'electronics': return const Color(0xFFE8541A);
      case 'restaurant':  return const Color(0xFFEF4444);
      case 'clothing':    return const Color(0xFFEC4899);
      default:            return const Color(0xFF1A2B4A);
    }
  }
 
  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'grocery':     return Icons.local_grocery_store;
      case 'pharmacy':    return Icons.local_pharmacy;
      case 'electronics': return Icons.devices;
      case 'restaurant':  return Icons.restaurant;
      case 'clothing':    return Icons.checkroom;
      default:            return Icons.store;
    }
  }
 
  // ---------------- CUSTOM MARKER ----------------
  Future<BitmapDescriptor> _createLabelMarker(
      String shopName, Color color) async {
    const double width = 320;
    const double height = 140;
 
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
 
    final Paint pinPaint = Paint()..color = color;
 
    // Pin circle
    canvas.drawCircle(const Offset(60, 90), 30, pinPaint);
 
    // White ring on pin
    final Paint ringPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawCircle(const Offset(60, 90), 30, ringPaint);
 
    // Pin pointer
    final Path path = Path();
    path.moveTo(60, 125);
    path.lineTo(45, 90);
    path.lineTo(75, 90);
    path.close();
    canvas.drawPath(path, pinPaint);
 
    // Label shadow
    final Paint shadowPaint = Paint()
      ..color = Colors.black12
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(112, 47, 190, 55), const Radius.circular(12)),
      shadowPaint,
    );
 
    // White label background
    final RRect labelBg = RRect.fromRectAndRadius(
      const Rect.fromLTWH(110, 45, 190, 55),
      const Radius.circular(12),
    );
    canvas.drawRRect(labelBg, Paint()..color = Colors.white);
 
    // Left color accent on label
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        const Rect.fromLTWH(110, 45, 6, 55),
        topLeft: const Radius.circular(12),
        bottomLeft: const Radius.circular(12),
      ),
      Paint()..color = color,
    );
 
    // Border
    canvas.drawRRect(
        labelBg,
        Paint()
          ..color = color.withOpacity(0.25)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
 
    final textPainter = TextPainter(
      text: TextSpan(
        text: shopName.length > 18
            ? "${shopName.substring(0, 18)}..."
            : shopName,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1A2B4A),
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '...',
    );
 
    textPainter.layout(maxWidth: 170);
    textPainter.paint(canvas, const Offset(124, 60));
 
    final ui.Image image =
        await recorder.endRecording().toImage(width.toInt(), height.toInt());
    final ByteData? byteData =
        await image.toByteData(format: ui.ImageByteFormat.png);
 
    return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
  }
 
  // ---------------- FETCH VERIFIED SHOPS ----------------
  void _fetchVerifiedShops() {
    FirebaseFirestore.instance
        .collection('shops')
        .where('status', isEqualTo: 'verified')
        .snapshots()
        .listen((snapshot) async {
      Set<Marker> markers = {};
 
      for (var doc in snapshot.docs) {
        final data = doc.data();
 
        final double? lat = data['location_lat'];
        final double? lng = data['location_lng'];
        final String category = data['shop_category'] ?? 'Other';
        final String shopName = data['shop_name'] ?? 'Shop';
        final String openTime = data['open_time'] ?? 'N/A';
        final String closeTime = data['close_time'] ?? 'N/A';
 
        if (lat == null || lng == null) continue;
 
        // Category filter
        if (_selectedCategory != "All" &&
            category.toLowerCase() != _selectedCategory.toLowerCase()) {
          continue;
        }
 
        final Color markerColor = _getCategoryColor(category);
 
        // Fetch Reviews
        double avgRating = 0.0;
        int reviewCount = 0;
        try {
          final reviewsSnapshot = await FirebaseFirestore.instance
              .collection('shops')
              .doc(doc.id)
              .collection('reviews')
              .get();
          reviewCount = reviewsSnapshot.docs.length;
          if (reviewCount > 0) {
            double total = 0;
            for (var r in reviewsSnapshot.docs) {
              total += (r.data()['rating'] ?? 0).toDouble();
            }
            avgRating = total / reviewCount;
          }
        } catch (e) {
          debugPrint("Rating error: $e");
        }
 
        final customIcon = await _createLabelMarker(shopName, markerColor);
 
        markers.add(
          Marker(
            markerId: MarkerId(doc.id),
            position: LatLng(lat, lng),
            icon: customIcon,
            infoWindow: InfoWindow(
              title: shopName,
              snippet:
                  "Category: $category | "
                  "🕒 $openTime-$closeTime | "
                  "⭐ ${avgRating.toStringAsFixed(1)} ($reviewCount)",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ShopProductsScreen(
                      shopId: doc.id,
                      shopName: shopName,
                    ),
                  ),
                );
              },
            ),
          ),
        );
      }
 
      setState(() {
        _shopMarkers = markers;
        _shopCount = markers.length;
      });
    });
  }
 
  // ── Custom map style (clean light theme) ──
  static const String _mapStyle = '''
  [
    {"featureType":"poi","elementType":"labels","stylers":[{"visibility":"off"}]},
    {"featureType":"transit","elementType":"labels","stylers":[{"visibility":"off"}]},
    {"featureType":"road","elementType":"geometry","stylers":[{"color":"#ffffff"}]},
    {"featureType":"road","elementType":"labels.text.fill","stylers":[{"color":"#9ca3af"}]},
    {"featureType":"water","elementType":"geometry","stylers":[{"color":"#dbeafe"}]},
    {"featureType":"landscape","elementType":"geometry","stylers":[{"color":"#f9fafb"}]}
  ]
  ''';
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
        children: [
          // ── Map ──
          _currentLatLng == null
              ? Container(
                  color: AppColors.surface,
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: AppColors.primary),
                        SizedBox(height: 16),
                        Text("Fetching your location...",
                            style: TextStyle(
                                color: AppColors.textSecondary, fontSize: 14)),
                      ],
                    ),
                  ),
                )
              : GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _currentLatLng!,
                    zoom: 15,
                  ),
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  markers: _shopMarkers,
                  onMapCreated: (controller) {
                    mapController = controller;
                    controller.setMapStyle(_mapStyle);
                    if (_currentLatLng != null) {
                      controller.animateCamera(
                          CameraUpdate.newLatLngZoom(_currentLatLng!, 15));
                    }
                  },
                ),
 
          // ── Top Bar ──
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                  child: Row(
                    children: [
                      // Back button
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.cardBg,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                  color: AppColors.navy.withOpacity(0.12),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3))
                            ],
                          ),
                          child: const Icon(Icons.arrow_back_ios_new_rounded,
                              color: AppColors.navy, size: 18),
                        ),
                      ),
                      const SizedBox(width: 10),
 
                      // Title card
                      Expanded(
                        child: Container(
                          height: 44,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: AppColors.cardBg,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                  color: AppColors.navy.withOpacity(0.12),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3))
                            ],
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.location_on_rounded,
                                  color: AppColors.primary, size: 18),
                              const SizedBox(width: 6),
                              const Expanded(
                                child: Text(
                                  "Shops Near You",
                                  style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(8)),
                                child: Text(
                                  "$_shopCount shops",
                                  style: const TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
 
                      // My location button
                      GestureDetector(
                        onTap: () {
                          if (_currentLatLng != null && mapController != null) {
                            mapController!.animateCamera(
                                CameraUpdate.newLatLngZoom(
                                    _currentLatLng!, 15));
                          }
                        },
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                  color: AppColors.primary.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3))
                            ],
                          ),
                          child: const Icon(Icons.my_location_rounded,
                              color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
 
                const SizedBox(height: 10),
 
                // Category Filter Pills
                SizedBox(
                  height: 38,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final cat = _categories[index];
                      final isSelected = _selectedCategory == cat;
                      return GestureDetector(
                        onTap: () {
                          setState(() => _selectedCategory = cat);
                          _fetchVerifiedShops();
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.cardBg,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                  color: AppColors.navy.withOpacity(0.1),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2))
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (cat != "All") ...[
                                Icon(
                                  _getCategoryIcon(cat),
                                  size: 13,
                                  color: isSelected
                                      ? Colors.white
                                      : _getCategoryColor(cat),
                                ),
                                const SizedBox(width: 5),
                              ],
                              Text(
                                cat,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
 
          // ── Legend bottom card ──
          Positioned(
            bottom: 20,
            left: 12,
            right: 12,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: AppColors.navy.withOpacity(0.12),
                      blurRadius: 16,
                      offset: const Offset(0, 4))
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _legendItem("Grocery", const Color(0xFF10B981)),
                  _legendItem("Pharmacy", const Color(0xFF3B82F6)),
                  _legendItem("Electronics", const Color(0xFFE8541A)),
                  _legendItem("Restaurant", const Color(0xFFEF4444)),
                  _legendItem("Clothing", const Color(0xFFEC4899)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
 
  Widget _legendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500)),
      ],
    );
  }
}
