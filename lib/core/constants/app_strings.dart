/// Semua string UI dalam Bahasa Indonesia
/// Diorganisir per modul untuk kemudahan maintenance
class AppStrings {
  AppStrings._();

  // === App ===
  static const String appName = 'Semesta Cafee';
  static const String appTagline = 'Point of Sale';

  // === Login ===
  static const String login = 'Masuk';
  static const String username = 'Username';
  static const String password = 'Password';
  static const String loginButton = 'Masuk';
  static const String loginFailed = 'Username atau password salah';
  static const String accountLocked = 'Akun terkunci. Coba lagi dalam {minutes} menit.';
  static const String loginAttemptWarning = 'Sisa percobaan: {remaining}';
  static const String showPassword = 'Tampilkan password';
  static const String hidePassword = 'Sembunyikan password';
  static const String sessionExpired = 'Sesi telah berakhir. Silakan masuk kembali.';

  // === Navigation ===
  static const String dashboard = 'Dashboard';
  static const String pos = 'Kasir';
  static const String menu = 'Menu';
  static const String stock = 'Stok';
  static const String reports = 'Laporan';
  static const String settings = 'Pengaturan';
  static const String transactions = 'Transaksi';
  static const String shift = 'Shift';

  // === Dashboard ===
  static const String todaySales = 'Penjualan Hari Ini';
  static const String totalTransactions = 'Jumlah Transaksi';
  static const String voidTransactions = 'Transaksi Void';
  static const String bestSeller = 'Produk Terlaris';
  static const String averageTransaction = 'Rata-rata Transaksi';
  static const String totalDiscount = 'Total Diskon';
  static const String activeShift = 'Shift Aktif';
  static const String last7Days = 'Penjualan 7 Hari Terakhir';
  static const String salesByCategory = 'Penjualan per Kategori';
  static const String stockAlert = 'Peringatan Stok';
  static const String stockCriticalBanner = 'Ada {count} bahan baku di bawah stok minimum!';

  // === POS ===
  static const String searchProduct = 'Cari produk...';
  static const String allCategory = 'Semua';
  static const String outOfStock = 'Habis';
  static const String cart = 'Keranjang';
  static const String emptyCart = 'Keranjang kosong';
  static const String emptyCartMessage = 'Tap produk untuk menambahkan ke keranjang';
  static const String addToCart = 'Tambah ke Keranjang';
  static const String clearCart = 'Hapus Semua';
  static const String clearCartConfirm = 'Yakin ingin menghapus semua item dari keranjang?';
  static const String itemNotes = 'Catatan khusus';
  static const String itemNotesHint = 'Contoh: extra panas, tanpa bawang';

  // === Modifiers ===
  static const String size = 'Ukuran';
  static const String sizeRegular = 'Regular';
  static const String sizeLarge = 'Large';
  static const String sugarLevel = 'Tingkat Gula';
  static const String sugarNormal = 'Normal';
  static const String sugarLess = 'Less Sugar';
  static const String sugarNone = 'No Sugar';
  static const String iceLevel = 'Tingkat Es';
  static const String iceNormal = 'Normal Ice';
  static const String iceLess = 'Less Ice';
  static const String iceNone = 'No Ice';
  static const String extraShot = 'Extra Shot';
  static const String extraShotAdd = '+1 Shot Espresso';
  static const String toppings = 'Topping';

  // === Order Type ===
  static const String orderType = 'Jenis Pesanan';
  static const String dineIn = 'Dine In';
  static const String takeAway = 'Take Away';
  static const String tableNumber = 'Nomor Meja';
  static const String tableNumberHint = 'Masukkan nomor meja';

  // === Payment ===
  static const String pay = 'Bayar';
  static const String subtotal = 'Subtotal';
  static const String discount = 'Diskon';
  static const String discountPercentage = 'Diskon (%)';
  static const String discountNominal = 'Diskon (Rp)';
  static const String discountReason = 'Alasan diskon';
  static const String serviceCharge = 'Service Charge';
  static const String tax = 'PPN';
  static const String total = 'TOTAL';
  static const String paymentMethod = 'Metode Pembayaran';
  static const String cash = 'Tunai';
  static const String qris = 'QRIS';
  static const String bankTransfer = 'Transfer Bank';
  static const String edc = 'Kartu Debit/Kredit';
  static const String voucher = 'Voucher';
  static const String cashReceived = 'Uang Diterima';
  static const String change = 'Kembalian';
  static const String cashNotEnough = 'Nominal tunai kurang dari total';
  static const String confirmPayment = 'Konfirmasi Pembayaran';
  static const String paymentSuccess = 'Pembayaran Berhasil!';
  static const String queueNumber = 'Nomor Antrian';
  static const String printReceipt = 'Cetak Struk';
  static const String newTransaction = 'Transaksi Baru';

