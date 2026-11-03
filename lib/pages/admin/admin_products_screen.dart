import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/admin_service.dart';
import '../../theme/app_icons.dart';
import '../../theme/app_theme.dart';
import '../../widgets/admin/admin_widgets.dart';

/// Icono según el nombre de la categoría o del producto.
IconData foodIconFor(String text) {
  final s = text.toLowerCase();
  if (s.contains('pizza')) return AppIcons.pizza;
  if (s.contains('papa') || s.contains('fries')) return AppIcons.fries;
  if (s.contains('bebida') ||
      s.contains('jugo') ||
      s.contains('refresco') ||
      s.contains('soda')) {
    return AppIcons.drink;
  }
  return AppIcons.burger;
}

class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  final _service = AdminService();
  late final _products = _service.watchProducts();
  late final _categories = _service.watchCategories();
  String _query = '';
  String? _categoryId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AdminCategory>>(
      stream: _categories,
      builder: (context, catSnap) {
        final categories = catSnap.data ?? const <AdminCategory>[];
        final catById = {for (final c in categories) c.id: c};

        return StreamBuilder<List<AdminProduct>>(
          stream: _products,
          builder: (context, snap) {
            if (snap.hasError) {
              return EmptyState(
                icon: AppIcons.delayed,
                title: 'Error al cargar el menú',
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
                  (p) =>
                      _categoryId == null || p.categoriaRef?.id == _categoryId,
                )
                .where(
                  (p) =>
                      q.isEmpty ||
                      p.nombre.toLowerCase().contains(q) ||
                      p.descripcion.toLowerCase().contains(q),
                )
                .toList();
            final activeCount = all.where((p) => p.activo).length;
            final outOfStock = all.where((p) => p.stock <= 0).length;

            return LayoutBuilder(
              builder: (context, c) {
                final cols = c.maxWidth >= 1100
                    ? 3
                    : c.maxWidth >= 700
                    ? 2
                    : 1;
                return CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: AdminPageHeader(
                        title: 'Menú',
                        subtitle:
                            '${all.length} productos · $activeCount visibles · $outOfStock agotados',
                        action: FilledButton.icon(
                          icon: Icon(AppIcons.add, size: 14),
                          label: Text(
                            c.maxWidth >= 500 ? 'Nuevo producto' : 'Nuevo',
                          ),
                          onPressed: () =>
                              showProductForm(context, categories: categories),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                        child: AdminSearchField(
                          hint: 'Buscar en el menú',
                          onChanged: (v) => setState(() => _query = v),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: 40,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          children: [
                            _CatChip(
                              label: 'Todo',
                              selected: _categoryId == null,
                              onTap: () => setState(() => _categoryId = null),
                            ),
                            for (final cat in categories)
                              _CatChip(
                                label: cat.nombre,
                                icon: foodIconFor(cat.nombre),
                                selected: _categoryId == cat.id,
                                onTap: () =>
                                    setState(() => _categoryId = cat.id),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 12)),
                    if (list.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: EmptyState(
                          icon: AppIcons.burger,
                          title: 'Nada por aquí',
                          message: 'No hay productos que coincidan.',
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                        sliver: SliverGrid(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: cols,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                mainAxisExtent: 170,
                              ),
                          delegate: SliverChildBuilderDelegate(
                            (_, i) => _ProductCard(
                              product: list[i],
                              category: catById[list[i].categoriaRef?.id],
                              categories: categories,
                            ),
                            childCount: list.length,
                          ),
                        ),
                      ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}

class _CatChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  const _CatChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.textMuted;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        avatar: icon == null ? null : Icon(icon, size: 13, color: color),
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        labelStyle: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final AdminProduct product;
  final AdminCategory? category;
  final List<AdminCategory> categories;

  const _ProductCard({
    required this.product,
    required this.category,
    required this.categories,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final p = product;
    final service = AdminService();

    final (stockLabel, stockColor) = p.stock <= 0
        ? ('Agotado', AppColors.danger)
        : p.stock <= 5
        ? ('Quedan ${p.stock}', AppColors.warning)
        : ('Stock ${p.stock}', AppColors.textMuted);

    return Opacity(
      opacity: p.activo ? 1 : 0.55,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () =>
              showProductForm(context, categories: categories, product: p),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: p.activo ? AppColors.brandGradient : null,
                        color: p.activo ? null : AppColors.surfaceHigh,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        foodIconFor(category?.nombre ?? p.nombre),
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.nombre,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: t.titleMedium,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            category?.nombre ?? 'Sin categoría',
                            style: t.bodySmall?.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: p.activo,
                      onChanged: (v) async {
                        try {
                          await service.setProductActive(p.id, v);
                          if (context.mounted) {
                            showAdminSnack(
                              context,
                              v
                                  ? '${p.nombre} visible en el menú'
                                  : '${p.nombre} oculto',
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            showAdminSnack(context, '$e', error: true);
                          }
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: Text(
                    p.descripcion.isEmpty ? 'Sin descripción' : p.descripcion,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: t.bodySmall,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      formatMoney(p.precio),
                      style: t.titleMedium?.copyWith(color: AppColors.text),
                    ),
                    const Spacer(),
                    Tag(stockLabel, color: stockColor),
                    const SizedBox(width: 6),
                    Tag('${p.tiempoPreparacion} min', color: AppColors.info),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Formulario de producto
// ---------------------------------------------------------------------------

Future<void> showProductForm(
  BuildContext context, {
  required List<AdminCategory> categories,
  AdminProduct? product,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    constraints: const BoxConstraints(maxWidth: 640),
    builder: (_) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: _ProductForm(categories: categories, product: product),
    ),
  );
}

class _ProductForm extends StatefulWidget {
  final List<AdminCategory> categories;
  final AdminProduct? product;

  const _ProductForm({required this.categories, this.product});

  @override
  State<_ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends State<_ProductForm> {
  final _formKey = GlobalKey<FormState>();
  final _service = AdminService();
  late final _nombre = TextEditingController(text: widget.product?.nombre);
  late final _descripcion = TextEditingController(
    text: widget.product?.descripcion,
  );
  late final _precio = TextEditingController(
    text: widget.product?.precio.toStringAsFixed(2),
  );
  late final _stock = TextEditingController(
    text: widget.product?.stock.toString() ?? '0',
  );
  late final _tiempo = TextEditingController(
    text: widget.product?.tiempoPreparacion.toString() ?? '10',
  );
  late bool _activo = widget.product?.activo ?? true;
  late DocumentReference? _categoria = widget.product?.categoriaRef;
  bool _saving = false;

  bool get _isEdit => widget.product != null;

  @override
  void dispose() {
    for (final c in [_nombre, _descripcion, _precio, _stock, _tiempo]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await _service.saveProduct(
        id: widget.product?.id,
        nombre: _nombre.text.trim(),
        descripcion: _descripcion.text.trim(),
        precio: double.parse(_precio.text.replaceAll(',', '.')),
        stock: int.parse(_stock.text),
        tiempoPreparacion: int.parse(_tiempo.text),
        activo: _activo,
        categoriaRef: _categoria,
      );
      if (!mounted) return;
      Navigator.pop(context);
      showAdminSnack(
        context,
        _isEdit ? 'Producto actualizado' : 'Producto agregado al menú',
      );
    } catch (e) {
      if (mounted) showAdminSnack(context, '$e', error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final p = widget.product!;
    final ok = await confirmAction(
      context,
      title: 'Eliminar ${p.nombre}',
      message:
          'Se borrará permanentemente del menú. Si solo quieres ocultarlo, desactívalo.',
      confirmLabel: 'Eliminar',
      destructive: true,
    );
    if (!ok) return;
    try {
      await _service.deleteProduct(p.id);
      if (!mounted) return;
      Navigator.pop(context);
      showAdminSnack(context, 'Producto eliminado');
    } catch (e) {
      if (mounted) showAdminSnack(context, '$e', error: true);
    }
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Campo requerido' : null;

  String? _number(String? v, {bool decimal = false}) {
    if (_required(v) != null) return 'Campo requerido';
    final n = decimal
        ? double.tryParse(v!.replaceAll(',', '.'))
        : int.tryParse(v!);
    if (n == null || n < 0) return 'Número inválido';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final hasCategory = widget.categories.any(
      (c) => c.ref.path == _categoria?.path,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                IconTile(icon: _isEdit ? AppIcons.edit : AppIcons.add),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _isEdit ? 'Editar producto' : 'Nuevo producto',
                    style: t.headlineSmall,
                  ),
                ),
                if (_isEdit)
                  IconButton(
                    tooltip: 'Eliminar',
                    color: AppColors.danger,
                    icon: Icon(AppIcons.delete, size: 18),
                    onPressed: _delete,
                  ),
              ],
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nombre,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Nombre'),
              validator: _required,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descripcion,
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Descripción'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: hasCategory ? _categoria!.path : null,
              decoration: const InputDecoration(labelText: 'Categoría'),
              dropdownColor: AppColors.surfaceHigh,
              items: [
                for (final c in widget.categories)
                  DropdownMenuItem(
                    value: c.ref.path,
                    child: Row(
                      children: [
                        Icon(
                          foodIconFor(c.nombre),
                          size: 14,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 10),
                        Text(c.nombre),
                      ],
                    ),
                  ),
              ],
              onChanged: (path) => setState(
                () => _categoria = widget.categories
                    .firstWhere((c) => c.ref.path == path)
                    .ref,
              ),
              validator: (v) => v == null ? 'Elige una categoría' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _precio,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Precio',
                      prefixText: 'RD\$ ',
                    ),
                    validator: (v) => _number(v, decimal: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _stock,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(labelText: 'Stock'),
                    validator: _number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _tiempo,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Prep.',
                      suffixText: 'min',
                    ),
                    validator: _number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceHigh,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Visible en el menú', style: t.bodyMedium),
                        Text('Los clientes podrán pedirlo', style: t.bodySmall),
                      ],
                    ),
                  ),
                  Switch(
                    value: _activo,
                    onChanged: (v) => setState(() => _activo = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(_isEdit ? 'Guardar cambios' : 'Agregar al menú'),
            ),
          ],
        ),
      ),
    );
  }
}
