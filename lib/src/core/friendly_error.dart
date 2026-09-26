import 'api_client.dart';

String friendlyError(Object error) {
  final raw = error.toString();
  final lower = raw.toLowerCase();

  if (lower.contains('row-level security') ||
      lower.contains('row level security') ||
      lower.contains('rls') ||
      lower.contains('storage upload failed')) {
    return 'Could not save the photo. You can submit without a photo, or try again in a moment.';
  }
  if (lower.contains('location permission') ||
      lower.contains('permission denied')) {
    return 'Location permission is off. Enable it in Settings, or continue without location.';
  }
  if (lower.contains('location service is disabled') ||
      lower.contains('disabled')) {
    return 'Turn on GPS / location services and try again.';
  }
  if (lower.contains('timeout') || lower.contains('timed out')) {
    return 'That took too long. Check your connection and try again.';
  }
  if (lower.contains('socketexception') ||
      lower.contains('failed host lookup') ||
      lower.contains('network is unreachable')) {
    return 'No internet right now. The action was saved locally where possible.';
  }
  if (error is ApiException) {
    if (error.statusCode == 401) return 'Please sign in again.';
    if (error.statusCode == 403) {
      return 'You do not have permission for this action.';
    }
    if (error.statusCode >= 500) {
      return error.message.isNotEmpty
          ? error.message
          : 'Server error. Please try again.';
    }
    return error.message;
  }
  return raw.replaceFirst('Exception: ', '');
}
