import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Mock classes for testing

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockPostgrestClient extends Mock implements PostgrestClient {}

class MockPostgrestFilterBuilder extends Mock
    implements PostgrestFilterBuilder {}

class MockPostgrestTransformBuilder<T> extends Mock
    implements PostgrestTransformBuilder<T> {}

class MockUser extends Mock implements User {}

class MockSession extends Mock implements Session {}

/// Test utilities

/// Creates a mock Supabase user for testing
MockUser createMockUser({
  String? id,
  String? email,
}) {
  final user = MockUser();
  when(() => user.id).thenReturn(id ?? 'test-user-id');
  when(() => user.email).thenReturn(email ?? 'test@example.com');
  return user;
}

/// Creates a mock Supabase session for testing
MockSession createMockSession({
  String? userId,
  String? userEmail,
}) {
  final session = MockSession();
  final user = createMockUser(id: userId, email: userEmail);
  when(() => session.user).thenReturn(user);
  return session;
}

/// Verifies that a function throws an exception with a specific message
void expectThrowsWithMessage(
  Function() function,
  String expectedMessage,
) {
  expect(
    () => function(),
    throwsA(
      predicate(
        (e) => e.toString().contains(expectedMessage),
      ),
    ),
  );
}

/// Delays execution to allow async operations to complete
Future<void> pumpAndSettle(WidgetTester tester) async {
  await tester.pumpAndSettle(const Duration(milliseconds: 100));
}
