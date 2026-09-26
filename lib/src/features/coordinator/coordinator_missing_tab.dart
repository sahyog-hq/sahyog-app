import 'dart:async';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/location_service.dart';
import '../../core/remote_report_image.dart';
import '../../theme/app_colors.dart';
import '../../widgets/expandable_record_card.dart';
import 'package:sahyog_app/l10n/app_localizations.dart';

/// Coordinator Missing Persons — single tab (no report form).
/// Shows all missing persons with sorting and Mark Found.
class CoordinatorMissingTab extends StatefulWidget {
  const CoordinatorMissingTab({super.key, required this.api});

  final ApiClient api;

  @override
  State<CoordinatorMissingTab> createState() => _CoordinatorMissingTabState();
}

class _CoordinatorMissingTabState extends State<CoordinatorMissingTab>
    with AutomaticKeepAliveClientMixin {
  List<Map<String, dynamic>> _board = [];
  bool _loading = true;
  String _error = '';
  Timer? _pollTimer;

  String _sortBy = 'created_at';
  String _sortOrder = 'desc';

  final _phoneCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  XFile? _pickedPhoto;
  double? _lat;
  double? _lng;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadBoard();
    _pollTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) _loadBoard(silent: true);
    });
  }

  final _foundNoteCtrl = TextEditingController();
  final _foundLocCtrl = TextEditingController();

  @override
  void dispose() {
    _pollTimer?.cancel();
    _phoneCtrl.dispose();
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    _foundNoteCtrl.dispose();
    _foundLocCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadBoard({bool silent = false}) async {
    try {
      if (!silent) {
        setState(() {
          _loading = true;
          _error = '';
        });
      }
      final raw = await widget.api.get(
        '/api/v1/coordinator/missing',
        query: {'sort': _sortBy, 'order': _sortOrder},
      );
      if (!mounted) return;
      setState(() {
        _board = (raw is List)
            ? raw.cast<Map<String, dynamic>>()
            : <Map<String, dynamic>>[];
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _markFound(String id) async {
    String condition = 'found_safe';
    XFile? pickedFile;
    final picker = ImagePicker();

    _foundNoteCtrl.clear();
    _foundLocCtrl.clear();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 24,
                right: 24,
                top: 32,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Close Missing Person Report',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: GestureDetector(
                        onTap: () async {
                          final file = await picker.pickImage(
                            source: ImageSource.gallery,
                            imageQuality: 70,
                          );
                          if (file != null) {
                            setModalState(() => pickedFile = file);
                          }
                        },
                        child: Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.grey.withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: pickedFile == null
                              ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_a_photo_outlined,
                                      size: 40,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Add Proof Image',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ],
                                )
                              : ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: Image.file(
                                    File(pickedFile!.path),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    DropdownButtonFormField<String>(
                      value: condition,
                      decoration: const InputDecoration(
                        labelText: 'Condition at Rescue',
                        prefixIcon: Icon(Icons.health_and_safety_outlined),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'found_safe',
                          child: Text('Found Safe & Healthy'),
                        ),
                        DropdownMenuItem(
                          value: 'needs_assistance',
                          child: Text('Needs Medical Assistance'),
                        ),
                        DropdownMenuItem(
                          value: 'critical',
                          child: Text('Critical Condition'),
                        ),
                      ],
                      onChanged: (v) {
                        if (v != null) setModalState(() => condition = v);
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _foundLocCtrl,
                      decoration: InputDecoration(
                        labelText: 'Rescue Location',
                        prefixIcon: const Icon(Icons.location_on_outlined),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.my_location),
                          onPressed: () async {
                            try {
                              final p = await LocationService()
                                  .getCurrentPosition();
                              _foundLocCtrl.text =
                                  '${p.latitude.toStringAsFixed(4)}, ${p.longitude.toStringAsFixed(4)}';
                            } catch (_) {}
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _foundNoteCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Closure description',
                        hintText: 'Add final details/notes for coordination...',
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () async {
                          Navigator.pop(ctx);
                          try {
                            final closePhoto = pickedFile;
                            final photos = closePhoto == null
                                ? <String>[]
                                : await widget.api.uploadImages(
                                    [closePhoto.path],
                                    folder: 'missing',
                                  );
                            await widget.api.patch(
                              '/api/v1/coordinator/missing/$id/found',
                              body: {
                                'description': _foundNoteCtrl.text.trim(),
                                'condition': condition,
                                'rescue_location': _foundLocCtrl.text.trim(),
                                'rescue_photo': photos.isEmpty
                                    ? ''
                                    : photos.first,
                              },
                            );
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Marked as found.')),
                            );
                            _loadBoard();
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Failed: $e')),
                              );
                            }
                          }
                        },
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Confirm Finding'),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _useCurrentLocation(StateSetter setModalState) async {
    try {
      final pos = await LocationService().getCurrentPosition();
      setModalState(() {
        _lat = pos.latitude;
        _lng = pos.longitude;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Location error: $e')));
    }
  }

  Future<void> _submitReport() async {
    final phone = _phoneCtrl.text.trim();
    if (phone.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Phone is required.')));
      return;
    }

    setState(() => _submitting = true);
    try {
      final photoUrls = _pickedPhoto == null
          ? <String>[]
          : await widget.api.uploadImages(
              [_pickedPhoto!.path],
              folder: 'missing',
            );
      final body = <String, dynamic>{
        'reporter_phone': phone,
        'name': _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text.trim(),
        'age': int.tryParse(_ageCtrl.text.trim()),
        'photo_urls': photoUrls,
        'description': 'Reported by Coordinator.',
      };

      if (_lat != null && _lng != null) {
        body['last_seen_location'] = {'lat': _lat, 'lng': _lng};
      }

      await widget.api.post('/api/v1/missing', body: body);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report submitted successfully.')),
      );

      _phoneCtrl.clear();
      _nameCtrl.clear();
      _ageCtrl.clear();
      _pickedPhoto = null;
      _lat = null;
      _lng = null;

      Navigator.of(context).pop();
      _loadBoard();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Submission failed: $e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showReportDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (stctx, setModalState) {
            return AlertDialog(
              title: const Text('Report Missing Person'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Reporter Phone *',
                        prefixIcon: Icon(Icons.phone),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Missing Person Name',
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _ageCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Approximate Age',
                        prefixIcon: Icon(Icons.cake_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: GestureDetector(
                        onTap: () async {
                          final picker = ImagePicker();
                          final file = await picker.pickImage(
                            source: ImageSource.gallery,
                            imageQuality: 70,
                          );
                          if (file != null) {
                            setModalState(() => _pickedPhoto = file);
                          }
                        },
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: _pickedPhoto == null
                              ? const Icon(
                                  Icons.add_a_photo,
                                  color: Colors.grey,
                                )
                              : ClipRRect(
                                  borderRadius: BorderRadius.circular(15),
                                  child: Image.file(
                                    File(_pickedPhoto!.path),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.my_location),
                          onPressed: () => _useCurrentLocation(setModalState),
                        ),
                        Expanded(
                          child: Text(
                            _lat == null
                                ? 'No location'
                                : '${_lat!.toStringAsFixed(3)}, ${_lng!.toStringAsFixed(3)}',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: _submitting ? null : _submitReport,
                  child: const Text('Submit'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _showReportDialog,
        backgroundColor: AppColors.primaryGreen,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Sort controls
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  Text(
                    'Sort by:',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: _sortBy,
                    underline: const SizedBox(),
                    isDense: true,
                    items: const [
                      DropdownMenuItem(
                        value: 'created_at',
                        child: Text('Date'),
                      ),
                      DropdownMenuItem(value: 'name', child: Text('Name')),
                      DropdownMenuItem(value: 'status', child: Text('Status')),
                      DropdownMenuItem(value: 'age', child: Text('Age')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _sortBy = val);
                        _loadBoard();
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(
                      _sortOrder == 'desc'
                          ? Icons.arrow_downward
                          : Icons.arrow_upward,
                      size: 18,
                    ),
                    tooltip: _sortOrder == 'desc'
                        ? 'Newest first'
                        : 'Oldest first',
                    onPressed: () {
                      setState(
                        () =>
                            _sortOrder = _sortOrder == 'desc' ? 'asc' : 'desc',
                      );
                      _loadBoard();
                    },
                  ),
                  const Spacer(),
                  Text(
                    '${_board.length} reports',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Board
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _loadBoard,
                      child: _buildBoard(),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBoard() {
    if (_error.isNotEmpty) {
      return ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              _error,
              style: const TextStyle(color: AppColors.criticalRed),
            ),
          ),
        ],
      );
    }
    if (_board.isEmpty) {
      return ListView(
        children: const [
          Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: Text('No missing person reports.')),
          ),
        ],
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _board.length,
      itemBuilder: (context, index) {
        final item = _board[index];
        final l10n = AppLocalizations.of(context);
        final status = (item['status'] ?? 'missing').toString();
        final name = (item['name'] ?? l10n.unnamed).toString();
        final age = item['age']?.toString() ?? l10n.unknown;
        final id = (item['id'] ?? '').toString();
        final isFound = status == 'found';
        final phone = (item['reporter_phone'] ?? '').toString();
        final desc = (item['description'] ?? '').toString();
        final statusLabel = isFound ? l10n.found : l10n.statusMissing;

        return ExpandableRecordCard(
          title: name,
          subtitle: '${l10n.ageLabel}: $age • ${l10n.statusLabel}: $statusLabel',
          imageUrls: networkImageUrls(item['photo_urls']),
          placeholderIcon: isFound ? Icons.verified : Icons.person_search,
          accentColor:
              isFound ? AppColors.primaryGreen : AppColors.criticalRed,
          trailing: !isFound && id.isNotEmpty
              ? FilledButton.tonal(
                  onPressed: () => _markFound(id),
                  child: Text(l10n.found, style: const TextStyle(fontSize: 12)),
                )
              : Chip(
                  label: Text(l10n.found, style: const TextStyle(fontSize: 10)),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
          details: [
            DetailRow(label: l10n.description, value: desc),
            DetailRow(label: l10n.reporterPhone, value: phone),
            DetailRow(
              label: l10n.lastSeen,
              value: formatLastSeen(item['last_seen_location']),
            ),
          ],
        );
      },
    );
  }
}
