import 'package:expenz/constant/colors.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key});

  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  final TextEditingController mailcontroller = TextEditingController();
  final _formkey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    mailcontroller.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (!_formkey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // TODO: Add your reset logic here.
      // Firebase example:
      // await FirebaseAuth.instance
      //     .sendPasswordResetEmail(email: mailcontroller.text.trim());

      await Future.delayed(const Duration(seconds: 1)); // demo delay

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.primary,
          content: Text("Password reset link sent! Check your email."),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text("Something went wrong: $e"),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 20.0,
            ),
            child: Form(
              key: _formkey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20.0),

                  // Header Image (same as login screen)
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        "assets/images/logo.png",
                        height: 180,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 180,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Symbols.account_balance_wallet_rounded,
                            size: 60,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30.0),

                  const Text(
                    "Forgot Password?",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  const Text(
                    "Enter your email address and we'll send you a link to reset your password.",
                    style: TextStyle(
                      fontSize: 15,
                      color: AppColors.textSecondary,
                    ),
                  ),

                  const SizedBox(height: 30.0),

                  // Email Field
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 4.0,
                      horizontal: 20.0,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.cardSurface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: TextFormField(
                      controller: mailcontroller,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please Enter E-mail';
                        }
                        if (!RegExp(
                          r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                        ).hasMatch(value.trim())) {
                          return 'Please Enter a valid E-mail';
                        }
                        return null;
                      },
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: "Email Address",
                        prefixIcon: Icon(
                          Symbols.mail_rounded,
                          color: AppColors.textSecondary,
                        ),
                        hintStyle: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 16.0,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30.0),

                  // Send Reset Link Button
                  GestureDetector(
                    onTap: _isLoading ? null : _resetPassword,
                    child: Container(
                      width: MediaQuery.of(context).size.width,
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: _isLoading
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: AppColors.textOnPrimary,
                                ),
                              )
                            : const Text(
                                "Send Reset Link",
                                style: TextStyle(
                                  color: AppColors.textOnPrimary,
                                  fontSize: 18.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30.0),

                  // Back to Login
                  Center(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Text(
                        "Back to Sign In",
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                        ),
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
}
