import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Navigate to settings screen
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            const CircleAvatar(
              radius: 50,
              backgroundImage: NetworkImage(
                  'https://randomuser.me/api/portraits/men/1.jpg'),
            ),
            const SizedBox(height: 16),
            const Text(
              'Pin Monyvichea',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'pin.monyvichea@example.com',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            _buildProfileItem(
              icon: Icons.person_outline,
              title: 'Personal Information',
              onTap: () {
                // Navigate to personal info screen
              },
            ),
            _buildProfileItem(
              icon: Icons.shopping_bag_outlined,
              title: 'Order History',
              onTap: () {
                // Navigate to order history
              },
            ),
            _buildProfileItem(
              icon: Icons.favorite_border,
              title: 'Wishlist',
              onTap: () {
                // Navigate to wishlist
              },
            ),
            _buildProfileItem(
              icon: Icons.location_on_outlined,
              title: 'Shipping Addresses',
              onTap: () {
                // Navigate to addresses
              },
            ),
            _buildProfileItem(
              icon: Icons.payment_outlined,
              title: 'Payment Methods',
              onTap: () {
                // Navigate to payment methods
              },
            ),
            _buildProfileItem(
              icon: Icons.notifications_none,
              title: 'Notifications',
              onTap: () {
                // Navigate to notifications
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // Handle logout
                cart.clearCart();
                Navigator.pushNamedAndRemoveUntil(
                    context, '/login', (route) => false);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[50],
                foregroundColor: Colors.red,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Log Out'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }
}