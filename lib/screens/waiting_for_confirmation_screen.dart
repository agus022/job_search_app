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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    serviceId = args['serviceId'];

    FirebaseFirestore.instance
        .collection('services')
        .doc(serviceId)
        .snapshots()
        .listen((doc) {
      final data = doc.data();
      if (data?['clientConfirmed'] == true &&
          data?['oficialConfirmed'] == true) {
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
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
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
