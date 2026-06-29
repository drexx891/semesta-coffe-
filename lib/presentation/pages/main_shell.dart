import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_strings.dart';
import '../../domain/entities/user.dart';
import '../../services/session_manager.dart';
import '../../core/di/injection_container.dart';
import '../bloc/auth/auth_bloc.dart';
import '../bloc/auth/auth_event.dart';
import '../bloc/pos/pos_bloc.dart';
import '../bloc/pos/pos_event.dart';
import 'dashboard_page.dart';
import 'pos/pos_page.dart';
import 'transaction/transaction_history_page.dart';
import 'menu/menu_list_page.dart';
import 'stock/stock_list_page.dart';
import 'customer/customer_list_page.dart';
import 'voucher/voucher_list_page.dart';
import 'attendance/attendance_history_page.dart';
import 'report/report_page.dart';
import 'settings/settings_page.dart';
import 'shift/shift_page.dart';
import 'kds/kds_page.dart';
import '../widgets/attendance_dialog.dart';

/// Shell navigasi utama — responsive sidebar (tablet) / bottom nav (phone)
class MainShell extends StatefulWidget {
  final User user;
  const MainShell({super.key, required this.user});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;
  late final PosBloc _posBloc;

  List<_NavItem> get _navItems {
    final items = <_NavItem>[
      _NavItem(
        icon: Icons.dashboard_rounded, 
        label: AppStrings.dashboard, 
        page: DashboardPage(
          onNavigate: (destination) {
            _navigateToDestination(destination);
          },
        ),
      ),
      _NavItem(icon: Icons.point_of_sale_rounded, label: AppStrings.pos, page: const PosPage()),
      _NavItem(icon: Icons.receipt_long_rounded, label: AppStrings.transactions, page: const TransactionHistoryPage()),
      _NavItem(icon: Icons.people_alt_rounded, label: 'Pelanggan', page: const CustomerListPage()),
      _NavItem(icon: Icons.local_offer_rounded, label: 'Voucher', page: const VoucherListPage()),
      _NavItem(icon: Icons.kitchen_rounded, label: 'KDS', page: const KdsPage()),
      _NavItem(icon: Icons.schedule_rounded, label: AppStrings.shift, page: const ShiftPage()),
    ];

    if (widget.user.canSupervise) {
      items.add(_NavItem(icon: Icons.inventory_2_rounded, label: AppStrings.stock, page: const StockListPage()));
      items.add(_NavItem(icon: Icons.bar_chart_rounded, label: AppStrings.reports, page: const ReportPage()));
    }

    if (widget.user.canManageMenu) {
      items.add(_NavItem(icon: Icons.restaurant_menu_rounded, label: AppStrings.menu, page: const MenuListPage()));
    }
    
    // Virtual nav item for Attendance in mobile view (intercepted)
    items.add(_NavItem(icon: Icons.fingerprint_rounded, label: 'Clock In/Out', page: const Scaffold()));
    
    items.add(_NavItem(
      icon: Icons.history_rounded, 
      label: 'Riwayat Absensi', 
      page: AttendanceHistoryPage(userId: widget.user.id ?? 1),
    ));

    if (widget.user.canManageSettings) {
      items.add(_NavItem(icon: Icons.settings_rounded, label: AppStrings.settings, page: const SettingsPage()));
    }

    return items;
  }

