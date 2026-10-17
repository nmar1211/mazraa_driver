import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mazraa_driver/core/theme/app_theme.dart';
import 'package:mazraa_driver/shared/widgets/mazraa_widgets.dart';

class AppShell extends StatelessWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  static const _visibleBranches = <int>[0, 1, 2, 4];

  @override
  Widget build(BuildContext context) {
    final ar = isArabic(context);
    final visibleIndex = _visibleBranches.indexOf(navigationShell.currentIndex);
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.fromLTRB(18, 4, 18, 12),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: const [
              BoxShadow(
                color: Color(0x13000000),
                blurRadius: 24,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: _ReferenceDestination(
                  selected: visibleIndex == 0,
                  icon: Icons.home_rounded,
                  outlineIcon: Icons.home_outlined,
                  label: ar ? 'الرئيسية' : 'Home',
                  onTap: () => _go(0),
                ),
              ),
              Expanded(
                child: _ReferenceDestination(
                  selected: visibleIndex == 1,
                  icon: Icons.assignment_rounded,
                  outlineIcon: Icons.assignment_outlined,
                  label: ar ? 'الطلبات' : 'Orders',
                  onTap: () => _go(1),
                ),
              ),
              Expanded(
                child: _ReferenceDestination(
                  selected: visibleIndex == 2,
                  icon: Icons.bar_chart_rounded,
                  outlineIcon: Icons.bar_chart_outlined,
                  label: ar ? 'الأرباح' : 'Earnings',
                  onTap: () => _go(2),
                ),
              ),
              Expanded(
                child: _ReferenceDestination(
                  selected: visibleIndex == 3,
                  icon: Icons.person_rounded,
                  outlineIcon: Icons.person_outline_rounded,
                  label: ar ? 'حسابي' : 'Profile',
                  onTap: () => _go(4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _go(int branch) {
    navigationShell.goBranch(
      branch,
      initialLocation: branch == navigationShell.currentIndex,
    );
  }
}

class _ReferenceDestination extends StatelessWidget {
  const _ReferenceDestination({
    required this.selected,
    required this.icon,
    required this.outlineIcon,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final IconData outlineIcon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? const Color(0xFF075A35) : const Color(0xFF718078);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(selected ? icon : outlineIcon, color: color, size: 27),
            const SizedBox(height: 5),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: selected ? 24 : 0,
              height: 3,
              decoration: BoxDecoration(
                color: MazraaColors.forest,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
