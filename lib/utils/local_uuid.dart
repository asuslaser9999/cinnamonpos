import 'dart:math';

String newLocalUuid() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  String hex(int index) => bytes[index].toRadixString(16).padLeft(2, '0');
  return '${hex(0)}${hex(1)}${hex(2)}${hex(3)}-'
      '${hex(4)}${hex(5)}-'
      '${hex(6)}${hex(7)}-'
      '${hex(8)}${hex(9)}-'
      '${hex(10)}${hex(11)}${hex(12)}${hex(13)}${hex(14)}${hex(15)}';
}

String localSaleNumber(DateTime soldAt, String uuid) {
  final stamp =
      '${soldAt.year}'
      '${soldAt.month.toString().padLeft(2, '0')}'
      '${soldAt.day.toString().padLeft(2, '0')}';
  final short = uuid.replaceAll('-', '').substring(0, 8);
  return 'CN$stamp-$short';
}
