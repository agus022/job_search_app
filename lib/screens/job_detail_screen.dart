import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:job_search_oficial/cubit/user_cubit.dart';
import 'package:job_search_oficial/entities/user.dart';

class JobDetailScreen extends StatelessWidget {
  final UserEntity user;

  const JobDetailScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(user.name),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: NetworkImage(user.profilePicture),
            ),
            const SizedBox(height: 16),
            Text(
              '${user.name} ${user.lastName}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(user.oficialProfile?.description ?? 'Sin descripción'),
            const Divider(height: 32),
            Text('Ubicación: ${user.oficialProfile?.location ?? 'N/A'}'),
            Text('Teléfono: ${user.phone}'),
            Text('Email: ${user.email}'),
            const Divider(height: 32),
            Text('Calificaciones:',
                style: Theme.of(context).textTheme.titleMedium),
            ...?user.oficialProfile?.califications?.map((cal) => ListTile(
                  title: Text(cal.comment),
                  subtitle: Text('Puntuación: ${cal.punctuation.name}'),
                )),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          icon: const Icon(Icons.bolt),
          label: const Text('Solicitar Servicio Ahora'),
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
    );
  }
}
