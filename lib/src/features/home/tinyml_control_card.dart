import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import '../../core/tinyml_sensor_service.dart';
import 'package:sahyog_app/l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import 'tinyml_emergency_dialog.dart';

class TinyMLControlCard extends StatefulWidget {
  final ApiClient? api;
  final void Function(String anomalyType, String description)? onAutoSosTriggered;

  const TinyMLControlCard({
    super.key,
    this.api,
    this.onAutoSosTriggered,
  });

  @override
  State<TinyMLControlCard> createState() => _TinyMLControlCardState();
}

class _TinyMLControlCardState extends State<TinyMLControlCard> {
  late bool _isEnabled;
  late TinyMLSensitivity _sensitivity;

  @override
  void initState() {
    super.initState();
    _isEnabled = TinyMLSensorService.instance.isEnabled;
    _sensitivity = TinyMLSensorService.instance.sensitivity;

    // Listen for anomaly events to automatically display modal
    TinyMLSensorService.instance.onAnomalyDetected = (event) async {
      try {
        if (!mounted) return;
        await TinyMLEmergencyDialog.show(
          context,
          event,
          api: widget.api,
          onAutoSosTriggered: widget.onAutoSosTriggered,
        );
      } finally {
        TinyMLSensorService.instance.finishAlert();
      }
    };
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: _isEnabled
              ? AppColors.primaryGreen.withValues(alpha: 0.3)
              : Colors.grey.withValues(alpha: 0.2),
        ),
      ),
      color: isDark ? const Color(0xFF1E242B) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (_isEnabled ? AppColors.primaryGreen : Colors.grey)
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.sensors_rounded,
                    color: _isEnabled ? AppColors.primaryGreen : Colors.grey,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.tinymlTitle,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _isEnabled
                            ? '${l10n.detecting_activity} — ${l10n.tinymlActive}'
                            : l10n.tinymlDisabled,
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _isEnabled,
                  activeColor: AppColors.primaryGreen,
                  onChanged: (val) {
                    setState(() {
                      _isEnabled = val;
                    });
                    TinyMLSensorService.instance.setEnabled(val);
                  },
                ),
              ],
            ),

            if (_isEnabled) ...[
              const Divider(height: 24),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sensitivity Mode:',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _ModeOptionButton(
                            label: 'Testing (Low Threshold)',
                            icon: Icons.bug_report_outlined,
                            isSelected: _sensitivity == TinyMLSensitivity.testing,
                            onTap: () {
                              setState(() => _sensitivity = TinyMLSensitivity.testing);
                              TinyMLSensorService.instance.setSensitivity(TinyMLSensitivity.testing);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _ModeOptionButton(
                            label: 'Production Mode',
                            icon: Icons.shield_outlined,
                            isSelected: _sensitivity == TinyMLSensitivity.production,
                            onTap: () {
                              setState(() => _sensitivity = TinyMLSensitivity.production);
                              TinyMLSensorService.instance.setSensitivity(TinyMLSensitivity.production);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                'TEST ANOMALY DETECTORS:',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _TestChip(
                    label: '🪂 Drop / Freefall',
                    onTap: () => TinyMLSensorService.instance.simulateAnomaly(AnomalyType.freefallImpact),
                  ),
                  _TestChip(
                    label: '🧍 Man-Down',
                    onTap: () => TinyMLSensorService.instance.simulateAnomaly(AnomalyType.manDownImmobility),
                  ),
                  _TestChip(
                    label: '💥 Crash Impact',
                    onTap: () => TinyMLSensorService.instance.simulateAnomaly(AnomalyType.highImpactCrash),
                  ),
                  _TestChip(
                    label: '🚨 Panic Shake',
                    onTap: () => TinyMLSensorService.instance.simulateAnomaly(AnomalyType.panicShake),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TestChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _TestChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }
}

class _ModeOptionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeOptionButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = AppColors.primaryGreen;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? primary.withValues(alpha: 0.15)
              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? primary
                : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.15),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected
                  ? primary
                  : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.visible,
                style: TextStyle(
                  fontSize: 11,
                  height: 1.1,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected
                      ? primary
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
