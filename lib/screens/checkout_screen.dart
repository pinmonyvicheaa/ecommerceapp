import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/cart_provider.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _zipController = TextEditingController();
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();

  bool _isProcessing = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _zipController.dispose();
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  Future<void> _processOrder(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isProcessing = true);

    final cart = Provider.of<CartProvider>(context, listen: false);
    final totalAmount = cart.totalPrice + (cart.cartItems.length * 2.0);

    try {
      final clientId = 'ASLMGKdtntQ5vKqo-ehR6BwiW4xQWjAbhtrx5J5XBgE6vU7c4xyanrx8_pFkphseiA-rNJn3OUTduAap';
      final secret = 'EKkLsLVvVN6yYh2NNHrm3wBLynlVUG28yDg7x0rpt1LE7S-SVkIuixXWIa-FuA8WknjMWtJtQPYehA3v';

      final basicAuth = 'Basic ${base64Encode(utf8.encode('$clientId:$secret'))}';

      final tokenResponse = await http.post(
        Uri.parse('https://api-m.sandbox.paypal.com/v1/oauth2/token'),
        headers: {
          'Authorization': basicAuth,
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {'grant_type': 'client_credentials'},
      );

      final accessToken = json.decode(tokenResponse.body)['access_token'];

      final orderResponse = await http.post(
        Uri.parse('https://api-m.sandbox.paypal.com/v2/checkout/orders'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: json.encode({
          "intent": "CAPTURE",
          "purchase_units": [
            {
              "amount": {
                "currency_code": "USD",
                "value": totalAmount.toStringAsFixed(2),
              },
            },
          ],
          "application_context": {
            "return_url": "https://example.com/success",
            "cancel_url": "https://example.com/cancel",
          },
        }),
      );

      final orderData = json.decode(orderResponse.body);
      debugPrint('PayPal order response: $orderData');

      if (orderResponse.statusCode == 201 && orderData['links'] != null) {
        final approvalLink = orderData['links'].firstWhere(
          (link) => link['rel'] == 'approve',
          orElse: () => null,
        );

        if (approvalLink != null && approvalLink['href'] != null) {
          final approvalUrl = approvalLink['href'];

          if (await canLaunchUrl(Uri.parse(approvalUrl))) {
            await launchUrl(
              Uri.parse(approvalUrl),
              mode: LaunchMode.externalApplication,
            );
          } else {
            throw Exception('Could not launch PayPal approval URL');
          }

          cart.clearCart();
        } else {
          throw Exception('Approval URL not found in PayPal response.');
        }
      } else {
        throw Exception('Failed to create PayPal order: ${orderResponse.body}');
      }
    } catch (e) {
      debugPrint('PayPal Payment Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment failed: $e')),
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _processPaywayOrder(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isProcessing = true);

    final cart = Provider.of<CartProvider>(context, listen: false);
    final totalAmount = cart.totalPrice + (cart.cartItems.length * 2.0);

    try {
      final paywayUrl = Uri.parse(
          'https://sandbox.payway.com.kh/payment?amount=${totalAmount.toStringAsFixed(2)}&currency=USD');

      if (await canLaunchUrl(paywayUrl)) {
        await launchUrl(paywayUrl, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Could not launch PayWay sandbox URL');
      }

      cart.clearCart();
    } catch (e) {
      debugPrint('PayWay Payment Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PayWay payment failed: $e')),
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final shippingCost = cart.cartItems.length * 2.0;
    final total = cart.totalPrice + shippingCost;

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Shipping Information',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Full Name'),
                validator: (value) => value!.isEmpty ? 'Enter your name' : null,
              ),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (value) => value!.isEmpty ? 'Enter your email' : null,
                keyboardType: TextInputType.emailAddress,
              ),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Address'),
                validator: (value) => value!.isEmpty ? 'Enter your address' : null,
              ),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _cityController,
                      decoration: const InputDecoration(labelText: 'City'),
                      validator: (value) => value!.isEmpty ? 'Enter city' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _zipController,
                      decoration: const InputDecoration(labelText: 'ZIP Code'),
                      validator: (value) => value!.isEmpty ? 'Enter ZIP' : null,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text('Payment Information',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cardNumberController,
                decoration: const InputDecoration(labelText: 'Card Number'),
                validator: (value) =>
                    value!.isEmpty ? 'Enter card number' : null,
                keyboardType: TextInputType.number,
              ),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _expiryController,
                      decoration: const InputDecoration(labelText: 'Expiry (MM/YY)'),
                      validator: (value) =>
                          value!.isEmpty ? 'Enter expiry date' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _cvvController,
                      decoration: const InputDecoration(labelText: 'CVV'),
                      validator: (value) =>
                          value!.isEmpty ? 'Enter CVV' : null,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text('Order Summary',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: cart.cartItems.length,
                itemBuilder: (context, index) {
                  final item = cart.cartItems[index];
                  return ListTile(
                    leading: Image.network(
                      item.product.imageUrl,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.broken_image),
                    ),
                    title: Text(item.product.name),
                    subtitle: Text('Qty: ${item.quantity}'),
                    trailing: Text(
                        '\$${(item.product.price * item.quantity).toStringAsFixed(2)}'),
                  );
                },
              ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Subtotal:'),
                    Text('\$${cart.totalPrice.toStringAsFixed(2)}'),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Shipping:'),
                    Text('\$${shippingCost.toStringAsFixed(2)}'),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('\$${total.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // PayPal Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : () => _processOrder(context),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isProcessing
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Pay with PayPal'),
                ),
              ),

              const SizedBox(height: 12),

              // PayWay Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed:
                      _isProcessing ? null : () => _processPaywayOrder(context),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.orange,
                  ),
                  child: _isProcessing
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Pay with PayWay Sandbox'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
