import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../providers/user_provider.dart';
import '../../ui/atoms/app_avatar.dart';
import '../../ui/atoms/app_button.dart';
import '../../ui/atoms/app_text_field.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _displayNameController = TextEditingController();
  final _bioController = TextEditingController();
  final _locationController = TextEditingController();
  final _websiteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  void _loadProfile() {
    final profileAsync = ref.read(profileProvider);
    profileAsync.whenData((user) {
      if (user != null && mounted) {
        _displayNameController.text = user.displayName;
        _bioController.text = user.bio;
        _locationController.text = user.location;
        _websiteController.text = user.website;
      }
    });
  }

  Future<void> _save() async {
    final notifier = ref.read(updateProfileProvider.notifier);
    await notifier.submit(
      displayName: _displayNameController.text.trim(),
      bio: _bioController.text.trim(),
      location: _locationController.text.trim(),
      website: _websiteController.text.trim(),
    );

    if (!mounted) return;

    final state = ref.read(updateProfileProvider);
    state.whenOrNull(
      data: (_) {
        ref.invalidate(profileProvider);
        context.pop();
      },
      error: (error, _) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('保存失败: $error')));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final updateState = ref.watch(updateProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.editProfile),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: AppButton(
              label: AppStrings.save,
              onPressed: updateState.isLoading ? null : _save,
              loading: updateState.isLoading,
              size: AppButtonSize.compact,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          children: [
            Center(
              child: Stack(
                children: [
                  const AppAvatar(fallbackText: 'Me', size: AvatarSize.xl),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: theme.appAccent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: theme.scaffoldBackgroundColor,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.camera_alt,
                        size: 16,
                        color: theme.appAccentText,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            AppTextField(
              controller: _displayNameController,
              label: AppStrings.displayName,
              hint: '你的显示名称',
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              controller: _bioController,
              label: AppStrings.bio,
              hint: '介绍一下你自己',
              maxLines: 3,
              maxLength: 160,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              controller: _locationController,
              label: AppStrings.location,
              hint: '你所在的城市',
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              controller: _websiteController,
              label: AppStrings.website,
              hint: 'https://example.com',
              keyboardType: TextInputType.url,
            ),
          ],
        ),
      ),
    );
  }
}
