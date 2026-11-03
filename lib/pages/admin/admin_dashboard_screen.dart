import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/order_status.dart';
import '../../services/admin_service.dart';
import '../../theme/app_icons.dart';
import '../../theme/app_theme.dart';
import '../../widgets/admin/admin_widgets.dart';
import 'admin_order_detail_sheet.dart';

class AdminDashboardScreen extends StatelessWidget {
  final List<AdminOrder>? orders;
  final Object? error;
  final VoidCallback onOpenOrders;

  const AdminDashboardScreen({
    super.key,
    required this.orders,
    required this.error,
    required this.onOpenOrders,
  });

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Buenos días';
    if (h < 19) return 'Buenas tardes';
    return 'Buenas noches';
  }

  @override
  Widget build(BuildContext context) {
    if (error != null) {
      return EmptyState(
        icon: AppIcons.delayed,
        title: 'No se pudieron cargar los pedidos',
        message: 'Revisa tu conexión y los permisos de Firestore.\n$error',
      );
    }
    if (orders == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final all = orders!;
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    bool isToday(AdminOrder o) =>
        o.createdAt == null || !o.createdAt!.isBefore(startOfDay);

    final today = all.where(isToday).toList();
    final todayValid = today
        .where((o) => o.status != OrderStatus.cancelled)
        .toList();
    final revenue = todayValid.fold<double>(0, (s, o) => s + o.total);
    final avgTicket = todayValid.isEmpty ? 0.0 : revenue / todayValid.length;
    final active = all.where((o) => o.status.isActive).toList()
      ..sort((a, b) => (a.createdAt ?? now).compareTo(b.createdAt ?? now));
    final delayed = active.where((o) => o.isDelayed).length;

    final dateLabel = toBeginningOfSentenceCase(
      DateFormat("EEEE d 'de' MMMM", 'es').format(now),
    );

    final kpis = [
      StatCard(
        label: 'Ventas de hoy',
        value: formatMoney(revenue),
        icon: AppIcons.revenue,
        color: AppColors.success,
      ),
      StatCard(
        label: 'Pedidos de hoy',
        value: '${today.length}',
        icon: AppIcons.orders,
        color: AppColors.primary,
      ),
      StatCard(
        label: 'En curso',
        value: '${active.length}',
        icon: AppIcons.pending,
        color: AppColors.info,
      ),
      StatCard(
        label: 'Retrasados',
        value: '$delayed',
        icon: AppIcons.delayed,
        color: delayed > 0 ? AppColors.danger : AppColors.textMuted,
        hint: delayed > 0 ? 'Atender' : null,
      ),
      StatCard(
        label: 'Ticket promedio',
        value: formatMoney(avgTicket),
        icon: AppIcons.ticket,
        color: AppColors.amber,
      ),
    ];

    return LayoutBuilder(
      builder: (context, c) {
        final wide = c.maxWidth >= 1000;
        final cols = c.maxWidth >= 1100
            ? 5
            : c.maxWidth >= 640
            ? 3
            : 2;
        const gap = 12.0;
        final cardW = (c.maxWidth - 40 - gap * (cols - 1)) / cols;

        final activePanel = _ActiveOrdersPanel(
          orders: active,
          onSeeAll: onOpenOrders,
        );
        final sidePanels = Column(
          children: [
            _WeekSalesPanel(orders: all),
            const SizedBox(height: gap),
            _TopProductsPanel(orders: all),
          ],
        );

        return ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            AdminPageHeader(
              title: _greeting(),
              subtitle: '$dateLabel · Así va el negocio hoy',
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final k in kpis) SizedBox(width: cardW, child: k),
                ],
              ),
            ),
            const SizedBox(height: gap),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: wide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: activePanel),
                        const SizedBox(width: gap),
                        Expanded(flex: 2, child: sidePanels),
                      ],
                    )
                  : Column(
                      children: [
                        activePanel,
                        const SizedBox(height: gap),
                        sidePanels,
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _ActiveOrdersPanel extends StatelessWidget {
  final List<AdminOrder> orders;
  final VoidCallback onSeeAll;

  const _ActiveOrdersPanel({required this.orders, required this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    final visible = orders.take(6).toList();
    return SectionCard(
      title: 'Pedidos en curso',
      trailing: TextButton(onPressed: onSeeAll, child: const Text('Ver todos')),
      child: visible.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: EmptyState(
                icon: AppIcons.chef,
                title: 'Cocina tranquila',
                message: 'No hay pedidos activos en este momento.',
              ),
            )
          : Column(
              children: [
                for (final o in visible) ...[
                  _OrderRow(order: o),
                  if (o != visible.last) const Divider(height: 1, indent: 16),
                ],
              ],
            ),
    );
  }
}

class _OrderRow extends StatelessWidget {
  final AdminOrder order;
  const _OrderRow({required this.order});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return InkWell(
      onTap: () => showAdminOrderDetail(context, order),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            IconTile(icon: order.status.icon, color: order.status.color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        order.shortId,
                        style: t.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (order.isDelayed)
                        const Tag('Retrasado', color: AppColors.danger),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${order.itemCount} art. · ${order.email}',
                    style: t.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatMoney(order.total),
                  style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(timeAgo(order.createdAt), style: t.bodySmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WeekSalesPanel extends StatelessWidget {
  final List<AdminOrder> orders;
  const _WeekSalesPanel({required this.orders});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final now = DateTime.now();
    final days = List.generate(
      7,
      (i) => DateTime(now.year, now.month, now.day - (6 - i)),
    );
    final totals = [
      for (final d in days)
        orders
            .where(
              (o) =>
                  o.status != OrderStatus.cancelled &&
                  o.createdAt != null &&
                  o.createdAt!.year == d.year &&
                  o.createdAt!.month == d.month &&
                  o.createdAt!.day == d.day,
            )
            .fold<double>(0, (s, o) => s + o.total),
    ];
    final max = totals.fold<double>(0, (a, b) => b > a ? b : a);
    final weekTotal = totals.fold<double>(0, (a, b) => a + b);

    return SectionCard(
      title: 'Ventas últimos 7 días',
      trailing: Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Text(
          formatMoney(weekTotal),
          style: t.bodyMedium?.copyWith(
            color: AppColors.success,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: SizedBox(
          height: 140,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < 7; i++)
                Expanded(
                  child: Tooltip(
                    message: formatMoney(totals[i]),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Flexible(
                          child: FractionallySizedBox(
                            heightFactor: max == 0
                                ? 0.04
                                : (totals[i] / max).clamp(0.04, 1.0),
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 5),
                              decoration: BoxDecoration(
                                gradient: i == 6
                                    ? AppColors.brandGradient
                                    : null,
                                color: i == 6
                                    ? null
                                    : AppColors.primary.withValues(alpha: 0.28),
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          DateFormat('E', 'es').format(days[i]).substring(0, 2),
                          style: t.labelSmall?.copyWith(
                            color: i == 6
                                ? AppColors.text
                                : AppColors.textMuted,
                          ),
                        ),
                      ],
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

class _TopProductsPanel extends StatelessWidget {
  final List<AdminOrder> orders;
  const _TopProductsPanel({required this.orders});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final since = DateTime.now().subtract(const Duration(days: 7));
    final counts = <String, int>{};
    for (final o in orders) {
      if (o.status == OrderStatus.cancelled) continue;
      if (o.createdAt != null && o.createdAt!.isBefore(since)) continue;
      for (final i in o.items) {
        final name = i['nombre']?.toString() ?? 'Producto';
        counts[name] =
            (counts[name] ?? 0) + ((i['cantidad'] as num?)?.toInt() ?? 0);
      }
    }
    final top = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final visible = top.take(5).toList();
    final max = visible.isEmpty ? 1 : visible.first.value;

    return SectionCard(
      title: 'Más vendidos · 7 días',
      trailing: Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Icon(AppIcons.trophy, size: 16, color: AppColors.amber),
      ),
      child: visible.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(20),
              child: Text('Aún no hay ventas esta semana.', style: t.bodySmall),
            )
          : Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                children: [
                  for (var i = 0; i < visible.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '${i + 1}',
                                style: t.bodySmall?.copyWith(
                                  color: i == 0
                                      ? AppColors.amber
                                      : AppColors.textFaint,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  visible[i].key,
                                  overflow: TextOverflow.ellipsis,
                                  style: t.bodyMedium,
                                ),
                              ),
                              Text(
                                '${visible[i].value} uds',
                                style: t.bodySmall,
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: visible[i].value / max,
                              minHeight: 6,
                              backgroundColor: AppColors.surfaceHigh,
                              color: i == 0
                                  ? AppColors.primary
                                  : AppColors.primary.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
