import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
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

            // Cairo Guide Card
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: InkWell(
                  onTap: () {
                    context.push('/cairo-guide');
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [colors.primary, colors.tertiary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.psychology,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ask Cairo Guide',
                                style: textStyles.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Get AI-powered fitness recommendations',
                                style: textStyles.bodyMedium?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.white.withValues(alpha: 0.8),
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(delay: 150.ms)
                    .slideY(begin: 0.1, delay: 150.ms),
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

      await context.read<QuickPhotoService>().addPhotoDataUrl(dataUrl: dataUrl);
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


String _inferMimeType(String filename) {
  final lower = filename.toLowerCase();
  if (lower.endsWith('.png')) return 'image/png';
  if (lower.endsWith('.webp')) return 'image/webp';
  if (lower.endsWith('.gif')) return 'image/gif';
  return 'image/jpeg';
}
