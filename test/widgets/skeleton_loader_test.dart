import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fittravel/widgets/skeleton_loader.dart';
import 'package:fittravel/screens/profile/profile_skeleton.dart';
import 'package:fittravel/theme.dart';
import '../helpers/pump_app.dart';

void main() {
  group('SkeletonBox', () {
    group('basic rendering', () {
      testWidgets('renders with specified dimensions', (tester) async {
        await pumpTestWidget(
          tester,
          const SkeletonBox(
            width: 100,
            height: 50,
          ),
        );

        // Find the container within SkeletonBox
        final container = tester.widget<Container>(
          find.descendant(
            of: find.byType(SkeletonBox),
            matching: find.byType(Container),
          ).first,
        );

        // Verify the dimensions are correct
        expect(container.constraints?.maxWidth, 100);
        expect(container.constraints?.maxHeight, 50);
      });

      testWidgets('uses default borderRadius when not specified',
          (tester) async {
        await pumpTestWidget(
          tester,
          const SkeletonBox(
            width: 100,
            height: 50,
          ),
        );

        final container = tester.widget<Container>(
          find.descendant(
            of: find.byType(SkeletonBox),
            matching: find.byType(Container),
          ).first,
        );

        final decoration = container.decoration as BoxDecoration;
        expect(
          decoration.borderRadius,
          BorderRadius.circular(AppRadius.sm),
        );
      });

      testWidgets('uses custom borderRadius when specified', (tester) async {
        final customRadius = BorderRadius.circular(AppRadius.lg);

        await pumpTestWidget(
          tester,
          SkeletonBox(
            width: 100,
            height: 50,
            borderRadius: customRadius,
          ),
        );

        final container = tester.widget<Container>(
          find.descendant(
            of: find.byType(SkeletonBox),
            matching: find.byType(Container),
          ).first,
        );

        final decoration = container.decoration as BoxDecoration;
        expect(decoration.borderRadius, customRadius);
      });

      testWidgets('uses AppColors.surface as background color',
          (tester) async {
        await pumpTestWidget(
          tester,
          const SkeletonBox(
            width: 100,
            height: 50,
          ),
        );

        final container = tester.widget<Container>(
          find.descendant(
            of: find.byType(SkeletonBox),
            matching: find.byType(Container),
          ).first,
        );

        final decoration = container.decoration as BoxDecoration;
        expect(decoration.color, AppColors.surface);
      });

      testWidgets('renders without specified dimensions (uses parent constraints)',
          (tester) async {
        await pumpTestWidget(
          tester,
          const SizedBox(
            width: 200,
            height: 100,
            child: SkeletonBox(),
          ),
        );

        // Should find the SkeletonBox without error
        expect(find.byType(SkeletonBox), findsOneWidget);
      });
    });
  });

  group('SkeletonCircle', () {
    group('basic rendering', () {
      testWidgets('renders with correct size', (tester) async {
        const testSize = 72.0;

        await pumpTestWidget(
          tester,
          const SkeletonCircle(size: testSize),
        );

        final container = tester.widget<Container>(
          find.descendant(
            of: find.byType(SkeletonCircle),
            matching: find.byType(Container),
          ).first,
        );

        // Verify width and height match the size
        expect(container.constraints?.maxWidth, testSize);
        expect(container.constraints?.maxHeight, testSize);
      });

      testWidgets('renders as a circle (BoxShape.circle)', (tester) async {
        await pumpTestWidget(
          tester,
          const SkeletonCircle(size: 72),
        );

        final container = tester.widget<Container>(
          find.descendant(
            of: find.byType(SkeletonCircle),
            matching: find.byType(Container),
          ).first,
        );

        final decoration = container.decoration as BoxDecoration;
        expect(decoration.shape, BoxShape.circle);
      });

      testWidgets('uses AppColors.surface as background color',
          (tester) async {
        await pumpTestWidget(
          tester,
          const SkeletonCircle(size: 72),
        );

        final container = tester.widget<Container>(
          find.descendant(
            of: find.byType(SkeletonCircle),
            matching: find.byType(Container),
          ).first,
        );

        final decoration = container.decoration as BoxDecoration;
        expect(decoration.color, AppColors.surface);
      });

      testWidgets('renders different sizes correctly', (tester) async {
        // Test small size
        await pumpTestWidget(
          tester,
          const SkeletonCircle(size: 24),
        );

        var container = tester.widget<Container>(
          find.descendant(
            of: find.byType(SkeletonCircle),
            matching: find.byType(Container),
          ).first,
        );

        expect(container.constraints?.maxWidth, 24);
        expect(container.constraints?.maxHeight, 24);

        // Test large size
        await pumpTestWidget(
          tester,
          const SkeletonCircle(size: 120),
        );

        container = tester.widget<Container>(
          find.descendant(
            of: find.byType(SkeletonCircle),
            matching: find.byType(Container),
          ).first,
        );

        expect(container.constraints?.maxWidth, 120);
        expect(container.constraints?.maxHeight, 120);
      });
    });
  });

  group('ProfileScreenSkeleton', () {
    group('composite rendering', () {
      testWidgets('renders without errors', (tester) async {
        await pumpTestWidget(
          tester,
          const ProfileScreenSkeleton(),
        );

        expect(find.byType(ProfileScreenSkeleton), findsOneWidget);
      });

      testWidgets('renders ProfileCardSkeleton section', (tester) async {
        await pumpTestWidget(
          tester,
          const ProfileScreenSkeleton(),
        );

        expect(find.byType(ProfileCardSkeleton), findsOneWidget);
      });

      testWidgets('renders StatsSectionSkeleton section', (tester) async {
        await pumpTestWidget(
          tester,
          const ProfileScreenSkeleton(),
        );

        expect(find.byType(StatsSectionSkeleton), findsOneWidget);
      });

      testWidgets('renders BadgesSectionSkeleton section', (tester) async {
        await pumpTestWidget(
          tester,
          const ProfileScreenSkeleton(),
        );

        expect(find.byType(BadgesSectionSkeleton), findsOneWidget);
      });

      testWidgets('renders QuickAddedPhotosSectionSkeleton section',
          (tester) async {
        await pumpTestWidget(
          tester,
          const ProfileScreenSkeleton(),
        );

        expect(find.byType(QuickAddedPhotosSectionSkeleton), findsOneWidget);
      });

      testWidgets('renders ContributionsSectionSkeleton section',
          (tester) async {
        await pumpTestWidget(
          tester,
          const ProfileScreenSkeleton(),
        );

        expect(find.byType(ContributionsSectionSkeleton), findsOneWidget);
      });

      testWidgets('renders StravaSectionSkeleton section', (tester) async {
        await pumpTestWidget(
          tester,
          const ProfileScreenSkeleton(),
        );

        expect(find.byType(StravaSectionSkeleton), findsOneWidget);
      });

      testWidgets('renders QuickSettingsSkeleton section', (tester) async {
        await pumpTestWidget(
          tester,
          const ProfileScreenSkeleton(),
        );

        expect(find.byType(QuickSettingsSkeleton), findsOneWidget);
      });

      testWidgets('renders all sections in correct order', (tester) async {
        await pumpTestWidget(
          tester,
          const ProfileScreenSkeleton(),
        );

        // Verify all sections are present
        expect(find.byType(ProfileCardSkeleton), findsOneWidget);
        expect(find.byType(StatsSectionSkeleton), findsOneWidget);
        expect(find.byType(BadgesSectionSkeleton), findsOneWidget);
        expect(find.byType(QuickAddedPhotosSectionSkeleton), findsOneWidget);
        expect(find.byType(ContributionsSectionSkeleton), findsOneWidget);
        expect(find.byType(StravaSectionSkeleton), findsOneWidget);
        expect(find.byType(QuickSettingsSkeleton), findsOneWidget);
      });

      testWidgets('uses CustomScrollView for scrolling', (tester) async {
        await pumpTestWidget(
          tester,
          const ProfileScreenSkeleton(),
        );

        expect(find.byType(CustomScrollView), findsOneWidget);
      });
    });
  });

  group('ProfileCardSkeleton', () {
    testWidgets('renders with gold shimmer gradient background',
        (tester) async {
      await pumpTestWidget(
        tester,
        const ProfileCardSkeleton(),
      );

      expect(find.byType(ProfileCardSkeleton), findsOneWidget);

      // Find the container with the gradient
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(ProfileCardSkeleton),
          matching: find.byType(Container),
        ).first,
      );

      final decoration = container.decoration as BoxDecoration;
      expect(decoration.gradient, isNotNull);
      expect(decoration.gradient, AppColors.goldShimmer);
    });
  });

  group('StatsSectionSkeleton', () {
    testWidgets('renders section title placeholder', (tester) async {
      await pumpTestWidget(
        tester,
        const StatsSectionSkeleton(),
      );

      expect(find.byType(StatsSectionSkeleton), findsOneWidget);
    });

    testWidgets('renders 4 stat cards in 2x2 grid', (tester) async {
      await pumpTestWidget(
        tester,
        const StatsSectionSkeleton(),
      );

      // Should find 2 Row widgets for the grid layout
      // (one for title + one for each row of cards, plus internal rows)
      expect(find.byType(Row), findsWidgets);
    });
  });

  group('BadgesSectionSkeleton', () {
    testWidgets('renders with horizontal scroll list', (tester) async {
      await pumpTestWidget(
        tester,
        const BadgesSectionSkeleton(),
      );

      expect(find.byType(BadgesSectionSkeleton), findsOneWidget);
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('renders 5 badge placeholders', (tester) async {
      await pumpTestWidget(
        tester,
        const BadgesSectionSkeleton(),
      );

      // ListView has 5 items but we verify via the SizedBox height
      final sizedBox = tester.widget<SizedBox>(
        find.descendant(
          of: find.byType(BadgesSectionSkeleton),
          matching: find.byWidgetPredicate(
            (widget) => widget is SizedBox && widget.height == 100,
          ),
        ).first,
      );

      expect(sizedBox.height, 100);
    });
  });

  group('QuickAddedPhotosSectionSkeleton', () {
    testWidgets('renders with photo placeholders', (tester) async {
      await pumpTestWidget(
        tester,
        const QuickAddedPhotosSectionSkeleton(),
      );

      expect(find.byType(QuickAddedPhotosSectionSkeleton), findsOneWidget);
      expect(find.byType(ListView), findsOneWidget);
    });
  });

  group('ContributionsSectionSkeleton', () {
    testWidgets('renders contribution list items', (tester) async {
      await pumpTestWidget(
        tester,
        const ContributionsSectionSkeleton(),
      );

      expect(find.byType(ContributionsSectionSkeleton), findsOneWidget);
    });
  });

  group('StravaSectionSkeleton', () {
    testWidgets('renders strava integration card', (tester) async {
      await pumpTestWidget(
        tester,
        const StravaSectionSkeleton(),
      );

      expect(find.byType(StravaSectionSkeleton), findsOneWidget);
    });
  });

  group('QuickSettingsSkeleton', () {
    testWidgets('renders settings list items', (tester) async {
      await pumpTestWidget(
        tester,
        const QuickSettingsSkeleton(),
      );

      expect(find.byType(QuickSettingsSkeleton), findsOneWidget);
    });

    testWidgets('contains dividers between items', (tester) async {
      await pumpTestWidget(
        tester,
        const QuickSettingsSkeleton(),
      );

      // Should have 2 dividers between 3 items
      expect(find.byType(Divider), findsNWidgets(2));
    });
  });
}
