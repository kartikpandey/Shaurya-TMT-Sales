import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../providers/auth_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _obscurePassword = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _error = null;
      _loading = true;
    });
    final error = await ref
        .read(authStateProvider.notifier)
        .login(_identifierController.text, _passwordController.text);
    if (!mounted) return;
    setState(() => _loading = false);
    if (error != null) setState(() => _error = error);
  }

  void _fillDemo(String identifier) {
    setState(() {
      _identifierController.text = identifier;
      _passwordController.text = AppConstants.demoPassword;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _BrandHeader(),
                  const SizedBox(height: 32),

                  Text(
                    'Welcome back',
                    style: AppTextStyles.headlineLarge(context),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Sign in to continue your field day',
                    style: AppTextStyles.bodyMedium(
                      context,
                    ).copyWith(color: AppColors.textHint),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),

                  TextFormField(
                    controller: _identifierController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Email or phone',
                      hintText: 'manager@shaurya.com',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (value) =>
                        (value == null || value.trim().isEmpty)
                        ? 'Enter your email or phone'
                        : null,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      hintText: 'â€¢â€¢â€¢â€¢â€¢â€¢â€¢â€¢',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: 20,
                        ),
                        onPressed: () =>
                            setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    validator: (value) => (value == null || value.isEmpty)
                        ? 'Enter your password'
                        : null,
                  ),

                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.warningRed.withValues(alpha:0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.warningRed.withValues(alpha:0.35),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: AppColors.warningRed,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _error!,
                              style: AppTextStyles.bodySmall(
                                context,
                              ).copyWith(color: AppColors.warningRed),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),
                  CustomButton(
                    label: 'Sign In',
                    isLoading: _loading,
                    onPressed: _submit,
                    icon: Icons.login_rounded,
                  ),
                  const SizedBox(height: 24),

                  _DemoAccountsCard(onSelect: _fillDemo),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: AppColors.premiumGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryOrange.withValues(alpha:0.35),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(Icons.bolt_rounded, size: 44, color: Colors.white),
        ),
        const SizedBox(height: 14),
        Text(
          AppConstants.appName,
          style: AppTextStyles.headlineMedium(context),
        ),
        const SizedBox(height: 4),
        Text(
          AppConstants.appDescription,
          style: AppTextStyles.labelMedium(
            context,
          ).copyWith(color: AppColors.textHint),
        ),
      ],
    );
  }
}

class _DemoAccountsCard extends StatelessWidget {
  const _DemoAccountsCard({required this.onSelect});

  final void Function(String identifier) onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.key_rounded,
                size: 16,
                color: AppColors.primaryOrange,
              ),
              const SizedBox(width: 8),
              Text(
                'Demo accounts',
                style: AppTextStyles.titleMedium(context),
              ),
              const Spacer(),
              Text(
                'Password: ${AppConstants.demoPassword}',
                style: AppTextStyles.labelSmall(
                  context,
                ).copyWith(color: AppColors.textHint),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ..._DemoAccounts.values.map((account) {
            return InkWell(
              onTap: () => onSelect(account.identifier),
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        account.name,
                        style: AppTextStyles.bodySmall(context),
                      ),
                    ),
                    Text(
                      account.role,
                      style: AppTextStyles.labelSmall(
                        context,
                      ).copyWith(color: AppColors.textHint),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 12,
                      color: AppColors.textHint,
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _DemoAccount {
  const _DemoAccount(this.name, this.role, this.identifier);
  final String name;
  final String role;
  final String identifier;
}

class _DemoAccounts {
  static const values = [
    _DemoAccount('Ravi Sharma', 'Sales Manager', 'manager@shaurya.com'),
    _DemoAccount('Anita Verma', 'Team Lead', 'lead@shaurya.com'),
    _DemoAccount('Rahul Mehta', 'Sales Executive', 'exec@shaurya.com'),
  ];
}
