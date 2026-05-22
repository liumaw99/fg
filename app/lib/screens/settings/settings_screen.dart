import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_strings.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../router/route_names.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeSettingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.settings)),
      body: ListView(
        children: [
          _SectionHeader(title: AppStrings.appearance),
          _ThemeSelector(
            currentMode: themeMode,
            onChanged: (mode) =>
                ref.read(themeSettingsProvider.notifier).setThemeMode(mode),
          ),
          const Divider(),
          _SectionHeader(title: AppStrings.account),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('个人资料'),
            trailing: const Icon(Icons.chevron_right, size: 20),
            onTap: () => context.push(RouteNames.profile),
          ),
          const Divider(),
          _SectionHeader(title: AppStrings.about),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text(AppStrings.help),
            trailing: const Icon(Icons.chevron_right, size: 20),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text(AppStrings.about),
            trailing: const Text(
              'v1.0.0',
              style: TextStyle(color: Color(0xFF71717A)),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              AppStrings.logout,
              style: TextStyle(color: Colors.red),
            ),
            onTap: () => _showLogoutDialog(context, ref),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.logout),
        content: const Text(AppStrings.logoutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(authProvider).logout();
              if (context.mounted) {
                context.go(RouteNames.login);
              }
            },
            child: const Text(
              AppStrings.logout,
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

class _ThemeSelector extends StatelessWidget {
  final ThemeMode currentMode;
  final ValueChanged<ThemeMode> onChanged;

  const _ThemeSelector({required this.currentMode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ThemeOption(
          title: AppStrings.lightMode,
          icon: Icons.light_mode_outlined,
          isSelected: currentMode == ThemeMode.light,
          onTap: () => onChanged(ThemeMode.light),
        ),
        _ThemeOption(
          title: AppStrings.darkMode,
          icon: Icons.dark_mode_outlined,
          isSelected: currentMode == ThemeMode.dark,
          onTap: () => onChanged(ThemeMode.dark),
        ),
        _ThemeOption(
          title: AppStrings.systemDefault,
          icon: Icons.settings_suggest_outlined,
          isSelected: currentMode == ThemeMode.system,
          onTap: () => onChanged(ThemeMode.system),
        ),
      ],
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: isSelected
          ? Icon(
              Icons.check_circle,
              color: Theme.of(context).colorScheme.primary,
            )
          : const Icon(Icons.circle_outlined, color: Color(0xFF71717A)),
      onTap: onTap,
    );
  }
}
