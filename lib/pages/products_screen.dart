import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product_model.dart';
import '../providers/cart_provider.dart';
import '../services/product_service.dart';
import '../theme/app_theme.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/product_image.dart';
import 'product_detail_screen.dart';

/// Pantalla principal de la tienda: saludo, buscador, categorías y menú.
class ProductsScreen extends StatefulWidget {
  /// Categoría seleccionada al abrir. Sin categoría se muestra todo el menú.
  final DocumentReference? categoryRef;
  final String categoryName;

  const ProductsScreen({super.key, this.categoryRef, this.categoryName = ''});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final _search = TextEditingController();
  final _products = ProductService().getTodosLosProductos();
  final _categories = FirebaseFirestore.instance
      .collection('categories')
      .where('activo', isEqualTo: true)
      .snapshots();

  String _query = '';
  String? _categoryId; // null = Todo
  String _firstName = '';

  @override
  void initState() {
    super.initState();
    _categoryId = widget.categoryRef?.id;
    _loadName();
  }

  Future<void> _loadName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final d = doc.data() ?? {};
      final full = (d['name'] ?? d['nombre'] ?? '').toString().trim();
      if (mounted && full.isNotEmpty) {
        setState(() => _firstName = full.split(RegExp(r'\s+')).first);
      }
    } catch (_) {
      // El saludo es opcional: si falla, se muestra sin nombre.
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  String get _greeting {
    final h = DateTime.now().hour;
    final base = h < 12
        ? 'Buenos días'
        : h < 19
            ? 'Buenas tardes'
            : 'Buenas noches';
    return _firstName.isEmpty ? base : '$base, $_firstName';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      floatingActionButton: const CartFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: const AppBottomBar(),
      body: SafeArea(
        bottom: false,
        child: StreamBuilder<List<Product>>(
          stream: _products,
          builder: (context, productSnap) {
            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _categories,
              builder: (context, catSnap) {
                final all = productSnap.data ?? const <Product>[];

                // Solo categorías activas que tienen algún producto
                final withProducts =
                    all.map((p) => p.categoriaId?.id).whereType<String>().toSet();
                final cats = (catSnap.data?.docs ?? [])
                    .where((c) => withProducts.contains(c.id))
                    .toList()
                  ..sort((a, b) => (a.data()['nombre'] ?? '')
                      .toString()
                      .compareTo((b.data()['nombre'] ?? '').toString()));

                final selected =
                    cats.any((c) => c.id == _categoryId) ? _categoryId : null;

                var list = all;
                if (selected != null) {
                  list = list.where((p) => p.categoriaId?.id == selected).toList();
                }
                if (_query.isNotEmpty) {
                  list = list
                      .where((p) =>
                          p.nombre.toLowerCase().contains(_query) ||
                          p.descripcion.toLowerCase().contains(_query))
                      .toList();
                }
                // Disponibles primero
                list = [...list]
                  ..sort((a, b) => (a.stock <= 0 ? 1 : 0) - (b.stock <= 0 ? 1 : 0));

                return CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(child: _header(context)),
                    SliverToBoxAdapter(child: _searchField()),
                    if (cats.isNotEmpty)
                      SliverToBoxAdapter(child: _categoryChips(cats, selected)),
                    if (productSnap.hasError)
                      const SliverFillRemaining(
                        hasScrollBody: false,
                        child: _Empty(
                          icon: Icons.wifi_off_rounded,
                          title: 'No pudimos cargar el menú',
                          message: 'Revisa tu conexión e inténtalo de nuevo.',
                        ),
                      )
                    else if (!productSnap.hasData)
                      const SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (list.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _query.isNotEmpty
                            ? _Empty(
                                icon: Icons.search_off_rounded,
                                title: 'Sin resultados',
                                message: 'No encontramos "${_search.text.trim()}".',
                              )
                            : const _Empty(
                                icon: Icons.restaurant_menu_rounded,
                                title: 'Menú vacío por ahora',
                                message: 'Pronto agregaremos productos aquí.',
                              ),
                      )
                    else ...[
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
                        sliver: SliverToBoxAdapter(
                          child: Text(
                            '${list.length} ${list.length == 1 ? 'producto' : 'productos'}',
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ),
                      ),
                      SliverPadding(
                        // espacio extra para la barra inferior flotante
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                        sliver: SliverList.separated(
                          itemCount: list.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (_, i) => _ProductCard(product: list[i]),
                        ),
                      ),
                    ],
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_greeting, style: t.bodySmall?.copyWith(fontSize: 14)),
                const SizedBox(height: 2),
                Text('¿Qué se te antoja hoy?', style: t.headlineSmall),
              ],
            ),
          ),
          Container(
            width: 46,
            height: 46,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.brandGradient,
            ),
            child: const Icon(
              Icons.local_fire_department_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
      child: TextField(
        controller: _search,
        textInputAction: TextInputAction.search,
        onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
        decoration: InputDecoration(
          hintText: 'Buscar hamburguesas, pizzas…',
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: _query.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Borrar búsqueda',
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () {
                    _search.clear();
                    FocusScope.of(context).unfocus();
                    setState(() => _query = '');
                  },
                ),
        ),
      ),
    );
  }

  Widget _categoryChips(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> cats,
    String? selected,
  ) {
    Widget chip(String label, String? id, IconData icon) {
      final active = selected == id;
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          selected: active,
          onSelected: (_) => setState(() => _categoryId = id),
          avatar: Icon(
            icon,
            size: 18,
            color: active ? AppColors.primary : AppColors.textMuted,
          ),
          label: Text(label),
          labelStyle: TextStyle(
            fontWeight: FontWeight.w600,
            color: active ? AppColors.primary : AppColors.text,
          ),
          side: BorderSide(
            color: active ? AppColors.primary : AppColors.border,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        ),
      );
    }

    return SizedBox(
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          chip('Todo', null, Icons.restaurant_menu_rounded),
          for (final c in cats)
            chip(
              (c.data()['nombre'] ?? '').toString(),
              c.id,
              foodIcon((c.data()['nombre'] ?? '').toString()),
            ),
        ],
      ),
    );
  }
}

