import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'role_selection_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
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
              bottomRight: Radius.circular(25)),
        ),
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(
                color: Color.fromARGB(255, 21, 101, 192),
              ),
              accountName: Text(
                user?.displayName ?? "Admin",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              accountEmail: Text(user?.email ?? ""),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.admin_panel_settings,
                    color: Colors.blue, size: 40),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text("Dashboard Overview"),
              onTap: () => Navigator.pop(context),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.verified_user),
              title: const Text("Approve Shops"),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Approval module coming soon!")),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.report),
              title: const Text("Reports"),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Reports feature coming soon!")),
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
        title: const Text("Admin Dashboard"),
        backgroundColor: const Color.fromARGB(255, 21, 101, 192),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.admin_panel_settings,
                size: 80, color: Color.fromARGB(255, 21, 101, 192)),
            const SizedBox(height: 20),
            const Text(
              "Welcome Admin!",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              "Manage shop approvals, users, and reports efficiently.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ],
        ),
      ),
    );
  }
}