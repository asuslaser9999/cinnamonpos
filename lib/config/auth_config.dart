/// Domain email internal — sama dengan Ultimate POS agar username lama tetap bisa login
/// sebelum / jika RPC `cn_resolve_login_email` belum di-deploy.
const internalAuthEmailDomain = '@mulyasari.pos';

String usernameToInternalEmail(String username) {
  return '${username.trim().toLowerCase()}$internalAuthEmailDomain';
}

String? usernameFromInternalEmail(String? email) {
  if (email == null || email.isEmpty) return null;
  if (!email.endsWith(internalAuthEmailDomain)) return null;
  return email.substring(0, email.length - internalAuthEmailDomain.length);
}

bool isValidUsername(String username) {
  final normalized = username.trim().toLowerCase();
  if (normalized.length < 3 || normalized.length > 32) return false;
  return RegExp(r'^[a-z0-9_]+$').hasMatch(normalized);
}

bool isValidLoginInput(String input) {
  final trimmed = input.trim();
  if (trimmed.isEmpty) return false;
  if (trimmed.contains('@')) {
    return trimmed.length >= 5 && trimmed.contains('.');
  }
  return isValidUsername(trimmed);
}
