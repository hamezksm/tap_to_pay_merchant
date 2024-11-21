import 'package:tap_to_pay_merchant/models/transaction.dart';

abstract class MerchantState {}

class MerchantInitial extends MerchantState {}

class NFCListening extends MerchantState {}

class PaymentReceived extends MerchantState {
  final Transaction transaction;
  PaymentReceived(this.transaction);
}

class MerchantError extends MerchantState {
  final String message;
  MerchantError(this.message);
}

class TransactionHistoryLoaded extends MerchantState {
  final List<Transaction> transactions;
  final double totalRevenue;
  TransactionHistoryLoaded(this.transactions, this.totalRevenue);
}
