import 'package:flutter/material.dart';

import '../../services/admin_service.dart';
import '../../theme/app_icons.dart';
import '../../theme/app_theme.dart';
import '../../widgets/admin/admin_widgets.dart';
import 'admin_products_screen.dart' show foodIconFor;

class AdminCategoriesScreen extends StatefulWidget {
  const AdminCategoriesScreen({super.key});

  @override
  State<AdminCategoriesScreen> createState() => _AdminCategoriesScreenState();
}

class _AdminCategoriesScreenState extends State<AdminCategoriesScreen> {
  final _service = AdminService();
  late final _categories = _service.watchCategories();
  late final _products = _service.watchProducts();

  Future<void> _edit([AdminCategory? category]) async {
    final ctrl = TextEditingController(text: category?.nombre);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          category == null ? 'Nueva categoría' : 'Renombrar categoría',
        ),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(hintText: 'Ej. Hamburguesas'),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (name == null || name.trim().isEmpty) return;
    try {
      await _service.saveCategory(id: category?.id, nombre: name.trim());
      if (mounted) showAdminSnack(context, 'Categoría guardada');
    } catch (e) {
      if (mounted) showAdminSnack(context, '$e', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return StreamBuilder<List<AdminProduct>>(
      stream: _products,
      builder: (context, prodSnap) {
        final counts = <String, int>{};
        for (final p in prodSnap.data ?? const <AdminProduct>[]) {
          final id = p.categoriaRef?.id;
          if (id != null) counts[id] = (counts[id] ?? 0) + 1;
        }

        return StreamBuilder<List<AdminCategory>>(
          stream: _categories,
          builder: (context, snap) {
            if (snap.hasError) {
              return EmptyState(
                icon: AppIcons.delayed,
                title: 'Error al cargar categorías',
                message: '${snap.error}',
              );
            }
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final list = snap.data!;

            return ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                AdminPageHeader(
                  title: 'Categorías',
                  subtitle: 'Organiza cómo los clientes ven tu menú',
                  action: FilledButton.icon(
                    icon: Icon(AppIcons.add, size: 14),
                    label: const Text('Nueva'),
                    onPressed: () => _edit(),
                  ),
                ),
                if (list.isEmpty)
                  EmptyState(
                    icon: AppIcons.categories,
                    title: 'Sin categorías',
                    message: 'Crea la primera para organizar tu menú.',
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Card(
                      child: Column(
                        children: [
                          for (final c in list) ...[
                            ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              leading: IconTile(
                                icon: foodIconFor(c.nombre),
                                color: c.activo
                                    ? AppColors.primary
                                    : AppColors.textFaint,
                              ),
                              title: Text(c.nombre, style: t.titleMedium),
                              subtitle: Text(
                                '${counts[c.id] ?? 0} productos · ${c.activo ? 'Visible' : 'Oculta'}',
                                style: t.bodySmall,
                              ),
                              onTap: () => _edit(c),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    tooltip: 'Renombrar',
                                    icon: Icon(AppIcons.edit, size: 16),
                                    color: AppColors.textMuted,
                                    onPressed: () => _edit(c),
                                  ),
                                  Switch(
                                    value: c.activo,
                                    onChanged: (v) =>
                                        _service.setCategoryActive(c.id, v),
                                  ),
                                ],
                              ),
                            ),
                            if (c != list.last)
                              const Divider(height: 1, indent: 70),
                          ],
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}
