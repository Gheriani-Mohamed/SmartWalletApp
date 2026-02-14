class SavingGoalModel {
  final double currentAmount;
  final String endDate;
  final String id;
  final String startDate;
  final double targetAmount;
  final String title;
  final String userId;
  final String walletId;

  SavingGoalModel({
    required this.currentAmount,
    required this.endDate,
    required this.id,
    required this.startDate,
    required this.targetAmount,
    required this.title,
    required this.userId,
    required this.walletId,
  });

  // Calculated properties
  double get percentageComplete {
    if (targetAmount == 0) return 0;
    return (currentAmount / targetAmount) * 100;
  }

  bool get isCompleted => currentAmount >= targetAmount;
  double get remainingAmount => targetAmount - currentAmount;

  // Parse dates
  DateTime get endDateTime => DateTime.parse(endDate);
  DateTime get startDateTime => DateTime.parse(startDate);

  // From JSON
  factory SavingGoalModel.fromJson(Map<String, dynamic> json) {
    return SavingGoalModel(
      currentAmount: (json['currentAmount'] ?? 0).toDouble(),
      endDate: json['endDate'] ?? '',
      id: json['id'] ?? '',
      startDate: json['startDate'] ?? '',
      targetAmount: (json['targetAmount'] ?? 0).toDouble(),
      title: json['title'] ?? '',
      userId: json['userId'] ?? '',
      walletId: json['walletId'] ?? '',
    );
  }

  // To JSON
  Map<String, dynamic> toJson() {
    return {
      'currentAmount': currentAmount,
      'endDate': endDate,
      'id': id,
      'startDate': startDate,
      'targetAmount': targetAmount,
      'title': title,
      'userId': userId,
      'walletId': walletId,
    };
  }
}