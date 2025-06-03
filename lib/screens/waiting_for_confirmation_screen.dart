import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class WaitingForConfirmationScreen extends StatefulWidget {
  const WaitingForConfirmationScreen({super.key});

  @override
  State<WaitingForConfirmationScreen> createState() =>
      _WaitingForConfirmationScreenState();
}

class _WaitingForConfirmationScreenState
    extends State<WaitingForConfirmationScreen> {
  late String serviceId;
  StreamSubscription<DocumentSnapshot>? _serviceSub;
  Timer? _timeoutTimer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    serviceId = args['serviceId'];

    //  Escuchar confirmación del oficial
    _serviceSub = FirebaseFirestore.instance
        .collection('services')
        .doc(serviceId)
        .snapshots()
        .listen((doc) {
      final data = doc.data();
      if (data?['clientConfirmed'] == true &&
          data?['oficialConfirmed'] == true &&
          mounted) {
        _timeoutTimer?.cancel();
        _serviceSub?.cancel();
        Navigator.pushReplacementNamed(
          context,
          '/live_tracking',
          arguments: {
            'serviceId': serviceId,
            'isOficial': false,
          },
        );
      }
    });

    //  Inicia el temporizador de 30 segundos
    _timeoutTimer = Timer(const Duration(seconds: 30), _handleTimeout);
  }

  Future<void> _handleTimeout() async {
    await FirebaseFirestore.instance
        .collection('services')
        .doc(serviceId)
        .update({'state': 'cancelled'});

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El oficial no respondió a tiempo.')),
      );
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  Future<void> _cancelManually() async {
    _timeoutTimer?.cancel();
    _serviceSub?.cancel();

    await FirebaseFirestore.instance
        .collection('services')
        .doc(serviceId)
        .update({'state': 'cancelled'});

    if (mounted) {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  void dispose() {
    _serviceSub?.cancel();
    _timeoutTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Esperando Confirmación'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.cancel),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('¿Cancelar solicitud?'),
                  content: const Text('¿Estás seguro de que deseas cancelar?'),
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

              if (confirmed == true) {
                await _cancelManually();
              }
            },
          )
        ],
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Esperando confirmación del oficial...'),
          ],
        ),
      ),
    );
  }
}
