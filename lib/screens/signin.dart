import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'signup.dart';
import '../blocs/auth/auth_bloc.dart';
import '../theme/app_theme.dart';
import '../blocs/theme/theme_bloc.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _login() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(
      AuthLoginEvent(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 600;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        // AuthWrapper in main.dart handles navigation for Authenticated state.
        // We only need to show error feedback here.
        if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: isDark ? AppTheme.bgBaseDark : const Color(0xFFF5F7FA),
        body: SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: 10,
                right: 10,
                child: BlocBuilder<ThemeBloc, ThemeState>(
                  builder: (context, themeState) {
                    final isDarkTheme = themeState.themeMode == ThemeMode.dark;
                    return IconButton(
                      icon: Icon(
                        isDarkTheme ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                        color: isDarkTheme ? Colors.white : const Color(0xFF374151),
                      ),
                      onPressed: () {
                        context.read<ThemeBloc>().add(ToggleThemeEvent());
                      },
                    );
                  },
                ),
              ),
              Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isWide ? size.width * 0.3 : 24,
                    vertical: 32,
                  ),
                  child: Column(
                    children: [
                      // Logo
                      _buildLogo(isDark),
                      const SizedBox(height: 32),
                      // Card
                      Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.bgCardDark : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isDark ? AppTheme.borderDark : const Color(0xFFE5E7EB)),
                          boxShadow: isDark ? [] : [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Welcome back',
                                  style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: isDark ? Colors.white : const Color(0xFF111827))),
                              const SizedBox(height: 4),
                              Text('Sign in to your ECRAFTZ CRM account',
                                  style: TextStyle(
                                      fontSize: 13, color: isDark ? const Color(0xFF8E9CB8) : const Color(0xFF6B7280))),
                              const SizedBox(height: 24),
                              const _FieldLabel('Email Address'),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _emailCtrl,
                                keyboardType: TextInputType.emailAddress,
                                decoration: _inputDec(
                                    context, 'you@ecraftz.com', Icons.email_outlined),
                                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Email required';
                                  if (!v.contains('@')) return 'Invalid email';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              const _FieldLabel('Password'),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _passCtrl,
                                obscureText: _obscure,
                                decoration: _inputDec(
                                  context,
                                  '••••••••',
                                  Icons.lock_outline_rounded,
                                ).copyWith(
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscure
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: isDark ? Colors.white54 : const Color(0xFF9CA3AF),
                                      size: 18,
                                    ),
                                    onPressed: () =>
                                        setState(() => _obscure = !_obscure),
                                  ),
                                ),
                                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Password required';
                                  if (v.length < 6) return 'Minimum 6 characters';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {},
                                  style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap),
                                  child: const Text('Forgot password?',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF00BCD4),
                                          fontWeight: FontWeight.w600)),
                                ),
                              ),
                              const SizedBox(height: 20),
                              BlocBuilder<AuthBloc, AuthState>(
                                builder: (context, state) {
                                  final loading = state is AuthLoading;
                                  return SizedBox(
                                    width: double.infinity,
                                    height: 48,
                                    child: ElevatedButton(
                                      onPressed: loading ? null : _login,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF00BCD4),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10)),
                                        elevation: 0,
                                      ),
                                      child: loading
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                  color: Colors.white, strokeWidth: 2))
                                          : const Text('Sign In',
                                              style: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w700)),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text("Don't have an account? ",
                                      style: TextStyle(
                                          fontSize: 13, color: isDark ? const Color(0xFF8E9CB8) : const Color(0xFF6B7280))),
                                  GestureDetector(
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) => const RegisterPage()),
                                    ),
                                    child: const Text('Register',
                                        style: TextStyle(
                                            fontSize: 13,
                                            color: Color(0xFF00BCD4),
                                            fontWeight: FontWeight.w700)),
                                  ),
                                ],
                              ),
                            ],
                          ),
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
    );
  }
}

// ─── SHARED WIDGETS ───────────────────────────────────────────────────────────

Widget _buildLogo(bool isDark) {
  return Image.asset(
    isDark ? 'assets/ecraftzlogolight.png' : 'assets/ecraftzlogodark.png',
    height: 55,
    fit: BoxFit.contain,
  );
}

InputDecoration _inputDec(BuildContext context, String hint, IconData icon) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: isDark ? Colors.white38 : const Color(0xFF9CA3AF), fontSize: 13),
    prefixIcon: Icon(icon, size: 18, color: isDark ? Colors.white38 : const Color(0xFF9CA3AF)),
    filled: true,
    fillColor: isDark ? AppTheme.bgBaseDark : const Color(0xFFF9FAFB),
    border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: isDark ? AppTheme.borderDark : const Color(0xFFE5E7EB))),
    enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: isDark ? AppTheme.borderDark : const Color(0xFFE5E7EB))),
    focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: isDark ? AppTheme.primary : const Color(0xFF00BCD4), width: 1.5)),
    errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.red)),
    focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.red, width: 1.5)),
    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
  );
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(text,
        style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : const Color(0xFF374151)));
  }
}