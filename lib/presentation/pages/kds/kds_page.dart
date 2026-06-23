import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'dart:convert';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/di/injection_container.dart';
import '../../../data/database/dao/transaction_dao.dart';
import '../../../core/utils/date_formatter.dart';

class KdsPage extends StatefulWidget {
  const KdsPage({super.key});

  @override
  State<KdsPage> createState() => _KdsPageState();
}

class _KdsPageState extends State<KdsPage> {
  final TransactionDao _transactionDao = sl<TransactionDao>();
  List<Map<String, dynamic>> _activeOrders = [];
  Timer? _refreshTimer;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) => _loadOrders());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    final today = await _transactionDao.getTodayTransactions();
    
    // Filter active orders (queued, preparing, ready)
    final active = today.where((t) {
      final status = t['order_status'] as String? ?? 'completed';
      return status != 'completed' && t['status'] != 'void';
    }).toList();
    
    // Reverse to show oldest first (FIFO)
    active.sort((a, b) => (a['created_at'] as String).compareTo(b['created_at'] as String));

    // Fetch items for each active order
    final List<Map<String, dynamic>> fullOrders = [];
    for (final t in active) {
      final orderWithItems = await _transactionDao.getById(t['id'] as int);
      if (orderWithItems != null) {
        fullOrders.add(orderWithItems);
      }
    }

    if (mounted) {
      setState(() {
        _activeOrders = fullOrders;
        _isLoading = false;
      });
    }
  }

  Future<void> _updateOrderStatus(int transactionId, String newStatus) async {
    await sl<TransactionDao>().updateOrderStatus(transactionId, newStatus);
    await _loadOrders();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'queued': return AppColors.textSecondary;
      case 'preparing': return AppColors.warning;
      case 'ready': return AppColors.success;
      default: return AppColors.border;
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Kitchen Display System (KDS)', style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w600)),
        backgroundColor: AppColors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              setState(() => _isLoading = true);
              _loadOrders();
            },
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _activeOrders.isEmpty
              ? Center(child: Text('Tidak ada pesanan aktif.', style: GoogleFonts.inter(fontSize: 18, color: AppColors.textTertiary)))
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 350,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: _activeOrders.length,
                  itemBuilder: (ctx, index) {
                    final order = _activeOrders[index];
                    return _buildOrderCard(order);
                  },
                ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final items = List<Map<String, dynamic>>.from(order['items'] as List);
    final status = order['order_status'] as String? ?? 'queued';
    final isDineIn = order['order_type'] == 'dine_in';
    final customerName = order['customer_name'] ?? order['table_number'] ?? 'Pelanggan';

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: _getStatusColor(status), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _getStatusColor(status).withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('#${order['queue_number']}', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800)),
                      Text(customerName, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDineIn ? AppColors.info : AppColors.warning,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(isDineIn ? 'Dine In' : 'Takeaway', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.white)),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: items.length,
              separatorBuilder: (ctx, i) => const Divider(),
              itemBuilder: (ctx, i) {
                final item = items[i];
                // Build modifier string
                final modifiers = <String>[];
                if (item['size'] != null && item['size'] != 'regular') {
                  modifiers.add('${(item['size'] as String).toUpperCase()}');
                }
                if (item['extra_shot'] == 1) {
                  modifiers.add('Extra Shot');
                }
                if (item['sugar_level'] != null && item['sugar_level'] != 'normal') {
                  modifiers.add(item['sugar_level'] == 'less' ? 'Less Sugar' : 'No Sugar');
                }
                if (item['ice_level'] != null && item['ice_level'] != 'normal') {
                  modifiers.add(item['ice_level'] == 'less' ? 'Less Ice' : 'No Ice');
                }
                if (item['toppings_json'] != null) {
                  try {
                    final toppings = (jsonDecode(item['toppings_json'] as String) as List);
                    for (final t in toppings) {
                      modifiers.add('+ ${t['name']}');
                    }
                  } catch (_) {}
                }
                final modifierText = modifiers.join(' · ');

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${item['quantity']}x ', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item['product_name'], style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
                          if (modifierText.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(modifierText, style: GoogleFonts.inter(fontSize: 12, color: AppColors.accent, fontWeight: FontWeight.w500)),
                            ),
                          if (item['notes'] != null && item['notes'].toString().isNotEmpty)
                            Text('📝 ${item['notes']}', style: GoogleFonts.inter(fontSize: 13, color: AppColors.error, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (status == 'queued')
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _updateOrderStatus(order['id'], 'preparing'),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning),
                      child: const Text('Proses'),
                    ),
                  ),
                if (status == 'preparing')
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _updateOrderStatus(order['id'], 'ready'),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                      child: const Text('Selesai (Siap)'),
                    ),
                  ),
                if (status == 'ready')
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _updateOrderStatus(order['id'], 'completed'),
                      child: const Text('Tandai Diambil'),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