  void _navigateToDestination(String destination) {
    final navItems = _navItems;
    int targetIndex = 0;
    if (destination == 'pos') {
      targetIndex = 1;
    } else if (destination == 'shift') {
      targetIndex = navItems.indexWhere((item) => item.label == AppStrings.shift);
    } else if (destination == 'stock') {
      targetIndex = navItems.indexWhere((item) => item.label == AppStrings.stock);
    } else if (destination == 'settings') {
      targetIndex = navItems.indexWhere((item) => item.label == AppStrings.settings);
    }
    
    if (targetIndex != -1) {
      setState(() {
        _selectedIndex = targetIndex;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _posBloc = sl<PosBloc>()..add(InitPos());
  }

  @override
  void dispose() {
    _posBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= AppDimensions.tabletBreakpoint;
    final navItems = _navItems;

    // Reset index jika melebihi jumlah menu
    if (_selectedIndex >= navItems.length) {
      _selectedIndex = 0;
    }

    return BlocProvider.value(
      value: _posBloc,
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) => sl<SessionManager>().resetActivity(),
        onPointerMove: (_) => sl<SessionManager>().resetActivity(),
        child: Scaffold(
          body: isTablet ? _buildTabletLayout(navItems) : _buildPhoneLayout(navItems),
        ),
      ),
    );
  }

  /// Layout tablet: sidebar kiri + content area
  Widget _buildTabletLayout(List<_NavItem> navItems) {
    return Row(
      children: [
        // === Sidebar ===
        Container(
          width: AppDimensions.sidebarWidth,
          decoration: const BoxDecoration(
            color: AppColors.primaryDark,
            boxShadow: [
              BoxShadow(
                color: AppColors.cardShadow,
                blurRadius: 8,
                offset: Offset(2, 0),
              ),
            ],
          ),
          child: Column(
            children: [
              const SizedBox(height: AppDimensions.spacing16),
              // Logo
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.coffee_rounded, color: AppColors.white, size: 24),
              ),
              const SizedBox(height: AppDimensions.spacing24),

              // Nav items
              Expanded(
                child: ListView.builder(
                  itemCount: navItems.length,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemBuilder: (context, index) {
                    final item = navItems[index];
                    final isSelected = _selectedIndex == index;

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      child: Tooltip(
                        message: item.label,
                        preferBelow: false,
                        child: InkWell(
                          onTap: () => setState(() => _selectedIndex = index),
                          borderRadius: BorderRadius.circular(12),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.accent.withValues(alpha: 0.15) : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: isSelected
                                  ? Border.all(color: AppColors.accent.withValues(alpha: 0.3), width: 1)
                                  : null,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  item.icon,
                                  color: isSelected ? AppColors.accent : AppColors.white.withValues(alpha: 0.6),
                                  size: 22,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item.label,
                                  style: GoogleFonts.inter(
                                    fontSize: 9,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                    color: isSelected ? AppColors.accent : AppColors.white.withValues(alpha: 0.6),
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // User info & logout
              _buildSidebarFooter(),
            ],
          ),
        ),

        // === Content ===
        Expanded(
          child: navItems[_selectedIndex].page,
        ),
      ],
    );
  }

  /// Layout phone: bottom navigation
  Widget _buildPhoneLayout(List<_NavItem> navItems) {
    // Batasi bottom nav max 5 items, sisanya masuk ke "More"
    final maxBottomItems = navItems.length > 5 ? 4 : navItems.length;
    final bottomItems = navItems.take(maxBottomItems).toList();
    final hasMore = navItems.length > 5;

    return Scaffold(
      body: navItems[_selectedIndex].page,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: AppColors.cardShadow.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _selectedIndex < bottomItems.length ? _selectedIndex : bottomItems.length,
          onDestinationSelected: (index) {
            if (hasMore && index == bottomItems.length) {
              _showMoreMenu(navItems.sublist(maxBottomItems), maxBottomItems);
            } else {
              if (bottomItems[index].label == 'Clock In/Out') {
                _showAttendanceDialog();
                return;
              }
              setState(() => _selectedIndex = index);
            }
          },
          destinations: [
            ...bottomItems.map((item) => NavigationDestination(
              icon: Icon(item.icon),
              selectedIcon: Icon(item.icon),
              label: item.label,
            )),
            if (hasMore)
              const NavigationDestination(
                icon: Icon(Icons.more_horiz_rounded),
                label: 'Lainnya',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarFooter() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacing12),
      child: Column(
        children: [
          const Divider(color: AppColors.white, thickness: 0.2),
          const SizedBox(height: 8),
          // User avatar
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.accent,
            child: Text(
              widget.user.name[0].toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.white,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.user.name,
            style: GoogleFonts.inter(
              fontSize: 9,
              color: AppColors.white.withValues(alpha: 0.8),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            widget.user.role.displayName,
            style: GoogleFonts.inter(
              fontSize: 8,
              color: AppColors.accent.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 8),
          // Attendance / Clock In
          InkWell(
            onTap: () async {
              final result = await showDialog<String>(
                context: context,
                builder: (ctx) => AttendanceDialog(userId: widget.user.id ?? 1),
              );
              if (result != null && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Berhasil merekam absensi: $result')));
              }
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.white.withValues(alpha: 0.2)),
              ),
              child: Icon(
                Icons.fingerprint_rounded,
                color: AppColors.white.withValues(alpha: 0.6),
                size: 18,
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Logout button
          InkWell(
            onTap: _confirmLogout,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.white.withValues(alpha: 0.2)),
              ),
              child: Icon(
                Icons.logout_rounded,
                color: AppColors.white.withValues(alpha: 0.6),
                size: 18,
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Yakin ingin keluar dari aplikasi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(AppStrings.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthBloc>().add(LogoutRequested());
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _showMoreMenu(List<_NavItem> moreItems, int startOffset) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(AppDimensions.spacing16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: moreItems.asMap().entries.map((entry) {
            final localIndex = entry.key;
            final item = entry.value;
            final globalIndex = startOffset + localIndex;
            return ListTile(
              leading: Icon(item.icon, color: AppColors.primary),
              title: Text(item.label),
              onTap: () {
                if (item.label == 'Clock In/Out') {
                  Navigator.pop(context);
                  _showAttendanceDialog();
                  return;
                }
                Navigator.pop(context);
                if (mounted) {
                  setState(() => _selectedIndex = globalIndex);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showAttendanceDialog() async {
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AttendanceDialog(userId: widget.user.id ?? 1),
    );
    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Berhasil merekam absensi: $result')));
    }
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final Widget page;

  _NavItem({required this.icon, required this.label, required this.page});
}
