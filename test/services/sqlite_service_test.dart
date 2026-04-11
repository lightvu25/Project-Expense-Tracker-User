import 'package:flutter_test/flutter_test.dart';
import 'package:project_expense_tracker_user/services/sqlite_service.dart';

void main() {
  group('SqliteService - Service Availability', () {
    test('instance_isSingleton', () {
      // Assert: SqliteService uses singleton pattern
      final instance1 = SqliteService.instance;
      final instance2 = SqliteService.instance;
      expect(identical(instance1, instance2), true);
    });

    test('database_propertyExists', () {
      // Assert: Database property is available
      expect(SqliteService.instance.database, isNotNull);
    });

    test('close_methodExists', () {
      // Assert: Close method exists
      expect(SqliteService.instance.close, isNotNull);
    });
  });

  group('SqliteService - CRUD Operations (API Contract Tests)', () {
    test('getAllProjects_methodExists', () {
      expect(SqliteService.instance.getAllProjects, isNotNull);
    });

    test('getProjectById_methodExists', () {
      expect(SqliteService.instance.getProjectById, isNotNull);
    });

    test('insertProject_methodExists', () {
      expect(SqliteService.instance.insertProject, isNotNull);
    });

    test('updateProject_methodExists', () {
      expect(SqliteService.instance.updateProject, isNotNull);
    });

    test('deleteProject_methodExists', () {
      expect(SqliteService.instance.deleteProject, isNotNull);
    });

    test('insertExpense_methodExists', () {
      expect(SqliteService.instance.insertExpense, isNotNull);
    });

    test('getExpensesByProjectId_methodExists', () {
      expect(SqliteService.instance.getExpensesByProjectId, isNotNull);
    });

    test('updateExpense_methodExists', () {
      expect(SqliteService.instance.updateExpense, isNotNull);
    });

    test('deleteExpense_methodExists', () {
      expect(SqliteService.instance.deleteExpense, isNotNull);
    });

    test('addFavorite_methodExists', () {
      expect(SqliteService.instance.addFavorite, isNotNull);
    });

    test('removeFavorite_methodExists', () {
      expect(SqliteService.instance.removeFavorite, isNotNull);
    });

    test('isProjectFavorite_methodExists', () {
      expect(SqliteService.instance.isProjectFavorite, isNotNull);
    });

    test('clearAllData_methodExists', () {
      expect(SqliteService.instance.clearAllData, isNotNull);
    });

    test('insertProjectsBatch_methodExists', () {
      expect(SqliteService.instance.insertProjectsBatch, isNotNull);
    });
  });

  group('SqliteService - Account Operations', () {
    test('saveAccount_methodExists', () {
      expect(SqliteService.instance.saveAccount, isNotNull);
    });

    test('getAccount_methodExists', () {
      expect(SqliteService.instance.getAccount, isNotNull);
    });

    test('deleteAccount_methodExists', () {
      expect(SqliteService.instance.deleteAccount, isNotNull);
    });
  });
}
