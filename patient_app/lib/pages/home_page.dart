import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme.dart';
import 'symptom_page.dart';
import 'tickets_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final hello = 'Hello ${user?.email?.split('@').first ?? 'Patient'}';
    return Scaffold(
      appBar: AppBar(title: const Text('My prescription')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(alignment: Alignment.centerRight, child: Text(hello, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.subtext))),
            const SizedBox(height: 16),
            AppCard(child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.qr_code_scanner, color: AppColors.brand),
                  title: const Text('View Qr code/Pin', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.text, fontSize: 18)),
                  subtitle: const Text('Create ticket for your prescription'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TicketsPage())),
                ),
                const Divider(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.notes_outlined, color: AppColors.brand),
                  title: const Text('Send symtom', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.text, fontSize: 18)),
                  subtitle: const Text('Report symptoms & allergies'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SymptomPage())),
                ),
              ],
            )),
            const Spacer(),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Supabase.instance.client.auth.signOut(),
                child: const Text('Sign out'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
