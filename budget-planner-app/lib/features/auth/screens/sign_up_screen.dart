import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../controllers/auth_controller.dart';
import 'sign_in_screen.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _agreeTerms = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập đầy đủ thông tin.')),
      );
      return;
    }

    if (!_agreeTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đồng ý với Điều khoản sử dụng.')),
      );
      return;
    }

    final success = await ref
        .read(authControllerProvider.notifier)
        .signUpWithEmail(email, password, name);

    if (success && mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/setup', (route) => false);
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
              // Pill top icon matching Stitch AI
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.person_add_alt_1_rounded,
                  color: AppColors.primary,
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Tạo tài khoản mới',
                style: AppTextStyles.headingLarge(color: AppColors.textPrimary).copyWith(
                  fontSize: 24,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Bắt đầu hành trình tài chính thảnh thơi',
                style: AppTextStyles.bodyMedium(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 28),

              // Form Card matching Stitch AI Right
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
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        hintText: 'Tên hiển thị',
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        hintText: 'Email',
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        hintText: 'Mật khẩu',
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
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Checkbox(
                            value: _agreeTerms,
                            activeColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            onChanged: (val) {
                              setState(() {
                                _agreeTerms = val ?? true;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: AppTextStyles.bodyMedium(color: AppColors.textPrimary).copyWith(fontSize: 12),
                              children: const [
                                TextSpan(text: 'Tôi đồng ý với '),
                                TextSpan(
                                  text: 'Điều khoản sử dụng',
                                  style: TextStyle(color: AppColors.successGreen, fontWeight: FontWeight.w600),
                                ),
                                TextSpan(text: ' và '),
                                TextSpan(
                                  text: 'Chính sách bảo mật',
                                  style: TextStyle(color: AppColors.successGreen, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    if (authState.isLoading)
                      const Center(child: CircularProgressIndicator(color: AppColors.primary))
                    else
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.successGreen,
                          minimumSize: const Size(double.infinity, 52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: _submit,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Text('Đăng ký ngay', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward_rounded, size: 20),
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
                    'Đã có tài khoản? ',
                    style: AppTextStyles.bodyMedium(color: AppColors.textSecondary),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const SignInScreen()),
                      );
                    },
                    child: Text(
                      'Đăng nhập',
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
