import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../calendar/calendar_screen.dart';
import '../budget/budget_screen.dart';
import '../diary/diary_screen.dart';
import '../settings/settings_screen.dart';
import '../timetable/timetable_screen.dart';
import '../todo/todo_screen.dart';

/// Root bottom-navigation shell. The weekly timetable is the first tab
/// and the screen shown on launch, per the product spec.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  static final _screens = <Widget>[
    const TimetableScreen(),
    const TodoScreen(),
    const CalendarScreen(),
    const BudgetScreen(),
    DiaryScreen(initialDate: DateTime.now()),
    const SettingsScreen(),
  ];

  static const _items = [
    _NavItem(
        icon: Icons.calendar_view_week_outlined,
        activeIcon: Icons.calendar_view_week,
        label: '시간표'),
    _NavItem(
        icon: Icons.check_circle_outline,
        activeIcon: Icons.check_circle,
        label: '할 일'),
    _NavItem(
        icon: Icons.calendar_month_outlined,
        activeIcon: Icons.calendar_month,
        label: '캘린더'),
    _NavItem(
        icon: Icons.account_balance_wallet_outlined,
        activeIcon: Icons.account_balance_wallet,
        label: '가계부'),
    _NavItem(
        icon: Icons.menu_book_outlined,
        activeIcon: Icons.menu_book,
        label: '일기'),
    _NavItem(
        icon: Icons.settings_outlined, activeIcon: Icons.settings, label: '설정'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          border: Border(top: BorderSide(color: AppColors.divider)),
        ),
        child: SafeArea(
          child: BottomNavigationBar(
            currentIndex: _index,
            onTap: (i) => setState(() => _index = i),
            items: [
              for (final item in _items)
                BottomNavigationBarItem(
                  icon: Icon(item.icon),
                  activeIcon: Icon(item.activeIcon),
                  label: item.label,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem(
      {required this.icon, required this.activeIcon, required this.label});
}
