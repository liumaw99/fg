import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_strings.dart';
import '../../providers/user_provider.dart';
import '../../widgets/app_avatar.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $error')),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final updateState = ref.watch(updateProfileProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.editProfile),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: AppButton(
              label: AppStrings.save,
              onPressed: updateState.isLoading ? null : _save,
              isLoading: updateState.isLoading,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Center(
              child: Stack(
                children: [
                  const AppAvatar(
                    fallbackText: 'Me',
                    size: AvatarSize.xl,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            AppTextField(
              controller: _displayNameController,
              label: AppStrings.displayName,
              hint: '你的显示名称',
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 20),
            AppTextField(
              controller: _bioController,
              label: AppStrings.bio,
              hint: '介绍一下你自己',
              maxLines: 3,
              maxLength: 160,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 20),
            AppTextField(
              controller: _locationController,
              label: AppStrings.location,
              hint: '你所在的城市',
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 20),
            AppTextField(
              controller: _websiteController,
              label: AppStrings.website,
              hint: 'https://example.com',
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.done,
            ),
          ],
        ),
      ),
    );
  }
}