  // === Hold Order ===
  static const String holdOrder = 'Simpan Sementara';
  static const String holdOrders = 'Pesanan Tertunda';
  static const String holdLabel = 'Label Pesanan';
  static const String holdLabelHint = 'Nama pelanggan / nomor meja';
  static const String holdOrderFull = 'Slot penuh (maks 10). Selesaikan pesanan tertunda yang ada.';
  static const String holdOrderEmpty = 'Tidak ada pesanan tertunda';
  static const String retrieveOrder = 'Ambil Pesanan';

  // === Shift ===
  static const String openShift = 'Buka Shift';
  static const String closeShift = 'Tutup Shift';
  static const String openingCash = 'Modal Awal';
  static const String closingCash = 'Uang di Laci';
  static const String expectedCash = 'Ekspektasi Kas';
  static const String cashDifference = 'Selisih Kas';
  static const String cashOver = 'Lebih';
  static const String cashShort = 'Kurang';
  static const String shiftSummary = 'Ringkasan Shift';
  static const String shiftMustBeOpen = 'Shift harus dibuka terlebih dahulu sebelum transaksi';
  static const String shiftAlreadyOpen = 'Masih ada shift yang belum ditutup';
  static const String printShiftReport = 'Cetak Laporan Shift';

  // === Void ===
  static const String voidTransaction = 'Void Transaksi';
  static const String voidReason = 'Alasan Void';
  static const String voidReasonWrongOrder = 'Salah pesanan';
  static const String voidReasonCustomerRequest = 'Permintaan pelanggan';
  static const String voidReasonProductUnavailable = 'Produk tidak tersedia';
  static const String voidReasonSystemError = 'Error sistem';
  static const String voidReasonOther = 'Lainnya';
  static const String voidConfirm = 'Yakin ingin membatalkan transaksi ini?';
  static const String voidSuccess = 'Transaksi berhasil di-void';
  static const String voidStockRestored = 'Stok bahan baku telah dikembalikan';

  // === Menu Management ===
  static const String addMenu = 'Tambah Menu';
  static const String editMenu = 'Edit Menu';
  static const String productName = 'Nama Produk';
  static const String productCategory = 'Kategori';
  static const String productDescription = 'Deskripsi';
  static const String productPrice = 'Harga Jual';
  static const String productPriceRegular = 'Harga Regular';
  static const String productPriceLarge = 'Harga Large';
  static const String productImage = 'Foto Produk';
  static const String productActive = 'Aktif';
  static const String productInactive = 'Nonaktif';
  static const String duplicateProduct = 'Duplikasi Produk';
  static const String deleteProduct = 'Hapus Produk';
  static const String cannotDeleteProduct = 'Produk tidak dapat dihapus karena sudah ada transaksi. Gunakan nonaktifkan.';

  // === Stock ===
  static const String addIngredient = 'Tambah Bahan Baku';
  static const String editIngredient = 'Edit Bahan Baku';
  static const String ingredientName = 'Nama Bahan';
  static const String ingredientCategory = 'Kategori Bahan';
  static const String ingredientUnit = 'Satuan';
  static const String currentStock = 'Stok Saat Ini';
  static const String minimumStock = 'Stok Minimum';
  static const String costPerUnit = 'Harga Beli per Satuan';
  static const String addStock = 'Tambah Stok';
  static const String stockCorrection = 'Koreksi Stok';
  static const String stockHistory = 'Riwayat Stok';
  static const String stockIn = 'Stok Masuk';
  static const String stockOut = 'Stok Keluar';
  static const String invoiceNumber = 'Nomor Faktur';
  static const String supplierName = 'Nama Supplier';
  static const String correctionReason = 'Alasan Koreksi';
  static const String stockOpname = 'Stock Opname';
  static const String damaged = 'Kerusakan';
  static const String expired = 'Kadaluarsa';

  // === Recipe ===
  static const String recipe = 'Resep';
  static const String editRecipe = 'Atur Resep';
  static const String addIngredientToRecipe = 'Tambah Bahan ke Resep';
  static const String recipeQuantity = 'Jumlah';
  static const String noRecipeWarning = 'Produk ini belum memiliki resep. Stok tidak akan terpotong.';

  // === Reports ===
  static const String dailyReport = 'Laporan Harian';
  static const String monthlyReport = 'Laporan Bulanan';
  static const String bestSellerReport = 'Produk Terlaris';
  static const String salesByCashier = 'Penjualan per Kasir';
  static const String paymentMethodReport = 'Metode Pembayaran';
  static const String discountReport = 'Diskon & Voucher';
  static const String taxReport = 'Pajak & Service Charge';
  static const String voidReport = 'Void / Pembatalan';
  static const String shiftReport = 'Rekap Shift';
  static const String hppReport = 'HPP & Margin';
  static const String filterByDate = 'Filter Tanggal';
  static const String filterByCashier = 'Filter Kasir';
  static const String filterByPayment = 'Filter Pembayaran';
  static const String filterByCategory = 'Filter Kategori';
  static const String exportPdf = 'Export PDF';
  static const String exportExcel = 'Export Excel';

