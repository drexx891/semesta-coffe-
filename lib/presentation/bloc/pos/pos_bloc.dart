import 'dart:async';
import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'pos_event.dart';
import 'pos_state.dart';
import '../../../data/database/dao/product_dao.dart';
import '../../../data/database/dao/stock_dao.dart';
import '../../../data/database/dao/shift_dao.dart';
import '../../../data/database/dao/transaction_dao.dart';
import '../../../data/database/dao/settings_dao.dart';
import '../../../data/database/dao/hold_order_dao.dart';
import '../../../data/database/dao/voucher_dao.dart';
import '../../../services/session_manager.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../domain/entities/hold_order.dart';

class PosBloc extends Bloc<PosEvent, PosState> {
  // ignore: unused_field
  final ProductDao _productDao;
  final StockDao _stockDao;
  final ShiftDao _shiftDao;
  final TransactionDao _transactionDao;
  final SettingsDao _settingsDao;
  final HoldOrderDao _holdOrderDao;
  final VoucherDao _voucherDao;
  final SessionManager _sessionManager;
  final SharedPreferences _prefs;

  Timer? _holdOrderTimer;
  Timer? _shiftCheckTimer;

  PosBloc({
    required this._productDao,
    required this._stockDao,
    required this._shiftDao,
    required this._transactionDao,
    required this._settingsDao,
    required this._holdOrderDao,
    required this._voucherDao,
    required this._sessionManager,
    required this._prefs,
  })  : super(const PosState()) {
    on<InitPos>(_onInitPos);
    on<AddToCart>(_onAddToCart);
    on<UpdateCartItemQuantity>(_onUpdateCartItemQuantity);
    on<RemoveFromCart>(_onRemoveFromCart);
    on<ClearCart>(_onClearCart);
    on<SetOrderType>(_onSetOrderType);
    on<SetTableNumber>(_onSetTableNumber);
    on<SetCustomer>(_onSetCustomer);
    on<SetCustomerName>(_onSetCustomerName);
    on<ApplyDiscount>(_onApplyDiscount);
    on<ClearDiscount>(_onClearDiscount);
    on<ApplyVoucher>(_onApplyVoucher);
    on<ClearVoucher>(_onClearVoucher);
    on<ProcessPayment>(_onProcessPayment);
    on<SaveHoldOrder>(_onSaveHoldOrder);
    on<LoadHoldOrder>(_onLoadHoldOrder);
    on<CheckShiftStatus>(_onCheckShiftStatus);
    on<SyncCartState>(_onSyncCartState);
    on<ResetPos>(_onResetPos);
    on<StartNewTransaction>(_onStartNewTransaction);
  }

  @override
  Future<void> close() {
    _holdOrderTimer?.cancel();
    _shiftCheckTimer?.cancel();
    return super.close();
  }

  Future<void> _onInitPos(InitPos event, Emitter<PosState> emit) async {
    try {
      final settings = await _settingsDao.getSettings();
      if (settings != null) {
        emit(state.copyWith(
          taxPercentage: (settings['tax_percentage'] as num?)?.toDouble() ?? 11.0,
          serviceChargePercentage: (settings['service_charge_percentage'] as num?)?.toDouble() ?? 5.0,
          taxEnabled: settings['tax_enabled'] == 1,
          serviceChargeEnabled: settings['service_charge_enabled'] == 1,
          maxCashierDiscount: (settings['max_cashier_discount'] as num?)?.toDouble() ?? 20.0,
        ));
      }

      await _checkShiftStatus(emit);
      await _pollHoldOrders(emit);

      _holdOrderTimer = Timer.periodic(const Duration(seconds: 15), (_) {
        add(CheckShiftStatus()); // Check both hold orders and shift
      });
      
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Gagal memuat pengaturan: $e'));
    }
  }

  Future<void> _onCheckShiftStatus(CheckShiftStatus event, Emitter<PosState> emit) async {
    await _checkShiftStatus(emit);
    await _pollHoldOrders(emit);
  }

  Future<void> _checkShiftStatus(Emitter<PosState> emit) async {
    try {
      final shift = await _shiftDao.getActiveShift();
      if (shift != null) {
        emit(state.copyWith(activeShiftId: shift['id'] as int));
      } else {
        emit(state.copyWith(clearActiveShiftId: true));
      }
    } catch (_) {}
  }

