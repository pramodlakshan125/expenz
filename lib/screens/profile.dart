import 'package:expenz/constant/app_icons.dart';
import 'package:expenz/constant/colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  static const _green = Color(0xFF007F61);
  bool _notifications = true;
  bool _saving = false;

  void _message(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _editProfile(User user) async {
    final formKey = GlobalKey<FormState>();
    String name = user.displayName ?? '';
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Personal information'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                initialValue: name,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Full name'),
                onChanged: (value) => name = value,
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter your name'
                    : null,
              ),
              const SizedBox(height: 16),
              Text(
                user.email ?? user.phoneNumber ?? 'No contact information',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, name.trim());
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result == null || !mounted) return;
    setState(() => _saving = true);
    try {
      await user.updateDisplayName(result);
      _message('Profile updated');
    } on FirebaseAuthException {
      _message('Could not update your profile. Please try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _security(User user) async {
    final hasPassword = user.providerData.any(
      (provider) => provider.providerId == 'password',
    );
    final reset = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Account security'),
        content: Text(
          hasPassword
              ? 'Send a password reset link to ${user.email}?'
              : 'Your sign-in provider manages your account password.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (hasPassword && user.email != null)
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Send reset link'),
            ),
        ],
      ),
    );
    if (reset != true || !mounted) return;
    setState(() => _saving = true);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: user.email!);
      _message('Password reset email sent');
    } on FirebaseAuthException {
      _message('Could not send the reset email. Please try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final name = user?.displayName?.trim();
    final displayName = name == null || name.isEmpty ? 'Your profile' : name;
    final initials = name == null || name.isEmpty
        ? '?'
        : name
              .split(RegExp(r'\s+'))
              .take(2)
              .map((part) => part[0])
              .join()
              .toUpperCase();
    final joined = user?.metadata.creationTime;
    return ColoredBox(
      color: const Color(0xFFF5F8F7),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          children: [
            const Text(
              'Profile',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.7,
              ),
            ),
            const SizedBox(height: 22),
            _card(
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: const Color(0xFFE7F4EE),
                      child: Text(
                        initials,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: _green,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            user?.phoneNumber ?? user?.email ?? 'Not signed in',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: user == null || _saving
                          ? null
                          : () => _editProfile(user),
                      child: const Text(
                        'Edit',
                        style: TextStyle(
                          color: _green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _stat(
                    'Member since',
                    joined == null
                        ? '—'
                        : DateFormat('MMM yyyy').format(joined),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(child: _stat('Transactions', '—')),
                const SizedBox(width: 10),
                Expanded(child: _stat('Goals', '—')),
              ],
            ),
            if (_saving)
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: LinearProgressIndicator(color: _green),
              ),
            _heading('ACCOUNT'),
            _card(
              Column(
                children: [
                  _row(
                    Icons.person,
                    'Personal information',
                    onTap: user == null || _saving
                        ? null
                        : () => _editProfile(user),
                  ),
                  _divider(),
                  _row(
                    AppIcons.lock,
                    'Security',
                    value:
                        user?.providerData.any(
                              (provider) => provider.providerId == 'password',
                            ) ==
                            true
                        ? 'Password'
                        : null,
                    onTap: user == null || _saving
                        ? null
                        : () => _security(user),
                  ),
                ],
              ),
            ),
            _heading('PREFERENCES'),
            _card(
              Column(
                children: [
                  _row(
                    AppIcons.bell,
                    'Notifications',
                    trailing: Switch(
                      value: _notifications,
                      activeThumbColor: Colors.white,
                      activeTrackColor: _green,
                      onChanged: (value) {
                        setState(() => _notifications = value);
                      },
                    ),
                  ),
                  _divider(),
                  _row(AppIcons.globe, 'Language', value: 'English'),
                  _divider(),
                  _row(AppIcons.money, 'Currency', value: 'LKR'),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Notifications are a session-only preview. Account statistics will appear when your transactions and goals are connected.',
              style: TextStyle(
                fontSize: 12,
                height: 1.5,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _heading(String title) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 16),
    child: Text(
      title,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Color(0xFF5D6964),
        letterSpacing: 0.4,
      ),
    ),
  );
  Widget _stat(String label, String value) => _card(
    Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ],
      ),
    ),
  );
  Widget _divider() => const Padding(
    padding: EdgeInsets.symmetric(horizontal: 16),
    child: Divider(height: 1, color: Color(0xFFE5EBE8)),
  );
  Widget _card(Widget child) => Material(
    color: Colors.white,
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: const BorderSide(color: Color(0xFFE5EBE8)),
    ),
    child: child,
  );
  Widget _row(
    IconData icon,
    String title, {
    String? value,
    VoidCallback? onTap,
    Widget? trailing,
  }) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
    leading: Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: const Color(0xFFE7F4EE),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 19, color: _green),
    ),
    title: Text(
      title,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
    ),
    onTap: onTap,
    trailing:
        trailing ??
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (value != null)
              Text(
                value,
                style: const TextStyle(fontSize: 13, color: Color(0xFF5D6964)),
              ),
            if (onTap != null) ...[
              const SizedBox(width: 10),
              const Icon(
                AppIcons.chevronRight,
                size: 20,
                color: Color(0xFF5D6964),
              ),
            ],
          ],
        ),
  );
}
