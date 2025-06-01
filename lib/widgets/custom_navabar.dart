import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class CustomNavBar extends StatefulWidget {
  const CustomNavBar({super.key});

  @override
  State<CustomNavBar> createState() => _CustomNavBarState();
}

class _CustomNavBarState extends State<CustomNavBar> {
  int _selectedIndex = 0;

  final List<String> svgAssets = [
    'assets/svg/home.svg',
    'assets/svg/shopping-bag.svg',
    'assets/svg/heart.svg',
    'assets/svg/profile.svg',
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: List.generate(svgAssets.length, (index) {
        bool isSelected = _selectedIndex == index;
        return InkWell(
          onTap: () {
            setState(() {
              _selectedIndex = index;
              if (svgAssets[index] == 'assets/svg/shopping-bag.svg') {
                Navigator.pushNamed(context, '/');
              }
            });
          },
          child: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Color.fromARGB(13, 255, 255, 255),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                // Ícono base
                SvgPicture.asset(
                  svgAssets[index],
                  width: 24,
                  height: 24,
                  color: Colors.white,
                ),
                if (svgAssets[index] == 'assets/svg/shopping-bag.svg')
                  Positioned(
                    top: 4,
                    right: 2,
                    child: SvgPicture.asset(
                      'assets/svg/dot.svg',
                      width: 8,
                      height: 8,
                      color: Color(0xffF13658),
                    ),
                  ),
                // Dot abajo si está seleccionado
                if (isSelected)
                  Positioned(
                    bottom: -4,
                    child: SvgPicture.asset(
                      'assets/svg/dot.svg',
                      width: 4,
                      height: 4,
                      color: Colors.white,
                    ),
                  ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
