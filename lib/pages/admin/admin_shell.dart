import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/admin_service.dart';
import '../../theme/app_icons.dart';
import '../../theme/app_theme.dart';
import 'admin_categories_screen.dart';
import 'admin_dashboard_screen.dart';
import 'admin_orders_screen.dart';
import 'admin_products_screen.dart';
import 'admin_users_screen.dart';

class _NavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  const _NavItem(this.label, this.icon, this.activeIcon);
}

/// Contenedor del panel admin: sidebar en pantallas anchas, barra inferior en móvil.
class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  final _service = AdminService();
  StreamSubscription<List<AdminOrder>>? _sub;
  List<AdminOrder>? _orders;
  Object? _ordersError;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _sub = _service.watchOrders().listen(
      (orders) => setState(() {
        _orders = orders;
        _ordersError = null;
      }),
      onError: (Object e) => setState(() => _ordersError = e),
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  List<_NavItem> get _items => [
    _NavItem('Inicio', AppIcons.dashboard, AppIcons.dashboardActive),
    _NavItem('Pedidos', AppIcons.orders, AppIcons.ordersActive),
    _NavItem('Menú', AppIcons.products, AppIcons.productsActive),
    _NavItem('Categorías', AppIcons.categories, AppIcons.categoriesActive),
    _NavItem('Usuarios', AppIcons.users, AppIcons.usersActive),
  ];

  void _go(int i) => setState(() => _index = i);

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
  }

  Widget _page() => switch (_index) {
    0 => AdminDashboardScreen(
      orders: _orders,
      error: _ordersError,
      onOpenOrders: () => _go(1),
    ),
    1 => AdminOrdersScreen(orders: _orders, error: _ordersError),
    2 => const AdminProductsScreen(),
    3 => const AdminCategoriesScreen(),
    _ => const AdminUsersScreen(),
  };

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;

    final activeCount = (_orders ?? const [])
        .where((o) => o.status.isActive)
        .length;
    final body = AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: KeyedSubtree(key: ValueKey(_index), child: _page()),
    );

    if (wide) {
      return Scaffold(
        body: Row(
          children: [
            _Sidebar(
              items: _items,
              index: _index,
              badge: activeCount,
              onSelect: _go,
              onLogout: _logout,
            ),
            const VerticalDivider(width: 1),
            Expanded(child: SafeArea(child: body)),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: const _BrandMark(compact: true),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: Icon(AppIcons.logout, size: 18),
            onPressed: _logout,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _go,
        destinations: [
          for (var i = 0; i < _items.length; i++)
            NavigationDestination(
              icon: _withBadge(Icon(_items[i].icon), i == 1 ? activeCount : 0),
              selectedIcon: _withBadge(
                Icon(_items[i].activeIcon),
                i == 1 ? activeCount : 0,
              ),
              label: _items[i].label,
            ),
        ],
      ),
    );
  }

  Widget _withBadge(Widget icon, int count) => count == 0
      ? icon
      : Badge(
          label: Text('$count'),
          backgroundColor: AppColors.ember,
          child: icon,
        );
}

class _BrandMark extends StatelessWidget {
  final bool compact;
  const _BrandMark({this.compact = false});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: compact ? 34 : 40,
          height: compact ? 34 : 40,
          decoration: BoxDecoration(
            gradient: AppColors.brandGradient,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(AppIcons.brand, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("D'Julio", style: t.titleLarge?.copyWith(height: 1.1)),
            Text(
              'Panel de gestión',
              style: t.labelSmall?.copyWith(color: AppColors.primary),
            ),
          ],
        ),
      ],
    );
  }
}

class _Sidebar extends StatelessWidget {
  final List<_NavItem> items;
  final int index;
  final int badge;
  final ValueChanged<int> onSelect;
  final VoidCallback onLogout;

  const _Sidebar({
    required this.items,
    required this.index,
    required this.badge,
    required this.onSelect,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final email = FirebaseAuth.instance.currentUser?.email ?? '';
    final t = Theme.of(context).textTheme;

    return Container(
      width: 248,
      color: AppColors.surface,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _BrandMark(),
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.only(left: 12, bottom: 8),
                child: Text('GESTIÓN', style: t.labelSmall),
              ),
              for (var i = 0; i < items.length; i++)
                _SidebarTile(
                  item: items[i],
                  selected: i == index,
                  badge: i == 1 ? badge : 0,
                  onTap: () => onSelect(i),
                ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceHigh,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                      child: Text(
                        email.isEmpty ? 'A' : email[0].toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.primary,
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
                            'Administrador',
                            style: t.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            email,
                            style: t.bodySmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Cerrar sesión',
                      icon: Icon(AppIcons.logout, size: 16),
                      color: AppColors.textMuted,
                      onPressed: onLogout,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarTile extends StatelessWidget {
  final _NavItem item;
  final bool selected;
  final int badge;
  final VoidCallback onTap;

  const _SidebarTile({
    required this.item,
    required this.selected,
    required this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.textMuted;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: selected
            ? AppColors.primary.withValues(alpha: 0.12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Icon(
                  selected ? item.activeIcon : item.icon,
                  size: 18,
                  color: color,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.label,
                    style: TextStyle(
                      color: selected ? AppColors.text : AppColors.textMuted,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
                if (badge > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.ember,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '$badge',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
