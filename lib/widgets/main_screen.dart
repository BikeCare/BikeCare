import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppBottomNav extends StatelessWidget {
  final Map<String, dynamic> user;

  const AppBottomNav({super.key, required this.user});

  int _getCurrentIndex(BuildContext context) {
    // ✅ Dùng path thay vì toString() để không dính query / slash
    final path = GoRouter.of(
      context,
    ).routerDelegate.currentConfiguration.uri.path;

    if (path.startsWith('/homepage')) return 0;
    if (path.startsWith('/garage')) return 1;
    if (path.startsWith('/find')) return 2;
    if (path.startsWith('/history')) return 3;
    if (path.startsWith('/profile')) return 4;

    return 0;
  }

  void _onNavTap(BuildContext context, int index) {
    final currentIndex = _getCurrentIndex(context);
    if (index == currentIndex) return;

    switch (index) {
      case 0:
        context.go('/homepage', extra: user);
        break;

      case 1:
        // nếu đã có route thì bật dòng dưới, chưa có thì để snackBar
        // context.go('/garage', extra: user);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tab Garage sẽ được phát triển sau')),
        );
        break;

      case 2:
        // context.go('/find', extra: user);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tab Tìm sẽ được phát triển sau')),
        );
        break;

      case 3:
        context.go('/history', extra: user);
        break;

      case 4:
        context.go('/profile', extra: user);
        break;
    }
  }

  BottomNavigationBarItem _item(String path, String label) {
    return BottomNavigationBarItem(
      // ✅ icon thường (màu trắng)
      icon: _NavIcon(path, color: Colors.white),
      // ✅ icon active (màu xanh)
      activeIcon: _NavIcon(path, color: const Color(0xFF92D6E3)),
      label: label,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _getCurrentIndex(context);

    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (i) => _onNavTap(context, i),
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.black,
      selectedItemColor: const Color(0xFF92D6E3),
      unselectedItemColor: Colors.white,
      showUnselectedLabels: true,

      // ✅ KHÔNG dùng const ở đây nữa (vì icon cần đổi theo activeIcon)
      items: [
        _item('images/home.png', 'Trang chủ'),
        _item('images/gara.png', 'Garage'),
        _item('images/find.png', 'Tìm'),
        _item('images/history.png', 'Lịch sử'),
        _item('images/profile.png', 'Thông tin'),
      ],
    );
  }
}

class _NavIcon extends StatelessWidget {
  final String path;
  final Color color;

  const _NavIcon(this.path, {required this.color});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      path,
      height: 24,
      color: color, // ✅ đây là chỗ làm icon đổi màu
    );
  }
}
