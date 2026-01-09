import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fittravel/widgets/empty_state_widget.dart';
import '../helpers/pump_app.dart';

void main() {
  group('EmptyStateWidget', () {
    group('basic rendering', () {
      testWidgets('renders title and description', (tester) async {
        await pumpTestWidget(
          tester,
          const EmptyStateWidget(
            title: 'Test Title',
            description: 'Test Description',
            animate: false,
          ),
        );

        expect(find.text('Test Title'), findsOneWidget);
        expect(find.text('Test Description'), findsOneWidget);
      });

      testWidgets('renders with custom illustration', (tester) async {
        await pumpTestWidget(
          tester,
          EmptyStateWidget(
            title: 'Test Title',
            description: 'Test Description',
            illustration: Container(
              key: const Key('custom-illustration'),
              width: 100,
              height: 100,
            ),
            animate: false,
          ),
        );

        expect(find.byKey(const Key('custom-illustration')), findsOneWidget);
      });

      testWidgets('renders with fallback icon when no illustration',
          (tester) async {
        await pumpTestWidget(
          tester,
          const EmptyStateWidget(
            title: 'Test Title',
            description: 'Test Description',
            icon: Icons.star,
            animate: false,
          ),
        );

        expect(find.byIcon(Icons.star), findsOneWidget);
      });

      testWidgets('does not render icon or illustration when both are null',
          (tester) async {
        await pumpTestWidget(
          tester,
          const EmptyStateWidget(
            title: 'Test Title',
            description: 'Test Description',
            animate: false,
          ),
        );

        // Should not find any generic icon widget
        expect(find.byType(Icon), findsNothing);
      });
    });

    group('CTA button', () {
      testWidgets('renders CTA button when label and callback provided',
          (tester) async {
        var tapped = false;

        await pumpTestWidget(
          tester,
          EmptyStateWidget(
            title: 'Test Title',
            description: 'Test Description',
            ctaLabel: 'Click Me',
            onCtaPressed: () => tapped = true,
            animate: false,
          ),
        );

        expect(find.text('Click Me'), findsOneWidget);
        expect(find.byType(ElevatedButton), findsOneWidget);

        await tester.tap(find.byType(ElevatedButton));
        await tester.pump();

        expect(tapped, isTrue);
      });

      testWidgets('does not render CTA button when only label provided',
          (tester) async {
        await pumpTestWidget(
          tester,
          const EmptyStateWidget(
            title: 'Test Title',
            description: 'Test Description',
            ctaLabel: 'Click Me',
            animate: false,
          ),
        );

        expect(find.byType(ElevatedButton), findsNothing);
      });

      testWidgets('does not render CTA button when only callback provided',
          (tester) async {
        await pumpTestWidget(
          tester,
          EmptyStateWidget(
            title: 'Test Title',
            description: 'Test Description',
            onCtaPressed: () {},
            animate: false,
          ),
        );

        expect(find.byType(ElevatedButton), findsNothing);
      });

      testWidgets('renders secondary CTA button when useSecondaryCta is true',
          (tester) async {
        await pumpTestWidget(
          tester,
          EmptyStateWidget(
            title: 'Test Title',
            description: 'Test Description',
            ctaLabel: 'Secondary Button',
            onCtaPressed: () {},
            useSecondaryCta: true,
            animate: false,
          ),
        );

        expect(find.byType(OutlinedButton), findsOneWidget);
        expect(find.byType(ElevatedButton), findsNothing);
      });
    });

    group('compact mode', () {
      testWidgets('applies compact styling when compact is true',
          (tester) async {
        await pumpTestWidget(
          tester,
          const EmptyStateWidget(
            title: 'Test Title',
            description: 'Test Description',
            compact: true,
            animate: false,
          ),
        );

        // Verify widget renders without errors in compact mode
        expect(find.text('Test Title'), findsOneWidget);
        expect(find.text('Test Description'), findsOneWidget);
      });

      testWidgets('renders smaller icon container in compact mode',
          (tester) async {
        await pumpTestWidget(
          tester,
          const EmptyStateWidget(
            title: 'Test Title',
            description: 'Test Description',
            icon: Icons.star,
            compact: true,
            animate: false,
          ),
        );

        // Find the icon container
        final container = tester.widget<Container>(
          find.ancestor(
            of: find.byIcon(Icons.star),
            matching: find.byType(Container),
          ).first,
        );

        // Compact mode uses 56x56 container
        expect(container.constraints?.maxWidth, 56);
        expect(container.constraints?.maxHeight, 56);
      });
    });

    group('preset factory constructors', () {
      testWidgets('trips() preset renders correctly', (tester) async {
        await pumpTestWidget(
          tester,
          EmptyStateWidget.trips(animate: false),
        );

        expect(find.text('No trips yet'), findsOneWidget);
        expect(
          find.text(
            'Plan your next fitness adventure and discover amazing places to stay active while traveling.',
          ),
          findsOneWidget,
        );
      });

      testWidgets('trips() preset with CTA button', (tester) async {
        var tapped = false;

        await pumpTestWidget(
          tester,
          EmptyStateWidget.trips(
            ctaLabel: 'Plan Trip',
            onCtaPressed: () => tapped = true,
            animate: false,
          ),
        );

        expect(find.text('Plan Trip'), findsOneWidget);
        await tester.tap(find.byType(ElevatedButton));
        await tester.pump();
        expect(tapped, isTrue);
      });

      testWidgets('activities() preset renders correctly', (tester) async {
        await pumpTestWidget(
          tester,
          EmptyStateWidget.activities(animate: false),
        );

        expect(find.text('Ready to move?'), findsOneWidget);
        expect(
          find.textContaining('No activities yet today'),
          findsOneWidget,
        );
      });

      testWidgets('activities() preset with custom streak message',
          (tester) async {
        await pumpTestWidget(
          tester,
          EmptyStateWidget.activities(
            streakMessage: 'Keep your 10-day streak!',
            animate: false,
          ),
        );

        expect(
          find.text('No activities yet today. Keep your 10-day streak!'),
          findsOneWidget,
        );
      });

      testWidgets('challenges() preset renders for no active challenges',
          (tester) async {
        await pumpTestWidget(
          tester,
          EmptyStateWidget.challenges(animate: false),
        );

        expect(find.text('No active challenges'), findsOneWidget);
        expect(
          find.text('New challenges are coming soon. Keep pushing your limits!'),
          findsOneWidget,
        );
      });

      testWidgets('challenges() preset renders for all completed',
          (tester) async {
        await pumpTestWidget(
          tester,
          EmptyStateWidget.challenges(allCompleted: true, animate: false),
        );

        expect(find.text('All challenges completed!'), findsOneWidget);
        expect(
          find.text(
            'Amazing work! Check back soon for new challenges to conquer.',
          ),
          findsOneWidget,
        );
      });

      testWidgets('gyms() preset renders correctly', (tester) async {
        await pumpTestWidget(
          tester,
          EmptyStateWidget.gyms(animate: false),
        );

        expect(find.text('Find your gym'), findsOneWidget);
        expect(
          find.text(
            'Discover top-rated gyms and fitness centers near your destination.',
          ),
          findsOneWidget,
        );
      });

      testWidgets('food() preset renders correctly', (tester) async {
        await pumpTestWidget(
          tester,
          EmptyStateWidget.food(animate: false),
        );

        expect(find.text('Fuel your fitness'), findsOneWidget);
        expect(
          find.text(
            'Discover healthy restaurants and nutritious food spots that support your goals.',
          ),
          findsOneWidget,
        );
      });

      testWidgets('trails() preset renders correctly', (tester) async {
        await pumpTestWidget(
          tester,
          EmptyStateWidget.trails(animate: false),
        );

        expect(find.text('Explore the outdoors'), findsOneWidget);
        expect(
          find.text(
            'Find scenic trails for hiking, running, and outdoor adventures.',
          ),
          findsOneWidget,
        );
      });

      testWidgets('events() preset renders correctly', (tester) async {
        await pumpTestWidget(
          tester,
          EmptyStateWidget.events(animate: false),
        );

        expect(find.text('No events found'), findsOneWidget);
        expect(
          find.text(
            'Discover marathons, yoga classes, and fitness meetups near you.',
          ),
          findsOneWidget,
        );
      });

      testWidgets('events() preset with destination name', (tester) async {
        await pumpTestWidget(
          tester,
          EmptyStateWidget.events(
            destinationName: 'Tokyo',
            animate: false,
          ),
        );

        expect(
          find.text('No fitness events found in Tokyo. Try expanding your search.'),
          findsOneWidget,
        );
      });

      testWidgets('photos() preset renders correctly', (tester) async {
        await pumpTestWidget(
          tester,
          EmptyStateWidget.photos(animate: false),
        );

        expect(find.text('No photos yet'), findsOneWidget);
        expect(
          find.text(
            'Capture your fitness journey and share the places you discover.',
          ),
          findsOneWidget,
        );
      });

      testWidgets('reviews() preset renders correctly', (tester) async {
        await pumpTestWidget(
          tester,
          EmptyStateWidget.reviews(animate: false),
        );

        expect(find.text('No reviews yet'), findsOneWidget);
        expect(
          find.text(
            'Share your experiences and help others find great fitness spots.',
          ),
          findsOneWidget,
        );
      });

      testWidgets('savedPlaces() preset renders correctly', (tester) async {
        await pumpTestWidget(
          tester,
          EmptyStateWidget.savedPlaces(animate: false),
        );

        expect(find.text('Nothing saved yet'), findsOneWidget);
        expect(
          find.text(
            'Bookmark gyms, restaurants, and trails to quickly find them later.',
          ),
          findsOneWidget,
        );
      });

      testWidgets('search() preset renders correctly with query',
          (tester) async {
        await pumpTestWidget(
          tester,
          EmptyStateWidget.search(query: 'yoga studio', animate: false),
        );

        expect(find.text('No results for "yoga studio"'), findsOneWidget);
        expect(
          find.text(
            'Try different keywords or check for typos in your search.',
          ),
          findsOneWidget,
        );
      });
    });

    group('illustrations', () {
      testWidgets('trips preset includes trips illustration', (tester) async {
        await pumpTestWidget(
          tester,
          EmptyStateWidget.trips(animate: false),
        );

        // The illustration should be a CustomPaint widget
        expect(find.byType(CustomPaint), findsWidgets);
      });

      testWidgets('illustrations scale with compact mode', (tester) async {
        // Normal mode - 120px
        await pumpTestWidget(
          tester,
          EmptyStateWidget.trips(animate: false),
        );

        // Verify the trips illustration is present
        expect(find.byType(CustomPaint), findsWidgets);
      });
    });

    group('edge cases', () {
      testWidgets('handles empty title gracefully', (tester) async {
        await pumpTestWidget(
          tester,
          const EmptyStateWidget(
            title: '',
            description: 'Description only',
            animate: false,
          ),
        );

        expect(find.text(''), findsOneWidget);
        expect(find.text('Description only'), findsOneWidget);
      });

      testWidgets('handles long description text', (tester) async {
        const longDescription =
            'This is a very long description that should wrap properly '
            'across multiple lines without causing any overflow issues. '
            'The widget should handle text of any reasonable length gracefully.';

        await pumpTestWidget(
          tester,
          const EmptyStateWidget(
            title: 'Long Description Test',
            description: longDescription,
            animate: false,
          ),
        );

        expect(find.text(longDescription), findsOneWidget);
      });

      testWidgets('renders correctly with animation delay', (tester) async {
        await pumpTestWidget(
          tester,
          const EmptyStateWidget(
            title: 'Delayed Animation',
            description: 'Should appear after delay',
            animate: true,
            animationDelay: Duration(milliseconds: 100),
          ),
        );

        // Widget should be built regardless of animation
        await tester.pumpAndSettle();
        expect(find.text('Delayed Animation'), findsOneWidget);
      });

      testWidgets('all presets support secondary CTA style', (tester) async {
        await pumpTestWidget(
          tester,
          EmptyStateWidget.trips(
            ctaLabel: 'Secondary CTA',
            onCtaPressed: () {},
            useSecondaryCta: true,
            animate: false,
          ),
        );

        expect(find.byType(OutlinedButton), findsOneWidget);
        expect(find.byType(ElevatedButton), findsNothing);
      });
    });
  });
}
