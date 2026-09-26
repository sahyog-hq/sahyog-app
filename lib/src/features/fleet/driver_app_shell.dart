import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../core/api_client.dart';
import '../../core/app_config.dart';
import '../../core/models.dart';
import '../../theme/app_colors.dart';

class DriverAppShell extends StatefulWidget {
  final ApiClient api;
  final AppUser user;

  const DriverAppShell({Key? key, required this.api, required this.user}) : super(key: key);

  @override
  State<DriverAppShell> createState() => _DriverAppShellState();
}

class _DriverAppShellState extends State<DriverAppShell> {
  late io.Socket socket;
  LatLng? _currentLocation;
  StreamSubscription<Position>? _positionStream;

  Map<String, dynamic>? _incomingPing;
  Map<String, dynamic>? _activeMission;
  List<LatLng> _routePoints = [];

  bool _isOnline = false;

  @override
  void initState() {
    super.initState();
    _initSocket();
  }

  void _initSocket() {
    socket = io.io(
      AppConfig.baseUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );

    socket.on('fleet.dispatch.ping', (data) {
      if (mounted) {
        setState(() {
          _incomingPing = Map<String, dynamic>.from(data);
        });
      }
    });
  }

  Future<void> _goOnline() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location services disabled.')));
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    socket.connect();

    setState(() {
      _isOnline = true;
    });

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((Position position) {
      if (mounted) {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
        });
        
        socket.emit('fleet.location.update', {
          'vehicleId': widget.user.id,
          'lat': position.latitude,
          'lng': position.longitude,
        });
      }
    });
  }

  void _goOffline() {
    _positionStream?.cancel();
    socket.disconnect();
    setState(() {
      _isOnline = false;
      _incomingPing = null;
      _activeMission = null;
      _routePoints.clear();
    });
  }

  Future<void> _acceptMission() async {
    if (_incomingPing == null) return;

    try {
      final res = await widget.api.patch(
        '/api/v1/fleet/dispatch/${_incomingPing!['id']}/status',
        body: {
          'status': 'accepted',
          'vehicle_id': widget.user.id,
        },
      );
      
      setState(() {
        _activeMission = res;
        _incomingPing = null;
      });
      
      _fetchRoute();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _fetchRoute() async {
    if (_activeMission == null || _currentLocation == null) return;
    
    final dropLat = _activeMission!['dropoff_lat'];
    final dropLng = _activeMission!['dropoff_lng'];
    
    if (dropLat == null || dropLng == null) return;

    // Use OSRM public API to fetch route geometry
    final url = Uri.parse(
        'http://router.project-osrm.org/route/v1/driving/'
        '${_currentLocation!.longitude},${_currentLocation!.latitude};'
        '$dropLng,$dropLat?geometries=geojson');
        
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final coords = data['routes'][0]['geometry']['coordinates'] as List;
          setState(() {
            _routePoints = coords.map((c) => LatLng(c[1] as double, c[0] as double)).toList();
          });
        }
      }
    } catch (e) {
      debugPrint('Route fetch error: $e');
    }
  }

  Future<void> _completeMission() async {
    if (_activeMission == null) return;

    try {
      await widget.api.patch(
        '/api/v1/fleet/dispatch/${_activeMission!['id']}/status',
        body: {
          'status': 'completed',
          'vehicle_id': widget.user.id,
        },
      );
      
      setState(() {
        _activeMission = null;
        _routePoints.clear();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    socket.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black.withOpacity(0.8), Colors.transparent],
            ),
          ),
        ),
        title: const Text('ResQDrive', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.white)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: ActionChip(
              backgroundColor: _isOnline ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
              side: BorderSide(color: _isOnline ? Colors.green : Colors.red),
              label: Text(_isOnline ? 'ONLINE' : 'OFFLINE', style: TextStyle(color: _isOnline ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
              onPressed: _isOnline ? _goOffline : _goOnline,
              avatar: Icon(_isOnline ? Icons.wifi : Icons.wifi_off, color: _isOnline ? Colors.green : Colors.red, size: 16),
            ),
          )
        ],
      ),
      body: Stack(
        children: [
          if (_currentLocation != null)
            FlutterMap(
              options: MapOptions(
                initialCenter: _currentLocation!,
                initialZoom: 15.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.sahyog.app',
                ),
                if (_routePoints.isNotEmpty)
                  PolylineLayer(
                    polylines: <Polyline<Object>>[
                      Polyline<Object>(
                        points: _routePoints,
                        strokeWidth: 6.0,
                        color: AppColors.primaryGreen.withOpacity(0.8),
                        pattern: StrokePattern.dashed(segments: const [10, 10]),
                      ),
                    ],
                  ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _currentLocation!,
                      width: 60,
                      height: 60,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Container(
                            width: 24, height: 24,
                            decoration: BoxDecoration(color: AppColors.primaryGreen, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3)),
                          ),
                        ),
                      ),
                    ),
                    if (_activeMission != null && _activeMission!['dropoff_lat'] != null)
                      Marker(
                        point: LatLng(
                          double.parse(_activeMission!['dropoff_lat'].toString()),
                          double.parse(_activeMission!['dropoff_lng'].toString())
                        ),
                        width: 50,
                        height: 50,
                        child: const Icon(Icons.location_on, color: Colors.redAccent, size: 50),
                      ),
                  ],
                ),
              ],
            )
          else
            const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen)),
            
          if (!_isOnline)
            Container(
              color: Colors.black.withOpacity(0.6),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.airport_shuttle, size: 80, color: Colors.white70),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _goOnline,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                        elevation: 10,
                      ),
                      child: const Text('GO ONLINE TO RECEIVE MISSIONS', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ),

          if (_incomingPing != null && _activeMission == null)
            Positioned(
              bottom: 40, left: 20, right: 20,
              child: Card(
                elevation: 20,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.warning_amber_rounded, color: Colors.red),
                            SizedBox(width: 8),
                            Text('EMERGENCY DISPATCH', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text('${_incomingPing!['type']}'.toUpperCase(), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.location_on, color: Colors.grey),
                          const SizedBox(width: 8),
                          Expanded(child: Text('${_incomingPing!['dropoff_address'] ?? 'Unknown'}', style: const TextStyle(fontSize: 16, color: Colors.black87))),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), side: const BorderSide(color: Colors.grey), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                              onPressed: () => setState(() => _incomingPing = null),
                              child: const Text('REJECT', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                              onPressed: _acceptMission,
                              child: const Text('ACCEPT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ),
            
          if (_activeMission != null)
            Positioned(
              bottom: 40, left: 20, right: 20,
              child: Card(
                elevation: 20,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), shape: BoxShape.circle),
                            child: const Icon(Icons.navigation, color: Colors.blue),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('En Route to Destination', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                Text('Follow the dotted green path', style: TextStyle(color: Colors.grey)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: _completeMission,
                          child: const Text('MARK AS COMPLETED', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.1)),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
