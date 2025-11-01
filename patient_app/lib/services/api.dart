import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config.dart';
import '../model.dart';

SupabaseClient get _client => Supabase.instance.client;

Map<String, String> _authHeaders() {
  final token = _client.auth.currentSession?.accessToken;
  return {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  };
}

Future<dynamic> edgePost(String name, Map<String, dynamic> body) async {
  final url = Uri.parse('$edgeBase/$name');
  final resp = await http.post(url, headers: _authHeaders(), body: jsonEncode(body));
  if (resp.statusCode >= 200 && resp.statusCode < 300) {
    return jsonDecode(resp.body);
  }
  throw Exception('Edge POST $name failed: ${resp.statusCode} ${resp.body}');
}

Future<dynamic> edgeGet(String name, {Map<String, String>? query}) async {
  final uri = Uri.parse('$edgeBase/$name').replace(queryParameters: query ?? {});
  final resp = await http.get(uri, headers: _authHeaders());
  if (resp.statusCode >= 200 && resp.statusCode < 300) {
    return jsonDecode(resp.body);
  }
  throw Exception('Edge GET $name failed: ${resp.statusCode} ${resp.body}');
}

/// --- Patient flows ---

Future<List<Prescription>> fetchPrescriptions() async {
  final data = await edgePost('patient-list-prescriptions', {});
  if (data is List) {
    final List<Prescription> items = data
        .map((e) => Prescription.fromJson(e as Map<String, dynamic>))
        .toList();
    return items;
  }
  return <Prescription>[];
}

Future<TicketPayload> createTicket(String prescriptionId) async {
  final data = await edgePost('patient-create-ticket', {
    'prescription_id': prescriptionId,
  });
  return TicketPayload.fromEdge(data as Map<String, dynamic>);
}

Future<LatestTicket?> getLatestTicket() async {
  final data = await edgeGet('patient-get-ticket', query: {'limit': '1'});
  if (data is Map && data['ticket'] != null) {
    final t = data['ticket'] as Map;
    return LatestTicket(
      jobId: t['job_id'] as String?,
      ticketId: t['id'] as String?,
      otp: t['otp'] as String?,
      qrText: t['qr_text'] as String?,
    );
  }
  return null;
}

Future<bool> reportSymptoms({
  required String jobId,
  String? symptoms,
  String? allergies,
  int? age,
}) async {
  final res = await edgePost('patient-report-symptoms', {
    'job_id': jobId,
    if (age != null) 'age': age,
    'symptoms': symptoms,
    'allergies': allergies,
    'chronic_diseases': null,
  });
  return res is Map && res['ok'] == true;
}

/// สร้างโปรไฟล์ผู้ป่วยถ้ายังไม่มี (ถ้า RLS ไม่อนุญาตจะถูก ignore)
Future<void> ensurePatientProfile({required String displayName}) async {
  final user = _client.auth.currentUser;
  if (user == null) return;

  final existing = await _client
      .from('patients')
      .select('id')
      .eq('user_id', user.id)
      .maybeSingle();

  if (existing != null) return;

  try {
    await _client.from('patients').insert({
      'user_id': user.id,
      'first_name': displayName,
      'last_name': '',
      'display_name': displayName,
    });
  } catch (_) {
    // ignore if RLS forbids
  }
}
