import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/di/injection_container.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_strings.dart';
import 'core/constants/app_colors.dart';
import 'data/database/dao/user_dao.dart';
import 'data/database/dao/settings_dao.dart';
import 'services/session_manager.dart';
import 'presentation/bloc/auth/auth_bloc.dart';
import 'presentation/bloc/menu/menu_bloc.dart';
import 'presentation/bloc/menu/menu_event.dart';
import 'core/routes/app_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'presentation/bloc/stock/stock_bloc.dart';
import 'presentation/bloc/stock/stock_event.dart';
import 'presentation/bloc/customer/customer_bloc.dart';
import 'presentation/bloc/customer/customer_event.dart';
import 'presentation/bloc/voucher/voucher_bloc.dart';
import 'presentation/bloc/voucher/voucher_event.dart';
import 'presentation/bloc/attendance/attendance_bloc.dart';
import 'presentation/bloc/attendance/attendance_event.dart';

void main() async {
  // Tangkap semua error widget dan render ke layar (mencegah layar putih)
  ErrorWidget.builder = (FlutterErrorDetails details) {
    debugPrint('WIDGET ERROR: ${details.exceptionAsString()}');
    debugPrint('STACKTRACE: ${details.stack?.toString()}');
    return const Directionality(
      textDirection: TextDirection.ltr,
      child: Material(
        color: AppColors.background,
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.circle_alert, color: AppColors.error, size: 48),
                SizedBox(height: 16),
                Text('Terjadi Kesalahan', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                SizedBox(height: 8),
                Text('Maaf, halaman ini mengalami gangguan sementara.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          ),
        ),
      ),
    );
  };

  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();

  // Muat file .env untuk API keys
  await dotenv.load(fileName: ".env");

  // Inisialisasi locale Indonesia
  await initializeDateFormatting('id_ID', null);

  String initStep = 'Starting initialization...';
  try {
    initStep = 'Initializing Supabase...';
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL'] ?? '',
      anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
    );

    initStep = 'Initializing Dependencies (Database, etc)...';
    await initDependencies();
  } catch (e, stackTrace) {
    debugPrint('FAILED TO INIT DEPENDENCIES at step: $initStep - $e');
    debugPrint('STACKTRACE: $stackTrace');
    
    // Tampilkan error di layar jika inisialisasi gagal
    runApp(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Material(
          color: AppColors.background,
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cloud_off_rounded, color: AppColors.error, size: 64),
                  SizedBox(height: 24),
                  Text('Gagal Memuat Aplikasi', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  SizedBox(height: 16),
                  Text('Koneksi sistem terputus. Silakan muat ulang (Refresh) halaman ini.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    return; // Berhenti di sini, jangan lanjut ke SmestaCoffeeApp
  }

  // Set preferred orientations (Khusus Tablet POS Landscape)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Status bar style
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: AppColors.primaryDark,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppColors.white,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));

  runApp(const SmestaCoffeeApp());
}

class SmestaCoffeeApp extends StatelessWidget {
  const SmestaCoffeeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (_) => AuthBloc(
            userDao: sl<UserDao>(),
            settingsDao: sl<SettingsDao>(),
            sessionManager: sl<SessionManager>(),
          ),
        ),
        BlocProvider<MenuBloc>(
          create: (_) => sl<MenuBloc>()..add(LoadMenu()),
        ),
        BlocProvider<StockBloc>(
          create: (_) => sl<StockBloc>()..add(LoadStock()),
        ),
        BlocProvider<CustomerBloc>(
          create: (_) => sl<CustomerBloc>()..add(LoadCustomers()),
        ),
        BlocProvider<VoucherBloc>(
          create: (_) => sl<VoucherBloc>()..add(LoadVouchers()),
        ),
        BlocProvider<AttendanceBloc>(
          create: (_) => sl<AttendanceBloc>(),
        ),
      ],
      child: MaterialApp.router(
        title: AppStrings.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        routerConfig: appRouter,
      ),
    );
  }
}

