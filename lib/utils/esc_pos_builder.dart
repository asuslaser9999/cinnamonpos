import 'dart:convert';

/// Builds raw ESC/POS byte commands for 58mm / 80mm thermal printers.
class EscPosBuilder {
  final List<int> _bytes = [];

  List<int> get bytes => List.unmodifiable(_bytes);

  void reset() {
    _bytes.addAll(const [0x1B, 0x40]);
  }

  void fontA() {
    _bytes.addAll(const [0x1B, 0x4D, 0x00]);
  }

  void fontB() {
    _bytes.addAll(const [0x1B, 0x4D, 0x01]);
  }

  void bold({required bool on}) {
    _bytes.addAll([0x1B, 0x45, on ? 0x01 : 0x00]);
  }

  void alignLeft() {
    _bytes.addAll(const [0x1B, 0x61, 0x00]);
  }

  void alignCenter() {
    _bytes.addAll(const [0x1B, 0x61, 0x01]);
  }

  void alignRight() {
    _bytes.addAll(const [0x1B, 0x61, 0x02]);
  }

  void text(String value) {
    _bytes.addAll(const Latin1Codec(allowInvalid: true).encode(value));
  }

  void newline([int count = 1]) {
    for (var i = 0; i < count; i++) {
      _bytes.add(0x0A);
    }
  }

  void line(String value) {
    text(value);
    newline();
  }

  void separator(int width, {String char = '='}) {
    line(char * width);
  }

  void feedAndCut({int feedLines = 3}) {
    newline(feedLines);
    _bytes.addAll(const [0x1D, 0x56, 0x42, 0x00]);
  }
}
