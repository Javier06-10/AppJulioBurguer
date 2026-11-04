import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product_model.dart';
import '../providers/cart_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/product_image.dart';

String _money(double v) => 'RD\$ ${v.toStringAsFixed(v % 1 == 0 ? 0 : 2)}';

/// Detalle de un producto: portada, datos y selector de cantidad.
class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _qty = 1;

  Product get p => widget.product;

  void _addToCart(int qty) {
    final cart = context.read<CartProvider>();
    final messenger = ScaffoldMessenger.of(context);
    for (var i = 0; i < qty; i++) {
      cart.addItem(p.id, p.nombre, p.precio, p.tiempoPreparacion);
    }
    Navigator.pop(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            qty == 1
                ? '${p.nombre} agregado al carrito'
                : '$qty × ${p.nombre} agregados al carrito',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final inCart = context.select<CartProvider, int>(
      (c) => c.items[p.id]?.cantidad ?? 0,
    );
    final available = (p.stock - inCart).clamp(0, 999);
    final soldOut = p.stock <= 0;
    final noMore = !soldOut && available == 0;
    final qty = available == 0 ? 1 : _qty.clamp(1, available);
    final lowStock = !soldOut && p.stock <= 5;
    final heroHeight = (MediaQuery.sizeOf(context).height * 0.38).clamp(240, 380).toDouble();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: heroHeight,
            pinned: true,
            stretch: true,
            backgroundColor: AppColors.background,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: IconButton.filled(
                tooltip: 'Volver',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black.withValues(alpha: 0.45),
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              background: Stack(
                fit: StackFit.expand,
                children: [
                  ProductImage(
                    url: p.imagen,
                    nombre: p.nombre,
                    size: heroHeight,
                    width: double.infinity,
                    radius: 0,
                  ),
                  // Degradado para que el contenido se lea sobre la foto
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: [0, 0.25, 0.75, 1],
                        colors: [
                          Color(0x66000000),
                          Colors.transparent,
                          Colors.transparent,
                          AppColors.background,
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            sliver: SliverList.list(
              children: [
                Text(p.nombre, style: t.headlineMedium),
                const SizedBox(height: 6),
                Text(
                  _money(p.precio),
                  style: t.headlineSmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _InfoPill(
                      icon: Icons.schedule_rounded,
                      text: '${p.tiempoPreparacion} min de preparación',
                    ),
                    if (soldOut)
                      const _InfoPill(
                        icon: Icons.block_rounded,
                        text: 'Agotado',
                        color: AppColors.danger,
                      )
                    else if (lowStock)
                      _InfoPill(
                        icon: Icons.local_fire_department_rounded,
                        text: p.stock == 1 ? '¡Queda 1!' : '¡Quedan ${p.stock}!',
                        color: AppColors.warning,
                      )
                    else
                      const _InfoPill(
                        icon: Icons.check_circle_outline_rounded,
                        text: 'Disponible',
                        color: AppColors.success,
                      ),
                  ],
                ),
                if (p.descripcion.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text(
                    'DESCRIPCIÓN',
                    style: t.labelSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    p.descripcion,
                    style: t.bodyLarge?.copyWith(
                      color: AppColors.textMuted,
                      height: 1.5,
                    ),
                  ),
                ],
                if (inCart > 0) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.shopping_cart_outlined,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Ya tienes $inCart en el carrito',
                          style: t.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _BottomBar(
        qty: qty,
        max: available,
        price: p.precio,
        soldOut: soldOut,
        noMore: noMore,
        onChanged: (v) => setState(() => _qty = v),
        onAdd: () => _addToCart(qty),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final int qty;
  final int max;
  final double price;
  final bool soldOut;
  final bool noMore;
  final ValueChanged<int> onChanged;
  final VoidCallback onAdd;

  const _BottomBar({
    required this.qty,
    required this.max,
    required this.price,
    required this.soldOut,
    required this.noMore,
    required this.onChanged,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = soldOut || noMore;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              if (!disabled) ...[
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceHigh,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: 'Quitar uno',
                        onPressed: qty > 1 ? () => onChanged(qty - 1) : null,
                        icon: const Icon(Icons.remove_rounded),
                      ),
                      SizedBox(
                        width: 28,
                        child: Text(
                          '$qty',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Agregar uno',
                        onPressed: qty < max ? () => onChanged(qty + 1) : null,
                        icon: const Icon(Icons.add_rounded),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: FilledButton(
                  onPressed: disabled ? null : onAdd,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 52),
                    disabledBackgroundColor: AppColors.surfaceHigh,
                    disabledForegroundColor: AppColors.textMuted,
                  ),
                  child: FittedBox(
                    child: Text(
                      soldOut
                          ? 'Agotado por ahora'
                          : noMore
                              ? 'Ya tienes todo el disponible'
                              : 'Agregar · ${_money(price * qty)}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _InfoPill({
    required this.icon,
    required this.text,
    this.color = AppColors.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color == AppColors.textMuted ? AppColors.text : color,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
