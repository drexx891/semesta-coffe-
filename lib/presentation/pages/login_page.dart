import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_dimensions.dart';
import '../bloc/auth/auth_bloc.dart';
import '../bloc/auth/auth_event.dart';
import '../bloc/auth/auth_state.dart';
import 'package:lucide_icons/lucide_icons.dart';

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
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primaryDark,
                Color(0xFF4A2500),
                AppColors.primary,
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

                        const SizedBox(height: AppDimensions.spacing24),

                        // === Footer ===
                        Text(
                          'v1.0.0',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.white.withValues(alpha: 0.4),
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
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.accent,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.3),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.coffee_rounded,
            size: 44,
            color: AppColors.white,
          ),
        ),
        const SizedBox(height: AppDimensions.spacing16),
        Text(
          AppStrings.appName,
          style: GoogleFonts.playfairDisplay(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: AppColors.white,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          AppStrings.appTagline,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: AppColors.white.withValues(alpha: 0.6),
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginCard() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacing32),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
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
            Text(
              AppStrings.login,
              style: GoogleFonts.playfairDisplay(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Masukkan akun Anda untuk melanjutkan',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppDimensions.spacing32),

            // === Username ===
            TextFormField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: AppStrings.username,
                prefixIcon: const Icon(LucideIcons.user),
                filled: true,
                fillColor: AppColors.surfaceVariant.withValues(alpha: 0.5),
              ),
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Username wajib diisi';
                }
                return null;
              },
            ),
            const SizedBox(height: AppDimensions.spacing16),

            // === Password ===
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: AppStrings.password,
                prefixIcon: const Icon(LucideIcons.lock_outline_rounded),
                filled: true,
                fillColor: AppColors.surfaceVariant.withValues(alpha: 0.5),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? LucideIcons.eyeOff_rounded : LucideIcons.eye,
                    color: AppColors.textTertiary,
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
            const SizedBox(height: AppDimensions.spacing32),

            // === Login Button ===
            BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                final isLoading = state is AuthLoading;

                return SizedBox(
                  height: AppDimensions.buttonHeightLarge,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryDark,
                      foregroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                      ),
                      elevation: 4,
                      shadowColor: AppColors.primaryDark.withValues(alpha: 0.3),
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
                            AppStrings.loginButton,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                  ),
                );
              },
            ),

            const SizedBox(height: AppDimensions.spacing16),

            // === Default Account Info ===
            Container(
              padding: const EdgeInsets.all(AppDimensions.spacing12),
              decoration: BoxDecoration(
                color: AppColors.infoLight,
                borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                border: Border.all(color: AppColors.info.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.info, size: 18, color: AppColors.info.withValues(alpha: 0.7)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Default: owner / owner123',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.info,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
