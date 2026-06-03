import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/auth_service.dart';
import '../../core/providers/locale_provider.dart';
import '../home/dashboard_screen.dart';
import '../activities/timeline_screen.dart';
import '../ai_coach/ai_coach_screen.dart';
import '../recommendations/recommendations_screen.dart';
import '../profile/profile_screen.dart';
import '../admin/admin_dashboard.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final auth   = context.watch<AuthService>();
    final loc    = context.watch<LocaleProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAdmin = auth.isAdmin;

    final pages = isAdmin
        ? <Widget>[
            const AdminDashboard(),
          ]
        : <Widget>[
            const DashboardScreen(),
            const TimelineScreen(),
            const AiCoachScreen(),
            const RecommendationsScreen(),
            const ProfileScreen(),
          ];

    final navItems = <BottomNavigationBarItem>[
      BottomNavigationBarItem(
          icon: const Icon(Icons.home_rounded),
          label: loc.tr('Trang chủ', 'Home')),
      BottomNavigationBarItem(
          icon: const Icon(Icons.timeline_rounded),
          label: loc.tr('Lịch trình', 'Schedule')),
      BottomNavigationBarItem(
          icon: const Icon(Icons.auto_awesome_rounded),
          label: loc.tr('AI Coach', 'AI Coach')),
      BottomNavigationBarItem(
          icon: const Icon(Icons.explore_rounded),
          label: loc.tr('Khám phá', 'Explore')),
      BottomNavigationBarItem(
          icon: const Icon(Icons.person_rounded),
          label: loc.tr('Cá nhân', 'Profile')),
    ];

    final barBg   = isDark ? const Color(0xFF111827) : Colors.white;
    final barBorder = isDark ? const Color(0xFF2A3650) : const Color(0xFFD1D9F0);

    return Scaffold(
      body: IndexedStack(index: isAdmin ? 0 : _currentIndex, children: pages),
      bottomNavigationBar: isAdmin ? null : Container(
        decoration: BoxDecoration(
          color: barBg,
          border: Border(top: BorderSide(color: barBorder, width: 0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
              blurRadius: 20, offset: const Offset(0, -4)),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: const Color(0xFF6C63FF),
          unselectedItemColor: isDark ? const Color(0xFF4A5568) : const Color(0xFF8892B0),
          selectedFontSize: 11,
          unselectedFontSize: 11,
          items: navItems,
        ),
      ),
    );
  }
}
