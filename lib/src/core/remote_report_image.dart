import 'package:flutter/material.dart';

/// Shows a report photo fetched from the server, with a spinner while it loads.
class RemoteReportImage extends StatelessWidget {
  const RemoteReportImage({
    super.key,
    required this.url,
    this.size = 56,
    this.icon = Icons.image_outlined,
  });

  final String? url;
  final double size;
  final IconData icon;

  bool get _isRemote {
    final value = url ?? '';
    return value.startsWith('http://') || value.startsWith('https://');
  }

  @override
  Widget build(BuildContext context) {
    if (!_isRemote) {
      return _placeholder(context);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(size / 2),
      child: Image.network(
        url!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          final total = progress.expectedTotalBytes;
          final value = total == null
              ? null
              : progress.cumulativeBytesLoaded / total;
          return SizedBox(
            width: size,
            height: size,
            child: Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, value: value),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => _placeholder(context),
      ),
    );
  }

  Widget _placeholder(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: size * 0.45),
    );
  }
}

String? firstNetworkImage(dynamic raw) {
  if (raw is! List) return null;
  for (final item in raw) {
    final value = item.toString();
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }
  }
  return null;
}
