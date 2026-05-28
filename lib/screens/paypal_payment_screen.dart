import 'package:flutter/material.dart';
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
      // Create PayPal order via backend
      final response = await ApiService.post('${ApiConfig.paypalBoost}', {
        'action': 'create_order',
        'amount': widget.paymentData['amount'],
        'description': widget.paymentData['description'],
        'order_id': widget.paymentData['orderId'],
        'ad_id': widget.paymentData['adId'],
        'plan_id': widget.paymentData['planId'],
      });

      if (response['success'] == true && response['approval_url'] != null) {
        // Open PayPal approval URL in webview or browser
        final approvalUrl = response['approval_url'];

        // Show confirmation and redirect
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } else {
        throw Exception(response['error'] ?? 'Erro ao criar pagamento');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro no pagamento: $e'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.of(context).pop(false);
      }
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
