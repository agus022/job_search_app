import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:job_search_oficial/cubit/category_cubit.dart';
import 'package:job_search_oficial/cubit/cubits.dart';
import 'package:job_search_oficial/widgets/custom_navabar.dart';

class Oficial {
  final String name;
  final String description;
  final String image;
  final String followers;
  final String projects;
  Oficial(
      {required this.name,
      required this.description,
      required this.image,
      required this.followers,
      required this.projects});
}

final List<Oficial> oficiales = [
  Oficial(
      name: "Sophie Bennett",
      description: "Product Designer who focuses on simplicity & usability.",
      image: "assets/img/user.webp",
      followers: "312",
      projects: "48"),
  Oficial(
      name: "Oficial Don",
      description: "Electricista con experiencia y recomendaciones.",
      image: "assets/img/user.webp",
      followers: "2.6K",
      projects: "34"),
  Oficial(
      name: "Oficial Juan",
      description: "Plomero certificado para trabajos residenciales.",
      image: "assets/img/user.webp",
      followers: "506",
      projects: "12"),
];

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final PageController _pageController = PageController(viewportFraction: 0.8);

  @override
  void initState() {
    context.read<CategoryCubit>().getCategories();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF9FAFB),
      drawer: _buildDrawer(context),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(bottom: 5, left: 24, right: 24),
        child: Container(
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 255, 255, 255),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(44),
              topRight: Radius.circular(44),
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(44),
              color: Color(0xff292526),
              boxShadow: [
                BoxShadow(
                  color: const Color.fromARGB(197, 255, 255, 255),
                  blurRadius: 10,
                  spreadRadius: 3,
                  offset: Offset(0, 0),
                ),
              ],
            ),
            padding: EdgeInsets.only(top: 10, bottom: 10, left: 16, right: 16),
            child: CustomNavBar(),
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
              builder: (BuildContext context, BoxConstraints constraints) {
                final double percent =
                    ((constraints.maxHeight - kToolbarHeight) /
                            (140 - kToolbarHeight))
                        .clamp(0.0, 1.0);

                // Cuando scroll hacia abajo (colapsado), ocultamos todo
                if (percent == 0) return const SizedBox.shrink();

                return FlexibleSpaceBar(
                  background: Opacity(
                    opacity: percent,
                    child: Padding(
                      padding: const EdgeInsets.only(
                        top: 60.0,
                        left: 16,
                        right: 16,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () =>
                                    _scaffoldKey.currentState?.openDrawer(),
                                child: const CircleAvatar(
                                  radius: 24,
                                  backgroundImage:
                                      AssetImage('assets/img/user.webp'),
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
                      return const SizedBox(
                          height: 24, child: CircularProgressIndicator());
                    }
                    if (state.error != null) {
                      return Text(state.error!);
                    }
                    final cats = state.categories ?? [];
                    return ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: cats.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(cats[index].name,
                            style: const TextStyle(color: Colors.black)),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: SizedBox(
                height: 390,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: oficiales.length,
                  itemBuilder: (context, index) {
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
                      child: _buildCard(context, oficiales[index]),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context, Oficial oficial) {
    return LayoutBuilder(
      builder: (context, constraints) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  oficial.image,
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
                          child: Text(oficial.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16))),
                      const Icon(Icons.verified, color: Colors.green, size: 20),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(oficial.description,
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
                              oficial.followers,
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey),
                            ),
                            const SizedBox(width: 16),
                            const Icon(Icons.folder_copy,
                                size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              oficial.projects,
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
                            Navigator.pushNamed(context, '/job_detail');
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
      ),
    );
  }

  Drawer _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              color: Color.fromARGB(255, 51, 51, 49), // verde profesional
            ),
            currentAccountPicture: const CircleAvatar(
              backgroundImage:
                  AssetImage('assets/img/user.webp'), // Reemplaza con tu imagen
            ),
            accountName: Text(
              'Cristian Quintana',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            accountEmail: Text(
              'cristian@email.com',
              style: TextStyle(fontSize: 14),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person_outline, color: Colors.black87),
            title: const Text('Perfil'),
            onTap: () {
              Navigator.pushNamed(context, '/profile_detail');
            },
          ),
          ListTile(
            leading:
                const Icon(Icons.group_add_outlined, color: Colors.black87),
            title: const Text('Convertirse en socio'),
            onTap: () {
              Navigator.pushNamed(context, '/partner');
            },
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Divider(thickness: 1),
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text(
              'Cerrar sesión',
              style: TextStyle(color: Colors.redAccent),
            ),
            onTap: () {
              // acción de cerrar sesión
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class AccountSettingsScreen extends StatelessWidget {
  const AccountSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Configuración de Cuenta")),
      body: const Center(child: Text("Pantalla de configuración")),
    );
  }
}