  // === Settings ===
  static const String storeProfile = 'Profil Toko';
  static const String storeName = 'Nama Toko';
  static const String storeLogo = 'Logo Toko';
  static const String storeAddress = 'Alamat';
  static const String storePhone = 'Telepon';
  static const String storeNpwp = 'NPWP';
  static const String receiptFooter = 'Pesan Footer Struk';
  static const String transactionConfig = 'Konfigurasi Transaksi';
  static const String taxPercentage = 'Persentase PPN';
  static const String serviceChargePercentage = 'Persentase Service Charge';
  static const String maxCashierDiscount = 'Batas Diskon Kasir';
  static const String sessionTimeout = 'Session Timeout (menit)';
  static const String holdOrderTimeout = 'Auto-hapus Hold Order (menit)';
  static const String printerSettings = 'Pengaturan Printer';
  static const String scanPrinter = 'Scan Printer';
  static const String paperSize = 'Ukuran Kertas';
  static const String testPrint = 'Test Print';
  static const String receiptPrinter = 'Printer Struk';
  static const String baristaPrinter = 'Printer Barista';
  static const String receiptCopies = 'Jumlah Salinan Struk';
  static const String userManagement = 'Kelola Pengguna';
  static const String addUser = 'Tambah Pengguna';
  static const String editUser = 'Edit Pengguna';
  static const String resetPassword = 'Reset Password';
  static const String activityLog = 'Log Aktivitas';

  // === Backup ===
  static const String backup = 'Backup';
  static const String restore = 'Restore';
  static const String backupRestore = 'Backup & Restore';
  static const String manualBackup = 'Backup Manual';
  static const String autoBackup = 'Backup Otomatis';
  static const String autoBackupTime = 'Waktu Backup';
  static const String backupSuccess = 'Backup berhasil disimpan';
  static const String restoreWarning = 'Restore akan mengganti seluruh data yang ada. Lanjutkan?';
  static const String restoreSuccess = 'Data berhasil di-restore';
  static const String exportData = 'Export Data';

  // === User Roles ===
  static const String roleOwner = 'Owner';
  static const String roleSupervisor = 'Supervisor';
  static const String roleCashier = 'Kasir';

  // === Common ===
  static const String save = 'Simpan';
  static const String cancel = 'Batal';
  static const String delete = 'Hapus';
  static const String edit = 'Edit';
  static const String add = 'Tambah';
  static const String confirm = 'Konfirmasi';
  static const String yes = 'Ya';
  static const String no = 'Tidak';
  static const String ok = 'OK';
  static const String close = 'Tutup';
  static const String back = 'Kembali';
  static const String next = 'Selanjutnya';
  static const String search = 'Cari';
  static const String filter = 'Filter';
  static const String refresh = 'Refresh';
  static const String loading = 'Memuat...';
  static const String noData = 'Tidak ada data';
  static const String error = 'Terjadi kesalahan';
  static const String retry = 'Coba Lagi';
  static const String success = 'Berhasil';
  static const String warning = 'Peringatan';
  static const String info = 'Informasi';
  static const String active = 'Aktif';
  static const String inactive = 'Nonaktif';
  static const String all = 'Semua';
  static const String today = 'Hari Ini';
  static const String yesterday = 'Kemarin';
  static const String thisWeek = 'Minggu Ini';
  static const String thisMonth = 'Bulan Ini';
  static const String selectDate = 'Pilih Tanggal';

  // === PIN Confirmation ===
  static const String enterPin = 'Masukkan PIN';
  static const String supervisorPinRequired = 'Diperlukan PIN Supervisor/Owner';
  static const String invalidPin = 'PIN tidak valid';

  // === Printer ===
  static const String printerNotConnected = 'Printer tidak terhubung';
  static const String printerConnected = 'Printer terhubung';
  static const String printingFailed = 'Gagal mencetak. Struk dapat dicetak ulang nanti.';
  static const String reprintReceipt = 'Cetak Ulang Struk';

  // === Categories ===
  static const String categoryCoffee = 'Coffee';
  static const String categoryNonCoffee = 'Non Coffee';
  static const String categoryTea = 'Tea';
  static const String categorySnack = 'Snack';
  static const String categoryDessert = 'Dessert';

  // === Ingredient Categories ===
  static const String ingredientCatBeans = 'Biji Kopi';
  static const String ingredientCatDairy = 'Susu & Dairy';
  static const String ingredientCatSyrup = 'Sirup';
  static const String ingredientCatPackaging = 'Packaging';
  static const String ingredientCatOther = 'Lainnya';

  // === Units ===
  static const String unitGram = 'gram';
  static const String unitMl = 'ml';
  static const String unitPcs = 'pcs';
  static const String unitLiter = 'liter';
  static const String unitKg = 'kg';
}
