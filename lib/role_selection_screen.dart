import 'package:flutter/material.dart';
import 'login_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Color mainBlue = const Color(0xFF0D47A1); // dark blue
    final Color accentOrange = const Color(0xFFF4511E); // orange

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // 🔹 Header Section
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [mainBlue, accentOrange],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(50),
                    bottomRight: Radius.circular(50),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // ✨ Centered App Name (Option 2 – Semi-Stylish Italic)
                    Text(
                      "NearBuy",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 40,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 2,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(1, 2),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    const Text(
                      "Select Your Role",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Login to continue",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 🔹 Buttons Section (slightly lower)
            Expanded(
              flex: 5, // increased flex to move it a bit lower
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    _buildRoleButton(
                      context,
                      title: "Customer",
                      icon: Icons.person,
                      color: accentOrange,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(role: "Customer"),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildRoleButton(
                      context,
                      title: "Shopkeeper",
                      icon: Icons.storefront_rounded,
                      color: mainBlue,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(role: "Shopkeeper"),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildRoleButton(
                      context,
                      title: "Admin",
                      icon: Icons.admin_panel_settings_rounded,
                      color: accentOrange,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(role: "Admin"),
                        ),
                      ),
                    ),

                    const Spacer(),

                    // 🔹 Footer Text
                    Text(
                      "© 2025 NearBuy | Smart Location Finder",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔹 Reusable Button Widget
  Widget _buildRoleButton(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.25),
            offset: const Offset(0, 6),
            blurRadius: 12,
          ),
        ],
      ),
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 55),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        icon: Icon(icon, size: 22),
        label: Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        onPressed: onTap,
      ),
    );
  }
}