import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../pages/cart_screen.dart';
import '../pages/orders_screen.dart';
import '../pages/profile_screen.dart';
import '../providers/cart_provider.dart';
import '../theme/app_theme.dart';

/// Navegación inferior de la tienda: Pedidos · Carrito (flotante, centro) · Perfil.
///
/// Uso en un Scaffold:
/// ```dart
/// extendBody: true,
/// floatingActionButton: const CartFab(),
/// floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
/// bottomNavigationBar: const AppBottomBar(),
/// ```
class AppBottomBar extends StatelessWidget {
  const AppBottomBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: _NavItem(
              icon: Icons.receipt_long_outlined,
              label: 'Pedidos',
              onTap: () => _open(context, const OrdersScreen()),
            ),
          ),
          // Espacio para el botón del carrito
          const SizedBox(width: 72),
          Expanded(
            child: _NavItem(
              icon: Icons.person_outline,
              label: 'Perfil',
              onTap: () => _open(context, const ProfileScreen()),
            ),
          ),
        ],
      ),
    );
  }
}

void _open(BuildContext context, Widget page) =>
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.textMuted, size: 24),
            const SizedBox(height: 3),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Botón flotante del carrito con el contador de productos.
class CartFab extends StatelessWidget {
  const CartFab({super.key});

  @override
  Widget build(BuildContext context) {
    final count = context.watch<CartProvider>().totalItems;

    return Semantics(
      button: true,
      label: 'Carrito, $count productos',
      child: GestureDetector(
        onTap: () => _open(context, const CartScreen()),
        child: Container(
          width: 66,
          height: 66,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppColors.brandGradient,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.45),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Badge(
            isLabelVisible: count > 0,
            label: Text('$count'),
            backgroundColor: Colors.white,
            textColor: AppColors.ember,
            offset: const Offset(8, -8),
            child: const Icon(
              Icons.shopping_cart_outlined,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }
}
