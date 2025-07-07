
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LogoutHelper {
  static Future<void> logout(BuildContext context, {String redirectRoute = '/login'}) async {
    try {
      await FirebaseAuth.instance.signOut();

      // Optionally, clear any local storage or cache here
      // e.g., SharedPreferences prefs = await SharedPreferences.getInstance();
      // await prefs.clear();

      if (context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(redirectRoute, (route) => false);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  static void showLogoutDialog(BuildContext context, {String redirectRoute = '/login'}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              logout(context, redirectRoute: redirectRoute); // Perform logout
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
