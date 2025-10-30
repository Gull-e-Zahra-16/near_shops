import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'role_selection_screen.dart';

class ShopkeeperDashboard extends StatefulWidget {
  const ShopkeeperDashboard({super.key});

  @override
  State<ShopkeeperDashboard> createState() => _ShopkeeperDashboardState();
}

class _ShopkeeperDashboardState extends State<ShopkeeperDashboard> {
  final user = FirebaseAuth.instance.currentUser;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(25),
            bottomRight: Radius.circular(25),
          ),
        ),
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(
                color: Color.fromARGB(255, 21, 101, 192),
              ),
              accountName: Text(
                user?.displayName ?? "Shopkeeper",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              accountEmail: Text(user?.email ?? ""),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.store, color: Colors.blue, size: 40),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text("Dashboard"),
              onTap: () => Navigator.pop(context),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.add_business),
              title: const Text("Register Shop"),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Shop registration coming soon!")),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text("Manage Shop"),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Shop management coming soon!")),
                );
              },
            ),
            const Spacer(),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text("Logout", style: TextStyle(color: Colors.red)),
              onTap: _logout,
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
      appBar: AppBar(
        title: const Text("Shopkeeper Dashboard"),
        backgroundColor: const Color.fromARGB(255, 21, 101, 192),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.store_mall_directory,
                size: 80, color: Color.fromARGB(255, 21, 101, 192)),
            const SizedBox(height: 20),
            const Text(
              "Welcome Shopkeeper!",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              "Register and manage your shop easily from here.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ],
        ),
      ),
    );
  }
}