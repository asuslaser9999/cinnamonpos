import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

const supabaseCallTimeout = Duration(seconds: 12);

bool isNetworkError(Object error) {
  if (error is TimeoutException) return true;
  if (error is SocketException) return true;
  if (error is HandshakeException) return true;
  if (error is HttpException) return true;

  final text = error.toString().toLowerCase();
  return text.contains('socket') ||
      text.contains('failed host lookup') ||
      text.contains('network') ||
      text.contains('connection') ||
      text.contains('timed out') ||
      text.contains('timeout') ||
      text.contains('offline') ||
      text.contains('clientexception') ||
      text.contains('xmlhttprequest');
}

bool isUniqueViolation(Object error) {
  if (error is PostgrestException && error.code == '23505') return true;
  final text = error.toString().toLowerCase();
  return text.contains('23505') || text.contains('duplicate');
}

String checkoutKeepCartMessage(Object error) {
  if (isNetworkError(error)) {
    return 'Koneksi terputus. Keranjang tidak dihapus.';
  }
  return 'Gagal menyimpan transaksi. Keranjang tidak dihapus. '
      'Coba Bayar lagi.';
}
