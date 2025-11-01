import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme.dart';
import 'signup_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false; String? _error;

  Future<void> _login() async {
    setState(() { _busy = true; _error = null; });
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: _email.text.trim(), password: _password.text);
    } on AuthException catch (e) { _error = e.message; }
    catch (e) { _error = '$e'; }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),
                  const Text('Sign In', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: AppColors.text)),
                  const SizedBox(height: 20),
                  AppCard(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('email', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.text)),
                      const SizedBox(height: 8),
                      TextField(controller: _email, keyboardType: TextInputType.emailAddress),
                      const SizedBox(height: 18),
                      const Text('password', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.text)),
                      const SizedBox(height: 8),
                      TextField(controller: _password, obscureText: true),
                      const SizedBox(height: 16),
                      if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 8),
                      FilledButton(
                        onPressed: _busy ? null : _login,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.brand, foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(54),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: _busy
                          ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('LOGIN', style: TextStyle(fontWeight: FontWeight.w800)),
                      ),
                    ],
                  )),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignUpPage())),
                    child: const Text("if you don’t have account Create one"),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
