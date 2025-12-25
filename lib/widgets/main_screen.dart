import 'package:flutter/material.dart';
import 'homepage.dart';
import '../garage/garage_list_page.dart';
import '../vehicle/garage_page.dart';
import 'history_expenses_page.dart';
import 'profile_page.dart';

class MainScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const MainScreen({super.key, required this.user});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  late final List<Widget> _pages;
  final GlobalKey<State<HomePage>> _homePageKey = GlobalKey<State<HomePage>>();

  @override
  void initState() {
    super.initState();
    _pages = [
      // Tab 0: Trang chủ
      HomePage(
        key: _homePageKey,
        user: widget.user,
        onSwitchTab: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
      const GaragePage(),
      const GarageListPage(), // Tab 2: Tìm kiếm
      HistoryExpensesPage(user: widget.user), // Tab 3: Lịch sử
      UserProfilePage(user: widget.user), // Tab 4: Thông tin
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.black,
        selectedItemColor: const Color(0xFF92D6E3),
        unselectedItemColor: Colors.white,
        showUnselectedLabels: true,
        onTap: (index) {
          setState(() => _currentIndex = index);
          // Refresh expenses when returning to home tab
          if (index == 0) {
            final homeState = _homePageKey.currentState;
            if (homeState != null && homeState.mounted) {
              (homeState as dynamic).refreshExpenses();
            }
          }
        },
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
      activeIcon: Image.asset(
        iconPath,
        height: 24,
        color: const Color(0xFF92D6E3),
      ),
      label: label,
    );
  }
}
