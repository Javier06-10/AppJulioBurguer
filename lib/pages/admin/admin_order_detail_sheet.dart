import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/order_status.dart';
import '../../services/admin_service.dart';
import '../../theme/app_icons.dart';
import '../../theme/app_theme.dart';
import '../../widgets/admin/admin_widgets.dart';

final _adminService = AdminService();

/// Avanza un pedido al estado indicado mostrando feedback.
Future<void> changeOrderStatus(
  BuildContext context,
  AdminOrder order,
  OrderStatus status,
) async {
  if (status == OrderStatus.cancelled) {
    final ok = await confirmAction(
      context,
      title: 'Cancelar pedido ${order.shortId}',
      message: 'El cliente verá el pedido como cancelado. ¿Continuar?',
      confirmLabel: 'Cancelar pedido',
      destructive: true,
    );
    if (!ok) return;
  }
  try {
    await _adminService.updateOrderStatus(order.id, status);
    if (context.mounted) {
      showAdminSnack(context, 'Pedido ${order.shortId} → ${status.label}');
    }
  } catch (e) {
    if (context.mounted) {
      showAdminSnack(context, 'No se pudo actualizar: $e', error: true);
    }
  }
}

Future<void> showAdminOrderDetail(BuildContext context, AdminOrder order) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    constraints: const BoxConstraints(maxWidth: 640),
    builder: (_) => _OrderDetailSheet(order: order),
  );
}

class _OrderDetailSheet extends StatelessWidget {
  final AdminOrder order;
  const _OrderDetailSheet({required this.order});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final status = order.status;
    final next = status.next;
    final progress = order.tiempoEstimado == 0
        ? 0.0
        : (order.elapsedMinutes / order.tiempoEstimado).clamp(0.0, 1.0);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      builder: (context, scroll) => ListView(
        controller: scroll,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Pedido ${order.shortId}', style: t.headlineSmall),
                    const SizedBox(height: 4),
                    Text(
                      order.createdAt == null
                          ? 'Recién creado'
                          : DateFormat(
                              "d MMM yyyy · HH:mm",
                              'es',
                            ).format(order.createdAt!),
                      style: t.bodySmall,
                    ),
                  ],
                ),
              ),
              StatusBadge(status: status),
            ],
          ),
          const SizedBox(height: 20),

          // Cliente y tiempos
          Card(
            color: AppColors.surfaceHigh,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  _InfoRow(icon: AppIcons.email, label: order.email),
                  const SizedBox(height: 10),
                  _InfoRow(
                    icon: AppIcons.clock,
                    label:
                        '${order.elapsedMinutes} min transcurridos · estimado ${order.tiempoEstimado} min',
                    color: order.isDelayed ? AppColors.danger : null,
                  ),
                  if (status.isActive) ...[
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 6,
                        backgroundColor: AppColors.border,
                        color: order.isDelayed
                            ? AppColors.danger
                            : AppColors.primary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          if (order.description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.amber.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.amber.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(AppIcons.note, size: 16, color: AppColors.amber),
                  const SizedBox(width: 10),
                  Expanded(child: Text(order.description, style: t.bodyMedium)),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),
          Text('PRODUCTOS', style: t.labelSmall),
          const SizedBox(height: 8),
          for (final item in order.items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceHigh,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${item['cantidad'] ?? 0}×',
                      style: t.bodySmall?.copyWith(
                        color: AppColors.text,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item['nombre']?.toString() ?? 'Producto',
                      style: t.bodyMedium,
                    ),
                  ),
                  Text(
                    formatMoney(
                      ((item['precio'] as num?) ?? 0) *
                          ((item['cantidad'] as num?) ?? 0),
                    ),
                    style: t.bodyMedium,
                  ),
                ],
              ),
            ),
          const Divider(height: 24),
          Row(
            children: [
              Text('Total', style: t.titleMedium),
              const Spacer(),
              Text(
                formatMoney(order.total),
                style: t.headlineSmall?.copyWith(color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 24),

          if (next != null)
            FilledButton.icon(
              icon: Icon(next.icon, size: 16),
              label: Text(status.nextActionLabel!),
              onPressed: () async {
                await changeOrderStatus(context, order, next);
                if (context.mounted) Navigator.pop(context);
              },
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: PopupMenuButton<OrderStatus>(
                  tooltip: 'Cambiar estado',
                  onSelected: (s) async {
                    await changeOrderStatus(context, order, s);
                    if (context.mounted) Navigator.pop(context);
                  },
                  itemBuilder: (_) => [
                    for (final s in OrderStatus.values)
                      if (s != status)
                        PopupMenuItem(
                          value: s,
                          child: Row(
                            children: [
                              Icon(s.icon, size: 14, color: s.color),
                              const SizedBox(width: 10),
                              Text(s.label),
                            ],
                          ),
                        ),
                  ],
                  child: IgnorePointer(
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: Icon(AppIcons.filter, size: 14),
                      label: const Text('Cambiar estado'),
                    ),
                  ),
                ),
              ),
              if (status.isActive) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      side: BorderSide(
                        color: AppColors.danger.withValues(alpha: 0.4),
                      ),
                    ),
                    icon: Icon(AppIcons.statusCancelled, size: 14),
                    label: const Text('Cancelar'),
                    onPressed: () async {
                      await changeOrderStatus(
                        context,
                        order,
                        OrderStatus.cancelled,
                      );
                      if (context.mounted) Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _InfoRow({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color ?? AppColors.textMuted),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}
