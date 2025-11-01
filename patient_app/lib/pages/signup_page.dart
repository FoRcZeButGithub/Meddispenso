import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});
  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _name = TextEditingController();
  final _age = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  String? _error; bool _busy = false;

  Future<void> _signup() async {
    setState(() { _busy = true; _error = null; });
    try {
      await Supabase.instance.client.auth.signUp(
        email: _email.text.trim(), password: _password.text,
      );
      if (mounted) Navigator.pop(context);
    } on AuthException catch (e) { setState(() => _error = e.message); }
    catch (e) { setState(() => _error = e.toString()); }
    finally { if (mounted) setState(() => _busy = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Sign In', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 16),
                  const Text('Name', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8), TextField(controller: _name),
                  const SizedBox(height: 16),
                  const Text('Age', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8), TextField(controller: _age, keyboardType: TextInputType.number),
                  const SizedBox(height: 16),
                  const Text('email', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8), TextField(controller: _email, keyboardType: TextInputType.emailAddress),
                  const SizedBox(height: 16),
                  const Text('password', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8), TextField(controller: _password, obscureText: true),
                  const SizedBox(height: 24),
                  if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
                  FilledButton(onPressed: _busy ? null : _signup,
                    style: FilledButton.styleFrom(backgroundColor: AppColors.brand, foregroundColor: Colors.white),
                    child: _busy ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Sign up')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
