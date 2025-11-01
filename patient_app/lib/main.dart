import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config.dart';
import 'theme.dart';
import 'pages/login_page.dart';
import 'pages/home_page.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext context) {
    final client = Supabase.instance.client;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Meddispenso Patient',
      theme: buildAppTheme(),
      home: StreamBuilder<AuthState>(
        stream: client.auth.onAuthStateChange,
        builder: (context, _) {
          final session = client.auth.currentSession;
          return session == null ? const LoginPage() : const HomePage();
        },
      ),
    );
  }
}
