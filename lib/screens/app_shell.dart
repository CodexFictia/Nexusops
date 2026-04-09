import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/models.dart';
import '../core/providers.dart';

// ─── Responsive App Shell ─────────────────────────────────────────────────────
// Provides sidebar on desktop, bottom nav on mobile.

class AppShell extends StatefulWidget {
  final List<ShellItem> items;
  final AppUser user;

  const AppShell({super.key, required this.items, required this.user});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 900;

    if (isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            _Sidebar(
              items: widget.items,
              user: widget.user,
              selectedIndex: _selectedIndex,
              onSelect: (i) => setState(() => _selectedIndex = i),
            ),
            Expanded(child: widget.items[_selectedIndex].page),
          ],
        ),
      );
    }

    return Scaffold(
      body: widget.items[_selectedIndex].page,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        backgroundColor: AppColors.card,
        elevation: 8,
        destinations: widget.items
            .map((item) => NavigationDestination(
                  icon: Icon(item.icon),
                  selectedIcon: Icon(item.activeIcon ?? item.icon),
                  label: item.label,
                ))
            .toList(),
      ),
    );
  }
}

// ─── Shell Item ───────────────────────────────────────────────────────────────

class ShellItem {
  final String label;
  final IconData icon;
  final IconData? activeIcon;
  final Widget page;
  final int? badgeCount;

  const ShellItem({
    required this.label,
    required this.icon,
    this.activeIcon,
    required this.page,
    this.badgeCount,
  });
}

// ─── Sidebar ──────────────────────────────────────────────────────────────────

class _Sidebar extends StatelessWidget {
  final List<ShellItem> items;
  final AppUser user;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const _Sidebar({
    required this.items,
    required this.user,
    required this.selectedIndex,
    required this.onSelect,
  });

  Color get _roleColor {
    switch (user.role) {
      case UserRole.executive:
        return AppColors.info;
      case UserRole.accountManager:
        return AppColors.warning;
      case UserRole.centreHead:
        return AppColors.success;
    }
  }

  String get _roleLabel {
    switch (user.role) {
      case UserRole.executive:
        return 'Executive';
      case UserRole.accountManager:
        return 'Account Manager';
      case UserRole.centreHead:
        return 'Centre Head';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      color: AppColors.sidebar,
      child: Column(
        children: [
          // Logo
          Container(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.bolt,
                      color: Colors.black, size: 16),
                ),
                const SizedBox(width: 10),
                const Text(
                  'NEXUS OPS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
          // Building info
          Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 16),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on,
                    color: AppColors.sidebarText, size: 14),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    'DLF Commercial, Tower A\nGurugram, Delhi NCR',
                    style: TextStyle(
                      color: AppColors.sidebarText,
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 8),
          // Nav items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: items.length,
              itemBuilder: (ctx, i) {
                final item = items[i];
                final isSelected = i == selectedIndex;
                return GestureDetector(
                  onTap: () => onSelect(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(bottom: 2),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white.withOpacity(0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSelected
                              ? (item.activeIcon ?? item.icon)
                              : item.icon,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.sidebarText,
                          size: 18,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            item.label,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.sidebarText,
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                        if (item.badgeCount != null && item.badgeCount! > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.error,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${item.badgeCount}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(color: Colors.white12, height: 1),
          // User info
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: _roleColor.withOpacity(0.2),
                  child: Text(
                    user.initials,
                    style: TextStyle(
                      color: _roleColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 2),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: _roleColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _roleLabel,
                          style: TextStyle(
                            color: _roleColor,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.logout,
                      color: AppColors.sidebarText, size: 16),
                  onPressed: () => context.read<AuthProvider>().logout(),
                  tooltip: 'Sign Out',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Page Wrapper ─────────────────────────────────────────────────────────────

class PageWrapper extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final Widget child;
  final bool scrollable;

  const PageWrapper({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    required this.child,
    this.scrollable = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Container(
          color: AppColors.card,
          padding: const EdgeInsets.fromLTRB(28, 20, 28, 16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              if (actions != null) ...actions!,
            ],
          ),
        ),
        const Divider(height: 1),
        // Content
        Expanded(
          child: scrollable
              ? SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: child,
                )
              : child,
        ),
      ],
    );
  }
}
