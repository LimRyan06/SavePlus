import 'package:cloud_firestore/cloud_firestore.dart';

/// The user’s savings goal.
class GoalModel {
  final double amount;
  final DateTime createdAt;

  GoalModel({
    required this.amount,
    required this.createdAt,
  });

  /// Construct from a Firestore document snapshot.
  factory GoalModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GoalModel(
      amount: (data['amount'] as num).toDouble(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  /// Convert to a map for uploading to Firestore.
  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
