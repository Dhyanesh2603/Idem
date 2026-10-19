import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../core/theme/app_typography.dart';
import '../providers/auth_providers.dart';

class AuthDialog extends ConsumerStatefulWidget {
  const AuthDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (_) => const AuthDialog(),
    );
  }

  @override
  ConsumerState<AuthDialog> createState() => _AuthDialogState();
}

class _AuthDialogState extends ConsumerState<AuthDialog> {
  bool _isRegisterMode = false;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final notifier = ref.read(authNotifierProvider.notifier);

    final success = _isRegisterMode
        ? await notifier.register(email, password)
        : await notifier.login(email, password);

    if (success && mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isRegisterMode
              ? 'Account created and synchronized successfully.'
              : 'Welcome back. Cloud sync active.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 440,
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: context.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.border, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 36,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header with Brand & Close Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: context.accent,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Center(
                            child: Icon(
                              LucideIcons.layers,
                              size: 14,
                              color: ThemeData.estimateBrightnessForColor(context.accent) == Brightness.dark
                                  ? Colors.white
                                  : const Color(0xFF0F1115),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'IDEM CLOUD SYNC',
                          style: AppTypography.titleMedium(context.primaryText).copyWith(
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: Icon(LucideIcons.x, size: 18, color: context.mutedText),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Text(
                  _isRegisterMode ? 'Create Cloud Account' : 'Connect Account',
                  style: AppTypography.titleLarge(context.primaryText),
                ),
                const SizedBox(height: 6),
                Text(
                  'Your workstation operates 100% offline via SQLite. Sign in to seamlessly replicate and synchronize across your mobile and desktop devices.',
                  style: AppTypography.bodySmall(context.mutedText),
                ),
                const SizedBox(height: 20),

                // Tab Switcher
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: context.secondarySurface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: context.border, width: 0.8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            setState(() => _isRegisterMode = false);
                            ref.read(authNotifierProvider.notifier).clearError();
                          },
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: !_isRegisterMode ? context.surface : Colors.transparent,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Center(
                              child: Text(
                                'Sign In',
                                style: AppTypography.labelMedium(
                                  !_isRegisterMode ? context.primaryText : context.mutedText,
                                ).copyWith(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            setState(() => _isRegisterMode = true);
                            ref.read(authNotifierProvider.notifier).clearError();
                          },
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: _isRegisterMode ? context.surface : Colors.transparent,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Center(
                              child: Text(
                                'Register',
                                style: AppTypography.labelMedium(
                                  _isRegisterMode ? context.primaryText : context.mutedText,
                                ).copyWith(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Error Banner
                if (authState.errorMessage != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.4), width: 1),
                    ),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.alertCircle, size: 16, color: Colors.redAccent),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            authState.errorMessage!,
                            style: AppTypography.bodySmall(Colors.redAccent),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Email Field
                Text('EMAIL ADDRESS', style: AppTypography.labelSmall(context.mutedText).copyWith(letterSpacing: 1.1)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _emailController,
                  style: AppTypography.bodyMedium(context.primaryText),
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    prefixIcon: Icon(LucideIcons.mail, size: 16, color: context.mutedText),
                    hintText: 'developer@workstation.io',
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Email is required';
                    if (!val.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Password Field
                Text('PASSWORD', style: AppTypography.labelSmall(context.mutedText).copyWith(letterSpacing: 1.1)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _passwordController,
                  style: AppTypography.bodyMedium(context.primaryText),
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    prefixIcon: Icon(LucideIcons.lock, size: 16, color: context.mutedText),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? LucideIcons.eyeOff : LucideIcons.eye,
                        size: 16,
                        color: context.mutedText,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    hintText: '••••••••••••',
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Password is required';
                    if (val.length < 6) return 'Minimum 6 characters';
                    return null;
                  },
                  onFieldSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 24),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: authState.isLoading ? null : _submit,
                    child: authState.isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                          )
                        : Text(_isRegisterMode ? 'Create Cloud Account' : 'Sign In & Sync'),
                  ),
                ),
                const SizedBox(height: 14),

                // Guest Mode Footer
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Continue in Offline-First Guest Mode',
                      style: AppTypography.bodySmall(context.mutedText),
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
}
