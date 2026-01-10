import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fittravel/screens/home/challenges_screen.dart';
import 'package:fittravel/services/gamification_service.dart';
import 'package:fittravel/models/challenge_model.dart';
import '../helpers/pump_app.dart';

/// Mock GamificationService for testing
class MockGamificationService extends GamificationService {
  final List<ChallengeModel> _mockChallenges;
  final List<UserChallengeModel> _mockUserChallenges;

  MockGamificationService({
    List<ChallengeModel>? challenges,
    List<UserChallengeModel>? userChallenges,
  })  : _mockChallenges = challenges ?? [],
        _mockUserChallenges = userChallenges ?? [];

  @override
  List<ChallengeModel> get allChallenges => _mockChallenges;

  @override
  List<UserChallengeModel> get userChallenges => _mockUserChallenges;

  @override
  ChallengeModel? getChallengeById(String challengeId) {
    try {
      return _mockChallenges.firstWhere((c) => c.id == challengeId);
    } catch (e) {
      return null;
    }
  }
}

/// Test data factory
class TestData {
  static ChallengeModel createChallenge({
    String id = 'challenge-1',
    String title = 'Test Challenge',
    String description = 'Test Description',
    ChallengeType type = ChallengeType.daily,
    int xpReward = 50,
    int requirementValue = 100,
  }) {
    return ChallengeModel(
      id: id,
      title: title,
      description: description,
      type: type,
      xpReward: xpReward,
      requirementType: 'steps',
      requirementValue: requirementValue,
    );
  }

  static UserChallengeModel createUserChallenge({
    String id = 'uc-1',
    String challengeId = 'challenge-1',
    int progress = 50,
    bool isCompleted = false,
    DateTime? completedAt,
  }) {
    return UserChallengeModel(
      id: id,
      odId: 'user-1',
      challengeId: challengeId,
      progress: progress,
      isCompleted: isCompleted,
      completedAt: completedAt,
    );
  }
}

