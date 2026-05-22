import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';
import '../../router/route_names.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = ref.read(authProvider);
    await auth.login(_emailController.text.trim(), _passwordController.text);

    if (!mounted) return;

    if (auth.isAuthenticated) {
      context.go(RouteNames.home);
    } else if (auth.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error!)),
      );
      auth.clearError();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Spacer(flex: 2),
                      Text(
                        AppStrings.welcomeBack,
                        style: Theme.of(context).textTheme.displaySmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppStrings.signInToContinue,
                        style: TextStyle(
                          fontSize: 16,
                          color: isDark
                              ? const Color(0xFF71717A)
                              : const Color(0xFFA1A1AA),
                        ),
                      ),
                      const SizedBox(height: 48),
                      AppTextField(
                        controller: _emailController,
                        label: AppStrings.email,
                        hint: AppStrings.emailHint,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        prefixIcon: Icons.email_outlined,
                        validator: Validators.email,
                      ),
                      const SizedBox(height: 20),
                      AppTextField(
                        controller: _passwordController,
                        label: AppStrings.password,
                        hint: AppStrings.passwordHint,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        prefixIcon: Icons.lock_outlined,
                        suffixIcon: _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        onSuffixTap: () => setState(
                            () => _obscurePassword = !_obscurePassword),
                        validator: Validators.password,
                        onSubmitted: _login,
                      ),
                      const SizedBox(height: 32),
                      AppButton(
                        label: AppStrings.signIn,
                        onPressed: auth.isLoading ? null : _login,
                        isLoading: auth.isLoading,
                        isFullWidth: true,
                      ),
                      const Spacer(flex: 3),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            AppStrings.noAccount,
                            style: TextStyle(
                              color: isDark
                                  ? const Color(0xFF71717A)
                                  : const Color(0xFFA1A1AA),
                            ),
                          ),
                          TextButton(
                            onPressed: () => context.push(RouteNames.register),
                            child: const Text(AppStrings.signUp),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
