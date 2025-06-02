import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:job_search_oficial/entities/service.dart';

class IncomingRequestScreen extends StatelessWidget {
  final Service service;

  const IncomingRequestScreen({super.key, required this.service});

  Future<void> confirmAsOficial(BuildContext context) async {
    try {
      await FirebaseFirestore.instance
          .collection('services')
          .doc(service.id)
          .update({'oficialConfirmed': true});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Esperando confirmación del cliente...')),
      );

      FirebaseFirestore.instance
          .collection('services')
          .doc(service.id)
          .snapshots()
          .listen((doc) {
        final data = doc.data();
        if (data?['clientConfirmed'] == true &&
            data?['oficialConfirmed'] == true) {
          // Ambos confirmaron, cambiar estado a 'accepted'
          FirebaseFirestore.instance
              .collection('services')
              .doc(service.id)
              .update({'state': ServiceStatus.accepted.name});

          Navigator.pushReplacementNamed(
            context,
            '/live_tracking',
            arguments: {
              'serviceId': service.id!,
              'isOficial': true, // Oficial
            },
          );
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al aceptar el servicio: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Solicitud entrante')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Dirección: ${service.address}'),
            Text('Descripción: ${service.description}'),
            Text('Cliente: ${service.clientRef}'),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => confirmAsOficial(context),
              icon: const Icon(Icons.check_circle),
              label: const Text('Aceptar servicio'),
            ),
          ],
        ),
      ),
    );
  }
}
