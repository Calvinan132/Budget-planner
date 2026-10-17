import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../controllers/auth_controller.dart';
import 'sign_up_screen.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập đầy đủ email và mật khẩu.')),
      );
      return;
    }

    final success = await ref
        .read(authControllerProvider.notifier)
        .signInWithEmail(email, password);

    if (success && mounted) {
      final user = ref.read(authControllerProvider).user;
      if (user?.hasPlan == true) {
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      } else {
        Navigator.pushNamedAndRemoveUntil(context, '/setup', (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 10),
              // Header Icon Pill matching Stitch AI
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.lock_outline_rounded,
                  color: AppColors.primary,
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Chào mừng trở lại',
                style: AppTextStyles.headingLarge(color: AppColors.textPrimary).copyWith(
                  fontSize: 24,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Tiếp tục hành trình tài chính của bạn',
                style: AppTextStyles.bodyMedium(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 28),

              // Form Card matching Stitch AI
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Email',
                      style: AppTextStyles.bodyMedium(color: AppColors.textPrimary).copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        hintText: 'name@example.com',
                        prefixIcon: Icon(Icons.mail_outline_rounded, size: 20, color: AppColors.textMuted),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Mật khẩu',
                      style: AppTextStyles.bodyMedium(color: AppColors.textPrimary).copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        hintText: '••••••••',
                        prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20, color: AppColors.textMuted),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 20,
                            color: AppColors.textMuted,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {},
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Quên mật khẩu?',
                          style: AppTextStyles.bodyMedium(color: AppColors.primaryDark).copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (authState.isLoading)
                      const Center(child: CircularProgressIndicator(color: AppColors.primary))
                    else
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryDark,
                          minimumSize: const Size(double.infinity, 52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: _submit,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Text('Đăng nhập', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward_rounded, size: 20),
                          ],
                        ),
                      ),
                    const SizedBox(height: 20),
                    Row(
                      children: const [
                        Expanded(child: Divider(color: AppColors.borderLight)),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text('hoặc', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                        ),
                        Expanded(child: Divider(color: AppColors.borderLight)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        side: const BorderSide(color: AppColors.borderLight),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () async {
                        final success = await ref
                            .read(authControllerProvider.notifier)
                            .signInWithGoogle();
                        if (success && mounted) {
                          Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
                        }
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.network(
                            'https://upload.wikimedia.org/wikipedia/commons/5/53/Google_%22G%22_Logo.svg',
                            width: 20,
                            height: 20,
                            errorBuilder: (_, __, ___) => const Icon(Icons.g_mobiledata, color: Colors.red),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Đăng nhập bằng Google',
                            style: AppTextStyles.bodyLarge(color: AppColors.textPrimary).copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Chưa có tài khoản? ',
                    style: AppTextStyles.bodyMedium(color: AppColors.textSecondary),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const SignUpScreen()),
                      );
                    },
                    child: Text(
                      'Đăng ký ngay',
                      style: AppTextStyles.bodyMedium(color: AppColors.primaryDark).copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
