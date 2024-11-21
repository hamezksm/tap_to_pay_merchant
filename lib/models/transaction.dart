import 'package:hive/hive.dart';

part 'transaction.g.dart';

@HiveType(typeId: 0)
class Transaction extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String merchantId;

  @HiveField(2)
  final String customerId;

  @HiveField(3)
  final double amount;

  @HiveField(4)
  final DateTime timestamp;

  @HiveField(5)
  final String description;

  @HiveField(6)
  final TransactionStatus status;

  @HiveField(7)
  final String currency;

  Transaction({
    required this.id,
    required this.merchantId,
    required this.customerId,
    required this.amount,
    required this.timestamp,
    required this.description,
    required this.status,
    required this.currency,
  });
}

enum TransactionStatus {
  pending,
  completed,
  failed,
}
