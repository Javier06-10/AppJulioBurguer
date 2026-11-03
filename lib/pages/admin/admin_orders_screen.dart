import 'package:flutter/material.dart';

import '../../models/order_status.dart';
import '../../services/admin_service.dart';
import '../../theme/app_icons.dart';
import '../../theme/app_theme.dart';
import '../../widgets/admin/admin_widgets.dart';
import 'admin_order_detail_sheet.dart';

/// Filtros de la lista de pedidos.
enum _Filter { active, all, pending, preparing, ready, delivered, cancelled }

extension on _Filter {
  String get label => switch (this) {
    _Filter.active => 'En curso',
    _Filter.all => 'Todos',
    _ => status!.label,
  };

  OrderStatus? get status => switch (this) {
    _Filter.pending => OrderStatus.pending,
    _Filter.preparing => OrderStatus.preparing,
    _Filter.ready => OrderStatus.ready,
    _Filter.delivered => OrderStatus.delivered,
    _Filter.cancelled => OrderStatus.cancelled,
    _ => null,
  };

  bool matches(AdminOrder o) => switch (this) {
    _Filter.active => o.status.isActive,
    _Filter.all => true,
    _ => o.status == status,
  };
}

class AdminOrdersScreen extends StatefulWidget {
  final List<AdminOrder>? orders;
  final Object? error;

  const AdminOrdersScreen({super.key, required this.orders, this.error});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  _Filter _filter = _Filter.active;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    if (widget.error != null) {
      return EmptyState(
        icon: AppIcons.delayed,
        title: 'Error al cargar pedidos',
        message: '${widget.error}',
      );
    }
    final all = widget.orders;
    if (all == null) return const Center(child: CircularProgressIndicator());

    final q = _query.trim().toLowerCase();
    final filtered = all
        .where(_filter.matches)
        .where(
          (o) =>
              q.isEmpty ||
              o.shortId.toLowerCase().contains(q) ||
              o.email.toLowerCase().contains(q),
        )
        .toList();

    return LayoutBuilder(
      builder: (context, c) {
        final board = c.maxWidth >= 1000 && _filter == _Filter.active;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AdminPageHeader(
              title: 'Pedidos',
              subtitle: board
                  ? 'Tablero de cocina en tiempo real'
                  : '${filtered.length} pedidos · actualizado en vivo',
              action: c.maxWidth >= 640
                  ? SizedBox(
                      width: 260,
                      child: AdminSearchField(
                        hint: 'Buscar por # o email',
                        onChanged: (v) => setState(() => _query = v),
                      ),
                    )
                  : null,
            ),
            if (c.maxWidth < 640)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: AdminSearchField(
                  hint: 'Buscar por # o email',
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  for (final f in _Filter.values)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(
                          '${f.label}  ${all.where(f.matches).length}',
                        ),
                        selected: _filter == f,
                        onSelected: (_) => setState(() => _filter = f),
                        labelStyle: TextStyle(
                          color: _filter == f
                              ? AppColors.primary
                              : AppColors.textMuted,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: board
                  ? _KitchenBoard(orders: filtered)
                  : filtered.isEmpty
                  ? EmptyState(
                      icon: AppIcons.orders,
                      title: 'Sin pedidos',
                      message: 'No hay pedidos para este filtro.',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => _OrderCard(order: filtered[i]),
                    ),
            ),
          ],
        );
      },
    );
  }
}

/// Tres columnas (pendiente / preparando / listo) para pantallas anchas.
class _KitchenBoard extends StatelessWidget {
  final List<AdminOrder> orders;
  const _KitchenBoard({required this.orders});

  @override
  Widget build(BuildContext context) {
    const columns = [
      OrderStatus.pending,
      OrderStatus.preparing,
      OrderStatus.ready,
    ];
    final t = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final s in columns) ...[
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: s.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(s.label, style: t.titleMedium),
                          const Spacer(),
                          Text(
                            '${orders.where((o) => o.status == s).length}',
                            style: t.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Builder(
                        builder: (context) {
                          final list =
                              orders.where((o) => o.status == s).toList()..sort(
                                (a, b) => (a.createdAt ?? DateTime.now())
                                    .compareTo(b.createdAt ?? DateTime.now()),
                              );
                          if (list.isEmpty) {
                            return Center(
                              child: Text('Sin pedidos', style: t.bodySmall),
                            );
                          }
                          return ListView.separated(
                            padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                            itemCount: list.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 8),
                            itemBuilder: (_, i) =>
                                _OrderCard(order: list[i], dense: true),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (s != columns.last) const SizedBox(width: 12),
          ],
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final AdminOrder order;
  final bool dense;

  const _OrderCard({required this.order, this.dense = false});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final next = order.status.next;
    final summary = order.items
        .map((i) => '${i['cantidad'] ?? 0}× ${i['nombre'] ?? ''}')
        .join(', ');

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: order.isDelayed
              ? AppColors.danger.withValues(alpha: 0.6)
              : AppColors.border,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => showAdminOrderDetail(context, order),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    order.shortId,
                    style: t.titleMedium?.copyWith(letterSpacing: 0.5),
                  ),
                  const SizedBox(width: 8),
                  Text(timeAgo(order.createdAt), style: t.bodySmall),
                  if (order.isDelayed) ...[
                    const SizedBox(width: 8),
                    const Tag('Retrasado', color: AppColors.danger),
                  ],
                  const Spacer(),
                  if (!dense) StatusBadge(status: order.status, compact: true),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                summary.isEmpty ? 'Sin productos' : summary,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: t.bodyMedium?.copyWith(color: AppColors.textMuted),
              ),
              if (order.description.isNotEmpty) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(AppIcons.note, size: 12, color: AppColors.amber),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        order.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: t.bodySmall?.copyWith(color: AppColors.amber),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    formatMoney(order.total),
                    style: t.titleMedium?.copyWith(color: AppColors.text),
                  ),
                  const Spacer(),
                  if (next != null)
                    FilledButton.tonalIcon(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 34),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        backgroundColor: next.color.withValues(alpha: 0.16),
                        foregroundColor: next.color,
                        textStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      icon: Icon(next.icon, size: 13),
                      label: Text(order.status.nextActionLabel!),
                      onPressed: () => changeOrderStatus(context, order, next),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
