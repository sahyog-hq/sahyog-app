import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/api_client.dart';
import '../../core/database_helper.dart';
import '../../core/location_service.dart';
import '../../core/models.dart';
import '../../core/sos_state_machine.dart';
import '../../core/sos_sync_engine.dart';
import '../../core/socket_service.dart';
import '../../theme/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'nearby_sos_radar_sheet.dart';
import 'sos_alerts_panel.dart';
import '../../core/mesh_service.dart';
import '../../core/tinyml_sensor_service.dart';
import '../../core/friendly_error.dart';
import '../../widgets/submit_loader.dart';
import 'package:sahyog_app/l10n/app_localizations.dart';

class EmergencySosBox extends StatefulWidget {
  const EmergencySosBox({
    super.key,
    required this.user,
    required this.api,
    this.onSosTap,
    this.onSosLocationTap,
  });

  final AppUser user;
  final ApiClient api;
  final VoidCallback? onSosTap;
  final Function(LatLng)? onSosLocationTap;

  @override
  State<EmergencySosBox> createState() => EmergencySosBoxState();
}

class EmergencySosBoxState extends State<EmergencySosBox>
    with AutomaticKeepAliveClientMixin {
  final _locationService = LocationService();

  int _sosHoldTicks = 0;
  Timer? _sosHoldTimer;
  bool _sosFired = false;
  String? _activeSosId;
  String? _activeLocalUuid;
  String _selectedDisaster = 'Emergency';
  int? _activePointer;
  ScrollHoldController? _scrollHold;

  static const _disasterTypes = <({String value, IconData icon})>[
    (value: 'Medical', icon: Icons.medical_services_rounded),
    (value: 'Fire', icon: Icons.local_fire_department_rounded),
    (value: 'Flood', icon: Icons.flood_rounded),
    (value: 'Earthquake', icon: Icons.landslide_rounded),
    (value: 'Accident', icon: Icons.car_crash_rounded),
  ];

  String _disasterLabel(AppLocalizations l10n, String value) {
    return switch (value) {
      'Flood' => l10n.disasterFlood,
      'Earthquake' => l10n.disasterEarthquake,
      'Fire' => l10n.disasterFire,
      'Landslide' => l10n.disasterLandslide,
      'Medical' => l10n.disasterMedical,
      'Accident' => l10n.disasterAccident,
      _ => l10n.disasterOther,
    };
  }

  final Map<String, GlobalKey> _chipKeys = {
    for (final type in _disasterTypes) type.value: GlobalKey(),
  };

  @override
  void initState() {
    super.initState();
    _checkActiveSOS();
  }

  @override
  void dispose() {
    _sosHoldTimer?.cancel();
    _unlockParentScroll();
    super.dispose();
  }

  Future<void> _checkActiveSOS() async {
    final db = DatabaseHelper.instance;
    final active = await db.getActiveIncident(widget.user.id);
    if (active != null) {
      if (mounted) {
        setState(() {
          _activeLocalUuid = active.uuid;
          _activeSosId = active.backendId;
          _sosFired = true;
        });
      }
    }
  }

  // ─────────────────────────────────────────────────────────
  // SOS Activation — State Machine Driven
  // ─────────────────────────────────────────────────────────

  static bool _sending = false;

  Future<void> triggerSOS({String? anomalyType, String? anomalyDesc}) async {
    if (_sending || _sosFired) return;
    _sending = true;
    _sosHoldTimer?.cancel();
    final db = DatabaseHelper.instance;

    try {
    final existing = await db.getActiveIncident(widget.user.id);
    if (existing != null) {
      SosLog.event(existing.uuid, 'DOUBLE_TRIGGER_BLOCKED');
      if (mounted) {
        setState(() {
          _activeLocalUuid = existing.uuid;
          _activeSosId = existing.backendId;
          _sosFired = true;
        });
      }
      return;
    }

    if (!mounted) return;
    await runWithLoader(
      context,
      message: 'Sending SOS…',
      action: () async {
        Position? pos;
        try {
          pos = await _locationService.getCurrentPosition().timeout(
            const Duration(seconds: 12),
          );
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(friendlyError(e))),
            );
          }
        }

        final incident = SosIncident(
          reporterId: widget.user.id,
          lat: pos?.latitude,
          lng: pos?.longitude,
          // Disaster-type chips are UI-only for now; server still gets Emergency.
          type: 'Emergency',
          status: SosStatus.activating,
        );

        SosLog.event(
          incident.uuid,
          'ACTIVATE',
          'lat=${pos?.latitude}, lng=${pos?.longitude}',
        );

        await db.insertSosIncident(incident);
        await db.atomicUpdateIncident(
          incident.uuid,
          status: SosStatus.activeOffline,
        );

        if (mounted) {
          setState(() {
            _activeLocalUuid = incident.uuid;
            _sosFired = true;
          });
        }

        SosLog.event(incident.uuid, 'IMMEDIATE_SYNC_ATTEMPT');

        final payload = {
          'uuid': incident.uuid,
          'type': 'Emergency',
          'lat': pos?.latitude,
          'lng': pos?.longitude,
          'reporter_id': widget.user.id,
          'reporter_name': widget.user.name,
          'reporter_phone': widget.user.phone,
          'hop_count': 0,
        };

        // Always start BLE so nearby phones hear it even if the API fails.
        unawaited(MeshService.instance.startBroadcastingSOS(payload));

        var sentToServer = false;
        try {
          final res = await widget.api.post(
            '/api/v1/sos',
            body: {
              'type': 'Emergency',
              'lat': pos?.latitude ?? 18.5204,
              'lng': pos?.longitude ?? 73.8567,
              'client_uuid': incident.uuid,
            },
          );
          if (res is Map && res['id'] != null) {
            sentToServer = true;
            final backendId = res['id'].toString();
            await db.atomicUpdateIncident(
              incident.uuid,
              status: SosStatus.activeOnline,
              isSynced: true,
              backendId: backendId,
              deliveryChannel: 'internet',
            );
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('active_sos_id', backendId);
            if (mounted) setState(() => _activeSosId = backendId);
          }
        } catch (e) {
          SosLog.event(incident.uuid, 'SYNC_DIRECT_FAIL', e.toString());
          await SosSyncEngine.instance.syncAll();
          final updated = await db.getIncidentByUuid(incident.uuid);
          sentToServer = updated != null &&
              updated.status == SosStatus.activeOnline &&
              (updated.backendId ?? '').isNotEmpty;
          if (sentToServer && mounted) {
            setState(() => _activeSosId = updated.backendId);
          }
        }

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              sentToServer
                  ? 'SOS sent to server. BLE backup is also on.'
                  : 'Server unreachable — SOS broadcasting over BLE.',
            ),
            backgroundColor:
                sentToServer ? AppColors.criticalRed : Colors.orange,
            duration: const Duration(seconds: 4),
          ),
        );
      },
    );
    } finally {
      _sending = false;
    }
  }

  // ─────────────────────────────────────────────────────────
  // SOS Cancellation
  // ─────────────────────────────────────────────────────────

  Future<void> _cancelSOS() async {
    final db = DatabaseHelper.instance;
    final uuidToCancel = _activeLocalUuid;
    final backendIdToCancel = _activeSosId;

    SosLog.event(
      uuidToCancel ?? 'unknown',
      'CANCEL_INITIATED',
      'backendId=$backendIdToCancel',
    );

    // Broadcast cancellation via mesh so nearby phones remove this alert
    if (uuidToCancel != null) {
      MeshService.instance.broadcastCancellation(uuidToCancel);
    } else {
      MeshService.instance.stopBroadcasting();
    }

    if (mounted) {
      setState(() {
        _activeSosId = null;
        _activeLocalUuid = null;
        _sosFired = false;
        _sosHoldTicks = 0;
      });
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('active_sos_id');

    if (uuidToCancel != null) {
      await db.atomicUpdateIncident(uuidToCancel, status: SosStatus.cancelled);
      SosLog.event(uuidToCancel, 'CANCEL_SQLITE', 'status=cancelled');
    }

    if (backendIdToCancel != null) {
      try {
        await widget.api.put('/api/v1/sos/$backendIdToCancel/cancel');
        SosLog.event(
          uuidToCancel ?? 'unknown',
          'CANCEL_SERVER',
          'backendId=$backendIdToCancel',
        );
        if (uuidToCancel != null) {
          await db.markCancellationSynced(uuidToCancel);
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Text('SOS Cancelled. You are marked as safe.'),
                ],
              ),
              backgroundColor: AppColors.primaryGreen,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } catch (e) {
        SosLog.event(
          uuidToCancel ?? 'unknown',
          'CANCEL_SERVER_FAIL',
          'Will retry on reconnect. error=$e',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'SOS cancelled locally. Server will be notified when online.',
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
      return;
    }

    SosLog.event(
      uuidToCancel ?? 'unknown',
      'CANCEL_OFFLINE',
      'No backend ID — local record cancelled. Will not sync.',
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Offline SOS cancelled. No data sent.'),
            ],
          ),
          backgroundColor: AppColors.primaryGreen,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void _lockParentScroll() {
    _scrollHold?.cancel();
    _scrollHold = Scrollable.maybeOf(context)?.position.hold(() {});
  }

  void _unlockParentScroll() {
    _scrollHold?.cancel();
    _scrollHold = null;
  }

  void _cancelHold() {
    _sosHoldTimer?.cancel();
    _activePointer = null;
    _unlockParentScroll();
    if (mounted) {
      setState(() {
        _sosHoldTicks = 0;
        _selectedDisaster = 'Emergency';
      });
    }
  }

  void _beginHold() {
    if (_sosFired || _sending || TinyMLSensorService.instance.alertOpen) {
      return;
    }
    _lockParentScroll();
    _sosHoldTicks = 0;
    _selectedDisaster = 'Emergency';
    _sosHoldTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted) return;
      setState(() {
        _sosHoldTicks++;
        if (_sosHoldTicks >= 50) {
          _sosHoldTimer?.cancel();
          _sosHoldTicks = 0;
          _activePointer = null;
          _unlockParentScroll();
          triggerSOS();
        }
      });
    });
  }

  void _handleIdleTap(Offset globalPosition) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final local = box.globalToLocal(globalPosition);
    final width = box.size.width;
    if (local.dx < width * 0.22) {
      _fetchAndShowSosAlerts();
    } else if (local.dx > width * 0.78) {
      NearbySosRadarSheet.show(
        context,
        onNavigateToLocation: (loc) => widget.onSosLocationTap?.call(loc),
      );
    } else if (widget.onSosTap != null) {
      widget.onSosTap!();
    } else {
      _fetchAndShowSosAlerts();
    }
  }

  void _selectDisasterAt(Offset globalPosition) {
    for (final type in _disasterTypes) {
      final box =
          _chipKeys[type.value]?.currentContext?.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) continue;
      final origin = box.localToGlobal(Offset.zero);
      final rect = (origin & box.size).inflate(10);
      if (rect.contains(globalPosition) && _selectedDisaster != type.value) {
        HapticFeedback.selectionClick();
        setState(() => _selectedDisaster = type.value);
        return;
      }
    }
  }

  Future<void> _fetchAndShowSosAlerts() async {
    try {
      final res = await widget.api.get('/api/v1/sos');
      if (res != null) {
        final list = (res is List)
            ? res
            : (res is Map && res['data'] is List)
                ? res['data'] as List
                : (res is Map && res['sosReports'] is List)
                    ? res['sosReports'] as List
                    : [];
        final Map<String, Map<String, dynamic>> fetchedMap = {};
        for (final item in list) {
          if (item is Map) {
            final mapItem = Map<String, dynamic>.from(item);
            final id = mapItem['id']?.toString() ??
                mapItem['_id']?.toString() ??
                UniqueKey().toString();
            final status = mapItem['status']?.toString().toLowerCase();
            if (status != 'resolved' &&
                status != 'cancelled' &&
                status != 'closed') {
              fetchedMap[id] = mapItem;
            }
          }
        }
        if (fetchedMap.isNotEmpty) {
          SocketService.instance.liveSosAlerts.value = {
            ...SocketService.instance.liveSosAlerts.value,
            ...fetchedMap,
          };
        }
      }
    } catch (e) {
      debugPrint('[EmergencySosBox] Fetch SOS error: $e');
    }

    if (!mounted) return;
    final alerts = SocketService.instance.liveSosAlerts.value;
    if (alerts.isNotEmpty) {
      SosAlertsPanel.show(
        context: context,
        alerts: alerts,
        activeLocalUuid: _activeLocalUuid,
        onCancelSos: (_activeSosId != null || _sosFired) ? _cancelSOS : null,
        onGoToSosPanels: () {
          if (widget.onSosTap != null) widget.onSosTap!();
        },
        onNavigateToLocation: (loc) {
          if (widget.onSosLocationTap != null) {
            widget.onSosLocationTap!(loc);
          }
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No active SOS alerts registered. Hold center 5s to trigger SOS.',
          ),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context);
    final double progress = (_sosHoldTicks / 50.0).clamp(0.0, 1.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_activeSosId != null || _sosFired) ...[
          Container(
            height: 74,
            decoration: BoxDecoration(
              color: AppColors.criticalRed,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.criticalRed.withValues(alpha: 0.35),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                children: [
                  // Hold Progress Fill for cancellation with margin
                  if (_sosHoldTicks > 0)
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: progress,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.28),
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                        ),
                      ),
                    ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        // Left: SOS icon
                        InkWell(
                          onTap: _fetchAndShowSosAlerts,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.emergency_rounded,
                              color: Colors.white,
                              size: 26,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Center: Hold to cancel action
                        Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              if (widget.onSosTap != null) {
                                widget.onSosTap!();
                              } else {
                                _fetchAndShowSosAlerts();
                              }
                            },
                            onTapDown: (_) {
                              _sosHoldTimer?.cancel();
                              _sosHoldTicks = 0;
                              _lockParentScroll();
                              _sosHoldTimer = Timer.periodic(
                                const Duration(milliseconds: 100),
                                (timer) {
                                  if (!mounted) return;
                                  setState(() {
                                    _sosHoldTicks++;
                                    if (_sosHoldTicks >= 50) {
                                      _sosHoldTimer?.cancel();
                                      _sosHoldTicks = 0;
                                      _unlockParentScroll();
                                      _cancelSOS();
                                    }
                                  });
                                },
                              );
                            },
                            onTapUp: (_) => _cancelHold(),
                            onTapCancel: () => _cancelHold(),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _sosHoldTicks > 0 ? l10n.releasing : l10n.sosActive,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 17,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _sosHoldTicks > 0
                                      ? l10n.releaseIn((5.0 - (_sosHoldTicks / 10)).toStringAsFixed(1))
                                      : l10n.holdToCancelSos,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Right: Radar action
                        InkWell(
                          onTap: () {
                            NearbySosRadarSheet.show(
                              context,
                              onNavigateToLocation: (loc) {
                                widget.onSosLocationTap?.call(loc);
                              },
                            );
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.radar_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // ── Live Sync Status Strip ──
          ValueListenableBuilder<SosSyncStatus>(
            valueListenable: SosSyncEngine.instance.syncStatusNotifier,
            builder: (context, status, _) {
              if (status.phase == SosSyncPhase.idle) {
                if (_activeSosId != null) {
                  return const _SyncStatusStrip(
                    icon: Icons.check_circle,
                    color: AppColors.primaryGreen,
                    message: 'SOS delivered to all responders',
                  );
                }
                return const _SyncStatusStrip(
                  icon: Icons.wifi_off,
                  color: Colors.orange,
                  message: 'Offline — waiting for connection...',
                  showPulse: true,
                );
              }

              switch (status.phase) {
                case SosSyncPhase.connecting:
                  return _SyncStatusStrip(
                    icon: Icons.sync,
                    color: Colors.orange,
                    message: status.message,
                    showPulse: true,
                  );
                case SosSyncPhase.syncing:
                  return _SyncStatusStrip(
                    icon: Icons.cloud_upload,
                    color: Colors.blue,
                    message: status.message,
                    showPulse: true,
                  );
                case SosSyncPhase.waitingRetry:
                  return _SyncStatusStrip(
                    icon: Icons.timer,
                    color: Colors.orange,
                    message: status.message,
                    showPulse: true,
                  );
                case SosSyncPhase.synced:
                  return _SyncStatusStrip(
                    icon: Icons.check_circle,
                    color: AppColors.primaryGreen,
                    message: status.message,
                  );
                case SosSyncPhase.failed:
                  return _SyncStatusStrip(
                    icon: Icons.error,
                    color: AppColors.criticalRed,
                    message: status.message,
                  );
                default:
                  return const SizedBox.shrink();
              }
            },
          ),
        ] else ...[
          Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: (event) {
              if (_activePointer != null) return;
              _activePointer = event.pointer;
              _beginHold();
            },
            onPointerMove: (event) {
              if (event.pointer != _activePointer) return;
              _selectDisasterAt(event.position);
            },
            onPointerUp: (event) {
              if (event.pointer != _activePointer) return;
              final ticks = _sosHoldTicks;
              final position = event.position;
              if (ticks < 50) {
                final wasTap = ticks < 5;
                _cancelHold();
                if (wasTap) _handleIdleTap(position);
              }
              _activePointer = null;
            },
            onPointerCancel: (event) {
              if (event.pointer != _activePointer) return;
              _cancelHold();
            },
            child: AnimatedPadding(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.all(_sosHoldTicks >= 5 ? 6 : 0),
              child: AnimatedSize(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutCubic,
                  decoration: BoxDecoration(
                    color: AppColors.card(context),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.isDark(context)
                          ? AppColors.border(context)
                          : AppColors.criticalRed.withValues(alpha: 0.8),
                      width: 1.5,
                    ),
                    boxShadow: [
                      if (_sosHoldTicks > 0)
                        BoxShadow(
                          color: AppColors.criticalRed.withValues(alpha: 0.25),
                          blurRadius: 14,
                          spreadRadius: progress * 4,
                        )
                      else
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: 74,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(19),
                          child: Stack(
                            children: [
                              // Smooth Progress Fill with Inset Margin
                              if (!_sosFired && _sosHoldTicks > 0)
                                Positioned.fill(
                                  child: Padding(
                                    padding: const EdgeInsets.all(5.0),
                                    child: FractionallySizedBox(
                                      alignment: Alignment.centerLeft,
                                      widthFactor: progress,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: AppColors.criticalRed.withValues(
                                            alpha: 0.16,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(14),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: Row(
                                  children: [
                                    // Left SOS rounded badge
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppColors.criticalRed.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.emergency_rounded,
                                        color: AppColors.criticalRed,
                                        size: 26,
                                      ),
                                    ),
                                    const SizedBox(width: 14),

                                    // Center Action Text
                                    Expanded(
                                      child: GestureDetector(
                                        behavior: HitTestBehavior.translucent,
                                        onTap: _sosHoldTicks > 0
                                            ? null
                                            : () {
                                                if (widget.onSosTap != null) {
                                                  widget.onSosTap!();
                                                } else {
                                                  _fetchAndShowSosAlerts();
                                                }
                                              },
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _sosHoldTicks > 0
                                                  ? _disasterLabel(
                                                      l10n,
                                                      _selectedDisaster,
                                                    )
                                                  : l10n.holdForSos,
                                              style: const TextStyle(
                                                color: AppColors.criticalRed,
                                                fontWeight: FontWeight.w900,
                                                fontSize: 17,
                                                letterSpacing: 1.1,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              _sosHoldTicks > 0
                                                  ? l10n.slideAType((5.0 - (_sosHoldTicks / 10)).toStringAsFixed(1))
                                                  : l10n.holdToRequestHelp,
                                              style: TextStyle(
                                                color: AppColors.mutedText(context),
                                                fontSize: 12,
                                                fontWeight: _sosHoldTicks > 0
                                                    ? FontWeight.bold
                                                    : FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                                    // Right: Radar Button
                                    GestureDetector(
                                      onTap: _sosHoldTicks > 0
                                          ? null
                                          : () {
                                              NearbySosRadarSheet.show(
                                                context,
                                                onNavigateToLocation: (loc) {
                                                  widget.onSosLocationTap?.call(
                                                    loc,
                                                  );
                                                },
                                              );
                                            },
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: AppColors.criticalRed.withValues(
                                            alpha: 0.08,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: const Icon(
                                          Icons.radar_rounded,
                                          color: AppColors.criticalRed,
                                          size: 24,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_sosHoldTicks >= 5) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 4, 12, 14),
                          child: Column(
                            children: [
                              Text(
                                l10n.keepHoldingSlide(
                                  _disasterLabel(l10n, _selectedDisaster),
                                ),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.mutedText(context),
                                ),
                              ),
                              const SizedBox(height: 10),
                              _ConnectedDisasterStrip(
                                types: _disasterTypes,
                                chipKeys: _chipKeys,
                                selectedDisaster: _selectedDisaster,
                                l10n: l10n,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ConnectedDisasterStrip extends StatelessWidget {
  const _ConnectedDisasterStrip({
    required this.types,
    required this.chipKeys,
    required this.selectedDisaster,
    required this.l10n,
  });

  final List<({String value, IconData icon})> types;
  final Map<String, GlobalKey> chipKeys;
  final String selectedDisaster;
  final AppLocalizations l10n;

  String _disasterLabel(AppLocalizations l10n, String value) {
    return switch (value) {
      'Flood' => l10n.disasterFlood,
      'Earthquake' => l10n.disasterEarthquake,
      'Fire' => l10n.disasterFire,
      'Landslide' => l10n.disasterLandslide,
      'Medical' => l10n.disasterMedical,
      'Accident' => l10n.disasterAccident,
      _ => l10n.disasterOther,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7F7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.criticalRed.withValues(alpha: 0.3),
          width: 1.0,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (int i = 0; i < types.length; i++) ...[
                if (i > 0)
                  Container(
                    width: 1.0,
                    color: AppColors.criticalRed.withValues(alpha: 0.2),
                  ),
                Expanded(
                  child: _DisasterSegment(
                    key: chipKeys[types[i].value],
                    label: _disasterLabel(l10n, types[i].value),
                    icon: types[i].icon,
                    selected: selectedDisaster == types[i].value,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DisasterSegment extends StatelessWidget {
  const _DisasterSegment({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
  });

  final String label;
  final IconData icon;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
      decoration: BoxDecoration(
        color: selected ? AppColors.criticalRed : Colors.transparent,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 22,
            color: selected ? Colors.white : AppColors.criticalRed,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              color: selected
                  ? Colors.white
                  : (AppColors.isDark(context)
                      ? const Color(0xFFFFB4AB)
                      : const Color(0xFF991B1B)),
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _SyncStatusStrip extends StatelessWidget {
  const _SyncStatusStrip({
    required this.icon,
    required this.color,
    required this.message,
    this.showPulse = false,
  });

  final IconData icon;
  final Color color;
  final String message;
  final bool showPulse;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (showPulse) _PulsingDot(color: color),
        ],
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  const _PulsingDot({required this.color});
  final Color color;

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: 0.3 + (_controller.value * 0.7),
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: widget.color,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}
