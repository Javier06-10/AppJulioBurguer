import 'package:flutter/material.dart';

import '../services/store_status.dart';
import '../theme/app_theme.dart';

/// Aviso "Estamos cerrados" con el mensaje del negocio. No ocupa espacio
/// cuando está abierto.
class StoreClosedBanner extends StatelessWidget {
  /// Para pruebas: permite inyectar el estado.
  final Stream<StoreStatus>? stream;

  const StoreClosedBanner({super.key, this.stream});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<StoreStatus>(
      stream: stream ?? storeStatusStream(),
      builder: (context, snap) {
        final s = snap.data ?? StoreStatus.open;
        if (s.abierto) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
          child: StoreClosedCard(status: s),
        );
      },
    );
  }
}

class StoreClosedCard extends StatelessWidget {
  final StoreStatus status;
  const StoreClosedCard({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.storefront_rounded,
              color: AppColors.danger,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Estamos cerrados',
                  style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  status.mensaje.isNotEmpty
                      ? status.mensaje
                      : 'Puedes ver el menú. Los pedidos se activan cuando abramos.',
                  style: t.bodySmall?.copyWith(color: AppColors.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
