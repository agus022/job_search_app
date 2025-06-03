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
        final validationCode =
            (1000 + (DateTime.now().millisecondsSinceEpoch % 9000)).toString();

        await FirebaseFirestore.instance
            .collection('services')
            .doc(service.id)
            .set({
          ...service.toMap(),
          'validationCode': validationCode,
          'clientConfirmed': true,
        });

        await FirebaseFirestore.instance
            .collection('users')
            .doc(client.id)
            .update({
          'activeService': service.id,
        });

        Navigator.pushReplacementNamed(context, '/waiting_confirmation',
            arguments: {
              'serviceId': service.id!,
            });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al confirmar el servicio: $e')),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Confirmación de Servicio')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('👤 Oficial: ${oficial.name} ${oficial.lastName}',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('📍 Dirección: ${service.address}'),
            const SizedBox(height: 8),
            Text('📝 Descripción: ${service.description}'),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Confirmar'),
                    onPressed: confirmService,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
