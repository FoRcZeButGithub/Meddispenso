import 'dart:async';
import 'dart:convert';
import 'package:flutter_libserialport/flutter_libserialport.dart';

class SerialService {
  SerialPort? _port;
  SerialPortReader? _reader;
  StreamSubscription<Uint8List>? _sub;

  final _lines = StreamController<String>.broadcast();
  Stream<String> get lines => _lines.stream;

  bool get isOpen => _port?.isOpen == true;

  List<String> listPorts() => SerialPort.availablePorts;

  bool open(String name, {int baud = 115200}) {
    close();
    final p = SerialPort(name);
    if (!p.openReadWrite()) return false;

    final cfg = SerialPortConfig()
      ..baudRate = baud
      ..bits = 8
      ..parity = SerialPortParity.none
      ..stopBits = 1
      ..setFlowControl(SerialPortFlowControl.none);
    p.config = cfg;

    _port = p;
    _reader = SerialPortReader(p);
    _sub = _reader!.stream.listen((data) {
      final s = utf8.decode(data, allowMalformed: true);
      for (final line in s.split(RegExp(r'\r?\n'))) {
        if (line.trim().isNotEmpty) _lines.add(line.trim());
      }
    });
    return true;
  }

  Future<void> writeLine(String line) async {
    final payload = utf8.encode('$line\r\n');
    _port?.write(payload);
  }

  void close() {
    _sub?.cancel();
    _reader?.close();
    if (_port?.isOpen == true) _port?.close();
    _sub = null; _reader = null; _port = null;
  }

  void dispose() { close(); _lines.close(); }
}
