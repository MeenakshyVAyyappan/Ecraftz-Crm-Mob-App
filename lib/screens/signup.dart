import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'signin.dart';
import 'Super_Admin/teams_screen.dart';
import '../blocs/auth/auth_bloc.dart';
import '../theme/app_theme.dart';
import '../blocs/theme/theme_bloc.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _submitted = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _register() {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final password = _passCtrl.text.trim();
    final confirmPassword = _confirmCtrl.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your full name.'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your email address.'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailRegex.hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid email address.'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your password.'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password must be at least 6 characters.'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (confirmPassword != password) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match.'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(
      AuthRegisterEvent(
        email: email,
        password: password,
        name: name,
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
        if (state is AuthRegistrationSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Registration successful. Please wait for admin approval.'),
              backgroundColor: AppTheme.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
          final name = _nameCtrl.text.trim();
          final email = _emailCtrl.text.trim();
          final newMember = TeamMember(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            name: name,
            email: email,
            role: 'Employee',
            department: 'No Department',
            status: MemberStatus.pending,
            registeredAt: DateTime.now(),
          );
          teamMembers.add(newMember);

          setState(() {
            _submitted = true;
          });
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              action: SnackBarAction(
                label: 'Demo Mode',
                textColor: Colors.white,
                onPressed: () {
                  ScaffoldMessenger.of(context).clearSnackBars();
                  final newMember = TeamMember(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: _nameCtrl.text.trim(),
                    email: _emailCtrl.text.trim(),
                    role: 'Employee',
                    department: 'No Department',
                    status: MemberStatus.pending,
                    registeredAt: DateTime.now(),
                  );
                  teamMembers.add(newMember);
                  setState(() {
                    _submitted = true;
                  });
                },
              ),
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
                      _buildLogo(isDark),
                      const SizedBox(height: 32),
                      if (_submitted)
                        _buildSuccessCard(isDark)
                      else
                        _buildForm(isDark),
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

  Widget _buildSuccessCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.bgCardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppTheme.borderDark : const Color(0xFFE5E7EB)),
        boxShadow: isDark ? [] : [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_outline_rounded,
                color: Color(0xFF10B981), size: 36),
          ),
          const SizedBox(height: 16),
          Text('Registration Submitted!',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF111827))),
          const SizedBox(height: 8),
          Text(
              'Your account is pending admin approval.\nYou\'ll be notified once approved.',
              style: TextStyle(
                  fontSize: 13,
                  color: isDark ? const Color(0xFF8E9CB8) : const Color(0xFF6B7280),
                  height: 1.5),
              textAlign: TextAlign.center),
          const SizedBox(height: 20),
          // Info box
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2C1E0A) : const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: isDark ? const Color(0xFF633B00) : const Color(0xFFF59E0B).withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.access_time_rounded,
                    size: 16, color: Color(0xFFF59E0B)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                      'Your registration will appear as PENDING in the Teams page until an admin approves it.',
                      style: TextStyle(
                          fontSize: 11,
                          color: isDark ? const Color(0xFFFFD18A) : const Color(0xFF92400E),
                          height: 1.4)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00BCD4),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: const Text('Go to Login',
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.bgCardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppTheme.borderDark : const Color(0xFFE5E7EB)),
        boxShadow: isDark ? [] : [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Create Account',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF111827))),
            const SizedBox(height: 4),
            Text('Register to access the ECRAFTZ CRM platform',
                style: TextStyle(fontSize: 13, color: isDark ? const Color(0xFF8E9CB8) : const Color(0xFF6B7280))),
            const SizedBox(height: 6),
            // Pending notice
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2C1E0A) : const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: isDark ? const Color(0xFF633B00) : const Color(0xFFF59E0B).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      size: 14, color: Color(0xFFF59E0B)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                        'New accounts require admin approval before access.',
                        style: TextStyle(
                            fontSize: 11, color: isDark ? const Color(0xFFFFD18A) : const Color(0xFF92400E))),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const _FieldLabel('Full Name'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _nameCtrl,
              decoration:
                  _inputDec(context, 'John Doe', Icons.person_outline_rounded),
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Please enter your full name.' : null,
            ),
            const SizedBox(height: 14),
            const _FieldLabel('Email Address'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration:
                  _inputDec(context, 'you@company.com', Icons.email_outlined),
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Please enter your email address.';
                if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(v.trim())) return 'Please enter a valid email address.';
                return null;
              },
            ),
            const SizedBox(height: 14),
            const _FieldLabel('Password'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _passCtrl,
              obscureText: _obscurePass,
              decoration: _inputDec(context, '••••••••', Icons.lock_outline_rounded)
                  .copyWith(
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePass
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 18,
                    color: isDark ? Colors.white54 : const Color(0xFF9CA3AF),
                  ),
                  onPressed: () =>
                      setState(() => _obscurePass = !_obscurePass),
                ),
              ),
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Please enter your password.';
                if (v.trim().length < 6) return 'Password must be at least 6 characters.';
                return null;
              },
            ),
            const SizedBox(height: 14),
            const _FieldLabel('Confirm Password'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _confirmCtrl,
              obscureText: _obscureConfirm,
              decoration:
                  _inputDec(context, '••••••••', Icons.lock_outline_rounded)
                      .copyWith(
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirm
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 18,
                    color: isDark ? Colors.white54 : const Color(0xFF9CA3AF),
                  ),
                  onPressed: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Please confirm password';
                if (v.trim() != _passCtrl.text.trim()) return 'Passwords do not match.';
                return null;
              },
            ),
            const SizedBox(height: 24),
            BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                final loading = state is AuthLoading;
                return SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: loading ? null : _register,
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
                        : const Text('Register Account',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w700)),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Already have an account? ',
                    style:
                        TextStyle(fontSize: 13, color: isDark ? const Color(0xFF8E9CB8) : const Color(0xFF6B7280))),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Text('Sign In',
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
    );
  }
}

// ─── PRIVATE HELPERS ─────────────────────────────────────────────────────────

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