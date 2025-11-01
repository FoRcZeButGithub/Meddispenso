// lib/api.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'config.dart' as cfg;
import 'models.dart';

class Api {
  Map<String, String> _headers({String? deviceKey}) => {
        'Authorization': 'Bearer ${cfg.anonKey}',
        'Content-Type': 'application/json',
        if (deviceKey != null) 'x-device-key': deviceKey,
      };

  /// Redeem ด้วย QR: ticket + otp
  Future<RedeemResp> redeem({
    required String deviceId,
    required String deviceKeyPlain,
    required String ticketId,
    required String otp,
  }) async {
    final uri = Uri.parse('${cfg.functionBase}/device_redeem_ticket');
    final r = await http.post(
      uri,
      headers: _headers(deviceKey: deviceKeyPlain),
      body: jsonEncode({'device_id': deviceId, 'ticket_id': ticketId, 'otp': otp}),
    );
    final j = _decodeJson(r.bodyBytes);
    if (r.statusCode != 200 || j['ok'] != true) {
      return RedeemResp(ok: false, error: j['error'] ?? r.reasonPhrase);
    }
    return RedeemResp.fromJson(j);
  }

  /// Redeem ด้วย PIN ล้วน ๆ
  Future<RedeemResp> redeemPin({
    required String deviceId,
    required String otp,
  }) async {
    final uri = Uri.parse('${cfg.functionBase}/device_redeem_pin');
    final r = await http.post(
      uri,
      headers: _headers(deviceKey: cfg.deviceKey),
      body: jsonEncode({'device_id': deviceId, 'otp': otp}),
    );
    final j = _decodeJson(r.bodyBytes);
    if (r.statusCode != 200 || j['ok'] != true) {
      return RedeemResp(ok: false, error: j['error'] ?? r.reasonPhrase);
    }
    return RedeemResp.fromJson(j);
  }

  /// รายงานผลหลังจ่ายยา
  Future<bool> report({
    required String deviceId,
    required String jobId,
    required bool okFlag,
    int? pulses,
  }) async {
    final uri = Uri.parse('${cfg.functionBase}/device_report');
    final r = await http.post(
      uri,
      headers: _headers(deviceKey: cfg.deviceKey),
      body: jsonEncode({
        'device_id': deviceId,
        'job_id': jobId,
        'ok': okFlag,
        if (pulses != null) 'pulses': pulses,
      }),
    );
    return r.statusCode == 200;
  }

  Map<String, dynamic> _decodeJson(List<int> bytes) {
    final txt = utf8.decode(bytes);
    try {
      return jsonDecode(txt) as Map<String, dynamic>;
    } catch (_) {
      return {'ok': false, 'error': 'Invalid JSON: $txt'};
    }
  }
}

final api = Api();
