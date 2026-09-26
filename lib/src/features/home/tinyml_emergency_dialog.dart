import 'package:flutter/material.dart';
import '../../core/anomaly_detection_service.dart';
import '../../core/api_client.dart';
import '../../core/local_notification_service.dart';
import '../../theme/app_colors.dart';

class TinyMLEmergencyDialog extends StatefulWidget {
  final AnomalyEvent event;
  final ApiClient? api;
  final void Function(String anomalyType, String description)? onAutoSosTriggered;

  const TinyMLEmergencyDialog({
    super.key,
    required this.event,
    this.api,
    this.onAutoSosTriggered,
  });

  static Future<void> show(
    BuildContext context, 
    AnomalyEvent event, 
    {
      ApiClient? api, 
      void Function(String anomalyType, String description)? onAutoSosTriggered,
    }
  ) {
    return showDialog(
      context: context,
      barrierDismissible: false, // Force user interaction or wait for countdown
      builder: (ctx) => TinyMLEmergencyDialog(
        event: event, 
        api: api,
        onAutoSosTriggered: onAutoSosTriggered,
      ),
    );
  }

  @override
  State<TinyMLEmergencyDialog> createState() => _TinyMLEmergencyDialogState();
}

class _TinyMLEmergencyDialogState extends State<TinyMLEmergencyDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late final AnomalyDetectionService _engine;

  @override
  void initState() {
    super.initState();
    _engine = AnomalyDetectionService.instance;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _engine.timerState.addListener(_onTimerState);
    LocalNotificationService.instance.showMeshSosNotification(
      title: '🚨 ${widget.event.title}',
      body: 'Emergency countdown initiated. Tap I AM OKAY to cancel auto-SOS.',
    );
  }

  void _onTimerState() {
    if (!mounted) return;
    if (_engine.timerState.value == SosTimerState.expired) {
      Navigator.of(context).maybePop();
    }
  }

  void _cancel() {
    _engine.timerState.removeListener(_onTimerState);
    _engine.cancelSOSTimer();
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Emergency countdown cancelled. Glad you are okay!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  void dispose() {
    _engine.timerState.removeListener(_onTimerState);
    if (_engine.timerState.value == SosTimerState.running) {
      _engine.cancelSOSTimer();
    }
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.criticalRed.withValues(
                      alpha: 0.1 + (_pulseController.value * 0.2),
                    ),
                    border: Border.all(
                      color: AppColors.criticalRed.withValues(
                        alpha: 0.4 + (_pulseController.value * 0.6),
                      ),
                      width: 3,
                    ),
                  ),
                  child: const Icon(
                    Icons.sensors_rounded,
                    size: 48,
                    color: AppColors.criticalRed,
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            Text(
              widget.event.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.criticalRed,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              widget.event.description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.criticalRed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.criticalRed.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  const Text(
                    'AUTO SOS DISTRESS DISPATCH IN',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ValueListenableBuilder<int>(
                    valueListenable: _engine.countdownSeconds,
                    builder: (context, seconds, _) {
                      return Text(
                        '${seconds}s',
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          color: AppColors.criticalRed,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _cancel,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.check_circle_rounded),
                label: const Text(
                  'I AM OKAY (CANCEL)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
