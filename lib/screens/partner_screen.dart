import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:job_search_oficial/cubit/cubits.dart';

class PartnerScreen extends StatefulWidget {
  const PartnerScreen({super.key});

  @override
  State<PartnerScreen> createState() => _PartnerScreenState();
}

class _PartnerScreenState extends State<PartnerScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _descController = TextEditingController();
  String? selectedCategoryId;
  final List<String> selectedJobs = [];
  final List<String> selectedJobNames = [];

  @override
  void initState() {
    super.initState();
    context.read<CategoryCubit>().getCategories();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate() || selectedJobs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Completa todos los campos y selecciona al menos un trabajo.'),
        ),
      );
      return;
    }

    final userCubit = context.read<UserCubit>();
    final user = userCubit.state.user;
    if (user == null) return;

    final jobRefs = selectedJobs.map((id) {
      return FirebaseFirestore.instance.collection('jobs').doc(id);
    }).toList();

    final oficialProfile = {
      'description': _descController.text.trim(),
      'location': 'Celaya, Gto.',
      'jobIds': jobRefs,
      'califications': [],
    };

    await FirebaseFirestore.instance.collection('users').doc(user.id).update({
      'type': 'official',
      'oficialProfile': oficialProfile,
      'clientProfile': FieldValue.delete(),
    });

    await userCubit.refreshUser();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Ya eres un socio oficial!')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text('Convertirse en socio',
            style: TextStyle(color: Colors.black)),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('📄 Describe tu experiencia',
                  style: textTheme.titleMedium!
                      .copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Ej. Sé hacer mezclas, plomería, etc.',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Campo requerido'
                    : null,
              ),
              const SizedBox(height: 24),
              Text('📂 Selecciona una categoría',
                  style: textTheme.titleMedium!
                      .copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              BlocBuilder<CategoryCubit, CategoryState>(
                builder: (context, state) {
                  final categories = state.categories ?? [];
                  return DropdownButtonFormField<String>(
                    value: selectedCategoryId,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    items: categories.map((cat) {
                      return DropdownMenuItem(
                        value: cat.id,
                        child: Text(cat.name),
                      );
                    }).toList(),
                    onChanged: (id) {
                      setState(() {
                        selectedCategoryId = id;
                        selectedJobs.clear();
                        selectedJobNames.clear();
                      });
                      if (id != null) {
                        context.read<JobCubit>().getJobsByCategory(id);
                      }
                    },
                    validator: (value) =>
                        value == null ? 'Selecciona una categoría' : null,
                  );
                },
              ),
              const SizedBox(height: 24),
              Text('🛠 Selecciona tus habilidades',
                  style: textTheme.titleMedium!
                      .copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              BlocBuilder<JobCubit, JobState>(
                builder: (context, state) {
                  final jobs = state.jobs ?? [];
                  if (jobs.isEmpty) {
                    return const Text(
                        'Selecciona una categoría para ver los trabajos.');
                  }
                  return Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: jobs.map((job) {
                      final isSelected = selectedJobs.contains(job.id);
                      return FilterChip(
                        label: Text(job.name),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              selectedJobs.add(job.id);
                              selectedJobNames.add(job.name);
                            } else {
                              selectedJobs.remove(job.id);
                              selectedJobNames.remove(job.name);
                            }
                          });
                        },
                        selectedColor: Colors.green.shade200,
                        backgroundColor: Colors.grey.shade200,
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _submitForm,
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Convertirse en socio'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
