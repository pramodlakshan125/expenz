import 'package:expenz/constant/colors.dart';
import 'package:expenz/constant/app_icons.dart';
import 'package:expenz/auth/login.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:expenz/services/appearance_settings.dart';
import 'package:intl/intl.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  static const _green = AppColors.primary;
  bool _notifications = true;
  bool _saving = false;
  bool _loggingOut = false;

  Future<void> _appearance() async {
    final selected = await showDialog<ThemeMode>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text('Appearance'),
        children: ThemeMode.values
            .map(
              (mode) => SimpleDialogOption(
                onPressed: () => Navigator.pop(context, mode),
                child: Row(
                  children: [
                    Icon(
                      AppearanceSettings.mode.value == mode
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                    ),
                    SizedBox(width: 12),
                    Text(AppearanceSettings.label(mode)),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
    if (selected == null) return;
    try {
      await AppearanceSettings.setMode(selected);
    } catch (error) {
      debugPrint('Could not save appearance: $error');
      _message('Could not save appearance. Please try again.');
    }
  }

  Future<void> _logout() async {
    if (_loggingOut) return;
    final navigator = Navigator.of(context, rootNavigator: true);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _loggingOut = true);
    try {
      await FirebaseAuth.instance.signOut();
      messenger.clearSnackBars();
      // Clear protected routes, including screens pushed outside the auth gate.
      if (navigator.mounted) {
        navigator.pushAndRemoveUntil(
          MaterialPageRoute<void>(builder: (_) => LogIn()),
          (_) => false,
        );
      }
    } catch (_) {
      _message('Could not log out. Please try again.');
    } finally {
      if (mounted) setState(() => _loggingOut = false);
    }
  }

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
        title: Text('Personal information'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                initialValue: name,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(labelText: 'Full name'),
                onChanged: (value) => name = value,
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter your name'
                    : null,
              ),
              SizedBox(height: 16),
              Text(
                user.email ?? user.phoneNumber ?? 'No contact information',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, name.trim());
              }
            },
            child: Text('Save'),
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
        title: Text('Account security'),
        content: Text(
          hasPassword
              ? 'Send a password reset link to ${user.email}?'
              : 'Your sign-in provider manages your account password.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
          if (hasPassword && user.email != null)
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Send reset link'),
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
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            Text(
              'Profile',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.7,
              ),
            ),
            SizedBox(height: 22),
            _card(
              Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.divider,
                      child: Text(
                        initials,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: _green,
                        ),
                      ),
                    ),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            user?.phoneNumber ?? user?.email ?? 'Not signed in',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: user == null || _saving
                          ? null
                          : () => _editProfile(user),
                      child: Text(
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
            SizedBox(height: 18),
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
                SizedBox(width: 10),
                Expanded(child: _stat('Transactions', '—')),
                SizedBox(width: 10),
                Expanded(child: _stat('Goals', '—')),
              ],
            ),
            if (_saving)
              Padding(
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
                  _divider(),
                  _row(
                    Icons.brightness_6_outlined,
                    'Appearance',
                    value: AppearanceSettings.label(
                      AppearanceSettings.mode.value,
                    ),
                    onTap: _appearance,
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: user == null || _saving || _loggingOut
                  ? null
                  : _logout,
              icon: _loggingOut
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(AppIcons.logout),
              label: Text(_loggingOut ? 'Logging out…' : 'Log out'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.dangerState,
                side: BorderSide(color: AppColors.divider),
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            SizedBox(height: 14),
            Text(
              'Notifications are a session-only preview. Account statistics will appear when your transactions and goals are connected.',
              style: TextStyle(
                fontSize: 12,
                height: 1.5,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _heading(String title) => Padding(
    padding: EdgeInsets.only(top: 20, bottom: 12),
    child: Text(
      title,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        letterSpacing: 0.4,
      ),
    ),
  );
  Widget _stat(String label, String value) => _card(
    Padding(
      padding: EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ],
      ),
    ),
  );
  Widget _divider() => Padding(
    padding: EdgeInsets.symmetric(horizontal: 16),
    child: Divider(
      height: 1,
      color: Theme.of(context).colorScheme.outlineVariant,
    ),
  );
  Widget _card(Widget child) => Material(
    color: Theme.of(context).colorScheme.surface,
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
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
    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    minTileHeight: 60,
    leading: Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: AppColors.divider,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 19, color: _green),
    ),
    title: Text(
      title,
      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
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
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            if (onTap != null) ...[
              SizedBox(width: 10),
              Icon(
                AppIcons.chevronRight,
                size: 20,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ],
        ),
  );
}