  Future<void> _pollHoldOrders(Emitter<PosState> emit) async {
    try {
      await _holdOrderDao.cleanupExpiredHoldOrders();
      final count = await _holdOrderDao.countActiveHoldOrders();
      emit(state.copyWith(activeHoldOrders: count));
    } catch (_) {}
  }

  void _onAddToCart(AddToCart event, Emitter<PosState> emit) {
    final updatedCart = List<CartItem>.from(state.cartItems)..add(event.item);
    emit(state.copyWith(cartItems: updatedCart));
    add(const SyncCartState());
  }

  void _onUpdateCartItemQuantity(UpdateCartItemQuantity event, Emitter<PosState> emit) {
    if (event.index < 0 || event.index >= state.cartItems.length) return;
    
    final item = state.cartItems[event.index];
    final newQty = item.quantity + event.delta;
    
    final updatedCart = List<CartItem>.from(state.cartItems);
    if (newQty <= 0) {
      updatedCart.removeAt(event.index);
    } else {
      updatedCart[event.index] = CartItem(
        cartItemId: item.cartItemId,
        productId: item.productId,
        productName: item.productName,
        productImagePath: item.productImagePath,
        size: item.size,
        sugarLevel: item.sugarLevel,
        iceLevel: item.iceLevel,
        extraShot: item.extraShot,
        selectedToppings: item.selectedToppings,
        notes: item.notes,
        basePrice: item.basePrice,
        modifierPrice: item.modifierPrice,
        quantity: newQty,
      );
    }
    
    emit(state.copyWith(cartItems: updatedCart));
    add(const SyncCartState());
  }

  void _onRemoveFromCart(RemoveFromCart event, Emitter<PosState> emit) {
    if (event.index < 0 || event.index >= state.cartItems.length) return;
    
    final updatedCart = List<CartItem>.from(state.cartItems)..removeAt(event.index);
    emit(state.copyWith(cartItems: updatedCart));
    add(const SyncCartState());
  }

  void _onClearCart(ClearCart event, Emitter<PosState> emit) {
    emit(state.copyWith(cartItems: []));
    add(const SyncCartState());
  }

  void _onSetOrderType(SetOrderType event, Emitter<PosState> emit) {
    emit(state.copyWith(orderType: event.orderType));
    add(const SyncCartState());
  }

  void _onSetTableNumber(SetTableNumber event, Emitter<PosState> emit) {
    emit(state.copyWith(tableNumber: event.tableNumber));
    add(const SyncCartState());
  }

  void _onSetCustomer(SetCustomer event, Emitter<PosState> emit) {
    if (event.customer != null) {
      emit(state.copyWith(
        selectedCustomer: event.customer,
        customerNameInput: event.customer!.name,
        tableNumber: event.customer!.name,
      ));
    } else {
      emit(state.copyWith(clearCustomer: true));
    }
    add(const SyncCartState());
  }

  void _onSetCustomerName(SetCustomerName event, Emitter<PosState> emit) {
    final name = event.customerName.trim();
    emit(state.copyWith(
      customerNameInput: name.isEmpty ? null : name,
      tableNumber: name.isEmpty ? null : name,
      clearCustomer: state.selectedCustomer != null && name != state.selectedCustomer!.name,
    ));
    add(const SyncCartState());
  }

  void _onApplyDiscount(ApplyDiscount event, Emitter<PosState> emit) {
    emit(state.copyWith(
      discountPercentage: event.percentage,
      discountNominal: event.nominal,
    ));
    add(const SyncCartState());
  }

  void _onClearDiscount(ClearDiscount event, Emitter<PosState> emit) {
    emit(state.copyWith(
      discountPercentage: 0,
      discountNominal: 0,
    ));
    add(const SyncCartState());
  }

  void _onApplyVoucher(ApplyVoucher event, Emitter<PosState> emit) {
    if (!event.voucher.isValid) {
      emit(state.copyWith(errorMessage: 'Voucher tidak valid atau sudah kadaluarsa'));
      return;
    }
    if (state.subtotal < event.voucher.minPurchase) {
      emit(state.copyWith(errorMessage: 'Minimum pembelian belum terpenuhi'));
      return;
    }
    
    emit(state.copyWith(
      selectedVoucher: event.voucher,
      discountPercentage: 0, // Clear manual discount when using voucher
      discountNominal: 0,
    ));
    add(const SyncCartState());
  }

