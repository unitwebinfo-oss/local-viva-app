import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/theme.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Open link directly and go back
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final url = Uri.parse('https://localviva.com.br/cadastrar');
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
      Navigator.of(context).pop();
    });

    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
