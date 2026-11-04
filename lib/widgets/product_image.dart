import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Icono de respaldo según el tipo de comida (mismo criterio que el panel).
IconData foodIcon(String nombre) {
  final n = nombre.toLowerCase();
  if (n.contains('pizza')) return Icons.local_pizza_outlined;
  if (n.contains('papa') || n.contains('frita')) return Icons.fastfood_outlined;
  if (n.contains('refresco') ||
      n.contains('jugo') ||
      n.contains('bebida') ||
      n.contains('agua') ||
      n.contains('mabi') ||
      n.contains('batida')) {
    return Icons.local_drink_outlined;
  }
  if (n.contains('helado') || n.contains('postre')) {
    return Icons.icecream_outlined;
  }
  if (n.contains('combo')) return Icons.lunch_dining;
  return Icons.lunch_dining_outlined;
}

/// Foto del producto con un icono de marca mientras carga o si no hay foto.
class ProductImage extends StatelessWidget {
  final String url;
  final String nombre;
  final double size;
  final double radius;

  const ProductImage({
    super.key,
    required this.url,
    required this.nombre,
    this.size = 84,
    this.radius = 14,
  });

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.22),
            AppColors.ember.withValues(alpha: 0.10),
          ],
        ),
      ),
      child: Icon(foodIcon(nombre), color: AppColors.primary, size: size * 0.45),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: url.startsWith('https://')
          ? Image.network(
              url,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => placeholder,
              loadingBuilder: (_, child, progress) =>
                  progress == null ? child : placeholder,
            )
          : placeholder,
    );
  }
}
