enum ExpenseCategory {
  materials,
  travel,
  equipment,
  labor,
  software,
  marketing,
  utilities,
  other,
}

extension ExpenseCategoryExtension on ExpenseCategory {
  String get displayName {
    switch (this) {
      case ExpenseCategory.materials:
        return 'Materials';
      case ExpenseCategory.travel:
        return 'Travel';
      case ExpenseCategory.equipment:
        return 'Equipment';
      case ExpenseCategory.labor:
        return 'Labor';
      case ExpenseCategory.software:
        return 'Software';
      case ExpenseCategory.marketing:
        return 'Marketing';
      case ExpenseCategory.utilities:
        return 'Utilities';
      case ExpenseCategory.other:
        return 'Other';
    }
  }

  String get icon {
    switch (this) {
      case ExpenseCategory.materials:
        return '🛒';
      case ExpenseCategory.travel:
        return '✈️';
      case ExpenseCategory.equipment:
        return '🔧';
      case ExpenseCategory.labor:
        return '👷';
      case ExpenseCategory.software:
        return '💻';
      case ExpenseCategory.marketing:
        return '📢';
      case ExpenseCategory.utilities:
        return '💡';
      case ExpenseCategory.other:
        return '📦';
    }
  }

  static ExpenseCategory fromString(String value) {
    return ExpenseCategory.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ExpenseCategory.other,
    );
  }
}

class Expense {
  final String id;
  final String description;
  final double amount;
  final ExpenseCategory category;
  final DateTime date;
  final String projectId;
  final String? imageUrl;
  final String? claimant;
  final String? paymentStatus;

  const Expense({
    required this.id,
    required this.description,
    required this.amount,
    required this.category,
    required this.date,
    required this.projectId,
    this.imageUrl,
    this.claimant,
    this.paymentStatus,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description': description,
      'amount': amount,
      'category': category.name,
      'date': date.toIso8601String(),
      'projectId': projectId,
      'imageUrl': imageUrl,
      'claimant': claimant,
      'paymentStatus': paymentStatus,
    };
  }

  static DateTime _parseDate(String? dateStr) {
    if (dateStr == null) return DateTime.now();
    try {
      return DateTime.parse(dateStr);
    } catch (_) {
      try {
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

  factory Expense.fromMap(Map<String, dynamic> map) {
    // Dart field takes priority over Java field
    final desc =
        map['description'] as String? ?? map['title'] as String? ?? 'Untitled';

    // Safe amount parsing
    final amountVal = (map['amount'] as num?)?.toDouble() ?? 0.0;

    // Dart field takes priority over Java field
    final categoryStr =
        map['category'] as String? ?? map['type'] as String? ?? '';
    final categoryVal = ExpenseCategoryExtension.fromString(categoryStr);

    return Expense(
      id: map['id'] as String? ?? '',
      description: desc,
      amount: amountVal,
      category: categoryVal,
      date: _parseDate(map['date'] as String?),
      projectId: map['projectId'] as String? ?? '',
      imageUrl: map['imageUrl'] as String?,
      claimant: map['claimant'] as String?,
      paymentStatus: map['paymentStatus'] as String?,
    );
  }

  Map<String, dynamic> toJson() => toMap();

  factory Expense.fromJson(Map<String, dynamic> json) => Expense.fromMap(json);

  Expense copyWith({
    String? id,
    String? description,
    double? amount,
    ExpenseCategory? category,
    DateTime? date,
    String? projectId,
    String? imageUrl,
    String? claimant,
    String? paymentStatus,
  }) {
    return Expense(
      id: id ?? this.id,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      date: date ?? this.date,
      projectId: projectId ?? this.projectId,
      imageUrl: imageUrl ?? this.imageUrl,
      claimant: claimant ?? this.claimant,
      paymentStatus: paymentStatus ?? this.paymentStatus,
    );
  }
}
