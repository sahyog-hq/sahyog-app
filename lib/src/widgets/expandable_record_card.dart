import 'package:flutter/material.dart';
import 'package:sahyog_app/l10n/app_localizations.dart';

import '../core/remote_report_image.dart';
import '../theme/app_colors.dart';

class ExpandableRecordCard extends StatefulWidget {
  const ExpandableRecordCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.imageUrls,
    this.details = const [],
    this.trailing,
    this.placeholderIcon = Icons.image_outlined,
    this.accentColor,
  });

  final String title;
  final String subtitle;
  final List<String> imageUrls;
  final List<Widget> details;
  final Widget? trailing;
  final IconData placeholderIcon;
  final Color? accentColor;

  @override
  State<ExpandableRecordCard> createState() => _ExpandableRecordCardState();
}

class _ExpandableRecordCardState extends State<ExpandableRecordCard>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;

  void _toggle() => setState(() => _expanded = !_expanded);

  void _openPhoto(String url) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        pageBuilder: (_, __, ___) => _PhotoViewer(url: url),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final accent = widget.accentColor ?? AppColors.primaryGreen;
    final hasPhoto = widget.imageUrls.isNotEmpty;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: AnimatedSize(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        alignment: Alignment.topCenter,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: _toggle,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    hasPhoto
                        ? RemoteReportImage(
                            url: widget.imageUrls.first,
                            size: 56,
                            icon: widget.placeholderIcon,
                            onTap: () => _openPhoto(widget.imageUrls.first),
                          )
                        : CircleAvatar(
                            radius: 28,
                            backgroundColor: accent.withValues(alpha: 0.15),
                            child: Icon(widget.placeholderIcon, color: accent),
                          ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.subtitle,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _expanded
                                ? l10n.description
                                : l10n.tapToViewDetails,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: accent,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (widget.trailing != null) widget.trailing!,
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 220),
                      child: Icon(
                        Icons.expand_more_rounded,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_expanded) ...[
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (hasPhoto)
                      SizedBox(
                        height: 180,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: widget.imageUrls.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 10),
                          itemBuilder: (context, index) {
                            final url = widget.imageUrls[index];
                            return RemoteReportImage(
                              url: url,
                              width: 220,
                              height: 180,
                              circular: false,
                              borderRadius: BorderRadius.circular(14),
                              icon: widget.placeholderIcon,
                              onTap: () => _openPhoto(url),
                            );
                          },
                        ),
                      )
                    else
                      Text(
                        l10n.noPhoto,
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      ),
                    if (widget.details.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      ...widget.details,
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class DetailRow extends StatelessWidget {
  const DetailRow({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13, height: 1.35)),
          ),
        ],
      ),
    );
  }
}

class _PhotoViewer extends StatelessWidget {
  const _PhotoViewer({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: InteractiveViewer(
              child: RemoteReportImage(
                url: url,
                width: MediaQuery.sizeOf(context).width - 32,
                height: MediaQuery.sizeOf(context).height * 0.7,
                circular: false,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String formatLastSeen(dynamic loc) {
  if (loc is Map) {
    final lat = loc['lat'] ?? loc['latitude'];
    final lng = loc['lng'] ?? loc['longitude'];
    if (lat != null && lng != null) return '$lat, $lng';
  }
  final value = loc?.toString() ?? '';
  if (value == 'null') return '';
  return value;
}