void main() {
  group('ChallengesScreen', () {
    group('tab rendering', () {
      testWidgets('renders Active and Completed tabs', (tester) async {
        final mockService = MockGamificationService();

        await pumpTestWidget(
          tester,
          const ChallengesScreen(),
          gamificationService: mockService,
        );

        expect(find.text('Active (0)'), findsOneWidget);
        expect(find.text('Completed (0)'), findsOneWidget);
      });

      testWidgets('renders correct counts in tab labels', (tester) async {
        final challenges = [
          TestData.createChallenge(id: 'c1', title: 'Challenge 1'),
          TestData.createChallenge(id: 'c2', title: 'Challenge 2'),
          TestData.createChallenge(id: 'c3', title: 'Challenge 3'),
        ];

        final userChallenges = [
          TestData.createUserChallenge(id: 'uc1', challengeId: 'c1', isCompleted: false),
          TestData.createUserChallenge(id: 'uc2', challengeId: 'c2', isCompleted: true),
          TestData.createUserChallenge(id: 'uc3', challengeId: 'c3', isCompleted: true),
        ];

        final mockService = MockGamificationService(
          challenges: challenges,
          userChallenges: userChallenges,
        );

        await pumpTestWidget(
          tester,
          const ChallengesScreen(),
          gamificationService: mockService,
        );

        expect(find.text('Active (1)'), findsOneWidget);
        expect(find.text('Completed (2)'), findsOneWidget);
      });

      testWidgets('renders app bar with Challenges title', (tester) async {
        final mockService = MockGamificationService();

        await pumpTestWidget(
          tester,
          const ChallengesScreen(),
          gamificationService: mockService,
        );

        expect(find.text('Challenges'), findsOneWidget);
      });
    });

    group('active challenges tab', () {
      testWidgets('shows active challenges list', (tester) async {
        final challenges = [
          TestData.createChallenge(id: 'c1', title: 'Daily Steps Goal'),
          TestData.createChallenge(id: 'c2', title: 'Weekly Workout'),
        ];

        final userChallenges = [
          TestData.createUserChallenge(id: 'uc1', challengeId: 'c1', progress: 50),
          TestData.createUserChallenge(id: 'uc2', challengeId: 'c2', progress: 30),
        ];

        final mockService = MockGamificationService(
          challenges: challenges,
          userChallenges: userChallenges,
        );

        await pumpTestWidget(
          tester,
          const ChallengesScreen(),
          gamificationService: mockService,
        );
        await tester.pumpAndSettle();

        expect(find.text('Daily Steps Goal'), findsOneWidget);
        expect(find.text('Weekly Workout'), findsOneWidget);
      });

      testWidgets('shows progress indicator for active challenges', (tester) async {
        final challenges = [
          TestData.createChallenge(id: 'c1', title: 'Test Challenge', requirementValue: 100),
        ];

        final userChallenges = [
          TestData.createUserChallenge(id: 'uc1', challengeId: 'c1', progress: 50),
        ];

        final mockService = MockGamificationService(
          challenges: challenges,
          userChallenges: userChallenges,
        );

        await pumpTestWidget(
          tester,
          const ChallengesScreen(),
          gamificationService: mockService,
        );
        await tester.pumpAndSettle();

        // Check progress indicator is shown
        expect(find.byType(LinearProgressIndicator), findsOneWidget);
        expect(find.text('50/100'), findsOneWidget);
      });

      testWidgets('shows XP reward for active challenges', (tester) async {
        final challenges = [
          TestData.createChallenge(id: 'c1', title: 'Test Challenge', xpReward: 150),
        ];

        final userChallenges = [
          TestData.createUserChallenge(id: 'uc1', challengeId: 'c1', isCompleted: false),
        ];

        final mockService = MockGamificationService(
          challenges: challenges,
          userChallenges: userChallenges,
        );

        await pumpTestWidget(
          tester,
          const ChallengesScreen(),
          gamificationService: mockService,
        );
        await tester.pumpAndSettle();

        expect(find.text('+150'), findsOneWidget);
      });

      testWidgets('shows challenge type label', (tester) async {
        final challenges = [
          TestData.createChallenge(id: 'c1', type: ChallengeType.daily),
          TestData.createChallenge(id: 'c2', type: ChallengeType.weekly),
        ];

        final userChallenges = [
          TestData.createUserChallenge(id: 'uc1', challengeId: 'c1'),
          TestData.createUserChallenge(id: 'uc2', challengeId: 'c2'),
        ];

        final mockService = MockGamificationService(
          challenges: challenges,
          userChallenges: userChallenges,
        );

        await pumpTestWidget(
          tester,
          const ChallengesScreen(),
          gamificationService: mockService,
        );
        await tester.pumpAndSettle();

        expect(find.text('Daily'), findsOneWidget);
        expect(find.text('Weekly'), findsOneWidget);
      });
    });

    group('completed challenges tab', () {
      testWidgets('shows completed challenges when tab is selected', (tester) async {
        final challenges = [
          TestData.createChallenge(id: 'c1', title: 'Completed Challenge'),
        ];

        final userChallenges = [
          TestData.createUserChallenge(
            id: 'uc1',
            challengeId: 'c1',
            progress: 100,
            isCompleted: true,
            completedAt: DateTime.now().subtract(const Duration(days: 1)),
          ),
        ];

        final mockService = MockGamificationService(
          challenges: challenges,
          userChallenges: userChallenges,
        );

        await pumpTestWidget(
          tester,
          const ChallengesScreen(),
          gamificationService: mockService,
        );
        await tester.pumpAndSettle();

        // Tap Completed tab
        await tester.tap(find.text('Completed (1)'));
        await tester.pumpAndSettle();

        expect(find.text('Completed Challenge'), findsOneWidget);
      });

      testWidgets('shows Completed badge for completed challenges', (tester) async {
        final challenges = [
          TestData.createChallenge(id: 'c1', title: 'Done Challenge'),
        ];

        final userChallenges = [
          TestData.createUserChallenge(
            id: 'uc1',
            challengeId: 'c1',
            progress: 100,
            isCompleted: true,
          ),
        ];

        final mockService = MockGamificationService(
          challenges: challenges,
          userChallenges: userChallenges,
        );

        await pumpTestWidget(
          tester,
          const ChallengesScreen(),
          gamificationService: mockService,
        );
        await tester.pumpAndSettle();

        // Tap Completed tab
        await tester.tap(find.text('Completed (1)'));
        await tester.pumpAndSettle();

        expect(find.text('Completed'), findsOneWidget);
      });

      testWidgets('shows completion date for completed challenges', (tester) async {
        final completedAt = DateTime.now().subtract(const Duration(days: 1));

        final challenges = [
          TestData.createChallenge(id: 'c1', title: 'Challenge With Date'),
        ];

        final userChallenges = [
          TestData.createUserChallenge(
            id: 'uc1',
            challengeId: 'c1',
            progress: 100,
            isCompleted: true,
            completedAt: completedAt,
          ),
        ];

        final mockService = MockGamificationService(
          challenges: challenges,
          userChallenges: userChallenges,
        );

        await pumpTestWidget(
          tester,
          const ChallengesScreen(),
          gamificationService: mockService,
        );
        await tester.pumpAndSettle();

        // Tap Completed tab
        await tester.tap(find.text('Completed (1)'));
        await tester.pumpAndSettle();

        expect(find.text('Completed yesterday'), findsOneWidget);
      });

      testWidgets('can navigate directly to completed tab with initialTab', (tester) async {
        final challenges = [
          TestData.createChallenge(id: 'c1', title: 'Completed One'),
        ];

        final userChallenges = [
          TestData.createUserChallenge(
            id: 'uc1',
            challengeId: 'c1',
            isCompleted: true,
          ),
        ];

        final mockService = MockGamificationService(
          challenges: challenges,
          userChallenges: userChallenges,
        );

        await pumpTestWidget(
          tester,
          const ChallengesScreen(initialTab: 1),
          gamificationService: mockService,
        );
        await tester.pumpAndSettle();

        // Should show completed challenge directly without needing to tap
        expect(find.text('Completed One'), findsOneWidget);
      });
    });

    group('empty states', () {
      testWidgets('shows empty state when no active challenges', (tester) async {
        final mockService = MockGamificationService();

        await pumpTestWidget(
          tester,
          const ChallengesScreen(),
          gamificationService: mockService,
        );
        await tester.pumpAndSettle();

        expect(find.text('No active challenges'), findsOneWidget);
      });

      testWidgets('shows View Completed CTA when active is empty but completed exists', (tester) async {
        final challenges = [
          TestData.createChallenge(id: 'c1', title: 'Completed One'),
        ];

        final userChallenges = [
          TestData.createUserChallenge(id: 'uc1', challengeId: 'c1', isCompleted: true),
        ];

        final mockService = MockGamificationService(
          challenges: challenges,
          userChallenges: userChallenges,
        );

        await pumpTestWidget(
          tester,
          const ChallengesScreen(),
          gamificationService: mockService,
        );
        await tester.pumpAndSettle();

        expect(find.text('All challenges completed!'), findsOneWidget);
        expect(find.text('View Completed'), findsOneWidget);
      });

      testWidgets('shows empty state when no completed challenges', (tester) async {
        final challenges = [
          TestData.createChallenge(id: 'c1', title: 'Active One'),
        ];

        final userChallenges = [
          TestData.createUserChallenge(id: 'uc1', challengeId: 'c1', isCompleted: false),
        ];

        final mockService = MockGamificationService(
          challenges: challenges,
          userChallenges: userChallenges,
        );

        await pumpTestWidget(
          tester,
          const ChallengesScreen(initialTab: 1),
          gamificationService: mockService,
        );
        await tester.pumpAndSettle();

        expect(find.text('No completed challenges'), findsOneWidget);
      });

      testWidgets('shows View Active CTA when completed is empty but active exists', (tester) async {
        final challenges = [
          TestData.createChallenge(id: 'c1', title: 'Active One'),
        ];

        final userChallenges = [
          TestData.createUserChallenge(id: 'uc1', challengeId: 'c1', isCompleted: false),
        ];

        final mockService = MockGamificationService(
          challenges: challenges,
          userChallenges: userChallenges,
        );

        await pumpTestWidget(
          tester,
          const ChallengesScreen(initialTab: 1),
          gamificationService: mockService,
        );
        await tester.pumpAndSettle();

        expect(find.text('View Active Challenges'), findsOneWidget);
      });
    });

    group('tab switching', () {
      testWidgets('can switch between Active and Completed tabs', (tester) async {
        final challenges = [
          TestData.createChallenge(id: 'c1', title: 'Active Challenge'),
          TestData.createChallenge(id: 'c2', title: 'Completed Challenge'),
        ];

        final userChallenges = [
          TestData.createUserChallenge(id: 'uc1', challengeId: 'c1', isCompleted: false),
          TestData.createUserChallenge(id: 'uc2', challengeId: 'c2', isCompleted: true),
        ];

        final mockService = MockGamificationService(
          challenges: challenges,
          userChallenges: userChallenges,
        );

        await pumpTestWidget(
          tester,
          const ChallengesScreen(),
          gamificationService: mockService,
        );
        await tester.pumpAndSettle();

        // Active tab should show active challenge
        expect(find.text('Active Challenge'), findsOneWidget);
        expect(find.text('Completed Challenge'), findsNothing);

        // Switch to Completed tab
        await tester.tap(find.text('Completed (1)'));
        await tester.pumpAndSettle();

        // Completed tab should show completed challenge
        expect(find.text('Completed Challenge'), findsOneWidget);
        expect(find.text('Active Challenge'), findsNothing);

        // Switch back to Active tab
        await tester.tap(find.text('Active (1)'));
        await tester.pumpAndSettle();

        // Should show active again
        expect(find.text('Active Challenge'), findsOneWidget);
      });

      testWidgets('View Completed CTA switches to completed tab', (tester) async {
        final challenges = [
          TestData.createChallenge(id: 'c1', title: 'Completed One'),
        ];

        final userChallenges = [
          TestData.createUserChallenge(id: 'uc1', challengeId: 'c1', isCompleted: true),
        ];

        final mockService = MockGamificationService(
          challenges: challenges,
          userChallenges: userChallenges,
        );

        await pumpTestWidget(
          tester,
          const ChallengesScreen(),
          gamificationService: mockService,
        );
        await tester.pumpAndSettle();

        // Tap View Completed button
        await tester.tap(find.text('View Completed'));
        await tester.pumpAndSettle();

        // Should now show the completed challenge
        expect(find.text('Completed One'), findsOneWidget);
      });

      testWidgets('View Active CTA switches to active tab', (tester) async {
        final challenges = [
          TestData.createChallenge(id: 'c1', title: 'Active One'),
        ];

        final userChallenges = [
          TestData.createUserChallenge(id: 'uc1', challengeId: 'c1', isCompleted: false),
        ];

        final mockService = MockGamificationService(
          challenges: challenges,
          userChallenges: userChallenges,
        );

        await pumpTestWidget(
          tester,
          const ChallengesScreen(initialTab: 1),
          gamificationService: mockService,
        );
        await tester.pumpAndSettle();

        // Tap View Active Challenges button
        await tester.tap(find.text('View Active Challenges'));
        await tester.pumpAndSettle();

        // Should now show the active challenge
        expect(find.text('Active One'), findsOneWidget);
      });
    });

    group('edge cases', () {
      testWidgets('handles challenge without matching user challenge', (tester) async {
        final challenges = [
          TestData.createChallenge(id: 'c1', title: 'Orphan Challenge'),
        ];

        // No user challenges - empty list
        final mockService = MockGamificationService(challenges: challenges);

        await pumpTestWidget(
          tester,
          const ChallengesScreen(),
          gamificationService: mockService,
        );
        await tester.pumpAndSettle();

        // Should show empty state since there are no user challenges
        expect(find.text('No active challenges'), findsOneWidget);
      });

      testWidgets('clamps initialTab to valid range', (tester) async {
        final mockService = MockGamificationService();

        // Try initialTab beyond valid range (should clamp to 1)
        await pumpTestWidget(
          tester,
          const ChallengesScreen(initialTab: 5),
          gamificationService: mockService,
        );
        await tester.pumpAndSettle();

        // Should start on completed tab (index 1 after clamping)
        expect(find.text('No completed challenges'), findsOneWidget);
      });

      testWidgets('clamps negative initialTab to 0', (tester) async {
        final mockService = MockGamificationService();

        // Try negative initialTab (should clamp to 0)
        await pumpTestWidget(
          tester,
          const ChallengesScreen(initialTab: -1),
          gamificationService: mockService,
        );
        await tester.pumpAndSettle();

        // Should start on active tab (index 0)
        expect(find.text('No active challenges'), findsOneWidget);
      });
    });
  });
}
