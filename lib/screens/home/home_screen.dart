import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fittravel/theme.dart';
import 'package:fittravel/services/services.dart';
import 'package:fittravel/screens/home/widgets/widgets.dart';
import 'package:fittravel/utils/haptic_utils.dart';
import 'package:image_picker/image_picker.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userService = context.watch<UserService>();
    final user = userService.currentUser;
    final colors = context.colorScheme;
    final textStyles = context.textTheme;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        heroTag: 'quick_add_fab',
        onPressed: () async {
          await HapticUtils.light();
          await _captureQuickPhoto(context);
        },
        tooltip: 'Quick Capture',
        backgroundColor: colors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.camera_alt_outlined),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.15), width: 1),
        ),
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getGreeting(),
                            style: textStyles.bodyMedium?.withColor(
                              colors.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user?.displayName ?? 'Traveler',
                            style: textStyles.headlineMedium,
                          ),
                        ],
                      ),
                    ),
                    // Level badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: AppColors.goldShimmer,
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Lv ${user?.level ?? 1}',
                            style: textStyles.labelMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 200.ms).scale(delay: 200.ms),
                  ],
                ),
              ),
            ),

            // Streak Card
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: const StreakCard()
                    .animate()
                    .fadeIn(delay: 100.ms)
                    .slideY(begin: 0.1, delay: 100.ms),
              ),
            ),

            // Quick Actions
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: const QuickActions()
                    .animate()
                    .fadeIn(delay: 200.ms)
                    .slideY(begin: 0.1, delay: 200.ms),
              ),
            ),

            // Today's Activities
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: const TodayActivities()
                    .animate()
                    .fadeIn(delay: 300.ms)
                    .slideY(begin: 0.1, delay: 300.ms),
              ),
            ),

            // Active Challenges
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                child: const ActiveChallenges()
                    .animate()
                    .fadeIn(delay: 400.ms)
                    .slideY(begin: 0.1, delay: 400.ms),
              ),
            ),

            // Bottom spacer so content doesn't sit under FAB
            const SliverToBoxAdapter(
              child: SizedBox(height: 96),
            ),
          ],
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning 🌅';
    if (hour < 17) return 'Good afternoon ☀️';
    return 'Good evening 🌙';
  }

  Future<void> _captureQuickPhoto(BuildContext context) async {
    try {
      final picker = ImagePicker();
      final XFile? file = await picker.pickImage(source: ImageSource.camera, imageQuality: 85);
      if (file == null) return;
      final bytes = await file.readAsBytes();
      final mime = _inferMimeType(file.name);
      final dataUrl = 'data:$mime;base64,${base64Encode(bytes)}';

      final userId = context.read<UserService>().currentUser?.id;
      await context.read<QuickPhotoService>().addPhotoDataUrl(dataUrl: dataUrl, userId: userId);
      await HapticUtils.success();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved to your gallery. Assign it later from Profile.'), behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e, st) {
      debugPrint('Camera capture failed: $e');
      debugPrint(st.toString());
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to capture photo'), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }
}

class _QuickAddSheet extends StatelessWidget {
  const _QuickAddSheet();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textStyles = Theme.of(context).textTheme;

    final options = [
      ('📸', 'Add Photo', 'Quick capture a moment', AppColors.info),
      ('🏋️', 'Log Workout', 'Record your training', AppColors.primary),
      ('🥗', 'Log Meal', 'Track what you ate', AppColors.success),
      ('📍', 'Add Location', 'Save a new place', AppColors.warning),
    ];

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.outline.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text('Quick Add', style: textStyles.titleLarge),
              const SizedBox(height: 8),
              Text(
                'Quickly capture your activity or discovery',
                style: textStyles.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
              ),
              const SizedBox(height: 20),
              ...options.map((option) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _QuickAddOption(
                  emoji: option.$1,
                  label: option.$2,
                  description: option.$3,
                  color: option.$4,
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${option.$2} - Coming soon!'),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: colors.surfaceContainerHighest,
                      ),
                    );
                  },
                ),
              )),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAddOption extends StatelessWidget {
  final String emoji;
  final String label;
  final String description;
  final Color color;
  final VoidCallback onTap;

  const _QuickAddOption({
    required this.emoji,
    required this.label,
    required this.description,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textStyles = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: textStyles.titleSmall),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: textStyles.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: colors.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

String _inferMimeType(String filename) {
  final lower = filename.toLowerCase();
  if (lower.endsWith('.png')) return 'image/png';
  if (lower.endsWith('.webp')) return 'image/webp';
  if (lower.endsWith('.gif')) return 'image/gif';
  return 'image/jpeg';
}
