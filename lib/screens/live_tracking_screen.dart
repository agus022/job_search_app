import 'dart:async';
import 'dart:convert';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
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
  bool _navigatedOut = false;
  Set<Polyline> _polylines = {};
  PolylinePoints polylinePoints = PolylinePoints();

  StreamSubscription<DocumentSnapshot>? _firestoreSubscription;
  StreamSubscription<LocationData>? _locationSubscription;

  String validationCode = '';
  int currentStep = 0;
  bool _loadingRoute = false;
  bool _routeDrawn = false;

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
    try {
      final permissionGranted = await _location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        await _location.requestPermission();
      }

      final locData = await _location.getLocation();
      if (locData.latitude != null && locData.longitude != null) {
        setState(() {
          _myPosition = LatLng(locData.latitude!, locData.longitude!);
        });
      }

      _locationSubscription = _location.onLocationChanged.listen((locData) {
        if (locData.latitude == null || locData.longitude == null) return;

        final pos = LatLng(locData.latitude!, locData.longitude!);

        if (isOficial) {
          FirebaseFirestore.instance
              .collection('services')
              .doc(serviceId)
              .update(
                  {'currentLocation': GeoPoint(pos.latitude, pos.longitude)});
        } else {
          setState(() => _myPosition = pos);
          FirebaseFirestore.instance
              .collection('services')
              .doc(serviceId)
              .update(
                  {'clientLocation': GeoPoint(pos.latitude, pos.longitude)});
        }
      });
    } catch (e) {
      debugPrint("Error al obtener ubicación: $e");
    }
  }

  Future<void> _getPolylineWithGeoapify() async {
    if (_myPosition == null || _otherPosition == null) return;
    if (_myPosition == _otherPosition) return;

    setState(() => _loadingRoute = true);
    final apiKey = '8e31776af9ae486488542bb8ac195991';

    final url =
        'https://api.geoapify.com/v1/routing?waypoints=${_myPosition!.latitude},${_myPosition!.longitude}|${_otherPosition!.latitude},${_otherPosition!.longitude}&mode=drive&apiKey=$apiKey';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print("Geoapify response: $data");
        final List coordinates = data['features'][0]['geometry']['coordinates'];

        // Si es MultiLineString → accede a coordinates[0]
        final List subCoords = coordinates[0];

        final polylineCoordinates = subCoords
            .map<LatLng>((coord) => LatLng(coord[1], coord[0]))
            .toList();

        setState(() {
          _polylines = {
            Polyline(
              polylineId: const PolylineId("route"),
              color: Colors.blue,
              width: 5,
              points: polylineCoordinates,
            ),
          };

          _routeDrawn = true;
          _loadingRoute = false;
        });

        if (_controller.isCompleted && polylineCoordinates.isNotEmpty) {
          final GoogleMapController controller = await _controller.future;

          final bounds = LatLngBounds(
            southwest: LatLng(
              polylineCoordinates
                  .map((e) => e.latitude)
                  .reduce((a, b) => a < b ? a : b),
              polylineCoordinates
                  .map((e) => e.longitude)
                  .reduce((a, b) => a < b ? a : b),
            ),
            northeast: LatLng(
              polylineCoordinates
                  .map((e) => e.latitude)
                  .reduce((a, b) => a > b ? a : b),
              polylineCoordinates
                  .map((e) => e.longitude)
                  .reduce((a, b) => a > b ? a : b),
            ),
          );

          await controller
              .animateCamera(CameraUpdate.newLatLngBounds(bounds, 60));
        }
      } else {
        debugPrint("Geoapify error: ${response.body}");
        setState(() => _loadingRoute = false);
      }
    } catch (e) {
      debugPrint("Exception in Geoapify route: $e");
      setState(() => _loadingRoute = false);
    }
  }

  void _listenToFirestore() {
    _firestoreSubscription = FirebaseFirestore.instance
        .collection('services')
        .doc(serviceId)
        .snapshots()
        .listen((doc) {
      if (!doc.exists) return;

      final data = doc.data()!;
      if (data['state'] == 'cancelled' && !_navigatedOut) {
        _navigatedOut = true;
        if (mounted) {
          // Limpiar activeService del usuario actual
          final userId = FirebaseAuth.instance.currentUser!.uid;
          FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .update({'activeService': null});

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('El servicio fue cancelado.')),
          );

          Navigator.pushReplacementNamed(context, '/home');
        }
        return;
      }

      if (!isOficial && data.containsKey('currentLocation')) {
        final geo = data['currentLocation'] as GeoPoint;
        _otherPosition = LatLng(geo.latitude, geo.longitude);

        if (!_routeDrawn) {
          _getPolylineWithGeoapify(); // muestra loader y traza
        }
      } else if (isOficial && data.containsKey('clientLocation')) {
        final geo = data['clientLocation'] as GeoPoint;
        _otherPosition = LatLng(geo.latitude, geo.longitude);

        if (!_routeDrawn) {
          _getPolylineWithGeoapify();
        }
      }

      final state = data['state'] as String;
      setState(() {
        if (state == 'accepted') currentStep = 0;
        if (state == 'in_progress') currentStep = 1;
        if (state == 'completed') currentStep = 2;
        if (state == 'paid') currentStep = 3;
        if (state == 'paid' && !_navigatedOut) {
          _navigatedOut = true;

          final userId = FirebaseAuth.instance.currentUser!.uid;
          FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .update({'activeService': null});

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('El cliente ha realizado el pago.')),
          );

          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              Navigator.pushReplacementNamed(context, '/home');
            }
          });
        }

        validationCode = data['validationCode']?.toString() ?? '';
      });
    });
  }

  void _mostrarValidacionDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Validar servicio"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: "Código del cliente"),
        ),
        actions: [
          TextButton(
            child: const Text("Cancelar"),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: const Text("Validar"),
            onPressed: () async {
              final doc = await FirebaseFirestore.instance
                  .collection('services')
                  .doc(serviceId)
                  .get();
              final correctCode = doc['validationCode'];

              if (controller.text == correctCode) {
                await FirebaseFirestore.instance
                    .collection('services')
                    .doc(serviceId)
                    .update({'state': 'completed'});
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Código incorrecto")),
                );
              }
            },
          )
        ],
      ),
    );
  }

  void _finalizarPago() async {
    await FirebaseFirestore.instance
        .collection('services')
        .doc(serviceId)
        .update({'state': 'paid'});
  }

  Widget buildPagoButton() {
    return Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: ElevatedButton(
        onPressed: _finalizarPago,
        child: const Text("Finalizar y pagar"),
      ),
    );
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
            if (currentStep < 2)
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
                    initialCameraPosition: CameraPosition(
                      target: _myPosition!,
                      zoom: 16,
                    ),
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
                    polylines: _polylines,
                    onMapCreated: (controller) =>
                        _controller.complete(controller),
                  ),
                  if (_loadingRoute)
                    const Positioned.fill(
                      child: ColoredBox(
                        color: Colors.black45,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    ),
                  Positioned(
                    top: 40,
                    left: 20,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: Colors.black26, blurRadius: 8)
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Progreso del servicio",
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStep("En camino", Icons.directions_car, 0),
                              _buildLine(),
                              _buildStep("En curso", Icons.build, 1),
                              _buildLine(),
                              _buildStep("Finalizado", Icons.check_circle, 2),
                              _buildLine(),
                              _buildStep("Pagar", Icons.payment, 3),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (!isOficial &&
                      currentStep == 1 &&
                      validationCode.isNotEmpty)
                    Positioned(
                      bottom: 80,
                      left: 20,
                      right: 20,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(color: Colors.black26, blurRadius: 6)
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text("Tu código de validación:",
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 10),
                            SelectableText(
                              validationCode,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                                letterSpacing: 4,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              "Dáselo al oficial para validar que el servicio fue realizado.",
                              textAlign: TextAlign.center,
                              style:
                                  TextStyle(fontSize: 13, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (isOficial && currentStep == 0)
                    Positioned(
                      bottom: 20,
                      left: 20,
                      right: 20,
                      child: ElevatedButton(
                        onPressed: () async {
                          await FirebaseFirestore.instance
                              .collection('services')
                              .doc(serviceId)
                              .update({'state': 'in_progress'});
                        },
                        child: const Text("Iniciar servicio"),
                      ),
                    ),
                  if (isOficial && currentStep == 1)
                    Positioned(
                      bottom: 20,
                      left: 20,
                      right: 20,
                      child: ElevatedButton(
                        onPressed: _mostrarValidacionDialog,
                        child: const Text("Validar código del cliente"),
                      ),
                    ),
                  if (!isOficial && currentStep == 2) buildPagoButton(),
                ],
              ),
      ),
    );
  }

  Widget _buildStep(String label, IconData icon, int stepIndex) {
    final isActive = stepIndex <= currentStep;
    return Column(
      children: [
        CircleAvatar(
          backgroundColor: isActive ? Colors.blue : Colors.grey[300],
          child: Icon(icon, color: isActive ? Colors.white : Colors.grey),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isActive ? Colors.black : Colors.grey,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildLine() {
    return Container(
      width: 20,
      height: 2,
      color: Colors.grey[400],
    );
  }
}
