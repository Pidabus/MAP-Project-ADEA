import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../repositories/user_repository.dart';
import '../../models/task_model.dart';
import '../../models/goal_model.dart';
import '../../services/task_service.dart';
import '../../services/goal_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_text_field.dart';

/// Profile Screen — User info, edit name/preferences, logout matching Stitch Design
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _userRepo = UserRepository();
  final _taskService = TaskService();
  final _goalService = GoalService();
  final _authService = AuthService();
  bool _notificationsOn = true;
  bool _darkModeOn = false;
  bool _dailySummaryOn = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  void _loadPreferences() {
    final state = context.read<AuthBloc>().state;
    if (state is AuthAuthenticated) {
      _notificationsOn = state.user.preferences['notifications'] ?? true;
      _darkModeOn = state.user.preferences['darkMode'] ?? false;
      _dailySummaryOn = state.user.preferences['dailySummary'] ?? true;
    }
  }

  Future<void> _updatePreference(String key, bool value) async {
    final state = context.read<AuthBloc>().state;
    if (state is! AuthAuthenticated) return;

    try {
      await _userRepo.updateUser(state.user.uid, {
        'preferences': {
          'notifications': key == 'notifications' ? value : _notificationsOn,
          'darkMode': key == 'darkMode' ? value : _darkModeOn,
          'dailySummary': key == 'dailySummary' ? value : _dailySummaryOn,
        }
      });
      if (mounted) {
        context.read<AuthBloc>().add(AuthCheckRequested());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update preference: $e')));
      }
    }
  }

  Future<void> _saveDisplayName(String newName) async {
    final state = context.read<AuthBloc>().state;
    if (state is! AuthAuthenticated) return;

    try {
      await _userRepo.updateUser(state.user.uid, {'name': newName});
      await _authService.updateDisplayName(newName);
      if (!mounted) return;
      context.read<AuthBloc>().add(AuthCheckRequested());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile: $e')),
      );
    }
  }

  void _showEditProfileDialog(String currentName) {
    final nameController = TextEditingController(text: currentName);
    final formKey = GlobalKey<FormState>();
    var isSaving = false;

    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.w700)),
            content: Form(
              key: formKey,
              child: CustomTextField(
                controller: nameController,
                label: 'Display name',
                hint: 'Enter your name',
                prefixIcon: Icons.person_outline_rounded,
                textInputAction: TextInputAction.done,
                validator: (value) {
                  if (value == null || value.trim().length < 2) {
                    return 'Name must be at least 2 characters';
                  }
                  return null;
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.pop(dialogContext),
                child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: isSaving
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        setDialogState(() => isSaving = true);
                        final name = nameController.text.trim();
                        if (dialogContext.mounted) Navigator.pop(dialogContext);
                        await _saveDisplayName(name);
                      },
                child: isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Save'),
              ),
            ],
          );
        },
      ),
    ).whenComplete(nameController.dispose);
  }

  Future<void> _sendPasswordReset(String email) async {
    try {
      await _authService.resetPassword(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Password reset link sent to $email'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  void _showChangePasswordDialog(String email) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Change Password', style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text('We’ll send a reset link to $email so you can set a new password.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _sendPasswordReset(email);
            },
            child: const Text('Send link'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Logout', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthBloc>().add(LogoutEvent());
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFba1a1a), foregroundColor: Colors.white, elevation: 0),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final subtextColor = isDark ? const Color(0xFFc2c6d2) : const Color(0xFF424751);
    final cardColor = isDark ? const Color(0xFF1A1A2E) : Colors.white;
    final scaffoldBg = isDark ? const Color(0xFF0F0F1A) : const Color(0xFFf2f3f7);
    final outlineColor = isDark ? const Color(0xFF727782) : const Color(0xFFc2c6d2);
    final primaryContainer = const Color(0xFF185FA5);

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is! AuthAuthenticated) {
          return Scaffold(backgroundColor: scaffoldBg, body: const Center(child: CircularProgressIndicator(color: Color(0xFF185FA5))));
        }
        final user = state.user;

        return Scaffold(
          backgroundColor: scaffoldBg,
          appBar: AppBar(
            backgroundColor: scaffoldBg,
            elevation: 0,
            title: Text('Profile', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_rounded, color: textColor, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Header Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(top: 24, bottom: 0),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 1))],
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 96, height: 96,
                        decoration: BoxDecoration(color: primaryContainer, shape: BoxShape.circle),
                        child: Center(child: Text(user.initials, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w700))),
                      ),
                      const SizedBox(height: 16),
                      Text(user.name, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: textColor)),
                      const SizedBox(height: 4),
                      Text(user.email, style: TextStyle(fontSize: 14, color: subtextColor)),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () => _showEditProfileDialog(user.name),
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xFFE6F1FB),
                          foregroundColor: const Color(0xFF185FA5),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Edit Profile', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(border: Border(top: BorderSide(color: outlineColor.withOpacity(0.2)))),
                        child: Row(
                          children: [
                            Expanded(
                              child: StreamBuilder<List<TaskModel>>(
                                stream: _taskService.getTasks(),
                                builder: (context, snapshot) {
                                  final count = snapshot.data?.length ?? 0;
                                  return _statItem('$count', 'Tasks', textColor, subtextColor);
                                },
                              ),
                            ),
                            Container(width: 1, height: 40, color: outlineColor.withOpacity(0.2)),
                            Expanded(
                              child: StreamBuilder<List<GoalModel>>(
                                stream: _goalService.getGoals(),
                                builder: (context, snapshot) {
                                  final count = snapshot.data?.length ?? 0;
                                  return _statItem('$count', 'Goals', textColor, subtextColor);
                                },
                              ),
                            ),
                            Container(width: 1, height: 40, color: outlineColor.withOpacity(0.2)),
                            Expanded(child: _statItem('${user.preferences['streak'] ?? 1}', 'Day Streak', textColor, subtextColor)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Account Section
                Text('Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColor)),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 1))]),
                  child: Column(
                    children: [
                      _menuItem('Edit Personal Info', Icons.person_rounded, const Color(0xFF185FA5), const Color(0xFFE6F1FB), textColor, outlineColor, onTap: () => _showEditProfileDialog(user.name)),
                      Divider(height: 1, color: outlineColor.withOpacity(0.2)),
                      _menuItem('Change Password', Icons.lock_rounded, const Color(0xFF185FA5), const Color(0xFFE6F1FB), textColor, outlineColor, onTap: () => _showChangePasswordDialog(user.email)),
                      Divider(height: 1, color: outlineColor.withOpacity(0.2)),
                      _menuItem('Connected Accounts', Icons.link_rounded, const Color(0xFF185FA5), const Color(0xFFE6F1FB), textColor, outlineColor, isLast: true, onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Signed in as ${user.email}'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Preferences Section
                Text('Preferences', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColor)),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 1))]),
                  child: Column(
                    children: [
                      _toggleItem('Push Notifications', Icons.notifications_active_rounded, const Color(0xFF265100), const Color(0xFFEAF3DE), _notificationsOn, (v) {
                        setState(() => _notificationsOn = v);
                        _updatePreference('notifications', v);
                      }, textColor, outlineColor, primaryContainer),
                      Divider(height: 1, color: outlineColor.withOpacity(0.2)),
                      _toggleItem('Daily Summary', Icons.summarize_rounded, const Color(0xFF265100), const Color(0xFFEAF3DE), _dailySummaryOn, (v) {
                        setState(() => _dailySummaryOn = v);
                        _updatePreference('dailySummary', v);
                      }, textColor, outlineColor, primaryContainer),
                      Divider(height: 1, color: outlineColor.withOpacity(0.2)),
                      _toggleItem('Dark Mode', Icons.dark_mode_rounded, const Color(0xFF424751), const Color(0xFFe2e0fc), _darkModeOn, (v) {
                        setState(() => _darkModeOn = v);
                        _updatePreference('darkMode', v);
                      }, textColor, outlineColor, primaryContainer, isLast: true),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Support Section
                Text('Support', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColor)),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 1))]),
                  child: Column(
                    children: [
                      _menuItem('Help Center', Icons.help_rounded, textColor, const Color(0xFFe8e5ff), textColor, outlineColor),
                      Divider(height: 1, color: outlineColor.withOpacity(0.2)),
                      _menuItem('Privacy Policy', Icons.privacy_tip_rounded, textColor, const Color(0xFFe8e5ff), textColor, outlineColor),
                      Divider(height: 1, color: outlineColor.withOpacity(0.2)),
                      _menuItem('Terms of Service', Icons.gavel_rounded, textColor, const Color(0xFFe8e5ff), textColor, outlineColor, isLast: true),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Logout Button
                SizedBox(
                  width: double.infinity, height: 52,
                  child: OutlinedButton(
                    onPressed: _showLogoutDialog,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFba1a1a)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Logout', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFFba1a1a))),
                  ),
                ),
                const SizedBox(height: 16),
                Center(child: Text('AllInOne v1.0.0', style: TextStyle(fontSize: 12, color: subtextColor))),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _statItem(String value, String label, Color textColor, Color subtextColor) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: textColor)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 12, color: subtextColor)),
      ],
    );
  }

  Widget _menuItem(String title, IconData icon, Color iconColor, Color bgIconColor, Color textColor, Color outlineColor, {bool isLast = false, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: isLast ? const BorderRadius.vertical(bottom: Radius.circular(16)) : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: bgIconColor, borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(child: Text(title, style: TextStyle(fontSize: 15, color: textColor))),
            Icon(Icons.chevron_right_rounded, color: outlineColor),
          ],
        ),
      ),
    );
  }

  Widget _toggleItem(String title, IconData icon, Color iconColor, Color bgIconColor, bool value, ValueChanged<bool> onChanged, Color textColor, Color outlineColor, Color activeColor, {bool isLast = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: bgIconColor, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(child: Text(title, style: TextStyle(fontSize: 15, color: textColor))),
          Switch(value: value, onChanged: onChanged, activeThumbColor: activeColor),
        ],
      ),
    );
  }
}