/// Tarjeta de producto con foto, precio, tiempo y control de cantidad.
class _ProductCard extends StatelessWidget {
  final Product product;

  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final p = product;
    final t = Theme.of(context).textTheme;
    final soldOut = p.stock <= 0;
    final qty = context.select<CartProvider, int>(
      (c) => c.items[p.id]?.cantidad ?? 0,
    );

    return Opacity(
      opacity: soldOut ? 0.55 : 1,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ProductDetailScreen(product: p)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ProductImage(url: p.imagen, nombre: p.nombre),
                const SizedBox(width: 14),
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
                      if (p.descripcion.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          p.descripcion,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: t.bodySmall,
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            'RD\$ ${p.precio.toStringAsFixed(p.precio % 1 == 0 ? 0 : 2)}',
                            style: t.titleMedium?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Icon(
                            Icons.schedule_rounded,
                            size: 14,
                            color: AppColors.textFaint,
                          ),
                          const SizedBox(width: 3),
                          Text('${p.tiempoPreparacion} min', style: t.bodySmall),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (soldOut)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Agotado',
                      style: TextStyle(
                        color: AppColors.danger,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  )
                else
                  _QtyControl(product: p, qty: qty),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QtyControl extends StatelessWidget {
  final Product product;
  final int qty;

  const _QtyControl({required this.product, required this.qty});

  void _add(BuildContext context) {
    final p = product;
    if (qty >= p.stock) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('Solo quedan ${p.stock} disponibles')),
        );
      return;
    }
    context.read<CartProvider>().addItem(
          p.id,
          p.nombre,
          p.precio,
          p.tiempoPreparacion,
        );
  }

  @override
  Widget build(BuildContext context) {
    if (qty == 0) {
      return IconButton.filled(
        tooltip: 'Agregar al carrito',
        onPressed: () => _add(context),
        style: IconButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        icon: const Icon(Icons.add_rounded),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _stepButton(Icons.add_rounded, 'Agregar uno', () => _add(context)),
          Text(
            '$qty',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          _stepButton(
            qty == 1 ? Icons.delete_outline_rounded : Icons.remove_rounded,
            'Quitar uno',
            () => context.read<CartProvider>().decreaseItem(product.id),
          ),
        ],
      ),
    );
  }

  Widget _stepButton(IconData icon, String tooltip, VoidCallback onTap) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      color: AppColors.text,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 32),
      padding: EdgeInsets.zero,
    );
  }
}

class _Empty extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _Empty({required this.icon, required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 32, 32, 120),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.surfaceHigh,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Icon(icon, color: AppColors.textMuted, size: 34),
          ),
          const SizedBox(height: 16),
          Text(title, style: t.titleLarge),
          const SizedBox(height: 6),
          Text(message, textAlign: TextAlign.center, style: t.bodySmall),
        ],
      ),
    );
  }
}
