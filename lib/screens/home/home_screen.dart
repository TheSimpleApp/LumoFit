import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fittravel/theme.dart';
import 'package:fittravel/services/services.dart';
import 'package:fittravel/screens/home/widgets/widgets.dart';
import 'package:fittravel/utils/haptic_utils.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<void> _onRefresh() async {
    // Capture service references before async gap
    final userService = context.read<UserService>();
    final activityService = context.read<ActivityService>();
    final gamificationService = context.read<GamificationService>();
    final tripService = context.read<TripService>();

    await HapticUtils.light();

    // Re-initialize services to fetch fresh data from Supabase
    await Future.wait([
      userService.initialize(),
      activityService.initialize(),
      gamificationService.initialize(),
      tripService.initialize(),
    ]);
    await HapticUtils.success();
  }

  @override
  Widget build(BuildContext context) {
    final userService = context.watch<UserService>();
    final user = userService.currentUser;
    final colors = context.colorScheme;
    final textStyles = context.textTheme;

    return Scaffold(
      // Commented out for D2D Con demo - simplified UI
      // floatingActionButton: FloatingActionButton.extended(
      //   heroTag: 'quick_add_fab',
      //   onPressed: () async {
      //     await HapticUtils.light();
      //     await _captureQuickPhoto(context);
      //   },
      //   tooltip: 'Log Activity Photo',
      //   backgroundColor: colors.primary,
      //   foregroundColor: Colors.white,
      //   icon: const Icon(Icons.add_a_photo),
      //   label: const Text('Log Activity'),
      // ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          color: colors.primary,
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

              // Active Trip Card (if any)
              Consumer<TripService>(
                builder: (context, tripService, _) {
                  final activeTrip = tripService.activeTrip;
                  if (activeTrip == null) {
                    return const SliverToBoxAdapter(child: SizedBox.shrink());
                  }

                  final hasImage = activeTrip.imageUrl != null &&
                      activeTrip.imageUrl!.isNotEmpty;

                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      child: Hero(
                        tag: 'trip_image_${activeTrip.id}',
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () => context.push('/trip/${activeTrip.id}'),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              height: 96,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                color: colors.surface,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    // Background image with caching
                                    if (hasImage)
                                      CachedNetworkImage(
                                        imageUrl: activeTrip.imageUrl!,
                                        fit: BoxFit.cover,
                                        color: Colors.black.withValues(alpha: 0.4),
                                        colorBlendMode: BlendMode.darken,
                                        placeholder: (_, __) => Container(
                                          color: colors.surfaceContainerHighest,
                                        ),
                                        errorWidget: (_, __, ___) => Container(
                                          color: colors.surface,
                                        ),
                                      )
                                    else
                                      Container(color: colors.surface),
                                    // Cinematic gradient overlay
                                    if (hasImage)
                                      Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.centerLeft,
                                            end: Alignment.centerRight,
                                            colors: [
                                              Colors.black.withValues(alpha: 0.55),
                                              Colors.black.withValues(alpha: 0.25),
                                              Colors.black.withValues(alpha: 0.45),
                                            ],
                                            stops: const [0.0, 0.5, 1.0],
                                          ),
                                        ),
                                      ),
                                    // Content
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 14),
                                      child: Row(
                                        children: [
                                          // Icon container
                                          Container(
                                            width: 48,
                                            height: 48,
                                            decoration: BoxDecoration(
                                              color: hasImage
                                                  ? Colors.white.withValues(alpha: 0.15)
                                                  : colors.primary.withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(14),
                                              border: hasImage
                                                  ? Border.all(
                                                      color: Colors.white
                                                          .withValues(alpha: 0.1),
                                                      width: 1,
                                                    )
                                                  : null,
                                            ),
                                            child: Icon(
                                              Icons.flight_takeoff_rounded,
                                              color: hasImage
                                                  ? Colors.white
                                                  : colors.primary,
                                              size: 22,
                                            ),
                                          ),
                                          const SizedBox(width: 14),
                                          // Text content
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Row(
                                                  children: [
                                                    Container(
                                                      width: 6,
                                                      height: 6,
                                                      decoration: BoxDecoration(
                                                        color: const Color(0xFF4ADE80),
                                                        shape: BoxShape.circle,
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: const Color(0xFF4ADE80)
                                                                .withValues(alpha: 0.5),
                                                            blurRadius: 4,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Text(
                                                      'Active Trip',
                                                      style: textStyles.labelSmall
                                                          ?.copyWith(
                                                        color: hasImage
                                                            ? Colors.white
                                                                .withValues(alpha: 0.85)
                                                            : colors.primary,
                                                        fontWeight: FontWeight.w600,
                                                        letterSpacing: 0.2,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  activeTrip.destinationCity,
                                                  style: textStyles.titleMedium?.copyWith(
                                                    color: hasImage
                                                        ? Colors.white
                                                        : colors.onSurface,
                                                    fontWeight: FontWeight.bold,
                                                    letterSpacing: -0.3,
                                                  ),
                                                ),
                                                if (activeTrip.destinationCountry != null)
                                                  Text(
                                                    activeTrip.destinationCountry!,
                                                    style: textStyles.bodySmall?.copyWith(
                                                      color: hasImage
                                                          ? Colors.white
                                                              .withValues(alpha: 0.7)
                                                          : colors.onSurfaceVariant,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                          // Arrow
                                          Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: hasImage
                                                  ? Colors.white.withValues(alpha: 0.1)
                                                  : colors.primary.withValues(alpha: 0.1),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              Icons.arrow_forward_ios_rounded,
                                              color: hasImage
                                                  ? Colors.white.withValues(alpha: 0.7)
                                                  : colors.primary.withValues(alpha: 0.6),
                                              size: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      )
                          .animate()
                          .fadeIn(delay: 50.ms)
                          .slideY(begin: 0.1, delay: 50.ms),
                    ),
                  );
                },
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

              // Fitness Guide Card
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: InkWell(
                    onTap: () {
                      context.push('/fitness-guide');
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: AppColors.goldPremium,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.goldDark.withValues(alpha: 0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.psychology,
                              color: Colors.black87,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Fitness Guide',
                                  style: textStyles.titleMedium?.copyWith(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Get AI-powered fitness recommendations',
                                  style: textStyles.bodyMedium?.copyWith(
                                    color: Colors.black.withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.black.withValues(alpha: 0.5),
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

              // Commented out for D2D Con demo - simplified UI
              // Active Challenges
              // SliverToBoxAdapter(
              //   child: Padding(
              //     padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              //     child: const ActiveChallenges()
              //         .animate()
              //         .fadeIn(delay: 400.ms)
              //         .slideY(begin: 0.1, delay: 400.ms),
              //   ),
              // ),

              // Bottom spacer so content doesn't sit under FAB
              const SliverToBoxAdapter(
                child: SizedBox(height: 96),
              ),
            ],
          ),
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
}
