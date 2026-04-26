class ErrorUtils {
  static String friendly(
    String raw, {
    String fallback = 'Something went wrong. Please try again.',
  }) {
    final clean = raw.replaceAll('Exception: ', '').trim();
    if (clean.isEmpty) return fallback;
    final lower = clean.toLowerCase();
    if (lower.contains('failed host lookup') || lower.contains('socket')) {
      return 'Network unavailable. Check your connection.';
    }
    if (lower.contains('timeout')) {
      return 'Request timed out. Please retry.';
    }
    if (lower.contains('500')) {
      return 'Server is unavailable right now. Please try again later.';
    }
    if (lower.contains('401')) {
      return 'Session expired. Please sign in again.';
    }
    return clean;
  }
}
