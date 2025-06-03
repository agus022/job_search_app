// imports necesarios
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:job_search_oficial/core/constants/text_styles.dart';
import 'package:job_search_oficial/cubit/cubits.dart';
import 'package:job_search_oficial/entities/entities.dart';
import 'package:job_search_oficial/widgets/custom_navabar.dart';
import 'package:job_search_oficial/widgets/glowing_button.dart';
import 'package:job_search_oficial/widgets/lottie_loader.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final PageController _pageController = PageController(viewportFraction: 0.8);
  String selectedCategoryId = 'all';
  late final JobCubit jobCubit;

  @override
  void initState() {
    context.read<CategoryCubit>().getCategories();
    super.initState();
    final user = context.read<UserCubit>().state.user;
    if (user != null && user.type == UserType.official) {
      listenForIncomingRequests(user.id!, context);
    }
    jobCubit = context.read<JobCubit>();
    _loadAllUsers();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserCubit>().state.user;
    final jobCubit = context.read<JobCubit>();

    if (user?.type == UserType.official) {
      // Mostrar otra cosa para usuarios tipo "official"
      return Scaffold(
          key: _scaffoldKey,
          backgroundColor: const Color.fromARGB(255, 255, 255, 255),
          drawer: _buildDrawer(context, user),
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.only(bottom: 5, left: 24, right: 24),
            child: Container(
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 255, 255, 255),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(44),
                  topRight: Radius.circular(44),
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(44),
                  color: const Color(0xff292526),
                  boxShadow: const [
                    BoxShadow(
                      color: Color.fromARGB(197, 255, 255, 255),
                      blurRadius: 10,
                      spreadRadius: 3,
                    ),
                  ],
                ),
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                child: const CustomNavBar(),
              ),
            ),
          ),
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor: Colors.white,
                pinned: false,
                floating: true,
                automaticallyImplyLeading: false,
                expandedHeight: 140,
                flexibleSpace: LayoutBuilder(
                  builder: (context, constraints) {
                    final percent = ((constraints.maxHeight - kToolbarHeight) /
                            (140 - kToolbarHeight))
                        .clamp(0.0, 1.0);
                    if (percent == 0) return const SizedBox.shrink();

                    return FlexibleSpaceBar(
                      background: Opacity(
                        opacity: percent,
                        child: Padding(
                          padding: const EdgeInsets.only(
                              top: 20, bottom: 30, left: 16, right: 16),
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: () =>
                                    _scaffoldKey.currentState?.openDrawer(),
                                child: Container(
                                  padding: const EdgeInsets.all(
                                      2), // Grosor del borde
                                  decoration: BoxDecoration(
                                    color: Colors.white, // Color del borde
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color.fromARGB(255, 255, 196,
                                          0), // Color del borde (puedes usar Theme.of(context).primaryColor)
                                      width: 2, // Ancho del borde
                                    ),
                                  ),
                                  child: CircleAvatar(
                                    radius: 24,
                                    backgroundColor: Colors.black,
                                    backgroundImage: (user?.profilePicture !=
                                                null &&
                                            user!.profilePicture
                                                .trim()
                                                .isNotEmpty)
                                        ? NetworkImage(user.profilePicture)
                                        : const AssetImage(
                                                'assets/img/default_avatar3.png')
                                            as ImageProvider,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  decoration: InputDecoration(
                                    hintText: 'Search...',
                                    hintStyle: AppTextStyles.formSearch,
                                    filled: true,
                                    fillColor: Colors.grey[200],
                                    prefixIcon: const Icon(Icons.search),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ));
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      drawer: _buildDrawer(context, user),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(bottom: 5, left: 24, right: 24),
        child: Container(
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 255, 255, 255),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(44),
              topRight: Radius.circular(44),
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(44),
              color: const Color(0xff292526),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromARGB(197, 255, 255, 255),
                  blurRadius: 10,
                  spreadRadius: 3,
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            child: const CustomNavBar(),
          ),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: Colors.white,
            pinned: false,
            floating: true,
            automaticallyImplyLeading: false,
            expandedHeight: 140,
            flexibleSpace: LayoutBuilder(
              builder: (context, constraints) {
                final percent = ((constraints.maxHeight - kToolbarHeight) /
                        (140 - kToolbarHeight))
                    .clamp(0.0, 1.0);
                if (percent == 0) return const SizedBox.shrink();

                return FlexibleSpaceBar(
                  background: Opacity(
                    opacity: percent,
                    child: Padding(
                      padding: const EdgeInsets.only(
                          top: 20, bottom: 30, left: 16, right: 16),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () =>
                                _scaffoldKey.currentState?.openDrawer(),
                            child: Container(
                              padding:
                                  const EdgeInsets.all(2), // Grosor del borde
                              decoration: BoxDecoration(
                                color: Colors.white, // Color del borde
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color.fromARGB(255, 255, 196,
                                      0), // Color del borde (puedes usar Theme.of(context).primaryColor)
                                  width: 2, // Ancho del borde
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 24,
                                backgroundColor: Colors.black,
                                backgroundImage: (user?.profilePicture !=
                                            null &&
                                        user!.profilePicture.trim().isNotEmpty)
                                    ? NetworkImage(user.profilePicture)
                                    : const AssetImage(
                                            'assets/img/default_avatar3.png')
                                        as ImageProvider,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: 'Search...',
                                hintStyle: AppTextStyles.formSearch,
                                filled: true,
                                fillColor: Colors.grey[200],
                                prefixIcon: const Icon(Icons.search),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(106),
              child: Container(
                height: 70,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: const BoxDecoration(
                  color: Colors.white,
                ),
                child: BlocBuilder<CategoryCubit, CategoryState>(
                  builder: (context, state) {
                    if (state.loading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final cats = state.categories ?? [];

                    return ListView.separated(
                      scrollDirection: Axis.horizontal,
                      shrinkWrap: true,
                      itemCount: cats.length + 1,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        final isSelected = index == 0
                            ? selectedCategoryId == 'all'
                            : selectedCategoryId == cats[index - 1].id;

                        final label =
                            index == 0 ? 'Todos' : cats[index - 1].name;

                        return GestureDetector(
                          onTap: () async {
                            final selectedId =
                                index == 0 ? 'all' : cats[index - 1].id;

                            setState(() {
                              selectedCategoryId = selectedId;
                            });

                            if (selectedId == 'all') {
                              final jobs = await jobCubit.getAllJobs();

                              List<UserEntity> allUsers = [];

                              for (var job in jobs) {
                                final users =
                                    await jobCubit.getUsersByJob(job.id);
                                allUsers.addAll(users);
                              }

                              jobCubit.setUsers(allUsers);
                            } else {
                              await jobCubit.getJobsByCategory(selectedId);
                              final jobs = jobCubit.state.jobs ?? [];

                              final Map<String, UserEntity> userMap = {};

                              for (var job in jobs) {
                                final users =
                                    await jobCubit.getUsersByJob(job.id);
                                for (var user in users) {
                                  userMap[user.id ?? UniqueKey().toString()] =
                                      user;
                                }
                              }

                              final allUsers = userMap.values.toList();
                              jobCubit.setUsers(allUsers);
                            }
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color.fromARGB(255, 0, 0, 0)
                                  : Color.fromARGB(255, 255, 255, 255),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color.fromARGB(
                                    255, 52, 52, 52), // Cambia el color aquí
                                width: 1.5, // Cambia el grosor aquí
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  index == 0 ? Icons.list : Icons.category,
                                  color: isSelected
                                      ? Colors.white
                                      : const Color.fromARGB(255, 29, 29, 29),
                                  size: 20,
                                ),
                                const SizedBox(width: 6),
                                Text(label,
                                    style: isSelected
                                        ? AppTextStyles.textCategoryon
                                        : AppTextStyles.textCategoryoff),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                        'Oficiales disponibles:', // Puedes cambiar este texto
                        style: AppTextStyles.hometitle),
                  ),
                  const SizedBox(height: 10),
                  BlocBuilder<JobCubit, JobState>(
                    builder: (context, state) {
                      final users = state.users ?? [];

                      if (state.loading) {
                        return const SizedBox(
                          height: 420,
                          child: Center(
                            child: LottieLoader(),
                          ),
                        );
                      }

                      if (users.isEmpty) {
                        return const SizedBox(
                          height: 420,
                          child: Center(
                            child: Text(
                                'No se encontraron oficiales en esta categoría'),
                          ),
                        );
                      }

                      return SizedBox(
                        height: 420,
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount: users.length,
                          itemBuilder: (context, index) {
                            final oficial = users[index];
                            return AnimatedBuilder(
                              animation: _pageController,
                              builder: (context, child) {
                                double value = 1.0;
                                if (_pageController.position.haveDimensions) {
                                  value = (_pageController.page! - index).abs();
                                  value = (1 - (value * 0.2)).clamp(0.9, 1.0);
                                }
                                return Transform.scale(
                                  scale: value,
                                  child: child,
                                );
                              },
                              child: _buildCardFromUser(context, oficial),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardFromUser(BuildContext context, UserEntity user) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.network(
                user.profilePicture,
                height: 210,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text('${user.name} ${user.lastName}',
                          style: AppTextStyles.mamecard),
                    ),
                    Icon(Icons.verified,
                        color: const Color.fromARGB(255, 41, 41, 41), size: 20),
                  ],
                ),
                const SizedBox(height: 6),
                Text(user.oficialProfile?.description ?? '',
                    style: AppTextStyles.desccard),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(Icons.location_on,
                              size: 16, color: Color(0xff595959)),
                          const SizedBox(width: 4),
                          Text(
                            user.oficialProfile?.location ??
                                'Ubicación no disponible',
                            style: AppTextStyles.locccard,
                          ),
                          const SizedBox(width: 16),
                          const Icon(Icons.reviews,
                              size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            '5',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    GlowingButton(user: user),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          )
        ],
      ),
    );
  }

  Drawer _buildDrawer(BuildContext context, UserEntity? user) {
    final isOfficial = user?.type == UserType.official;

    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration:
                const BoxDecoration(color: Color.fromARGB(255, 2, 2, 2)),
            currentAccountPicture: CircleAvatar(
              radius: 24,
              backgroundColor: Theme.of(context).primaryColor,
              backgroundImage: (user?.profilePicture != null &&
                      user!.profilePicture.trim().isNotEmpty)
                  ? NetworkImage(user.profilePicture)
                  : const AssetImage('assets/img/default_avatar3.png')
                      as ImageProvider,
            ),
            accountName: Text(
              '${user?.name ?? ''} ${user?.lastName ?? ''} ${user?.type == UserType.official ? ' (Oficial)' : ''}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            accountEmail:
                Text(user?.email ?? '', style: const TextStyle(fontSize: 14)),
          ),
          ListTile(
            leading: const Icon(Icons.person_outline, color: Colors.black87),
            title: const Text('Perfil'),
            onTap: () => Navigator.pushNamed(
              context,
              '/profile_detail',
              arguments: user,
            ),
          ),
          if (user?.type == UserType.official)
            ListTile(
              leading: const Icon(Icons.engineering, color: Colors.black87),
              title: const Text('Editar perfil de socio'),
              onTap: () {
                Navigator.pushNamed(context, '/edit_partner_profile',
                    arguments: user);
              },
            ),
          if (isOfficial)
            ListTile(
              leading: const Icon(Icons.swap_horiz),
              title: const Text('Cambiar a Cliente'),
              onTap: () async {
                if (user != null) {
                  await switchToClient(context, user.id!);

                  // Refrescar el estado del usuario
                  await context.read<UserCubit>().fetchUser();

                  // Actualizar la interfaz (por ejemplo, recargar pantalla)
                  setState(() {});
                }
              },
            ),
          if (!isOfficial)
            ListTile(
              leading:
                  const Icon(Icons.group_add_outlined, color: Colors.black87),
              title: Text(
                (user?.oficialProfile?.jobIds.isNotEmpty == true)
                    ? 'Convertirse en oficial'
                    : 'Convertirse en socio',
              ),
              onTap: () async {
                if (user != null) {
                  final hasJobs =
                      user.oficialProfile?.jobIds.isNotEmpty == true;

                  if (hasJobs) {
                    //  Actualizar tipo en Firestore directamente
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.id!)
                        .update({'type': UserType.official.name});

                    // Refrescar usuario
                    await context.read<UserCubit>().fetchUser();

                    //  Mostrar confirmación y refrescar UI
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Ahora eres oficial')),
                    );
                    setState(() {});
                  } else {
                    // Si aún no tiene trabajos, mandarlo al formulario de socio
                    Navigator.pushNamed(context, '/partner');
                  }
                }
              },
            ),
          const Spacer(),
          const Divider(thickness: 1),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Cerrar sesión'),
            onTap: () async {
              await context.read<UserCubit>().logout();
              Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void listenForIncomingRequests(String oficialId, BuildContext context) {
    final shownRequests = <String>{};
    bool isDialogShowing = false;

    FirebaseFirestore.instance
        .collection('services')
        .where('oficialRef', isEqualTo: oficialId)
        .where('state', isEqualTo: 'pendent')
        .snapshots()
        .listen((snapshot) {
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final service = Service.fromMap(data, docId: doc.id);

        // Evitar mostrar duplicados o si ya hay un diálogo activo
        if (service.state == ServiceStatus.pendent &&
            !shownRequests.contains(service.id) &&
            !isDialogShowing) {
          if (service.id != null) {
            shownRequests.add(service.id!);
          }
          isDialogShowing = true;

          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => AlertDialog(
              title: const Text('Nueva solicitud'),
              content: Text('¿Aceptar servicio en: ${service.address}?'),
              actions: [
                TextButton(
                  onPressed: () async {
                    await FirebaseFirestore.instance
                        .collection('services')
                        .doc(service.id)
                        .update({
                      'state': ServiceStatus.cancelled.name,
                    });
                    Navigator.of(context).pop();
                    isDialogShowing = false;
                  },
                  child: const Text('Rechazar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await FirebaseFirestore.instance
                        .collection('services')
                        .doc(service.id)
                        .update({
                      'state': ServiceStatus.accepted.name,
                      'oficialConfirmed': true,
                    });

                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(oficialId)
                        .update({'activeService': service.id});

                    Navigator.of(context).pop();
                    isDialogShowing = false;

                    if (context.mounted) {
                      Navigator.pushNamed(
                        context,
                        '/live_tracking',
                        arguments: {
                          'serviceId': service.id!,
                          'isOficial': true,
                        },
                      );
                    }
                  },
                  child: const Text('Aceptar'),
                ),
              ],
            ),
          ).then((_) {
            isDialogShowing = false;
          });
        }
      }
    });
  }

  Future<void> _loadAllUsers() async {
    final jobs = await jobCubit.getAllJobs();

    List<UserEntity> allUsers = [];

    for (var job in jobs) {
      final users = await jobCubit.getUsersByJob(job.id);
      allUsers.addAll(users);
    }

    jobCubit.setUsers(allUsers);
  }

  Future<void> switchToClient(BuildContext context, String userId) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'type': 'client',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Has cambiado a tipo cliente')),
      );

      // Redirigir a pantalla de cliente
      Navigator.pushReplacementNamed(context, '/home'); // o donde corresponda
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cambiar de tipo: $e')),
      );
    }
  }
}
