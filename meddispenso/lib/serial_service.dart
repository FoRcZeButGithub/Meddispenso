// lib/serial_service.dart
// Stub ชั่วคราวเพื่อให้บิลด์ได้ทุกแพลตฟอร์ม (Android/Tab S8 ก็รันได้)
// ถ้าคุณมีโค้ด Serial จริง ค่อยสลับกลับภายหลัง

class SerialService {
  static final SerialService instance = SerialService._();
  SerialService._();

  bool _inited = false;

  Future<void> initialize() async {
    // TODO: ใส่โค้ดเชื่อมต่ออุปกรณ์จริงภายหลัง
    _inited = true;
  }

  bool get isInitialized => _inited;

  // ตัวอย่าง API ให้โค้ดเดิมเรียกใช้ได้ (ไม่ทำอะไรตอนนี้)
  List<String> listPorts() => const [];
  Future<void> connect(String name) async {}
  Future<void> disconnect() async {}
}
