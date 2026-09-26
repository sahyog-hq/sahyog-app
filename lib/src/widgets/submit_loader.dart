import 'package:flutter/material.dart';

import '../core/friendly_error.dart';

/// Full-screen spinner while a submit/upload runs.
/// Back or "Go back" dismisses the loader; the in-flight request is ignored.
Future<bool> runWithLoader(
  BuildContext context, {
  required Future<void> Function() action,
  String message = 'Please wait…',
}) async {
  if (!context.mounted) return false;

  var dialogOpen = true;
  showDialog<void>(
    context: context,
    barrierDismissible: true,
    useRootNavigator: true,
    builder: (dialogContext) {
      return PopScope(
        canPop: true,
        child: AlertDialog(
          content: Row(
            children: [
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
              const SizedBox(width: 16),
              Expanded(child: Text(message)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Go back'),
            ),
          ],
        ),
      );
    },
  ).whenComplete(() => dialogOpen = false);

  try {
    await action();
    return true;
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyError(error))),
      );
    }
    return false;
  } finally {
    if (dialogOpen && context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }
}
