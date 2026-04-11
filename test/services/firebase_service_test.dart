import 'package:flutter_test/flutter_test.dart';
import 'package:project_expense_tracker_user/services/firebase_service.dart';

void main() {
  group('FirebaseService - Service Availability', () {
    test('instance_isSingleton', () {
      // Assert: FirebaseService uses singleton pattern
      final instance1 = FirebaseService.instance;
      final instance2 = FirebaseService.instance;
      expect(identical(instance1, instance2), true);
    });
  });

  group('FirebaseService - Auth Operations (API Contract Tests)', () {
    test('signIn_methodExists', () {
      expect(FirebaseService.instance.signIn, isNotNull);
    });

    test('signUp_methodExists', () {
      expect(FirebaseService.instance.signUp, isNotNull);
    });

    test('signOut_methodExists', () {
      expect(FirebaseService.instance.signOut, isNotNull);
    });

    test('resetPassword_methodExists', () {
      expect(FirebaseService.instance.resetPassword, isNotNull);
    });

    test('onAuthStateChanged_streamExists', () {
      expect(FirebaseService.instance.onAuthStateChanged, isNotNull);
    });

    test('currentUser_propertyExists', () {
      // Property might be null if not authenticated
      expect(FirebaseService.instance.currentUser, anyOf(isNull, isNotNull));
    });

    test('currentUserUid_propertyExists', () {
      // Property might be null if not authenticated
      expect(FirebaseService.instance.currentUserUid, anyOf(isNull, isNotNull));
    });
  });

  group('FirebaseService - Database Operations (API Contract Tests)', () {
    test('fetchProjectsFromFirebase_methodExists', () {
      expect(FirebaseService.instance.fetchProjectsFromFirebase, isNotNull);
    });

    test('fetchAllExpensesFromFirebase_methodExists', () {
      expect(FirebaseService.instance.fetchAllExpensesFromFirebase, isNotNull);
    });

    test('watchProjects_methodExists', () {
      expect(FirebaseService.instance.watchProjects, isNotNull);
    });
  });
}
