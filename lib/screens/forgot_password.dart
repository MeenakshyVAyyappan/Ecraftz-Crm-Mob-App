import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';

enum ForgotPasswordStep {
  enterEmail,
  enterOtp,
  resetPassword,
}

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  ForgotPasswordStep _currentStep = ForgotPasswordStep.enterEmail;
  bool _loading = false;
  String? _errorMessage;
  bool _obscureNewPass = true;
  bool _obscureConfirmPass = true;

  Timer? _resendTimer;
  int _resendCountdown = 0;

  @override
  void dispose() {
    _resendTimer?.cancel();
    _emailCtrl.dispose();
    _otpCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    setState(() {
      _resendCountdown = 30;
    });
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown == 0) {
        timer.cancel();
      } else {
        setState(() {
          _resendCountdown--;
        });
      }
    });
  }

  Future<void> _sendOtp() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your registered email address.'),
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

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      await SupabaseService.client.auth.signInWithOtp(
        email: email,
        shouldCreateUser: false,
      );
      
      setState(() {
        _currentStep = ForgotPasswordStep.enterOtp;
      });
      _startResendTimer();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('OTP sent successfully to your email.'),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to send OTP. Please try again.';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to send OTP. Please try again.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _resendOtp() async {
    if (_resendCountdown > 0) return;

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final email = _emailCtrl.text.trim();
      await SupabaseService.client.auth.signInWithOtp(
        email: email,
        shouldCreateUser: false,
      );
      _startResendTimer();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('OTP code has been resent to your email.'),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e is AuthException ? e.message : e.toString();
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _otpCtrl.text.trim();
    if (otp.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the verification code.'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (otp.length < 6 || otp.length > 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('OTP must be between 6 and 8 digits.'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final email = _emailCtrl.text.trim();
      final response = await SupabaseService.client.auth.verifyOTP(
        email: email,
        token: otp,
        type: OtpType.email,
      );

      if (response.session == null) {
        throw 'Unable to verify OTP. Verification session could not be established.';
      }

      setState(() {
        _currentStep = ForgotPasswordStep.resetPassword;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('OTP verified successfully.'),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Invalid OTP.';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid OTP.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _resetPassword() async {
    final newPass = _newPassCtrl.text.trim();
    final confirmPass = _confirmPassCtrl.text.trim();

    if (newPass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your password.'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (newPass.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password must be at least 6 characters.'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (confirmPass != newPass) {
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

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      // Update password (user is authenticated at this stage from verifyOTP session)
      await SupabaseService.client.auth.updateUser(
        UserAttributes(password: newPass),
      );

      // Log out to terminate the temporary session
      await SupabaseService.client.auth.signOut();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password updated successfully.'),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context); // Return to Sign In screen
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Password reset failed. Please try again.';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset failed. Please try again.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<bool> _onWillPop() async {
    if (_currentStep == ForgotPasswordStep.enterOtp) {
      setState(() {
        _currentStep = ForgotPasswordStep.enterEmail;
      });
      return false;
    } else if (_currentStep == ForgotPasswordStep.resetPassword) {
      // Clean up the temporary authenticated session
      await SupabaseService.client.auth.signOut();
      setState(() {
        _currentStep = ForgotPasswordStep.enterEmail;
      });
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 600;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: isDark ? AppTheme.bgBaseDark : const Color(0xFFF5F7FA),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_rounded,
              color: isDark ? Colors.white : const Color(0xFF374151),
            ),
            onPressed: () async {
              final shouldPop = await _onWillPop();
              if (shouldPop && mounted) {
                Navigator.pop(context);
              }
            },
          ),
          title: Text(
            'Reset Password',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF111827),
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isWide ? size.width * 0.3 : 24,
                vertical: 16,
              ),
              child: Column(
                children: [
                  // Logo
                  Image.asset(
                    isDark ? 'assets/ecraftzlogolight.png' : 'assets/ecraftzlogodark.png',
                    height: 50,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 24),
                  
                  // Main Card
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.bgCardDark : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? AppTheme.borderDark : const Color(0xFFE5E7EB),
                      ),
                      boxShadow: isDark
                          ? []
                          : [
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
                          // Custom Stepper
                          _buildStepper(context),
                          const SizedBox(height: 28),
                          
                          // Error Banner
                          if (_errorMessage != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 10,
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF2C1619)
                                    : const Color(0xFFFDF2F2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isDark
                                      ? const Color(0xFF7A2021)
                                      : const Color(0xFFF8B4B4),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.error_outline_rounded,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: TextStyle(
                                        color: isDark ? Colors.red[200] : Colors.red[800],
                                        fontSize: 12.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 18),
                          ],
                          
                          // Form Fields based on step
                          if (_currentStep == ForgotPasswordStep.enterEmail)
                            _buildEmailStep(context)
                          else if (_currentStep == ForgotPasswordStep.enterOtp)
                            _buildOtpStep(context)
                          else
                            _buildResetStep(context),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── STEPPER BUILDER ──────────────────────────────────────────────────────────

  Widget _buildStepper(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const activeColor = Color(0xFF00BCD4);
    final inactiveColor =
        isDark ? const Color(0xFF1E2E42) : const Color(0xFFE5E7EB);
    final textActiveColor = isDark ? Colors.white : const Color(0xFF111827);
    final textInactiveColor =
        isDark ? const Color(0xFF8E9CB8) : const Color(0xFF9CA3AF);

    return Row(
      children: [
        _buildStepItem(
          1,
          'Email',
          _currentStep == ForgotPasswordStep.enterEmail,
          _currentStep == ForgotPasswordStep.enterOtp ||
              _currentStep == ForgotPasswordStep.resetPassword,
          activeColor,
          inactiveColor,
          textActiveColor,
          textInactiveColor,
        ),
        _buildStepLine(
          _currentStep == ForgotPasswordStep.enterOtp ||
                  _currentStep == ForgotPasswordStep.resetPassword
              ? activeColor
              : inactiveColor,
        ),
        _buildStepItem(
          2,
          'Verify OTP',
          _currentStep == ForgotPasswordStep.enterOtp,
          _currentStep == ForgotPasswordStep.resetPassword,
          activeColor,
          inactiveColor,
          textActiveColor,
          textInactiveColor,
        ),
        _buildStepLine(
          _currentStep == ForgotPasswordStep.resetPassword
              ? activeColor
              : inactiveColor,
        ),
        _buildStepItem(
          3,
          'New Pass',
          _currentStep == ForgotPasswordStep.resetPassword,
          false,
          activeColor,
          inactiveColor,
          textActiveColor,
          textInactiveColor,
        ),
      ],
    );
  }

  Widget _buildStepItem(
    int num,
    String title,
    bool isActive,
    bool isDone,
    Color activeColor,
    Color inactiveColor,
    Color textActiveColor,
    Color textInactiveColor,
  ) {
    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: isDone
                ? activeColor
                : (isActive ? Colors.transparent : inactiveColor),
            shape: BoxShape.circle,
            border: isActive ? Border.all(color: activeColor, width: 2) : null,
          ),
          child: Center(
            child: isDone
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : Text(
                    '$num',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isActive
                          ? activeColor
                          : (isDone ? Colors.white : Colors.white70),
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isActive || isDone ? FontWeight.bold : FontWeight.normal,
            color: isActive || isDone ? textActiveColor : textInactiveColor,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine(Color color) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Container(
          height: 2,
          color: color,
        ),
      ),
    );
  }

  // ─── STEP WIDGETS ─────────────────────────────────────────────────────────────

  Widget _buildEmailStep(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Forgot Password',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "Enter your registered email address below, and we'll send you an OTP to reset your password.",
          style: TextStyle(
            fontSize: 13,
            color: isDark ? const Color(0xFF8E9CB8) : const Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 24),
        const _FieldLabel('Email Address'),
        const SizedBox(height: 6),
        TextFormField(
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration: _inputDec(context, 'you@ecraftz.com', Icons.email_outlined),
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Please enter your registered email address.';
            if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(v.trim())) return 'Please enter a valid email address.';
            return null;
          },
        ),
        const SizedBox(height: 24),
        _buildActionButton('Send OTP', _sendOtp),
      ],
    );
  }

  Widget _buildOtpStep(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Verification Code',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "We've sent a verification code to ${_emailCtrl.text.trim()}. Please enter it below.",
          style: TextStyle(
            fontSize: 13,
            color: isDark ? const Color(0xFF8E9CB8) : const Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 24),
        const _FieldLabel('OTP Verification Code'),
        const SizedBox(height: 6),
        TextFormField(
          controller: _otpCtrl,
          keyboardType: TextInputType.number,
          maxLength: 8,
          decoration: _inputDec(context, '••••••••', Icons.pin_outlined).copyWith(
            counterText: '',
          ),
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            letterSpacing: 8,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Please enter the verification code.';
            if (v.trim().length < 6 || v.trim().length > 8) return 'OTP must be between 6 and 8 digits.';
            return null;
          },
        ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.center,
          child: TextButton(
            onPressed: _resendCountdown > 0 ? null : _resendOtp,
            child: Text(
              _resendCountdown > 0
                  ? 'Resend code in ${_resendCountdown}s'
                  : 'Resend OTP Code',
              style: TextStyle(
                fontSize: 13,
                color: _resendCountdown > 0
                    ? (isDark ? Colors.white38 : const Color(0xFF9CA3AF))
                    : const Color(0xFF00BCD4),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildActionButton('Verify Code', _verifyOtp),
      ],
    );
  }

  Widget _buildResetStep(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Create New Password',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "Ensure your new password is secure and at least 6 characters long.",
          style: TextStyle(
            fontSize: 13,
            color: isDark ? const Color(0xFF8E9CB8) : const Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 24),
        const _FieldLabel('New Password'),
        const SizedBox(height: 6),
        TextFormField(
          controller: _newPassCtrl,
          obscureText: _obscureNewPass,
          decoration: _inputDec(
            context,
            '••••••••',
            Icons.lock_outline_rounded,
          ).copyWith(
            suffixIcon: IconButton(
              icon: Icon(
                _obscureNewPass
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: isDark ? Colors.white54 : const Color(0xFF9CA3AF),
                size: 18,
              ),
              onPressed: () =>
                  setState(() => _obscureNewPass = !_obscureNewPass),
            ),
          ),
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Please enter your password.';
            if (v.trim().length < 6) return 'Password must be at least 6 characters.';
            return null;
          },
        ),
        const SizedBox(height: 16),
        const _FieldLabel('Confirm Password'),
        const SizedBox(height: 6),
        TextFormField(
          controller: _confirmPassCtrl,
          obscureText: _obscureConfirmPass,
          decoration: _inputDec(
            context,
            '••••••••',
            Icons.lock_outline_rounded,
          ).copyWith(
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPass
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: isDark ? Colors.white54 : const Color(0xFF9CA3AF),
                size: 18,
              ),
              onPressed: () =>
                  setState(() => _obscureConfirmPass = !_obscureConfirmPass),
            ),
          ),
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Please confirm password';
            if (v.trim() != _newPassCtrl.text.trim()) {
              return 'Passwords do not match.';
            }
            return null;
          },
        ),
        const SizedBox(height: 24),
        _buildActionButton('Update Password', _resetPassword),
      ],
    );
  }

  Widget _buildActionButton(String text, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: _loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00BCD4),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 0,
        ),
        child: _loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                text,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }

  InputDecoration _inputDec(BuildContext context, String hint, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: isDark ? Colors.white38 : const Color(0xFF9CA3AF),
        fontSize: 13,
      ),
      prefixIcon: Icon(
        icon,
        size: 18,
        color: isDark ? Colors.white38 : const Color(0xFF9CA3AF),
      ),
      filled: true,
      fillColor: isDark ? AppTheme.bgBaseDark : const Color(0xFFF9FAFB),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: isDark ? AppTheme.borderDark : const Color(0xFFE5E7EB),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: isDark ? AppTheme.borderDark : const Color(0xFFE5E7EB),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: isDark ? AppTheme.primary : const Color(0xFF00BCD4),
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: isDark ? Colors.white70 : const Color(0xFF374151),
      ),
    );
  }
}