  void _onClearVoucher(ClearVoucher event, Emitter<PosState> emit) {
    emit(state.copyWith(clearVoucher: true));
    add(const SyncCartState());
  }

  Future<void> _onSaveHoldOrder(SaveHoldOrder event, Emitter<PosState> emit) async {
    if (state.cartItems.isEmpty) return;
    
    final user = _sessionManager.currentUser;
    if (user == null) return;

    try {
      final holdOrderData = {
        'label': event.label,
        'order_type': state.orderType,
        'table_number': state.tableNumber,
        'items_json': jsonEncode(state.cartItems.map((i) => i.toJson()).toList()),
        'user_id': user.id!,
        'created_at': DateTime.now().toIso8601String(),
        'expires_at': DateTime.now().add(Duration(minutes: _prefs.getInt('hold_order_timeout') ?? 120)).toIso8601String(),
      };

      await _holdOrderDao.insertHoldOrder(holdOrderData);
      add(ResetPos());
      add(CheckShiftStatus());
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Gagal menyimpan pesanan: $e'));
    }
  }

  Future<void> _onLoadHoldOrder(LoadHoldOrder event, Emitter<PosState> emit) async {
    emit(state.copyWith(
      cartItems: event.holdOrder.items,
      orderType: event.holdOrder.orderType,
      tableNumber: event.holdOrder.tableNumber,
      customerNameInput: event.holdOrder.label,
    ));
    try {
      if (event.holdOrder.id != null) {
        await _holdOrderDao.deleteHoldOrder(event.holdOrder.id!);
      }
      add(const SyncCartState());
      add(CheckShiftStatus());
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Gagal memuat pesanan: $e'));
    }
  }

