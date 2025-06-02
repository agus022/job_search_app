import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:job_search_oficial/entities/service.dart';
import 'package:job_search_oficial/entities/user.dart';

class RequestServiceScreen extends StatelessWidget {
  const RequestServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final client = args['client'] as UserEntity;
    final oficial = args['oficial'] as UserEntity;

    final docRef = FirebaseFirestore.instance.collection('services').doc();

    final service = Service(
      id: docRef.id,
      clientRef: client.id!,
      oficialRef: oficial.id!,
      date: DateTime.now(),
      address: oficial.oficialProfile?.location ?? 'Sin dirección',
      description: oficial.oficialProfile?.description ?? 'Sin descripción',
      state: ServiceStatus.pendent,
      price: 0.0,
      paymentMethods: [PaymentMethod.cash],
    );

    Future<void> confirmService() async {
      try {
        if (service.id == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ID del servicio no disponible.')),
          );
          return;
        }

        await FirebaseFirestore.instance
            .collection('services')
            .doc(service.id)
            .set(service.toMap());

        await FirebaseFirestore.instance
            .collection('services')
            .doc(service.id)
            .update({'clientConfirmed': true});

        // Ir a pantalla de espera
        Navigator.pushReplacementNamed(
          context,
          '/waiting_confirmation',
          arguments: {
            'serviceId': service.id!,
          },
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al confirmar el servicio: $e')),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Confirmar Servicio')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Oficial: ${oficial.name} ${oficial.lastName}'),
            Text(
                'Descripción: ${oficial.oficialProfile?.description ?? 'N/A'}'),
            const SizedBox(height: 24),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: confirmService,
                  icon: const Icon(Icons.check),
                  label: const Text('Confirmar'),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
