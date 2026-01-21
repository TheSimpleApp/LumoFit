import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fittravel/models/user_model.dart';
import 'package:fittravel/services/user_service.dart';
import 'package:fittravel/supabase/supabase_config.dart';
import 'package:fittravel/theme.dart';

/// Edit Profile screen for updating user details
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _imagePicker = ImagePicker();
  late TextEditingController _displayNameController;
  late TextEditingController _homeCityController;
  late FitnessLevel _fitnessLevel;
  bool _isSaving = false;
  bool _isUploadingPhoto = false;
  String? _newAvatarUrl;

  @override
  void initState() {
    super.initState();
    final user = context.read<UserService>().currentUser;
    _displayNameController =
        TextEditingController(text: user?.displayName ?? '');
    _homeCityController = TextEditingController(text: user?.homeCity ?? '');
    _fitnessLevel = user?.fitnessLevel ?? FitnessLevel.beginner;
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _homeCityController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadPhoto() async {
    // Capture context-dependent values before async operations
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final userService = context.read<UserService>();
    final user = userService.currentUser;
    if (user == null) return;

    // Show picker source dialog
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null || !mounted) return;

    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (pickedFile == null || !mounted) return;

      setState(() => _isUploadingPhoto = true);

      final fileExt = pickedFile.path.split('.').last;
      final fileName = '${user.id}/avatar.$fileExt';
      final bytes = await pickedFile.readAsBytes();

      // Upload to Supabase Storage
      await SupabaseConfig.client.storage
          .from('avatars')
          .uploadBinary(
            fileName,
            bytes,
            fileOptions: const FileOptions(upsert: true),
          );

      // Get the public URL
      final publicUrl = SupabaseConfig.client.storage
          .from('avatars')
          .getPublicUrl(fileName);

      setState(() {
        _newAvatarUrl = publicUrl;
        _isUploadingPhoto = false;
      });
    } catch (e) {
      debugPrint('Error uploading photo: $e');
      setState(() => _isUploadingPhoto = false);
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Failed to upload photo: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final userService = context.read<UserService>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);

    try {
      final currentUser = userService.currentUser;
      if (currentUser == null) return;

      final updatedUser = currentUser.copyWith(
        displayName: _displayNameController.text.trim(),
        homeCity: _homeCityController.text.trim().isEmpty
            ? null
            : _homeCityController.text.trim(),
        fitnessLevel: _fitnessLevel,
        avatarUrl: _newAvatarUrl ?? currentUser.avatarUrl,
      );

      await userService.updateUser(updatedUser);

      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      router.pop();
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Failed to update profile: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textStyles = Theme.of(context).textTheme;
    final user = context.watch<UserService>().currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        centerTitle: false,
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveProfile,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    'Save',
                    style: TextStyle(
                      color: colors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Avatar
                Center(
                  child: GestureDetector(
                    onTap: _isUploadingPhoto ? null : _pickAndUploadPhoto,
                    child: Stack(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            gradient: AppColors.goldShimmer,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: colors.outline.withValues(alpha: 0.3),
                              width: 3,
                            ),
                          ),
                          child: ClipOval(
                            child: _buildAvatarContent(user, textStyles),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: colors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: colors.surface,
                                width: 2,
                              ),
                            ),
                            child: _isUploadingPhoto
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(
                                    Icons.camera_alt,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Tap to change photo',
                    style: textStyles.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Display Name
                Text(
                  'Display Name',
                  style: textStyles.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _displayNameController,
                  decoration: const InputDecoration(
                    hintText: 'Enter your name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your name';
                    }
                    if (value.trim().length < 2) {
                      return 'Name must be at least 2 characters';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                // Home City
                Text(
                  'Home City',
                  style: textStyles.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _homeCityController,
                  decoration: const InputDecoration(
                    hintText: 'Enter your home city (optional)',
                    prefixIcon: Icon(Icons.location_city_outlined),
                  ),
                ),

                const SizedBox(height: 24),

                // Fitness Level
                Text(
                  'Fitness Level',
                  style: textStyles.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color:
                        colors.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: RadioGroup<FitnessLevel>(
                    groupValue: _fitnessLevel,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _fitnessLevel = value);
                      }
                    },
                    child: Column(
                      children: FitnessLevel.values.map((level) {
                        final isSelected = _fitnessLevel == level;
                        return RadioListTile<FitnessLevel>(
                          title: Text(
                            level.name[0].toUpperCase() +
                                level.name.substring(1),
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                          subtitle: Text(
                            _getFitnessLevelDescription(level),
                            style: textStyles.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                          value: level,
                          activeColor: colors.primary,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Email (read-only)
                Text(
                  'Email',
                  style: textStyles.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: user?.email ?? '',
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.email_outlined),
                    suffixIcon: Icon(
                      Icons.lock_outline,
                      size: 18,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  enabled: false,
                ),
                const SizedBox(height: 4),
                Text(
                  'Email cannot be changed',
                  style: textStyles.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),

                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarContent(UserModel? user, TextTheme textStyles) {
    // Priority: new avatar > existing avatar > initials
    final avatarUrl = _newAvatarUrl ?? user?.avatarUrl;

    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return Image.network(
        avatarUrl,
        width: 100,
        height: 100,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
              strokeWidth: 2,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Center(
            child: Text(
              user?.displayName.isNotEmpty == true
                  ? user!.displayName[0].toUpperCase()
                  : '?',
              style: textStyles.headlineLarge?.copyWith(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        },
      );
    }

    return Center(
      child: Text(
        user?.displayName.isNotEmpty == true
            ? user!.displayName[0].toUpperCase()
            : '?',
        style: textStyles.headlineLarge?.copyWith(
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _getFitnessLevelDescription(FitnessLevel level) {
    switch (level) {
      case FitnessLevel.beginner:
        return 'Just getting started with fitness';
      case FitnessLevel.intermediate:
        return 'Regular workouts, building strength';
      case FitnessLevel.advanced:
        return 'Dedicated athlete, high intensity';
    }
  }
}
