import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/di/injection_container.dart';
import '../../../data/database/dao/settings_dao.dart';

class ActivityLogPage extends StatefulWidget {
  const ActivityLogPage({super.key});

  @override
  State<ActivityLogPage> createState() => _ActivityLogPageState();
}

class _ActivityLogPageState extends State<ActivityLogPage> {
  final SettingsDao _settingsDao = sl<SettingsDao>();
  bool _isLoading = true;
  List<Map<String, dynamic>> _logs = [];

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() => _isLoading = true);
    try {
      _logs = await _settingsDao.getLogs(limit: 200);
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  IconData _getIconForAction(String action) {
    if (action.contains('VOID')) return Icons.cancel_rounded;
    if (action.contains('LOGIN')) return Icons.login_rounded;
    if (action.contains('SHIFT')) return Icons.schedule_rounded;
    if (action.contains('STOCK')) return Icons.inventory_2_rounded;
    if (action.contains('USER')) return Icons.group_rounded;
    if (action.contains('SETTINGS')) return Icons.settings_rounded;
    return Icons.info_rounded;
  }

  Color _getColorForAction(String action) {
    if (action.contains('VOID') || action.contains('DELETE') || action.contains('FAILED')) return AppColors.error;
    if (action.contains('ADD') || action.contains('CREATE') || action.contains('LOGIN_SUCCESS')) return AppColors.success;
    if (action.contains('UPDATE') || action.contains('EDIT') || action.contains('CORRECTION')) return AppColors.warning;
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Log Aktivitas', style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w600)),
        backgroundColor: AppColors.primaryDark,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadLogs,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _logs.isEmpty
              ? Center(child: Text('Belum ada log aktivitas', style: GoogleFonts.inter(color: AppColors.textTertiary)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _logs.length,
                  itemBuilder: (ctx, index) {
                    final log = _logs[index];
                    final date = DateTime.tryParse(log['created_at'] as String) ?? DateTime.now();
                    final actionType = log['action_type'] as String;
                    final description = log['description'] as String;
                    final userName = log['user_name'] as String? ?? 'Sistem';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getColorForAction(actionType).withValues(alpha: 0.1),
                          child: Icon(_getIconForAction(actionType), color: _getColorForAction(actionType)),
                        ),
                        title: Text(description, style: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 14)),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Oleh: $userName  •  ${DateFormat('dd MMM yyyy HH:mm').format(date)}',
                            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
