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

  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseDatabase get _database => FirebaseDatabase.instance;

  final StreamController<Account?> _authStateController =
      StreamController<Account?>.broadcast();
  bool _isInitialized = false;
  bool _hasFiredInitial = false;
  Account? _currentAccount;

  FirebaseService._init();

  Stream<Account?> get onAuthStateChanged => _authStateController.stream;
  User? get currentUser => _auth.currentUser;
  String? get currentUserUid => _auth.currentUser?.uid;
  bool get hasFiredInitial => _hasFiredInitial;
  Account? get currentAccount => _currentAccount;

  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;

    try {
      _auth.authStateChanges().listen((user) async {
        if (user != null) {
          final snapshot = await _database.ref('users/${user.uid}').get();
          String? displayName = user.displayName;
          String role = 'user';
          if (snapshot.value != null) {
            final userData = Map<String, dynamic>.from(snapshot.value as Map);
            displayName =
                userData['displayName'] as String? ?? user.displayName;
            role = userData['role'] as String? ?? 'user';
          }
          final account = Account(
            uid: user.uid,
            email: user.email ?? '',
            displayName: displayName,
            role: role,
          );
          _currentAccount = account;
          _hasFiredInitial = true;
          _authStateController.add(account);
        } else {
          _currentAccount = null;
          _hasFiredInitial = true;
          _authStateController.add(null);
        }
      });
    } catch (e) {
      print('FirebaseService initialize failed: $e');
      _currentAccount = null;
      _hasFiredInitial = true;
      _authStateController.add(null);
    }
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

  Map<String, dynamic> _mapProjectData(
    Map<String, dynamic> data,
    String? explicitId,
  ) {
    final mapped = Map<String, dynamic>.from(data);
    mapped['id'] = mapped['projectId'] ?? explicitId ?? '';
    if (mapped['isActive'] == null && mapped['status'] != null) {
      mapped['isActive'] =
          mapped['status'] != 'Completed' && mapped['status'] != 'Cancelled';
    }
    mapped['budget'] = (mapped['budget'] ?? 0).toDouble();
    mapped['spent'] = (mapped['spent'] ?? 0).toDouble();
    return mapped;
  }

  Map<String, dynamic> _mapExpenseData(Map<String, dynamic> data) {
    final mapped = Map<String, dynamic>.from(data);
    mapped['description'] = mapped['description'] ?? mapped['title'] ?? '';
    mapped['category'] = mapped['category'] ?? mapped['type'] ?? '';
    mapped['paymentMethod'] =
        mapped['paymentMethod'] ?? mapped['payment_method'] ?? 'Cash';
    mapped['paymentStatus'] =
        mapped['paymentStatus'] ?? mapped['payment_status'] ?? 'Pending';
    mapped['amount'] = (mapped['amount'] ?? 0).toDouble();
    return mapped;
  }

  Future<List<Project>> fetchProjectsFromFirebase() async {
    final projectsSnapshot = await _getProjectsRef().get().timeout(
      const Duration(seconds: 10),
    );
    final expensesSnapshot = await _getExpensesRef().get().timeout(
      const Duration(seconds: 10),
    );

    if (projectsSnapshot.value == null) return [];

    final Map<dynamic, dynamic> projectsData =
        projectsSnapshot.value as Map<dynamic, dynamic>;
    final Map<dynamic, dynamic>? expensesData =
        expensesSnapshot.value as Map<dynamic, dynamic>?;

    final allExpenses = <String, List<Expense>>{};
    if (expensesData != null) {
      for (final entry in expensesData.entries) {
        final rawExpenseData = Map<String, dynamic>.from(entry.value as Map);
        final expense = Expense.fromJson(_mapExpenseData(rawExpenseData));
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

      projectData['id'] = projectData['projectId'] ?? projectId;
      projectData['isActive'] =
          projectData['status'] != 'Completed' &&
          projectData['status'] != 'Cancelled';
      projectData['budget'] = (projectData['budget'] ?? 0).toDouble();
      projectData['spent'] = (projectData['spent'] ?? 0).toDouble();

      projectData['expenses'] = expenses.map((e) => e.toJson()).toList();
      projects.add(Project.fromJson(projectData));
    }
    return projects;
  }

  Future<List<Expense>> fetchAllExpensesFromFirebase() async {
    final snapshot = await _getExpensesRef().get();
    if (snapshot.value == null) return [];

    final Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
    return data.entries.map((entry) {
      final expenseData = Map<String, dynamic>.from(entry.value as Map);
      return Expense.fromJson(_mapExpenseData(expenseData));
    }).toList();
  }

  Future<void> pushExpenseToFirebase(Expense expense) async {
    await _getExpensesRef().child(expense.id).set(expense.toJson());
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

    final allExpenses = data.entries.map((entry) {
      final rawExpenseData = Map<String, dynamic>.from(entry.value as Map);
      return Expense.fromJson(_mapExpenseData(rawExpenseData));
    }).toList();

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
      return data.entries.map((entry) {
        final rawProjectData = Map<String, dynamic>.from(entry.value as Map);
        return Project.fromJson(
          _mapProjectData(rawProjectData, entry.key as String),
        );
      }).toList();
    });
  }

  void dispose() {
    _authStateController.close();
  }
}
