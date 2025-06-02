import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

class LiveTrackingScreen extends StatefulWidget {
  const LiveTrackingScreen({super.key});

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  final Location _location = Location();

  LatLng? _myPosition;
  LatLng? _otherPosition;
  late String serviceId;
  late bool isOficial;
  bool _initialized = false;

  StreamSubscription<DocumentSnapshot>? _firestoreSubscription;
  StreamSubscription<LocationData>? _locationSubscription;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final args = ModalRoute.of(context)!.settings.arguments as Map;
      serviceId = args['serviceId'];
      isOficial = args['isOficial'] ?? false;

      _getInitialLocation();
      _listenToFirestore();
      _initialized = true;
    }
  }

  void _getInitialLocation() async {
    final permissionGranted = await _location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      await _location.requestPermission();
    }

    final locData = await _location.getLocation();
    setState(() {
      _myPosition = LatLng(locData.latitude!, locData.longitude!);
    });

    _locationSubscription = _location.onLocationChanged.listen((locData) {
      if (isOficial) {
        FirebaseFirestore.instance
            .collection('services')
            .doc(serviceId)
            .update({
          'currentLocation': GeoPoint(locData.latitude!, locData.longitude!),
        });
      } else {
        setState(() {
          _myPosition = LatLng(locData.latitude!, locData.longitude!);
        });
      }
    });
  }

  void _listenToFirestore() {
    _firestoreSubscription = FirebaseFirestore.instance
        .collection('services')
        .doc(serviceId)
        .snapshots()
        .listen((doc) {
      if (!doc.exists) return;

      final data = doc.data()!;
      if (data['state'] == 'cancelled') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('El servicio fue cancelado.')),
          );
          Navigator.pushReplacementNamed(context, '/home');
        }
        return;
      }

      if (data.containsKey('currentLocation')) {
        final geo = data['currentLocation'] as GeoPoint;
        setState(() {
          _otherPosition = LatLng(geo.latitude, geo.longitude);
        });
      }
    });
  }

  Future<void> _cancelService() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    await FirebaseFirestore.instance
        .collection('services')
        .doc(serviceId)
        .update({'state': 'cancelled'});

    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .update({'activeService': null});

    if (mounted) {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  void dispose() {
    _firestoreSubscription?.cancel();
    _locationSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Seguimiento en vivo'),
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.cancel),
              tooltip: 'Cancelar servicio',
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('¿Cancelar servicio?'),
                    content: const Text('Esta acción no se puede deshacer.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('No'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Sí, cancelar'),
                      ),
                    ],
                  ),
                );

                if (confirmed == true) _cancelService();
              },
            ),
          ],
        ),
        body: _myPosition == null
            ? const Center(child: CircularProgressIndicator())
            : Stack(
                children: [
                  GoogleMap(
                    initialCameraPosition:
                        CameraPosition(target: _myPosition!, zoom: 16),
                    myLocationEnabled: true,
                    myLocationButtonEnabled: false,
                    markers: {
                      Marker(
                        markerId: const MarkerId('client'),
                        position: _myPosition!,
                        infoWindow: InfoWindow(
                            title: isOficial ? 'Oficial' : 'Tú (Cliente)'),
                        icon: BitmapDescriptor.defaultMarkerWithHue(
                          isOficial
                              ? BitmapDescriptor.hueBlue
                              : BitmapDescriptor.hueGreen,
                        ),
                      ),
                      if (_otherPosition != null)
                        Marker(
                          markerId: const MarkerId('oficial'),
                          position: _otherPosition!,
                          infoWindow: InfoWindow(
                              title:
                                  isOficial ? 'Cliente' : 'Oficial en camino'),
                          icon: BitmapDescriptor.defaultMarkerWithHue(
                            isOficial
                                ? BitmapDescriptor.hueGreen
                                : BitmapDescriptor.hueBlue,
                          ),
                        ),
                    },
                    onMapCreated: (controller) =>
                        _controller.complete(controller),
                  ),
                  Positioned(
                    top: 40,
                    left: 20,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: Colors.black26, blurRadius: 8),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Icon(Icons.directions_car, color: Colors.blue),
                          Text("Tu oficial está en camino",
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600)),
                          Icon(Icons.timer, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
