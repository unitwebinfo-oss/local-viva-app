import 'package:flutter/material.dart';
import 'package:paypal_checkout_flutter/paypal_checkout_flutter.dart';
import '../../services/api_service.dart';
import '../../config/api_config.dart';

class PaypalPaymentScreen extends StatefulWidget {
  final Map<String, dynamic> paymentData;

  const PaypalPaymentScreen({super.key, required this.paymentData});

  @override
  State<PaypalPaymentScreen> createState() => _PaypalPaymentScreenState();
}

class _PaypalPaymentScreenState extends State<PaypalPaymentScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final orderId = widget.paymentData['orderId'] ?? '';
    final amount = widget.paymentData['amount'] ?? '0.00';
    final description = widget.paymentData['description'] ?? '';
    final adId = widget.paymentData['adId'] ?? '';
    final planId = widget.paymentData['planId'] ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        title: const Text('Pagamento PayPal'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.blue),
                  SizedBox(height: 16),
                  Text('Processando pagamento...'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Resumo do Pagamento',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          description,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Valor: R\$ $amount',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        Text(
                          'Pedido: $orderId',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _processPayPalPayment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Pagar com PayPal',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      'Pagamento seguro processado pelo PayPal',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Future<void> _processPayPalPayment() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Initialize PayPal checkout
      await PayPalCheckout.init(
        clientId: "AdwM9cttlAFIe7PtG7tsM7geJiy67XKgb49Za9ajAZp4N4EUGghFUP70hTFjvRviYd3EEccwJC5fo93f",
        sandboxMode: false, // Use production mode
        returnURL: "https://localviva.com.br/api/paypal_boost/success",
        cancelURL: "https://localviva.com.br/api/paypal_boost/cancel",
      );

      // Create order and process payment
      final data = {
        "intent": "sale",
        "payer": {"payment_method": "paypal"},
        "transactions": [
          {
            "amount": {
              "total": widget.paymentData['amount'],
              "currency": "BRL",
              "details": {
                "subtotal": widget.paymentData['amount'],
                "tax": "0",
                "shipping": "0",
                "handling_fee": "0",
                "shipping_discount": "0",
                "insurance": "0"
              }
            },
            "description": widget.paymentData['description'],
            "custom": widget.paymentData['orderId'],
            "item_list": {
              "items": [
                {
                  "name": "Plano de Destaque",
                  "description": widget.paymentData['description'],
                  "quantity": "1",
                  "price": widget.paymentData['amount'],
                  "tax": "0",
                  "sku": widget.paymentData['planId'],
                  "currency": "BRL"
                }
              ]
            }
          }
        ],
        "redirect_urls": {
          "return_url": "https://localviva.com.br/api/paypal_boost/success",
          "cancel_url": "https://localviva.com.br/api/paypal_boost/cancel"
        }
      };

      final result = await PayPalCheckout.makePayment(data);

      if (result != null && result['success'] == true) {
        // Capture payment on backend
        await _capturePayment();
      } else {
        throw Exception('Pagamento cancelado ou falhou');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro no pagamento: $e'),
          backgroundColor: Colors.red,
        ),
      );
      Navigator.of(context).pop(false);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _capturePayment() async {
    try {
      final response = await ApiService.post('${ApiConfig.paypalBoost}', {
        'action': 'capture_payment',
        'order_id': widget.paymentData['orderId'],
        'ad_id': widget.paymentData['adId'],
      });

      if (response['success'] == true) {
        Navigator.of(context).pop(true);
      } else {
        throw Exception(response['error'] ?? 'Erro ao capturar pagamento');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao processar pagamento: $e'),
          backgroundColor: Colors.red,
        ),
      );
      Navigator.of(context).pop(false);
    }
  }
}
