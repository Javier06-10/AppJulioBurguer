import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/cart_provider.dart';
import '../services/location_service.dart';
import '../theme/app_theme.dart';
import '../widgets/location_card.dart';
import 'edit_profile_screen.dart';
import 'orders_screen.dart';

const _activeStatuses = {
  'pending',
  'pendiente',
  'paid',
  'preparing',
  'ready',
  'shipped',
};

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Mi perfil')),
      body: user == null
          ? const Center(child: Text('Inicia sesión para ver tu perfil'))
          : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text('No pudimos cargar tu perfil'),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                return ProfileView(
                  uid: user.uid,
                  authEmail: user.email ?? '',
                  data: snapshot.data!.data() ?? const {},
                );
              },
            ),
    );
  }
}

/// Contenido del perfil a partir del documento `users/{uid}`.
class ProfileView extends StatelessWidget {
  final String uid;
  final String authEmail;
  final Map<String, dynamic> data;

  const ProfileView({
    super.key,
    required this.uid,
    required this.authEmail,
    required this.data,
  });

  String _str(String key) => (data[key] ?? '').toString().trim();

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final name = _str('name').isNotEmpty ? _str('name') : _str('nombre');
    final email = _str('email').isNotEmpty ? _str('email') : authEmail;
    final phone = _str('phone');
    final direccion = _str('direccion');
    final ubicacion = LocationService.fromMap(data['ubicacion']);
    final created = data['createdAt'] is Timestamp
        ? (data['createdAt'] as Timestamp).toDate()
        : null;

    final missing = <String>[
      if (phone.isEmpty) 'teléfono',
      if (direccion.isEmpty) 'dirección',
      if (ubicacion == null) 'ubicación en el mapa',
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        // ───── Encabezado ─────
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radius + 4),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary.withValues(alpha: 0.22),
                AppColors.surface,
              ],
            ),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              _Avatar(name: name.isEmpty ? email : name),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.isEmpty ? 'Cliente D\'Julio' : name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.titleLarge,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.bodySmall,
                    ),
                    if (created != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Cliente desde ${DateFormat.yMMMM('es').format(created)}',
                        style: t.labelSmall,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),
        _OrderStats(uid: uid),

        // ───── Aviso de perfil incompleto ─────
        if (missing.isNotEmpty) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppTheme.radius),
              border: Border.all(
                color: AppColors.warning.withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: AppColors.warning),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Completa tu ${_join(missing)} para que tus pedidos lleguen más rápido.',
                    style: t.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        ],

        // ───── Datos de entrega ─────
        const _SectionTitle('Datos de entrega'),
        Card(
          child: Column(
            children: [
              _InfoTile(
                icon: Icons.phone_outlined,
                label: 'Teléfono',
                value: phone,
                empty: 'Agrega tu teléfono',
                onTap: () => _edit(context),
              ),
              const Divider(height: 1, indent: 56),
              _InfoTile(
                icon: Icons.home_outlined,
                label: 'Dirección',
                value: direccion,
                empty: 'Agrega tu dirección',
                onTap: () => _edit(context),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // El perfil se actualiza solo por el stream al guardar
        LocationCard(location: ubicacion),

        // ───── Cuenta ─────
        const _SectionTitle('Mi cuenta'),
        Card(
          child: Column(
            children: [
              _ActionTile(
                icon: Icons.receipt_long_outlined,
                label: 'Mis pedidos',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const OrdersScreen()),
                ),
              ),
              const Divider(height: 1, indent: 56),
              _ActionTile(
                icon: Icons.edit_outlined,
                label: 'Editar perfil',
                onTap: () => _edit(context),
              ),
              const Divider(height: 1, indent: 56),
              _ActionTile(
                icon: Icons.logout_rounded,
                label: 'Cerrar sesión',
                color: AppColors.danger,
                showChevron: false,
                onTap: () => _logout(context),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),
        Center(
          child: Text(
            "D'Julio Burger Pizza",
            style: t.labelSmall?.copyWith(color: AppColors.textFaint),
          ),
        ),
      ],
    );
  }

  static String _join(List<String> items) {
    if (items.length == 1) return items.first;
    return '${items.sublist(0, items.length - 1).join(', ')} y ${items.last}';
  }

  void _edit(BuildContext context) => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const EditProfileScreen()),
      );

  Future<void> _logout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Cerrar sesión?'),
        content: const Text(
          'Tendrás que volver a iniciar sesión para hacer pedidos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;

    context.read<CartProvider>().clear();
    final nav = Navigator.of(context);
    await FirebaseAuth.instance.signOut();
    nav.pushNamedAndRemoveUntil('/login', (route) => false);
  }
}

class _Avatar extends StatelessWidget {
  final String name;

  const _Avatar({required this.name});

  String get _initials {
    final parts = name
        .split(RegExp(r'[\s@._-]+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    final first = parts.first[0];
    final second = parts.length > 1 ? parts[1][0] : '';
    return (first + second).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.brandGradient,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        _initials,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

/// Resumen de pedidos del cliente: total, en curso y gastado.
class _OrderStats extends StatelessWidget {
  final String uid;

  const _OrderStats({required this.uid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('userId', isEqualTo: uid)
          .snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? const [];
        final active = docs
            .where((d) => _activeStatuses.contains(d.data()['status']))
            .length;
        final spent = docs
            .where((d) => const {'completed', 'completado', 'delivered'}
                .contains(d.data()['status']))
            .fold<double>(
              0,
              (s, d) => s + ((d.data()['total'] ?? 0) as num).toDouble(),
            );
        final loading = !snap.hasData && !snap.hasError;

        String v(String text) => loading ? '–' : text;

        return Row(
          children: [
            _Stat(label: 'Pedidos', value: v('${docs.length}')),
            const SizedBox(width: 10),
            _Stat(
              label: 'En curso',
              value: v('$active'),
              highlight: active > 0,
            ),
            const SizedBox(width: 10),
            _Stat(
              label: 'Consumido',
              value: v('RD\$ ${NumberFormat('#,##0', 'es').format(spent)}'),
            ),
          ],
        );
      },
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _Stat({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: highlight
              ? AppColors.primary.withValues(alpha: 0.12)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(AppTheme.radius),
          border: Border.all(
            color: highlight
                ? AppColors.primary.withValues(alpha: 0.5)
                : AppColors.border,
          ),
        ),
        child: Column(
          children: [
            FittedBox(
              child: Text(
                value,
                style: t.titleLarge?.copyWith(
                  color: highlight ? AppColors.primary : AppColors.text,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(label, style: t.labelSmall),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 24, 4, 10),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String empty;
  final VoidCallback onTap;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.empty,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final isEmpty = value.isEmpty;
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: AppColors.primary),
      title: Text(label, style: t.labelSmall),
      subtitle: Text(
        isEmpty ? empty : value,
        style: t.bodyMedium?.copyWith(
          color: isEmpty ? AppColors.warning : AppColors.text,
          fontWeight: isEmpty ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
      trailing: Icon(
        isEmpty ? Icons.add_circle_outline_rounded : Icons.chevron_right_rounded,
        color: isEmpty ? AppColors.warning : AppColors.textFaint,
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  final bool showChevron;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
    this.showChevron = true,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.text;
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: color ?? AppColors.textMuted),
      title: Text(
        label,
        style: TextStyle(color: c, fontWeight: FontWeight.w600),
      ),
      trailing: showChevron
          ? const Icon(Icons.chevron_right_rounded, color: AppColors.textFaint)
          : null,
    );
  }
}
