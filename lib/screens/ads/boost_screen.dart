import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../../providers/auth_provider.dart';
import '../../utils/theme.dart';
import '../../services/api_service.dart';
import '../../config/api_config.dart';
import '../../utils/storage_helper.dart';

class BoostScreen extends StatefulWidget {
  final int adId;
  final String adTitle;

  const BoostScreen({
    super.key,
    required this.adId,
    required this.adTitle,
  });

  @override
  State<BoostScreen> createState() => _BoostScreenState();
}

class _BoostScreenState extends State<BoostScreen> {
  List<Map<String, dynamic>> _plans = [];
  bool _isLoading = true;
  bool _isProcessing = false;
  Map<String, dynamic>? _selectedPlan;
  WebViewController? _webviewController;

  _BoostScreenState() {
    debugPrint('DEBUG: _BoostScreenState() construtor chamado');
  }

  @override
  void initState() {
    try {
      debugPrint('DEBUG: initState() iniciando');
      super.initState();
      debugPrint('DEBUG: initState() chamado');
      debugPrint('DEBUG: kIsWeb = $kIsWeb');
      debugPrint('DEBUG: defaultTargetPlatform = ${defaultTargetPlatform}');
      debugPrint('DEBUG: widget.adId = ${widget.adId}');
      debugPrint('DEBUG: widget.adTitle = ${widget.adTitle}');
      
      debugPrint('DEBUG: Chamando _loadPlans()');
      _loadPlans();
      debugPrint('DEBUG: _loadPlans() concluído');
      
      debugPrint('DEBUG: Chamando _initializeWebView()');
      _initializeWebView().then((_) {
        debugPrint('DEBUG: WebViewController após inicialização: $_webviewController');
        debugPrint('DEBUG: initState() concluído com sucesso');
      }).catchError((e) {
        debugPrint('DEBUG: Erro na inicialização assíncrona: $e');
      });
      debugPrint('DEBUG: initState() concluído com sucesso');
    } catch (e, stackTrace) {
      debugPrint('DEBUG: ERRO em initState(): $e');
      debugPrint('DEBUG: StackTrace: $stackTrace');
      super.initState(); // Garantir que o super seja chamado mesmo com erro
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    debugPrint('DEBUG: didChangeDependencies() chamado');
  }

  @override
  void dispose() {
    debugPrint('DEBUG: dispose() chamado');
    super.dispose();
  }


  Future<void> _initializeWebView() async {
    try {
      debugPrint('DEBUG: Iniciando inicialização do WebView...');
      debugPrint('DEBUG: kIsWeb = $kIsWeb');
      
      // Garante que estamos no contexto correto para criar WebView
      if (!mounted) {
        debugPrint('DEBUG: Widget não montado, abortando inicialização');
        return;
      }
      
      if (kIsWeb) {
        debugPrint('DEBUG: Criando WebViewController para Web');
        final params = const PlatformWebViewControllerCreationParams();
        _webviewController = WebViewController.fromPlatformCreationParams(params);
      } else {
        debugPrint('DEBUG: Criando WebViewController para Mobile');
        _webviewController = WebViewController();
      }
      
      debugPrint('DEBUG: WebViewController criado com sucesso');
      debugPrint('DEBUG: _webviewController após criação: $_webviewController');
      
      // Configurar WebView para web (monitoramento de URL para pagamento)
      if (kIsWeb) {
        _webviewController!
          ..setNavigationDelegate(
            NavigationDelegate(
              onProgress: (int progress) {},
              onPageStarted: (String url) {
                setState(() {
                  _isProcessing = true;
                });
                debugPrint('DEBUG: WebView started loading: $url');
              },
              onPageFinished: (String url) {
                setState(() {
                  _isProcessing = false;
                });
                debugPrint('DEBUG: WebView finished loading: $url');
                
                // Verificar URLs de sucesso/cancelamento para web
                if (url.contains('payment-success') || url.contains('return=success')) {
                  Navigator.of(context).pop(); // Close dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Pagamento aprovado! Anúncio turbinado com sucesso.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  Navigator.of(context).pop(); // Go back to my ads
                } else if (url.contains('payment-cancel') || url.contains('return=cancel')) {
                  Navigator.of(context).pop(); // Close dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Pagamento cancelado.'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              },
              onWebResourceError: (WebResourceError error) {
                debugPrint('DEBUG: WebView error: ${error.description}');
                setState(() {
                  _isProcessing = false;
                });
              },
            ),
          );
      } else {
        // Configurar WebView para mobile (com JavaScript channels)
        _webviewController!
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..addJavaScriptChannel(
            'paymentSuccess',
            onMessageReceived: (JavaScriptMessage message) {
              Navigator.of(context).pop(); // Close dialog
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Pagamento aprovado! Anúncio turbinado com sucesso.'),
                  backgroundColor: Colors.green,
                ),
              );
              Navigator.of(context).pop(); // Go back to my ads
            },
          )
          ..addJavaScriptChannel(
            'paymentCancel',
            onMessageReceived: (JavaScriptMessage message) {
              Navigator.of(context).pop(); // Close dialog
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Pagamento cancelado.'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
          )
          ..setNavigationDelegate(
            NavigationDelegate(
              onProgress: (int progress) {},
              onPageStarted: (String url) {
                setState(() {
                  _isProcessing = true;
                });
              },
              onPageFinished: (String url) {
                setState(() {
                  _isProcessing = false;
                });
              },
              onWebResourceError: (WebResourceError error) {
                debugPrint('DEBUG: WebView error: ${error.description}');
                setState(() {
                  _isProcessing = false;
                });
              },
            ),
          );
      }
      
      debugPrint('DEBUG: WebView inicializado com sucesso');
    } catch (e, stackTrace) {
      debugPrint('DEBUG: Falha ao inicializar WebView: $e');
      debugPrint('DEBUG: StackTrace: $stackTrace');
      _webviewController = null;
    }
  }

  Future<void> _loadPlans() async {
    try {
      debugPrint('DEBUG: Iniciando carregamento de planos...');
      final response = await ApiService.get('${ApiConfig.boost}/plans').timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Timeout ao carregar planos');
        },
      );
      
      debugPrint('DEBUG: Resposta recebida: $response');
      
      if (response['success'] == true) {
        debugPrint('DEBUG: Planos carregados com sucesso');
        setState(() {
          _plans = List<Map<String, dynamic>>. from(response['plans'] ?? []);
          _isLoading = false;
        });
      } else {
        debugPrint('DEBUG: Erro na resposta: ${response['error']}');
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['error'] ?? 'Erro ao carregar planos'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('DEBUG: Erro ao carregar planos: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao carregar planos: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'Tentar Novamente',
            onPressed: () => _loadPlans(),
          ),
        ),
      );
    }
  }

  Future<void> _purchaseBoost(Map<String, dynamic> plan) async {
    final auth = context.read<AuthProvider>();
    if (auth.user?.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Usuário não autenticado'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      debugPrint('DEBUG: Iniciando pagamento para plano ${plan['id']}');
      debugPrint('DEBUG: User ID: ${auth.user!.id}');
      debugPrint('DEBUG: Ad ID: ${widget.adId}');
      
      // Load PayPal checkout page
      await _loadPayPalCheckout(plan, auth.user!.id);
    } catch (e) {
      debugPrint('DEBUG: Erro ao processar pagamento: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao processar pagamento: $e'),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'Tentar Novamente',
            onPressed: () => _purchaseBoost(plan),
          ),
        ),
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _loadPayPalCheckout(Map<String, dynamic> plan, int userId) async {
    debugPrint('DEBUG: _loadPayPalCheckout() chamado');
    
    // Para web, usar URL launcher em vez de WebView
    if (kIsWeb) {
      await _launchWebPayment(plan, userId);
      return;
    }
    
    debugPrint('DEBUG: _webviewController = $_webviewController');
    debugPrint('DEBUG: _webviewController == null = ${_webviewController == null}');
    
    // Reinitialize WebView if null
    if (_webviewController == null) {
      debugPrint('DEBUG: WebView nulo, reinicializando...');
      await _initializeWebView();
      
      if (_webviewController == null) {
        debugPrint('DEBUG: Falha ao inicializar WebView.');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao inicializar checkout. Tente novamente.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    try {
      debugPrint('DEBUG: Gerando HTML para PayPal checkout');
      final htmlContent = _generatePayPalCheckoutHtml(plan, userId);
      
      debugPrint('DEBUG: Carregando HTML no WebView');
      await _webviewController!.loadRequest(Uri.dataFromString(
        htmlContent,
        mimeType: 'text/html',
      ));
      
      debugPrint('DEBUG: Abrindo dialog de pagamento');
      // Show PayPal checkout in dialog
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Dialog(
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.8,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star, color: Colors.white, size: 24),
                      const SizedBox(width: 12),
                      const Text(
                        'Pagamento PayPal',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: WebViewWidget(controller: _webviewController!),
                ),
                if (_isProcessing)
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.white,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: AppColors.primary),
                        SizedBox(width: 12),
                        Text('Processando...'),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      debugPrint('DEBUG: Erro ao carregar PayPal checkout: $e');
      rethrow;
    }
  }

  String _generatePayPalCheckoutHtml(Map<String, dynamic> plan, int userId) {
    return '''
<!DOCTYPE html>
<html>
<head>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Pagamento PayPal</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            margin: 0;
            padding: 20px;
            background: #f5f5f5;
        }
        .container {
            max-width: 400px;
            margin: 0 auto;
            background: white;
            padding: 20px;
            border-radius: 12px;
            box-shadow: 0 4px 12px rgba(0,0,0,0.1);
        }
        .summary {
            background: #f8f9fa;
            padding: 16px;
            border-radius: 8px;
            margin-bottom: 20px;
        }
        .summary h3 {
            margin: 0 0 8px 0;
            color: #333;
        }
        .summary p {
            margin: 4px 0;
            color: #666;
        }
        .price {
            font-size: 24px;
            font-weight: bold;
            color: #0070ba;
            margin: 12px 0;
        }
        #paypal-buttons {
            margin-top: 20px;
        }
        .feedback {
            text-align: center;
            margin-top: 16px;
            padding: 12px;
            border-radius: 6px;
            font-size: 14px;
        }
        .success { background: #d4edda; color: #155724; }
        .error { background: #f8d7da; color: #721c24; }
        .loading { background: #d1ecf1; color: #0c5460; }
    </style>
</head>
<body>
    <div class="container">
        <div class="summary">
            <h3>Resumo do Pedido</h3>
            <p><strong>Plano:</strong> ${plan['name']}</p>
            <p><strong>Duração:</strong> ${plan['duration_days']} dias</p>
            <p><strong>Anúncio:</strong> #${widget.adId}</p>
            <div class="price">R\$ ${plan['price']}</div>
        </div>
        
        <div id="paypal-buttons"></div>
        <div id="feedback" class="feedback" style="display: none;"></div>
    </div>

    <script src="https://www.paypal.com/sdk/js?client-id=AdwM9cttlAFIe7PtG7tsM7geJiy67XKgb49Za9ajAZp4N4EUGghFUP70hTFjvRviYd3EEccwJC5fo93f&currency=BRL&intent=capture&locale=pt_BR"></script>
    <script>
        let currentPlan = ${json.encode(plan)};
        let adId = ${widget.adId};
        let userId = $userId;
        
        const showFeedback = (message, isError = false) => {
            const feedback = document.getElementById('feedback');
            feedback.textContent = message;
            feedback.style.display = 'block';
            feedback.className = 'feedback ' + (isError ? 'error' : 'success');
        };
        
        const showLoading = (message) => {
            const feedback = document.getElementById('feedback');
            feedback.textContent = message;
            feedback.style.display = 'block';
            feedback.className = 'feedback loading';
        };

        paypal.Buttons({
            style: {
                layout: 'vertical',
                color: 'gold',
                shape: 'rect',
                label: 'paypal'
            },
            createOrder: () => {
                showLoading('Criando pedido...');
                return fetch('https://localviva.com.br/api/paypal_boost', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({
                        action: 'create_order',
                        ad_id: adId,
                        plan_id: currentPlan.id,
                        user_id: userId
                    }),
                })
                .then((response) => {
                    if (!response.ok) {
                        return response.json().then((data) => { 
                            throw new Error(data.error || 'Erro ao criar pedido.'); 
                        });
                    }
                    return response.json();
                })
                .then((data) => data.order_id)
                .catch((error) => {
                    showFeedback(error.message || 'Erro ao iniciar pagamento.', true);
                    throw error;
                });
            },
            onApprove: (data) => {
                showLoading('Processando pagamento...');
                return fetch('https://localviva.com.br/api/paypal_boost', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ 
                        action: 'capture_payment',
                        order_id: data.orderID,
                        ad_id: adId
                    }),
                })
                .then((response) => {
                    if (!response.ok) {
                        return response.json().then((data) => { 
                            throw new Error(data.error || 'Erro ao finalizar pagamento.'); 
                        });
                    }
                    return response.json();
                })
                .then((result) => {
                    showFeedback(result.message || 'Pagamento aprovado!', false);
                    setTimeout(() => {
                        paymentSuccess.postMessage({
                            success: true,
                            message: result.message || 'Pagamento aprovado!'
                        });
                    }, 1500);
                })
                .catch((error) => {
                    showFeedback(error.message || 'Erro ao processar pagamento.', true);
                });
            },
            onError: (err) => {
                showFeedback('Ocorreu um erro no pagamento. Tente novamente.', true);
            },
            onCancel: () => {
                showFeedback('Pagamento cancelado.', true);
                setTimeout(() => {
                    paymentCancel.postMessage();
                }, 1500);
            }
        }).render('#paypal-buttons');
    </script>
</body>
</html>
    ''';
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('DEBUG: build() chamado - _webviewController = $_webviewController');
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        foregroundColor: Colors.white,
        title: Text('Turbinar: ${widget.adTitle}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  const SizedBox(height: 16),
                  Text(
                    'Carregando planos...',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            )
          : _plans.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.star_outline,
                        size: 64,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Nenhum plano disponível',
                        style: AppTextStyles.heading3,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tente novamente mais tarde',
                        style: AppTextStyles.bodySmall,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => _loadPlans(),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Recarregar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                )
              : SafeArea(
                  child: Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _plans.length,
                          itemBuilder: (context, index) {
                            final plan = _plans[index];
                            final isSelected = _selectedPlan?['id'] == plan['id'];
                            
                            return Card(
                              margin: const EdgeInsets.only(bottom: 16),
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedPlan = plan;
                                  });
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              plan['name'],
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isSelected ? AppColors.primary : Colors.grey[200],
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              'R\$ ${plan['price']}',
                                              style: TextStyle(
                                                color: isSelected ? Colors.white : Colors.black,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        plan['description'] ?? 'Plano de destaque',
                                        style: const TextStyle(color: Colors.grey),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Duração: ${plan['duration_days']} dias',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      if (_selectedPlan != null)
                        Container(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                          child: SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _isProcessing ? null : () => _purchaseBoost(_selectedPlan!),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isProcessing
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : Text(
                                      'Turbinar por R\$ ${_selectedPlan!['price']}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }

  Future<void> _launchWebPayment(Map<String, dynamic> plan, int userId) async {
    try {
      debugPrint('=== PAYMENT DEBUG START ===');
      debugPrint('DEBUG: Iniciando pagamento web para plano ${plan['id']}');
      
      // Chamar backend para gerar URL de pagamento
      final token = await StorageHelper.getToken();
      debugPrint('=== TOKEN DEBUG START ===');
      debugPrint('DEBUG: Token retrieved for payment: ${token != null ? 'YES' : 'NO'}');
      debugPrint('DEBUG: Token length: ${token?.length ?? 0}');
      debugPrint('DEBUG: Token first 10 chars: ${token?.substring(0, 10) ?? 'NULL'}');
      debugPrint('DEBUG: Token last 10 chars: ${token?.substring(token.length - 10) ?? 'NULL'}');
      debugPrint('DEBUG: Token is empty: ${token?.isEmpty ?? true}');
      debugPrint('=== TOKEN DEBUG END ===');
      
      if (token == null || token.isEmpty) {
        debugPrint('DEBUG: TOKEN IS NULL OR EMPTY - This is the problem!');
        throw Exception('Token de autenticação não encontrado');
      }
      
      final headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };
      
      debugPrint('=== HEADERS DEBUG START ===');
      debugPrint('DEBUG: Authorization header: ${headers['Authorization']}');
      debugPrint('DEBUG: Full headers: $headers');
      debugPrint('=== HEADERS DEBUG END ===');
      
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/boost/create-payment?plan_id=${plan['id']}&user_id=$userId&ad_id=${widget.adId}&platform=web'),
        headers: headers,
      );
      
      debugPrint('DEBUG: Backend response status: ${response.statusCode}');
      debugPrint('DEBUG: Backend response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          // Verificar se retornou order_id (método moderno) ou payment_url (fallback)
          if (data.containsKey('order_id')) {
            // Método moderno: renderizar botões PayPal como no site
            final orderId = data['order_id'];
            final paypalClientId = data['paypal_client_id'] ?? '';
            debugPrint('DEBUG: Order ID recebido: $orderId');
            debugPrint('DEBUG: PayPal Client ID: $paypalClientId');
            
            // Mostrar diálogo com botões PayPal
            await _showPayPalButtonsDialog(orderId, paypalClientId, plan);
            
          } else if (data.containsKey('payment_url')) {
            // Fallback: redirecionar para URL clássica
            final paymentUrl = data['payment_url'];
            debugPrint('DEBUG: URL de pagamento gerada: $paymentUrl');
            
            // Abrir em nova aba
            final uri = Uri.parse(paymentUrl);
            if (await canLaunchUrl(uri)) {
              await launchUrl(
                uri,
                webOnlyWindowName: '_blank', // Nova aba
              );
              
              // Mostrar mensagem para usuário
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Pagamento aberto em nova aba. Complete o pagamento e volte aqui.'),
                  duration: Duration(seconds: 5),
                  backgroundColor: Colors.blue,
                ),
              );
              
              // Aguardar um pouco e verificar se pagamento foi concluído
              await _waitForPaymentCompletion();
            } else {
              throw Exception('Não foi possível abrir a URL de pagamento');
            }
          } else {
            throw Exception('Resposta inválida do servidor');
          }
        } else {
          throw Exception(data['error'] ?? 'Erro desconhecido');
        }
      } else {
        throw Exception('Erro na API: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('DEBUG: Erro ao iniciar pagamento web: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao iniciar pagamento: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _generatePayPalPaymentUrl(Map<String, dynamic> plan, int userId) {
    // Usar endpoint do backend para gerar URL de pagamento
    final baseUrl = '${ApiConfig.baseUrl}/boost/create-payment';
    final params = {
      'plan_id': plan['id'].toString(),
      'user_id': userId.toString(),
      'ad_id': widget.adId.toString(),
      'platform': 'web',
    };
    
    final queryString = params.entries.map((e) => '${e.key}=${e.value}').join('&');
    return '$baseUrl?$queryString';
  }

  Future<void> _showPayPalButtonsDialog(String orderId, String paypalClientId, Map<String, dynamic> plan) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.8,
            child: Column(
              children: [
                // Header
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Pagamento - ${plan['name']}',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                
                // Content
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(
                          'Valor: R\$ ${plan['price'].toStringAsFixed(2).replaceAll('.', ',')}',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Pague com cartão de crédito ou PayPal:',
                          style: TextStyle(fontSize: 14),
                        ),
                        SizedBox(height: 16),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: _buildPayPalWebView(orderId, paypalClientId),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPayPalWebView(String orderId, String paypalClientId) {
    // Simplificado para web - mostrar instruções e botão para abrir PayPal
    return Container(
      height: 300,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.payment, size: 48, color: Colors.blue),
          SizedBox(height: 16),
          Text(
            'Pagamento Seguro via PayPal',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Aceitamos cartão de crédito e PayPal',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _openPayPalCheckout(orderId),
            icon: Icon(Icons.credit_card),
            label: Text('Pagar com Cartão ou PayPal'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Você será redirecionado para o PayPal',
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Future<void> _openPayPalCheckout(String orderId) async {
    final paypalUrl = 'https://www.paypal.com/checkoutnow?token=$orderId';
    
    if (await canLaunchUrl(Uri.parse(paypalUrl))) {
      await launchUrl(
        Uri.parse(paypalUrl),
        webOnlyWindowName: '_blank',
      );
      
      // Fechar diálogo e mostrar mensagem
      Navigator.of(context).pop();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pagamento aberto em nova aba. Complete o pagamento.'),
          duration: Duration(seconds: 5),
          backgroundColor: Colors.blue,
        ),
      );
      
      // Aguardar pagamento
      await _waitForPaymentCompletion();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível abrir o PayPal.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _waitForPaymentCompletion() async {
    // Aguardar 5 minutos para pagamento
    await Future.delayed(const Duration(minutes: 5));
    
    // Verificar status do pagamento (implementar se necessário)
    debugPrint('DEBUG: Tempo de espera esgotado');
  }
}
