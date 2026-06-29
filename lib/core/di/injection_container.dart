import 'package:get_it/get_it.dart';
import '../../data/database/database_helper.dart';
import '../../data/database/dao/user_dao.dart';
import '../../data/database/dao/product_dao.dart';
import '../../data/database/dao/transaction_dao.dart';
import '../../data/database/dao/shift_dao.dart';
import '../../data/database/dao/stock_dao.dart';
import '../../data/database/dao/settings_dao.dart';
import '../../data/database/dao/hold_order_dao.dart';
import '../../data/database/dao/customer_dao.dart';
import '../../data/database/dao/voucher_dao.dart';
import '../../data/database/dao/attendance_dao.dart';
import '../../services/session_manager.dart';
import '../../services/audio_service.dart';
import '../../services/supabase_sync_service.dart';
import '../../services/printer_service.dart';
import '../../presentation/bloc/auth/auth_bloc.dart';
import '../../presentation/bloc/menu/menu_bloc.dart';
import '../../presentation/bloc/menu_management/menu_management_bloc.dart';
import '../../presentation/bloc/pos/pos_bloc.dart';
import '../../presentation/bloc/stock/stock_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sl = GetIt.instance;

/// Inisialisasi semua dependency
Future<void> initDependencies() async {
  // === Storage ===
  final prefs = await SharedPreferences.getInstance();
  sl.registerLazySingleton<SharedPreferences>(() => prefs);

  // === Database ===
  sl.registerLazySingleton<DatabaseHelper>(() => DatabaseHelper());

  // === DAOs ===
  sl.registerLazySingleton<UserDao>(() => UserDao(sl()));
  sl.registerLazySingleton<ProductDao>(() => ProductDao(sl()));
  sl.registerLazySingleton<TransactionDao>(() => TransactionDao(sl()));
  sl.registerLazySingleton<ShiftDao>(() => ShiftDao(sl()));
  sl.registerLazySingleton<StockDao>(() => StockDao(sl()));
  sl.registerLazySingleton<SettingsDao>(() => SettingsDao(sl()));
  sl.registerLazySingleton<HoldOrderDao>(() => HoldOrderDao(sl()));
  sl.registerLazySingleton<CustomerDao>(() => CustomerDao(sl()));
  sl.registerLazySingleton<VoucherDao>(() => VoucherDao(sl()));
  sl.registerLazySingleton<AttendanceDao>(() => AttendanceDao(sl()));

  // === BLoCs ===
  sl.registerFactory(() => AuthBloc(
        userDao: sl(),
        settingsDao: sl(),
        sessionManager: sl(),
      ));
  
  sl.registerFactory(() => MenuBloc(
        productDao: sl(),
      ));

  sl.registerFactory(() => MenuManagementBloc(
        productDao: sl(),
      ));

  sl.registerFactory(() => PosBloc(
        productDao: sl(),
        stockDao: sl(),
        shiftDao: sl(),
        transactionDao: sl(),
        settingsDao: sl(),
        holdOrderDao: sl(),
        voucherDao: sl(),
        sessionManager: sl(),
        prefs: sl(),
      ));
      
  sl.registerFactory(() => StockBloc(
        stockDao: sl(),
      ));

  // === Services ===
  sl.registerLazySingleton<SessionManager>(() => SessionManager());
  sl.registerLazySingleton<AudioService>(() => AudioService());
  sl.registerLazySingleton<SupabaseSyncService>(() => SupabaseSyncService(sl()));
  sl.registerLazySingleton<PrinterService>(() => PrinterService());

  // Inisialisasi database
  await sl<DatabaseHelper>().database;
}
