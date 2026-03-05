import 'package:flutter/material.dart';
import 'screens/input_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/history_screen.dart';
import 'screens/graph_screen.dart';
import 'screens/fixed_expense_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const InputScreen(),
    const DashboardScreen(),
    const HistoryScreen(),
    const GraphScreen(),
    const FixedExpenseScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: const Color(0xFF0F172A),
          selectedItemColor: const Color(0xFF6366F1),
          unselectedItemColor: Colors.white.withOpacity(0.5),
          showSelectedLabels: true,
          showUnselectedLabels: true,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline), label: '入力'),
            BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), label: 'ホーム'),
            BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: '履歴'),
            BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: '分析'),
            BottomNavigationBarItem(icon: Icon(Icons.settings), label: '固定費'),
          ],
        ),
      ),
    );
  }
}
