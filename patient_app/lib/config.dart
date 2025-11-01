// lib/config.dart
class AppConfig {
  // ✅ ใช้โดเมนจริงของโปรเจกต์ (ต้องมี https:// และห้ามมี % หรือ < >)
  static const supabaseUrl = 'https://gzdxnkejgebiwraxoakl.supabase.co';

  // ✅ ใช้ ANON KEY (ไม่ใช่ service_role)
  static const supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd6ZHhua2VqZ2ViaXdyYXhvYWtsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTY3ODUxMjAsImV4cCI6MjA3MjM2MTEyMH0.cuoZf12ACP6MDAWEpl8eC6PvHmPG5vbn8abZGX7iavQ';

  // Edge Functions base (เผื่อไฟล์ api.dart เรียกใช้)
  static const functionsBase = '$supabaseUrl/functions/v1';
}
