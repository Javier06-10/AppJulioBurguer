import 'package:flutter/material.dart';

import '../theme/app_icons.dart';
import '../theme/app_theme.dart';

/// Estados de pedido. `value` es lo que se guarda en Firestore (`orders.status`).
enum OrderStatus {
  pending('pending', 'Pendiente', AppColors.warning),
  preparing('preparing', 'Preparando', AppColors.info),
  ready('ready', 'Listo', AppColors.violet),
  delivered('delivered', 'Entregado', AppColors.success),
  cancelled('cancelled', 'Cancelado', AppColors.danger);

  const OrderStatus(this.value, this.label, this.color);

  final String value;
  final String label;
  final Color color;

  static OrderStatus fromValue(String? value) => OrderStatus.values.firstWhere(
    (s) => s.value == value,
    orElse: () => OrderStatus.pending,
  );

  IconData get icon => switch (this) {
    pending => AppIcons.statusPending,
    preparing => AppIcons.statusPreparing,
    ready => AppIcons.statusReady,
    delivered => AppIcons.statusDelivered,
    cancelled => AppIcons.statusCancelled,
  };

  /// Siguiente paso del flujo de cocina, o null si el pedido está cerrado.
  OrderStatus? get next => switch (this) {
    pending => preparing,
    preparing => ready,
    ready => delivered,
    delivered || cancelled => null,
  };

  String? get nextActionLabel => switch (this) {
    pending => 'Empezar a preparar',
    preparing => 'Marcar listo',
    ready => 'Entregar',
    delivered || cancelled => null,
  };

  bool get isActive => this == pending || this == preparing || this == ready;
}
