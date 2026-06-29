import 'package:flutter/material.dart';
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

void main() async {
  // Tangkap semua error widget dan render ke layar (mencegah layar putih)
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Material(
        color: Colors.red.shade900,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Text(
            'WIDGET ERROR:\n\n${details.exceptionAsString()}\n\n${details.stack?.toString() ?? ''}',
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ),
      ),
    );
  };

  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();

  // Inisialisasi locale Indonesia
  await initializeDateFormatting('id_ID', null);

  String initStep = 'Starting initialization...';
  try {
    initStep = 'Initializing Supabase...';
    await Supabase.initialize(
      url: 'https://jhdsklpaubhkcwgswqrt.supabase.co',
      anonKey: 'sb_publishable_LX3NuW-7wlF6k-m__iI17A_krboNnAb',
    );

    initStep = 'Initializing Dependencies (Database, etc)...';
    await initDependencies();
  } catch (e, stackTrace) {
    debugPrint('FAILED TO INIT DEPENDENCIES at step: $initStep - $e');
    debugPrint('STACKTRACE: $stackTrace');
    
    // Tampilkan error di layar jika inisialisasi gagal
    runApp(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Material(
          color: Colors.red.shade900,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Text(
              'INIT ERROR:\n\nStep: $initStep\n\nError: $e\n\nStack: $stackTrace',
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ),
      ),
    );
    return; // Berhenti di sini, jangan lanjut ke SmestaCoffeeApp
  }

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
    DeviceOrientation.portraitUp,
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

