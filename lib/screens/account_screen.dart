import 'package:flutter/material.dart';

import '../models.dart';
import '../repository.dart';
import '../theme.dart';
import '../widgets.dart';

class AccountScreen extends StatelessWidget {
  final Profile profile;

  const AccountScreen({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final email = supabase.auth.currentUser?.email ?? '';
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              children: [
                const PageHeader(subtitle: 'Profile', title: 'Account'),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: brandGradient,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        child: Text(
                          initials(profile.fullName),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile.fullName.isEmpty
                                  ? 'StaycationPro user'
                                  : profile.fullName,
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Pill(
                              icon: profile.isOwner
                                  ? Icons.home_work_rounded
                                  : Icons.luggage_rounded,
                              label: profile.isOwner ? 'Host' : 'Guest',
                              color: Colors.white,
                              background: Colors.white.withValues(alpha: 0.2),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                const SectionTitle('Contact details'),
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _InfoRow(
                        icon: Icons.mail_outline_rounded,
                        label: 'Email',
                        value: email,
                      ),
                      const Divider(indent: 64),
                      _InfoRow(
                        icon: Icons.phone_outlined,
                        label: 'Mobile number',
                        value: profile.phone?.isNotEmpty == true
                            ? profile.phone!
                            : 'Not set',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                AppCard(
                  padding: EdgeInsets.zero,
                  onTap: () => supabase.auth.signOut(),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        _IconBox(
                          icon: Icons.logout_rounded,
                          color: theme.colorScheme.error,
                        ),
                        const SizedBox(width: 14),
                        Text(
                          'Sign out',
                          style: TextStyle(
                            color: theme.colorScheme.error,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                const Center(
                  child: Text(
                    'StaycationPro · v1.0',
                    style: TextStyle(color: AppColors.muted, fontSize: 12),
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

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _IconBox(icon: icon, color: AppColors.brand),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IconBox extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _IconBox({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}
