import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/models.dart';

class PersonalExpenseData {
  final List<Expense> expenses;
  final double totalAmount;
  final double pendingAmount;
  final Map<String, double> categoryBreakdown;

  PersonalExpenseData({
    required this.expenses,
    required this.totalAmount,
    required this.pendingAmount,
    required this.categoryBreakdown,
  });

  factory PersonalExpenseData.empty() {
    return PersonalExpenseData(
      expenses: [],
      totalAmount: 0,
      pendingAmount: 0,
      categoryBreakdown: {},
    );
  }
}

class FirebaseService {
  static final FirebaseService instance = FirebaseService._init();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  final StreamController<Account?> _authStateController =
      StreamController<Account?>.broadcast();

  FirebaseService._init();

  Stream<Account?> get onAuthStateChanged => _authStateController.stream;
  User? get currentUser => _auth.currentUser;
  String? get currentUserUid => _auth.currentUser?.uid;

  Future<void> initialize() async {
    _auth.authStateChanges().listen((user) async {
      if (user != null) {
        final snapshot = await _database.ref('users/${user.uid}').get();
        String? displayName = user.displayName;
        String role = 'user';
        if (snapshot.value != null) {
          final userData = Map<String, dynamic>.from(snapshot.value as Map);
          displayName = userData['displayName'] as String? ?? user.displayName;
          role = userData['role'] as String? ?? 'user';
        }
        final account = Account(
          uid: user.uid,
          email: user.email ?? '',
          displayName: displayName,
          role: role,
        );
        _authStateController.add(account);
      } else {
        _authStateController.add(null);
      }
    });
  }

  Future<Account?> signIn(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (credential.user != null) {
        final snapshot = await _database
            .ref('users/${credential.user!.uid}')
            .get();
        String role = 'user';
        if (snapshot.value != null) {
          final userData = Map<String, dynamic>.from(snapshot.value as Map);
          role = userData['role'] as String? ?? 'user';
        }
        return Account(
          uid: credential.user!.uid,
          email: credential.user!.email ?? '',
          displayName: credential.user!.displayName,
          role: role,
        );
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
    return null;
  }

  Future<Account?> signUp(
    String email,
    String password, {
    String? displayName,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (credential.user != null) {
        if (displayName != null) {
          await credential.user!.updateDisplayName(displayName);
        }
        final snapshot = await _database
            .ref('users/${credential.user!.uid}')
            .get();
        String role = 'user';
        if (snapshot.value != null) {
          final userData = Map<String, dynamic>.from(snapshot.value as Map);
          role = userData['role'] as String? ?? 'user';
        }
        return Account(
          uid: credential.user!.uid,
          email: credential.user!.email ?? '',
          displayName: displayName,
          role: role,
        );
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
    return null;
  }

  Future<Account?> registerWithEmail(
    String email,
    String password,
    String name,
  ) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (credential.user != null) {
        final uid = credential.user!.uid;
        await credential.user!.updateDisplayName(name);
        await _database.ref('users/$uid').set({
          'uid': uid,
          'email': email,
          'displayName': name,
          'role': 'user',
          'createdAt': DateTime.now().toIso8601String(),
        });
        return Account(uid: uid, email: email, displayName: name, role: 'user');
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
    return null;
  }

  Future<Account?> loginWithEmail(String email, String password) async {
    return signIn(email, password);
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'email-already-in-use':
        return 'An account already exists with this email';
      case 'weak-password':
        return 'Password is too weak';
      case 'invalid-email':
        return 'Invalid email address';
      default:
        return 'An error occurred. Please try again';
    }
  }

  DatabaseReference _getProjectsRef() {
    return _database.ref('projects');
  }

  DatabaseReference _getExpensesRef() {
    return _database.ref('expenses');
  }

  Future<List<Project>> fetchProjectsFromFirebase() async {
    final projectsSnapshot = await _getProjectsRef().get();
    final expensesSnapshot = await _getExpensesRef().get();

    if (projectsSnapshot.value == null) return [];

    final Map<dynamic, dynamic> projectsData =
        projectsSnapshot.value as Map<dynamic, dynamic>;
    final Map<dynamic, dynamic>? expensesData =
        expensesSnapshot.value as Map<dynamic, dynamic>?;

    final allExpenses = <String, List<Expense>>{};
    if (expensesData != null) {
      for (final entry in expensesData.entries) {
        final expense = Expense.fromJson(
          Map<String, dynamic>.from(entry.value as Map),
        );
        if (!allExpenses.containsKey(expense.projectId)) {
          allExpenses[expense.projectId] = [];
        }
        allExpenses[expense.projectId]!.add(expense);
      }
    }

    final projects = <Project>[];
    for (final entry in projectsData.entries) {
      final projectData = Map<String, dynamic>.from(entry.value as Map);
      final projectId = entry.key as String;
      final expenses = allExpenses[projectId] ?? [];
      projectData['expenses'] = expenses.map((e) => e.toJson()).toList();
      projects.add(Project.fromJson(projectData));
    }
    return projects;
  }

  Future<List<Expense>> fetchAllExpensesFromFirebase() async {
    final snapshot = await _getExpensesRef().get();
    if (snapshot.value == null) return [];

    final Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
    return data.entries
        .map(
          (entry) =>
              Expense.fromJson(Map<String, dynamic>.from(entry.value as Map)),
        )
        .toList();
  }

  Future<PersonalExpenseData> fetchPersonalExpenses() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return PersonalExpenseData.empty();
    }

    final userEmail = currentUser.email ?? '';
    final userName = currentUser.displayName ?? '';
    final userUid = currentUser.uid;

    final snapshot = await _getExpensesRef().get();
    if (snapshot.value == null) {
      return PersonalExpenseData.empty();
    }

    final Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;

    final allExpenses = data.entries
        .map(
          (entry) =>
              Expense.fromJson(Map<String, dynamic>.from(entry.value as Map)),
        )
        .toList();

    final personalExpenses = allExpenses.where((expense) {
      return expense.claimant == userEmail ||
          expense.claimant == userName ||
          expense.claimant == userUid;
    }).toList();

    final totalAmount = personalExpenses.fold<double>(
      0,
      (sum, e) => sum + e.amount,
    );

    final pendingAmount = personalExpenses
        .where((e) => e.paymentStatus?.toLowerCase() == 'pending')
        .fold<double>(0, (sum, e) => sum + e.amount);

    final categoryBreakdown = <String, double>{};
    for (final expense in personalExpenses) {
      final cat = expense.category.displayName;
      categoryBreakdown[cat] = (categoryBreakdown[cat] ?? 0) + expense.amount;
    }

    return PersonalExpenseData(
      expenses: personalExpenses,
      totalAmount: totalAmount,
      pendingAmount: pendingAmount,
      categoryBreakdown: categoryBreakdown,
    );
  }

  Stream<List<Project>> watchProjects() {
    return _getProjectsRef().onValue.map((event) {
      if (event.snapshot.value == null) return <Project>[];

      final Map<dynamic, dynamic> data =
          event.snapshot.value as Map<dynamic, dynamic>;
      return data.entries
          .map(
            (entry) =>
                Project.fromJson(Map<String, dynamic>.from(entry.value as Map)),
          )
          .toList();
    });
  }

  void dispose() {
    _authStateController.close();
  }
}
