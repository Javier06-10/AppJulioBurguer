import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/admin_service.dart';
import '../../theme/app_icons.dart';
import '../../theme/app_theme.dart';
import '../../widgets/admin/admin_widgets.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final _service = AdminService();
  late final _users = _service.watchUsers();
  String _query = '';

  Future<void> _toggleRole(AdminUser u) async {
    final makeAdmin = !u.isAdmin;
    final ok = await confirmAction(
      context,
      title: makeAdmin ? 'Dar acceso admin' : 'Quitar acceso admin',
      message: makeAdmin
          ? '${u.nombre} podrá gestionar pedidos, menú y usuarios.'
          : '${u.nombre} volverá a ser cliente.',
      confirmLabel: makeAdmin ? 'Hacer admin' : 'Quitar acceso',
      destructive: !makeAdmin,
    );
    if (!ok) return;
    try {
      await _service.setUserRole(u.id, makeAdmin ? 'admin' : 'cliente');
      if (mounted) showAdminSnack(context, 'Rol actualizado');
    } catch (e) {
      if (mounted) showAdminSnack(context, '$e', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final myUid = FirebaseAuth.instance.currentUser?.uid;

    return StreamBuilder<List<AdminUser>>(
      stream: _users,
      builder: (context, snap) {
        if (snap.hasError) {
          return EmptyState(
            icon: AppIcons.delayed,
            title: 'Error al cargar usuarios',
            message: '${snap.error}',
          );
        }
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final all = snap.data!;
        final q = _query.trim().toLowerCase();
        final list = all
            .where(
              (u) =>
                  q.isEmpty ||
                  u.nombre.toLowerCase().contains(q) ||
                  u.email.toLowerCase().contains(q),
            )
            .toList();
        final admins = all.where((u) => u.isAdmin).length;

        return ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            AdminPageHeader(
              title: 'Usuarios',
              subtitle:
                  '${all.length - admins} clientes · $admins administradores',
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: AdminSearchField(
                hint: 'Buscar por nombre o email',
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Card(
                child: Column(
                  children: [
                    for (final u in list) ...[
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        leading: CircleAvatar(
                          backgroundColor:
                              (u.isAdmin ? AppColors.primary : AppColors.info)
                                  .withValues(alpha: 0.16),
                          child: Text(
                            u.nombre.isEmpty ? '?' : u.nombre[0].toUpperCase(),
                            style: TextStyle(
                              color: u.isAdmin
                                  ? AppColors.primary
                                  : AppColors.info,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        title: Row(
                          children: [
                            Flexible(
                              child: Text(
                                u.nombre,
                                overflow: TextOverflow.ellipsis,
                                style: t.titleMedium,
                              ),
                            ),
                            if (u.isAdmin) ...[
                              const SizedBox(width: 8),
                              const Tag('Admin', color: AppColors.primary),
                            ],
                          ],
                        ),
                        subtitle: Text(
                          [
                            u.email,
                            if (u.phone.isNotEmpty) u.phone,
                            if (u.direccion.isNotEmpty) u.direccion,
                          ].join(' · '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: t.bodySmall,
                        ),
                        trailing: u.id == myUid
                            ? Text('Tú', style: t.bodySmall)
                            : IconButton(
                                tooltip: u.isAdmin
                                    ? 'Quitar acceso admin'
                                    : 'Hacer admin',
                                icon: Icon(AppIcons.shield, size: 16),
                                color: u.isAdmin
                                    ? AppColors.primary
                                    : AppColors.textFaint,
                                onPressed: () => _toggleRole(u),
                              ),
                      ),
                      if (u != list.last) const Divider(height: 1, indent: 70),
                    ],
                    if (list.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('Sin resultados'),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
