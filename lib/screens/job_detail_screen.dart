import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:job_search_oficial/cubit/user_cubit.dart';
import 'package:job_search_oficial/entities/user.dart';

class JobDetailScreen extends StatelessWidget {
  final UserEntity user;

  const JobDetailScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: Text('${user.name} ${user.lastName}'),
        elevation: 0,
        surfaceTintColor: Colors.black,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey.shade200,
                backgroundImage: NetworkImage(user.profilePicture),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                '${user.name} ${user.lastName}',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 2,
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Descripción',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      user.oficialProfile?.description ?? 'Sin descripción',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const Divider(height: 32),
                    _infoRow(Icons.location_on, 'Ubicación',
                        user.oficialProfile?.location ?? 'N/A'),
                    _infoRow(Icons.phone, 'Teléfono', user.phone),
                    _infoRow(Icons.email, 'Email', user.email),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Calificaciones',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (user.oficialProfile?.califications?.isEmpty ?? true)
              Text('Este socio aún no tiene calificaciones.'),
            ...?user.oficialProfile?.califications?.map(
              (cal) => Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const Icon(Icons.star, color: Colors.amber),
                  title: Text(cal.comment),
                  subtitle: Text('Puntuación: ${cal.punctuation.name}'),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(20),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(
              Icons.bolt,
              color: Colors.amber,
            ),
            label: const Text(
              'Solicitar Servicio Ahora',
              style: TextStyle(
                fontSize: 16,
              ),
            ),
            onPressed: () {
              final currentUser = context.read<UserCubit>().state.user;

              if (currentUser == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Debes iniciar sesión para continuar')),
                );
                return;
              }

              Navigator.pushNamed(
                context,
                '/request_service',
                arguments: {
                  'client': currentUser,
                  'oficial': user,
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[700]),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$label: $value',
              style: const TextStyle(fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }
}
