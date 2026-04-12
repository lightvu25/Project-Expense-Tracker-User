import 'expense.dart';

class Project {
  final String id;
  final String name;
  final String description;
  final double budget;
  final double spent;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isActive;
  final List<Expense> expenses;
  bool isFavorite;

  Project({
    required this.id,
    required this.name,
    required this.description,
    required this.budget,
    required this.spent,
    required this.startDate,
    this.endDate,
    required this.isActive,
    required this.expenses,
    this.isFavorite = false,
  });

  double get remaining => budget - spent;
  double get progress => budget > 0 ? spent / budget : 0;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'budget': budget,
      'spent': spent,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'isActive': isActive ? 1 : 0,
      'isFavorite': isFavorite ? 1 : 0,
      'expenses': expenses.map((e) => e.toMap()).toList(),
    };
  }

  static DateTime _parseDate(String? dateStr) {
    if (dateStr == null) return DateTime.now();
    try {
      // Try ISO-8601 first
      return DateTime.parse(dateStr);
    } catch (_) {
      try {
        // Try dd/MM/yyyy format
        final parts = dateStr.split('/');
        if (parts.length == 3) {
          final day = int.parse(parts[0]);
          final month = int.parse(parts[1]);
          final year = int.parse(parts[2]);
          return DateTime(year, month, day);
        }
      } catch (_) {}
      return DateTime.now();
    }
  }

  factory Project.fromMap(
    Map<String, dynamic> map, {
    List<Expense>? expenses,
    bool? isFavorite,
  }) {
    final budgetVal = (map['budget'] as num?)?.toDouble() ?? 0.0;
    final spentVal = (map['spent'] as num?)?.toDouble() ?? 0.0;

    // Handle isActive - Java sends status field, NOT isActive
    bool isActiveVal = true;
    if (map['status'] != null) {
      isActiveVal = map['status'] != 'Completed';
    } else if (map['isActive'] != null) {
      isActiveVal = map['isActive'] == 1 || map['isActive'] == true;
    }

    final isFav =
        isFavorite ?? (map['isFavorite'] == 1 || map['isFavorite'] == true);

    return Project(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? 'Unnamed Project',
      description: map['description'] as String? ?? '',
      budget: budgetVal,
      spent: spentVal,
      startDate: _parseDate(map['startDate'] as String?),
      endDate: map['endDate'] != null
          ? _parseDate(map['endDate'] as String?)
          : null,
      isActive: isActiveVal,
      expenses: expenses ?? [],
      isFavorite: isFav,
    );
  }

  Map<String, dynamic> toJson() => toMap();

  factory Project.fromJson(Map<String, dynamic> json) {
    final expenseList = json['expenses'] as List<dynamic>?;
    final isFav = json['isFavorite'] == 1 || json['isFavorite'] == true;
    return Project.fromMap(
      json,
      expenses:
          expenseList
              ?.map((e) => Expense.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      isFavorite: isFav,
    );
  }

  Project copyWith({
    String? id,
    String? name,
    String? description,
    double? budget,
    double? spent,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    List<Expense>? expenses,
    bool? isFavorite,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      budget: budget ?? this.budget,
      spent: spent ?? this.spent,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      expenses: expenses ?? this.expenses,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}

class Account {
  final String uid;
  final String email;
  final String? displayName;
  final String role;

  const Account({
    required this.uid,
    required this.email,
    this.displayName,
    this.role = 'user',
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'role': role,
    };
  }

  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
      uid: map['uid'] as String,
      email: map['email'] as String,
      displayName: map['displayName'] as String?,
      role: map['role'] as String? ?? 'user',
    );
  }

  Map<String, dynamic> toJson() => toMap();

  factory Account.fromJson(Map<String, dynamic> json) => Account.fromMap(json);
}
