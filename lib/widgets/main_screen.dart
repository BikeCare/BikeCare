import 'package:flutter/material.dart';
import 'homepage.dart';         
import 'garage_list_page.dart'; 
import 'garage_page.dart';

class MainScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const MainScreen({super.key, required this.user});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      // Tab 0: Trang chủ
      HomePage(
        user: widget.user,
        onSwitchTab: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
      const GaragePage(),  
      const GarageListPage(),                   // Tab 2: Tìm kiếm
      const Center(child: Text("Lịch sử")),     // Tab 3

      const Center(child: Text("Thông tin", style: TextStyle(fontSize: 20))), // Tab 4
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.black,
        selectedItemColor: const Color(0xFF92D6E3),
        unselectedItemColor: Colors.white,
        showUnselectedLabels: true,
        onTap: (index) => setState(() => _currentIndex = index),
        items: [
          _bottomItem('images/home.png', 'Trang chủ'),
          _bottomItem('images/gara.png', 'Garage'),
          _bottomItem('images/find.png', 'Tìm'),
          _bottomItem('images/history.png', 'Lịch sử'),
          _bottomItem('images/profile.png', 'Thông tin'),
        ],
      ),
    );
  }

  BottomNavigationBarItem _bottomItem(String iconPath, String label) {
    return BottomNavigationBarItem(
      icon: Image.asset(iconPath, height: 24, color: Colors.white),
      activeIcon: Image.asset(iconPath, height: 24, color: const Color(0xFF92D6E3)),
      label: label,
    );
  }
}