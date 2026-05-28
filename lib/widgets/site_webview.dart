import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/theme.dart';

class SiteWebView extends StatefulWidget {
  final String url;
  final String title;

  const SiteWebView({
    super.key,
    required this.url,
    required this.title,
  });

  @override
  State<SiteWebView> createState() => _SiteWebViewState();
}

class _SiteWebViewState extends State<SiteWebView> {
  WebViewController? _controller;
  int _progress = 0;

  @override
  void initState() {
    super.initState();
    // Don't initialize WebView on web
    if (!kIsWeb) {
      _controller ??= WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0x00000000))
        ..setNavigationDelegate(
          NavigationDelegate(
            onProgress: (progress) {
              setState(() => _progress = progress);
            },
          ),
        )
        ..loadRequest(Uri.parse(widget.url));
    }
  }

  @override
  Widget build(BuildContext context) {
    // WebView not supported on web
    if (kIsWeb) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.open_in_browser,
              size: 64,
              color: AppColors.primary,
            ),
            const SizedBox(height: 16),
            Text(
              '${widget.title} não está disponível no navegador',
              style: AppTextStyles.body,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                final uri = Uri.parse(widget.url);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              icon: const Icon(Icons.launch),
              label: const Text('Abrir em nova aba'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        if (_progress < 100)
          LinearProgressIndicator(
            value: _progress / 100,
          ),
        Expanded(
          child: WebViewWidget(controller: _controller!),
        ),
      ],
    );
  }
}
