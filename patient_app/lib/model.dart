class Prescription {
  final String id;
  final Medicine medicine;
  final int doseUnits;

  Prescription({
    required this.id,
    required this.medicine,
    required this.doseUnits,
  });

  /// รองรับทั้งฟิลด์ `medicine` และ `medicines` (จาก Supabase select)
  factory Prescription.fromJson(Map<String, dynamic> json) {
    final medRaw = json['medicine'] ?? json['medicines'];
    if (medRaw is! Map<String, dynamic>) {
      throw ArgumentError('Prescription.medicine is missing or invalid');
    }
    return Prescription(
      id: json['id'] as String,
      medicine: Medicine.fromJson(medRaw),
      doseUnits: (json['dose_units'] as num).toInt(),
    );
  }
}

class Medicine {
  final String id;
  final String name;
  final String? form;
  final String? strength;
  final String? unit;

  Medicine({
    required this.id,
    required this.name,
    this.form,
    this.strength,
    this.unit,
  });

  factory Medicine.fromJson(Map<String, dynamic> j) => Medicine(
        id: j['id'] as String,
        name: j['name'] as String,
        form: j['form'] as String?,
        strength: j['strength'] as String?,
        unit: j['unit'] as String?,
      );
}

/// payload ที่ได้จาก patient-create-ticket
class TicketPayload {
  final bool ok;
  final String ticketId;
  final String jobId;
  final String otp;      // PIN
  final String qrText;   // "ticket:<id>|otp:<otp>"
  final int units;
  final String deviceId;
  final int? binId;

  TicketPayload({
    required this.ok,
    required this.ticketId,
    required this.jobId,
    required this.otp,
    required this.qrText,
    required this.units,
    required this.deviceId,
    required this.binId,
  });

  factory TicketPayload.fromEdge(Map<String, dynamic> j) => TicketPayload(
        ok: j['ok'] == true,
        ticketId: j['ticket_id'] as String,
        jobId: j['job_id'] as String,
        otp: j['otp'] as String,
        qrText: (j['qr_text'] ?? 'ticket:${j['ticket_id']}|otp:${j['otp']}') as String,
        units: ((j['payload']?['units'] ?? j['units']) as num? ?? 1).toInt(),
        deviceId: (j['payload']?['device_id'] ?? j['device_id']) as String,
        binId: (j['payload']?['bin_id']) as int?,
      );
}

class LatestTicket {
  final String? jobId;
  final String? ticketId;
  final String? otp;
  final String? qrText;
  LatestTicket({this.jobId, this.ticketId, this.otp, this.qrText});
}
