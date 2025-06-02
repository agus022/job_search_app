import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:job_search_oficial/cubit/cubits.dart';

class EditPartnerProfileScreen extends StatefulWidget {
  const EditPartnerProfileScreen({super.key});

  @override
  State<EditPartnerProfileScreen> createState() =>
      _EditPartnerProfileScreenState();
}

class _EditPartnerProfileScreenState extends State<EditPartnerProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  List<String> selectedJobs = [];
  List<String> selectedJobNames = [];
  String? selectedCategoryId;

  @override
  void initState() {
    super.initState();
    context.read<CategoryCubit>().getCategories();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = context.read<UserCubit>().state.user!;
    final profile = user.oficialProfile;

    _descController.text = profile?.description ?? '';
    _locationController.text = profile?.location ?? '';

    selectedJobs = profile?.jobIds.map((ref) => (ref).id).toList() ?? [];
    selectedJobNames = profile?.jobNames ?? [];
  }

  void _submit() async {
    final userCubit = context.read<UserCubit>();
    final user = userCubit.state.user!;

    final jobRefs = selectedJobs.map((id) {
      return FirebaseFirestore.instance.collection('jobs').doc(id);
    }).toList();

    final updatedProfile = {
      'description': _descController.text.trim(),
      'location': _locationController.text.trim(),
      'jobIds': jobRefs,
      'jobNames': selectedJobNames,
    };

    await FirebaseFirestore.instance.collection('users').doc(user.id).update({
      'oficialProfile': updatedProfile,
    });

    await userCubit.refreshUser();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil actualizado')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('Editar perfil de socio'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Descripción de tu experiencia'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descController,
                maxLines: 3,
                decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Ej. Mezclo concreto, coloco tabiques...'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 20),
              const Text('Ubicación textual'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                    border: OutlineInputBorder(), hintText: 'Ej. Celaya, Gto.'),
              ),
              const SizedBox(height: 20),
              const Text('Selecciona categoría'),
              BlocBuilder<CategoryCubit, CategoryState>(
                builder: (context, state) {
                  final categories = state.categories ?? [];
                  return DropdownButtonFormField<String>(
                    value: selectedCategoryId,
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
                  );
                },
              ),
              const SizedBox(height: 20),
              const Text('Selecciona tus trabajos'),
              BlocBuilder<JobCubit, JobState>(
                builder: (context, state) {
                  final jobs = state.jobs ?? [];
                  return Column(
                    children: jobs.map((job) {
                      return CheckboxListTile(
                        title: Text(job.name),
                        value: selectedJobs.contains(job.id),
                        onChanged: (selected) {
                          setState(() {
                            if (selected!) {
                              selectedJobs.add(job.id);
                              selectedJobNames.add(job.name);
                            } else {
                              selectedJobs.remove(job.id);
                              selectedJobNames.remove(job.name);
                            }
                          });
                        },
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.save),
                label: const Text('Guardar cambios'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
