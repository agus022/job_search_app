// imports necesarios
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:job_search_oficial/cubit/cubits.dart';
import 'package:job_search_oficial/entities/entities.dart';
import 'package:job_search_oficial/widgets/custom_navabar.dart';
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

  @override
  void initState() {
    context.read<CategoryCubit>().getCategories();
    super.initState();
    final user = context.read<UserCubit>().state.user;
    if (user != null && user.type == UserType.official) {
      listenForIncomingRequests(user.id!, context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserCubit>().state.user;
    final jobCubit = context.read<JobCubit>();

    // Si el usuario no está autenticado, redirigir al login

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF9FAFB),
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
            expandedHeight: 166,
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
                      padding:
                          const EdgeInsets.only(top: 60, left: 16, right: 16),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () =>
                                _scaffoldKey.currentState?.openDrawer(),
                            child: CircleAvatar(
                              radius: 24,
                              backgroundImage: (user?.profilePicture != null &&
                                      user!.profilePicture.trim().isNotEmpty)
                                  ? NetworkImage(user.profilePicture)
                                  : const AssetImage('assets/img/user.webp'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: 'Search...',
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
              preferredSize: const Size.fromHeight(66),
              child: Container(
                color: Colors.white,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.only(left: 16, right: 8, bottom: 6),
                height: 56,
                child: BlocBuilder<CategoryCubit, CategoryState>(
                  builder: (context, state) {
                    if (state.loading) {
                      return const CircularProgressIndicator();
                    }
                    final cats = state.categories ?? [];

                    return ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: cats.length + 1, // +1 para el botón 'Todos'
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          // Botón 'Todos'
                          return GestureDetector(
                            onTap: () async {
                              setState(() {
                                selectedCategoryId = 'all';
                              });

                              // Obtener todos los trabajos
                              final jobs = await jobCubit.getAllJobs();

                              // Obtener usuarios relacionados a cada trabajo
                              List<UserEntity> allUsers = [];

                              for (var job in jobs) {
                                final users =
                                    await jobCubit.getUsersByJob(job.id);
                                allUsers.addAll(users);
                              }

                              // Actualizar el estado con los usuarios encontrados
                              jobCubit.setUsers(allUsers);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 14),
                              decoration: BoxDecoration(
                                color: selectedCategoryId == 'all'
                                    ? Colors.black87
                                    : Colors.grey[200],
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Todos',
                                style: TextStyle(
                                  color: selectedCategoryId == 'all'
                                      ? Colors.white
                                      : Colors.black,
                                ),
                              ),
                            ),
                          );
                        }

                        final category =
                            cats[index - 1]; // porque index 0 es "Todos"

                        return GestureDetector(
                          onTap: () async {
                            setState(() {
                              selectedCategoryId = category.id;
                            });

                            await jobCubit.getJobsByCategory(category.id);
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
                            print('Usuarios encontrados: ${allUsers.length}');
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 14),
                            decoration: BoxDecoration(
                              color: selectedCategoryId == category.id
                                  ? Colors.black87
                                  : Colors.grey[200],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              category.name,
                              style: TextStyle(
                                color: selectedCategoryId == category.id
                                    ? Colors.white
                                    : Colors.black,
                              ),
                            ),
                          ),
                        );
                      },
                      separatorBuilder: (context, index) =>
                          const SizedBox(width: 8),
                    );
                  },
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: BlocBuilder<JobCubit, JobState>(
                builder: (context, state) {
                  final users = state.users ?? [];

                  if (state.loading) {
                    return const SizedBox(
                      height: 390,
                      child: Center(
                        child: LottieLoader(),
                      ),
                    );
                  }

                  if (users.isEmpty) {
                    return const SizedBox(
                      height: 390,
                      child: Center(
                        child: Text(
                            'No se encontraron oficiales en esta categoría'),
                      ),
                    );
                  }

                  return SizedBox(
                    height: 390,
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
                height: 180,
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
                      child: Text(user.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                    const Icon(Icons.verified, color: Colors.green, size: 20),
                  ],
                ),
                const SizedBox(height: 6),
                Text(user.oficialProfile?.description ?? '',
                    style: const TextStyle(fontSize: 13, color: Colors.grey)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(Icons.groups,
                              size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            user.oficialProfile?.location ??
                                'Ubicación no disponible',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(width: 16),
                          const Icon(Icons.folder_copy,
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
                    SizedBox(
                      width: 60,
                      height: 60,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            '/job_detail',
                            arguments: user,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFFFFD55),
                          foregroundColor: Colors.black,
                          shape: const CircleBorder(),
                          padding: EdgeInsets.zero,
                          elevation: 0,
                        ),
                        child: SvgPicture.asset(
                          'assets/svg/arrow-top-right.svg',
                          width: 24,
                          height: 24,
                          color: Colors.black,
                        ),
                      ),
                    ),
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
            decoration: const BoxDecoration(color: Color(0xFF333331)),
            currentAccountPicture: CircleAvatar(
              radius: 24,
              backgroundImage: (user?.profilePicture != null &&
                      user!.profilePicture.trim().isNotEmpty)
                  ? NetworkImage(user.profilePicture)
                  : const AssetImage('assets/img/user.webp'),
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
          if (!isOfficial)
            ListTile(
              leading:
                  const Icon(Icons.group_add_outlined, color: Colors.black87),
              title: const Text('Convertirse en socio'),
              onTap: () => Navigator.pushNamed(context, '/partner'),
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
}
