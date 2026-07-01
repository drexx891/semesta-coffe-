import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/base64_image_helper.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/di/injection_container.dart';
import '../../bloc/menu_management/menu_management_bloc.dart';
import '../../bloc/menu_management/menu_management_event.dart';
import '../../bloc/menu_management/menu_management_state.dart';
import 'product_form_page.dart';
import 'widgets/category_form_dialog.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

class MenuListPage extends StatelessWidget {
  const MenuListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<MenuManagementBloc>()..add(LoadMenuManagement()),
      child: const MenuListView(),
    );
  }
}

class MenuListView extends StatefulWidget {
  const MenuListView({super.key});

  @override
  State<MenuListView> createState() => _MenuListViewState();
}

class _MenuListViewState extends State<MenuListView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(AppStrings.menu, style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w600)),
        backgroundColor: AppColors.primaryDark,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.accent,
          labelColor: AppColors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Daftar Produk'),
            Tab(text: 'Kategori'),
          ],
        ),
      ),
      body: BlocConsumer<MenuManagementBloc, MenuManagementState>(
        listener: (context, state) {
          if (state is MenuManagementActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.green),
            );
          } else if (state is MenuManagementError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          }
        },
        builder: (context, state) {
          if (state is MenuManagementLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is MenuManagementLoaded) {
            return TabBarView(
              controller: _tabController,
              children: [
                _buildProductList(context, state.products, state.categories),
                _buildCategoryList(context, state.categories),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final state = context.read<MenuManagementBloc>().state;
          if (state is MenuManagementLoaded) {
            if (_tabController.index == 0) {
              if (state.categories.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Tambahkan Kategori terlebih dahulu!')),
                );
                return;
              }
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (ctx) => BlocProvider.value(
                    value: context.read<MenuManagementBloc>(),
                    child: ProductFormPage(categories: state.categories),
                  ),
                ),
              );
            } else {
              final menuManagementBloc = context.read<MenuManagementBloc>();
              final result = await showDialog(
                context: context,
                builder: (ctx) => const CategoryFormDialog(),
              );
              if (!mounted) return;
              if (result != null) {
                menuManagementBloc.add(CreateCategory(
                  name: result['name'],
                  sortOrder: result['sort_order'],
                ));
              }
            }
          }
        },
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
          side: BorderSide(color: AppColors.white.withValues(alpha: 0.2), width: 1),
        ),
        icon: const Icon(LucideIcons.plus, size: 20, color: AppColors.white),
        label: Text(
          _tabController.index == 0 ? 'Tambah Produk' : 'Tambah Kategori',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.white,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: AppColors.accent,
      ),
    );
  }

  Widget _buildProductList(BuildContext context, List<Map<String, dynamic>> products, List<Map<String, dynamic>> categories) {
    if (products.isEmpty) {
      return const Center(child: Text('Belum ada produk'));
    }

    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    
    // Kelompokkan produk berdasarkan category_id
    final Map<int, List<Map<String, dynamic>>> groupedProducts = {};
    for (var product in products) {
      final catId = product['category_id'] as int;
      groupedProducts.putIfAbsent(catId, () => []).add(product);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final catId = category['id'] as int;
        final catProducts = groupedProducts[catId] ?? [];

        // Jangan tampilkan kategori yang kosong
        if (catProducts.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 12, left: 4),
              child: Text(
                category['name'] as String,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDark,
                ),
              ),
            ),
            ...catProducts.map((product) {
              final isActive = product['is_active'] == 1;
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: Container(
                    width: 50,
                    height: 50,
                    clipBehavior: Clip.hardEdge,
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Base64ImageHelper.buildImage(product['image_path'] as String?),
                  ),
                  title: Text(
                    product['name'],
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        currencyFormat.format(product['price_regular']),
                        style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(
                        value: isActive,
                        onChanged: (val) {
                          context.read<MenuManagementBloc>().add(ToggleProductActive(product['id'], val));
                        },
                        activeThumbColor: AppColors.primary,
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.pencil, color: Colors.blue),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (ctx) => BlocProvider.value(
                                value: context.read<MenuManagementBloc>(),
                                child: ProductFormPage(product: product, categories: categories),
                              ),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _confirmDeleteProduct(context, product),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildCategoryList(BuildContext context, List<Map<String, dynamic>> categories) {
    if (categories.isEmpty) {
      return const Center(child: Text('Belum ada kategori'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.primary,
              child: Text(category['sort_order'].toString()),
            ),
            title: Text(category['name'], style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(LucideIcons.pencil, color: Colors.blue),
                  onPressed: () async {
                    final menuManagementBloc = context.read<MenuManagementBloc>();
                    final result = await showDialog(
                      context: context,
                      builder: (ctx) => CategoryFormDialog(category: category),
                    );
                    if (!mounted) return;
                    if (result != null) {
                      menuManagementBloc.add(UpdateCategory(
                        id: category['id'],
                        name: result['name'],
                        sortOrder: result['sort_order'],
                      ));
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_rounded, color: Colors.red),
                  onPressed: () => _confirmDeleteCategory(context, category),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmDeleteCategory(BuildContext context, Map<String, dynamic> category) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Kategori'),
        content: Text('Apakah Anda yakin ingin menghapus kategori "${category['name']}"?\nKategori hanya bisa dihapus jika kosong.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<MenuManagementBloc>().add(DeleteCategory(category['id']));
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteProduct(BuildContext context, Map<String, dynamic> product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Produk'),
        content: Text('Apakah Anda yakin ingin menghapus "${product['name']}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<MenuManagementBloc>().add(DeleteProduct(product['id']));
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
