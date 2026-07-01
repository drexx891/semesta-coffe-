import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_dimensions.dart';
import '../bloc/auth/auth_bloc.dart';
import '../bloc/auth/auth_event.dart';
import '../bloc/auth/auth_state.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

/// Halaman Login — tampilan pertama setelah splash
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  late AnimationController _animController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeIn),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(LoginRequested(
        username: _usernameController.text.trim(),
        password: _passwordController.text,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= AppDimensions.tabletBreakpoint;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0804), // Deep dark premium background
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.remainingAttempts != null
                      ? '${state.message}\nSisa percobaan: ${state.remainingAttempts}'
                      : state.message,
                ),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else if (state is AuthLocked) {
            final remaining = state.lockedUntil.difference(DateTime.now()).inMinutes + 1;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Akun terkunci. Coba lagi dalam $remaining menit.'),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 5),
              ),
            );
          }
        },
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.topCenter,
              radius: 1.5,
              colors: [
                Color(0xFF2A1708), // Warmer dark center
                Color(0xFF0F0804), // Almost black edges
              ],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? size.width * 0.25 : AppDimensions.spacing24,
                ),
                child: SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // === Logo Area ===
                        _buildLogo(),
                        const SizedBox(height: AppDimensions.spacing48),

                        // === Login Card ===
                        _buildLoginCard(),

                        const SizedBox(height: AppDimensions.spacing32),

                        // === Footer ===
                        Text(
                          'v1.0.0',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            letterSpacing: 2,
                            color: AppColors.white.withValues(alpha: 0.3),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        // Luxurious logo with golden glow
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.25),
                blurRadius: 40,
                spreadRadius: 5,
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/images/logo.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                // Fallback icon just in case the image fails to load
                return Container(
                  color: AppColors.accent,
                  child: const Icon(Icons.coffee_rounded, size: 44, color: AppColors.white),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: AppDimensions.spacing24),
        Text(
          AppStrings.appName,
          style: GoogleFonts.playfairDisplay(
            fontSize: 32,
            fontWeight: FontWeight.w600,
            color: AppColors.white,
            letterSpacing: 2.0,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          AppStrings.appTagline.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.accent,
            letterSpacing: 4.0,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppDimensions.radiusXLarge),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(AppDimensions.spacing32),
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: 0.05), // Frosted glass effect
            borderRadius: BorderRadius.circular(AppDimensions.radiusXLarge),
            border: Border.all(
              color: AppColors.white.withValues(alpha: 0.1),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Text(
                    AppStrings.login,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 26,
                      fontWeight: FontWeight.w600,
                      color: AppColors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Masukkan akun Anda untuk melanjutkan',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.white.withValues(alpha: 0.6),
                    ),
                  ),
                ),
                const SizedBox(height: AppDimensions.spacing32),

                // === Username ===
                TextFormField(
                  controller: _usernameController,
                  style: const TextStyle(color: AppColors.white),
                  decoration: _buildInputDecoration(
                    label: AppStrings.username,
                    icon: LucideIcons.user,
                  ),
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Username wajib diisi';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppDimensions.spacing20),

                // === Password ===
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: const TextStyle(color: AppColors.white),
                  decoration: _buildInputDecoration(
                    label: AppStrings.password,
                    icon: LucideIcons.lock,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? LucideIcons.eye_off : LucideIcons.eye,
                        color: AppColors.white.withValues(alpha: 0.5),
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      tooltip: _obscurePassword ? AppStrings.showPassword : AppStrings.hidePassword,
                    ),
                  ),
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _login(),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Password wajib diisi';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppDimensions.spacing40),

                // === Login Button ===
                BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    final isLoading = state is AuthLoading;

                    return Container(
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: AppColors.accentGradient,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accent.withValues(alpha: 0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: AppColors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                          ),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                                ),
                              )
                            : Text(
                                AppStrings.loginButton.toUpperCase(),
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 2.0,
                                ),
                              ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: AppDimensions.spacing24),

                // === Default Account Info ===
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.white.withValues(alpha: 0.1)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.info, size: 14, color: AppColors.accent.withValues(alpha: 0.8)),
                        const SizedBox(width: 8),
                        Text(
                          'Default: owner / owner123',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.white.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration({required String label, required IconData icon, Widget? suffixIcon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.inter(color: AppColors.white.withValues(alpha: 0.6)),
      prefixIcon: Icon(icon, color: AppColors.white.withValues(alpha: 0.6), size: 20),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: AppColors.white.withValues(alpha: 0.05), // Very subtle fill
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        borderSide: BorderSide(color: AppColors.white.withValues(alpha: 0.1), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        borderSide: const BorderSide(color: AppColors.accent, width: 1.5), // Golden focus
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        borderSide: BorderSide(color: AppColors.error.withValues(alpha: 0.8), width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
    );
  }

}
