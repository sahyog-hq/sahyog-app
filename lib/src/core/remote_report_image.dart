import 'package:flutter/material.dart';
import 'package:sahyog_app/l10n/app_localizations.dart';

class RemoteReportImage extends StatelessWidget {
  const RemoteReportImage({
    super.key,
    required this.url,
    this.size = 56,
    this.width,
    this.height,
    this.icon = Icons.image_outlined,
    this.circular = true,
    this.borderRadius,
    this.onTap,
    this.showRetry = true,
  });

  final String? url;
  final double size;
  final double? width;
  final double? height;
  final IconData icon;
  final bool circular;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;
  final bool showRetry;

  bool get _isRemote {
    final value = url ?? '';
    return value.startsWith('http://') || value.startsWith('https://');
  }

  double get _w => width ?? size;
  double get _h => height ?? size;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ??
        (circular ? BorderRadius.circular(_w / 2) : BorderRadius.circular(12));
    final child = !_isRemote
        ? _placeholder(context, radius)
        : _NetworkPhoto(
            url: url!,
            width: _w,
            height: _h,
            icon: icon,
            radius: radius,
            showRetry: showRetry,
          );

    if (onTap == null) return child;
    return GestureDetector(onTap: onTap, child: child);
  }

  Widget _placeholder(BuildContext context, BorderRadius radius) {
    return Container(
      width: _w,
      height: _h,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: radius,
      ),
      child: Icon(icon, size: (_w < _h ? _w : _h) * 0.45),
    );
  }
}

class _NetworkPhoto extends StatefulWidget {
  const _NetworkPhoto({
    required this.url,
    required this.width,
    required this.height,
    required this.icon,
    required this.radius,
    required this.showRetry,
  });

  final String url;
  final double width;
  final double height;
  final IconData icon;
  final BorderRadius radius;
  final bool showRetry;

  @override
  State<_NetworkPhoto> createState() => _NetworkPhotoState();
}

class _NetworkPhotoState extends State<_NetworkPhoto> {
  int _generation = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final cacheW = widget.width.isFinite
        ? (widget.width * dpr).round().clamp(48, 720)
        : 720;

    return ClipRRect(
      borderRadius: widget.radius,
      child: Image.network(
        widget.url,
        key: ValueKey('${widget.url}-$_generation'),
        width: widget.width.isFinite ? widget.width : null,
        height: widget.height.isFinite ? widget.height : null,
        fit: BoxFit.cover,
        cacheWidth: cacheW,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          final total = progress.expectedTotalBytes;
          final value = total == null
              ? null
              : progress.cumulativeBytesLoaded / total;
          return Container(
            width: widget.width,
            height: widget.height,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.2, value: value),
                ),
                if (widget.height >= 88) ...[
                  const SizedBox(height: 8),
                  Text(
                    l10n.loadingPhoto,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                  ),
                ],
              ],
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: widget.width,
            height: widget.height,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(widget.icon, size: 22, color: Colors.grey.shade600),
                const SizedBox(height: 4),
                Text(
                  l10n.photoFailed,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                ),
                if (widget.showRetry)
                  TextButton(
                    onPressed: () => setState(() => _generation++),
                    child: Text(l10n.retryPhoto),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

String? firstNetworkImage(dynamic raw) {
  final urls = networkImageUrls(raw);
  return urls.isEmpty ? null : urls.first;
}

List<String> networkImageUrls(dynamic raw) {
  if (raw is String) {
    return _isHttp(raw) ? [raw] : const [];
  }
  if (raw is! List) return const [];
  final urls = <String>[];
  for (final item in raw) {
    final value = item.toString();
    if (_isHttp(value)) urls.add(value);
  }
  return urls;
}

bool _isHttp(String value) =>
    value.startsWith('http://') || value.startsWith('https://');
