// lib/models.dart
class RedeemResp {
  final bool ok;
  final String? jobId;
  final int? units;
  final int? stepsPerUnit;
  final int? motorIndex;
  final String? patientId;
  final String? patientName;
  final String? error;

  RedeemResp({
    required this.ok,
    this.jobId,
    this.units,
    this.stepsPerUnit,
    this.motorIndex,
    this.patientId,
    this.patientName,
    this.error,
  });

  factory RedeemResp.fromJson(Map<String, dynamic> j) {
    int? _toInt(v) => v is int ? v : (v is num ? v.toInt() : null);
    return RedeemResp(
      ok: j['ok'] == true,
      jobId: j['job_id'] as String?,
      units: _toInt(j['units']),
      stepsPerUnit: _toInt(j['steps_per_unit']),
      motorIndex: _toInt(j['motor_index']),
      patientId: j['patient_id']?.toString(),
      patientName: j['patient_name'] as String?,
      error: j['error'] as String?,
    );
  }
}
