import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:fittravel/models/user_model.dart';
import 'package:fittravel/services/user_service.dart';
import 'package:fittravel/theme.dart';

/// Edit Profile screen for updating user details
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _displayNameController;
  late TextEditingController _homeCityController;
  late FitnessLevel _fitnessLevel;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<UserService>().currentUser;
    _displayNameController = TextEditingController(text: user?.displayName ?? '');
    _homeCityController = TextEditingController(text: user?.homeCity ?? '');
    _fitnessLevel = user?.fitnessLevel ?? FitnessLevel.beginner;
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _homeCityController.dispose();
    super.dispose();
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
                        child: Center(
                          child: Text(
                            user?.displayName.isNotEmpty == true
                                ? user!.displayName[0].toUpperCase()
                                : '?',
                            style: textStyles.headlineLarge?.copyWith(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Profile photo coming soon',
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
                    color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Column(
                    children: FitnessLevel.values.map((level) {
                      final isSelected = _fitnessLevel == level;
                      return RadioListTile<FitnessLevel>(
                        title: Text(
                          level.name[0].toUpperCase() + level.name.substring(1),
                          style: TextStyle(
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                        subtitle: Text(
                          _getFitnessLevelDescription(level),
                          style: textStyles.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                        value: level,
                        groupValue: _fitnessLevel,
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _fitnessLevel = value);
                          }
                        },
                        activeColor: colors.primary,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                      );
                    }).toList(),
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