  Future<void> _onProcessPayment(ProcessPayment event, Emitter<PosState> emit) async {
    if (state.cartItems.isEmpty) return;
    if (state.activeShiftId == null) {
      emit(state.copyWith(errorMessage: 'Shift harus dibuka terlebih dahulu'));
      return;
    }

    emit(state.copyWith(paymentStatus: PaymentStatus.processing, errorMessage: null));
    add(SyncCartState(status: 'payment', paymentMethod: event.paymentMethod));

    try {
      final user = _sessionManager.currentUser;
      if (user == null) throw Exception("User tidak ditemukan");

      // Generate nomor transaksi & antrian
      final trxCount = await _transactionDao.countTodayTransactions();
      final queueCount = await _transactionDao.countTodayQueue();
      final trxNumber = DateFormatter.generateTransactionNumber(trxCount + 1);
      final queueNumber = DateFormatter.generateQueueNumber(queueCount + 1);

      // Hitung pemotongan stok untuk semua item
      final allDeductions = <Map<String, dynamic>>[];
      for (final item in state.cartItems) {
        final deductions = await _stockDao.calculateStockDeduction(
          productId: item.productId,
          size: item.size,
          extraShot: item.extraShot,
          toppingIds: item.selectedToppings.map((t) => t.id).toList(),
          quantity: item.quantity,
        );
        allDeductions.addAll(deductions);
      }

      // Merge deductions
      final mergedDeductions = <int, double>{};
      for (final d in allDeductions) {
        final id = d['ingredient_id'] as int;
        mergedDeductions[id] = (mergedDeductions[id] ?? 0) + (d['quantity'] as double);
      }

      // Validasi Stok
      for (final entry in mergedDeductions.entries) {
        final ingredientId = entry.key;
        final requiredQty = entry.value;
        final ingredient = await _stockDao.getIngredientById(ingredientId);
        
        if (ingredient != null) {
          final currentStock = (ingredient['current_stock'] as num).toDouble();
          if (currentStock < requiredQty) {
            emit(state.copyWith(
              paymentStatus: PaymentStatus.error,
              errorMessage: 'Stok ${ingredient['name']} tidak mencukupi (Sisa: ${currentStock.toStringAsFixed(1)} ${ingredient['unit']})',
            ));
            return;
          }
        }
      }

      final change = event.paymentMethod == 'cash' ? event.cashReceived - state.total : 0.0;

      final transactionId = await _transactionDao.createTransaction(
        transaction: {
          'transaction_number': trxNumber,
          'shift_id': state.activeShiftId,
          'user_id': user.id!,
          'order_type': state.orderType,
          'table_number': state.tableNumber,
          'queue_number': queueNumber,
          'subtotal': state.subtotal,
          'discount_amount': state.discountAmount,
          'discount_percentage': state.selectedVoucher != null ? 0 : state.discountPercentage,
          'discount_reason': state.selectedVoucher != null ? 'Voucher: ${state.selectedVoucher!.code}' : null,
          'service_charge_amount': state.serviceChargeAmount,
          'tax_amount': state.taxAmount,
          'total': state.total,
          'payment_method': event.paymentMethod,
          'cash_received': event.paymentMethod == 'cash' ? event.cashReceived : state.total,
          'cash_change': change,
          'customer_id': state.selectedCustomer?.id,
          'status': 'completed',
          'order_status': 'queued',
          'created_at': DateTime.now().toIso8601String(),
        },
        items: state.cartItems.map((item) {
          return {
            'product_id': item.productId,
            'product_name': item.productName,
            'size': item.size,
            'sugar_level': item.sugarLevel,
            'ice_level': item.iceLevel,
            'extra_shot': item.extraShot ? 1 : 0,
            'toppings_json': item.selectedToppings.isNotEmpty
                ? jsonEncode(item.selectedToppings.map((t) => t.toJson()).toList())
                : null,
            'notes': item.notes,
            'unit_price': item.basePrice,
            'modifier_price': item.modifierPrice,
            'quantity': item.quantity,
            'subtotal': item.subtotal,
          };
        }).toList(),
        stockDeductions: mergedDeductions.entries.map((e) {
          return {
            'ingredient_id': e.key,
            'quantity': e.value,
          };
        }).toList(),
      );

      emit(state.copyWith(
        paymentStatus: PaymentStatus.success,
        lastTransactionId: transactionId,
        lastQueueNumber: queueNumber,
        lastTransactionNumber: trxNumber,
      ));
      
      if (state.selectedVoucher != null && state.selectedVoucher!.id != null) {
        await _voucherDao.incrementUsedCount(state.selectedVoucher!.id!);
      }
      
      add(const SyncCartState(status: 'success'));
      
    } catch (e) {
      emit(state.copyWith(
        paymentStatus: PaymentStatus.error,
        errorMessage: 'Gagal memproses transaksi: $e',
      ));
    }
  }

  void _onSyncCartState(SyncCartState event, Emitter<PosState> emit) {
    final cartList = state.cartItems.map((item) {
      return {
        'id': item.productId,
        'name': item.productName,
        'price': item.basePrice,
        'quantity': item.quantity,
        'modifier_text': item.modifierDisplay,
        'subtotal': item.subtotal,
      };
    }).toList();
    
    _prefs.setString('cfd_cart', jsonEncode({
       'status': event.status,
       'payment_method': event.paymentMethod,
       'customer_name': state.selectedCustomer?.name ?? state.customerNameInput,
       'order_type': state.orderType,
       'table_number': state.tableNumber,
       'items': cartList,
       'total': state.total,
       'discount': state.discountAmount,
       'tax': state.taxAmount,
       'service': state.serviceChargeAmount,
       'subtotal': state.subtotal
    }));
  }

  void _onResetPos(ResetPos event, Emitter<PosState> emit) {
    emit(state.copyWith(
      cartItems: [],
      discountPercentage: 0,
      discountNominal: 0,
      tableNumber: null,
      customerNameInput: null,
      clearCustomer: true,
      clearVoucher: true,
      paymentStatus: PaymentStatus.idle,
      errorMessage: null,
      lastQueueNumber: null,
      lastTransactionNumber: null,
      lastTransactionId: null,
    ));
    add(const SyncCartState(status: 'idle'));
  }

  void _onStartNewTransaction(StartNewTransaction event, Emitter<PosState> emit) {
    add(ResetPos());
  }
}
