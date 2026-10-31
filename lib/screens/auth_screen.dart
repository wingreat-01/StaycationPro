import 'package:flutter/material.dart';

import '../repository.dart';
import '../theme.dart';
import '../widgets.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  bool _isSignUp = false;
  String _role = 'guest';
  bool _busy = false;
  bool _showPassword = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      if (_isSignUp) {
        final res = await supabase.auth.signUp(
          email: _email.text.trim(),
          password: _password.text,
          data: {
            'full_name': _name.text.trim(),
            'phone': _phone.text.trim(),
            'role': _role,
          },
        );
        if (res.session == null) {
          messenger.showSnackBar(
            const SnackBar(
              content: Text(
                'Check your email to confirm your account, then sign in.',
              ),
            ),
          );
          setState(() => _isSignUp = false);
        }
      } else {
        await supabase.auth.signInWithPassword(
          email: _email.text.trim(),
          password: _password.text,
        );
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(errorMessage(e))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            _Hero(),
            Transform.translate(
              offset: const Offset(0, -36),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: AppCard(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              _isSignUp
                                  ? 'Create your account'
                                  : 'Welcome back',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _isSignUp
                                  ? 'Join in less than a minute.'
                                  : 'Sign in to continue.',
                              style: const TextStyle(color: AppColors.muted),
                            ),
                            const SizedBox(height: 20),
                            if (_isSignUp) ...[
                              Row(
                                children: [
                                  Expanded(
                                    child: _RoleOption(
                                      icon: Icons.luggage_rounded,
                                      title: "I'm booking",
                                      subtitle: 'Find & book stays',
                                      selected: _role == 'guest',
                                      onTap: () =>
                                          setState(() => _role = 'guest'),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _RoleOption(
                                      icon: Icons.home_work_rounded,
                                      title: "I'm hosting",
                                      subtitle: 'List my place',
                                      selected: _role == 'owner',
                                      onTap: () =>
                                          setState(() => _role = 'owner'),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _name,
                                decoration: const InputDecoration(
                                  hintText: 'Full name',
                                  prefixIcon: Icon(Icons.person_outline),
                                ),
                                textCapitalization: TextCapitalization.words,
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                    ? 'Enter your name'
                                    : null,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _phone,
                                decoration: const InputDecoration(
                                  hintText: 'Mobile number (09XX XXX XXXX)',
                                  prefixIcon: Icon(Icons.phone_outlined),
                                ),
                                keyboardType: TextInputType.phone,
                              ),
                              const SizedBox(height: 12),
                            ],
                            TextFormField(
                              controller: _email,
                              decoration: const InputDecoration(
                                hintText: 'Email address',
                                prefixIcon: Icon(Icons.mail_outline),
                              ),
                              keyboardType: TextInputType.emailAddress,
                              autofillHints: const [AutofillHints.email],
                              validator: (v) => (v == null || !v.contains('@'))
                                  ? 'Enter a valid email'
                                  : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _password,
                              decoration: InputDecoration(
                                hintText: 'Password',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _showPassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                  ),
                                  onPressed: () => setState(
                                    () => _showPassword = !_showPassword,
                                  ),
                                ),
                              ),
                              obscureText: !_showPassword,
                              onFieldSubmitted: (_) => _submit(),
                              validator: (v) => (v == null || v.length < 6)
                                  ? 'At least 6 characters'
                                  : null,
                            ),
                            const SizedBox(height: 24),
                            FilledButton(
                              onPressed: _busy ? null : _submit,
                              child: _busy
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.4,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      _isSignUp ? 'Create account' : 'Sign in',
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
            Transform.translate(
              offset: const Offset(0, -24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _isSignUp
                        ? 'Already have an account?'
                        : 'New to StaycationPro?',
                    style: const TextStyle(color: AppColors.muted),
                  ),
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => setState(() => _isSignUp = !_isSignUp),
                    child: Text(_isSignUp ? 'Sign in' : 'Create account'),
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

class _Hero extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: brandGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 40, 28, 72),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.beach_access_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'StaycationPro',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Book handpicked staycations across the Philippines '
                    '— or host your own.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withValues(alpha: 0.85),
                      height: 1.4,
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

class _RoleOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _RoleOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.brand.withValues(alpha: 0.08)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.brand : AppColors.line,
            width: selected ? 1.8 : 1.2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: selected ? AppColors.brand : AppColors.muted),
                const Spacer(),
                Icon(
                  selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                  size: 18,
                  color: selected ? AppColors.brand : AppColors.line,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            Text(
              subtitle,
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
