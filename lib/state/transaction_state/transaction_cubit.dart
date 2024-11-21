import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:tap_to_pay_merchant/models/transaction.dart';
import 'package:tap_to_pay_merchant/services/nfc_service.dart';
import 'package:tap_to_pay_merchant/state/transaction_state/transaction_state.dart';

class MerchantCubit extends Cubit<MerchantState> {
  final NFCService _nfcService;
  final String merchantId;
  final Box<Transaction> _transactionBox;
  bool _isListening = false;

  MerchantCubit({
    required this.merchantId,
    required NFCService nfcService,
    required Box<Transaction> transactionBox,
  })  : _nfcService = nfcService,
        _transactionBox = transactionBox,
        super(MerchantInitial()) {
    loadTransactions();
  }

  Future<void> startListeningForPayment() async {
    if (_isListening) return;

    try {
      // Check NFC availability first
      final canReceive = await _nfcService.canReceiveNFCPayments();
      if (!canReceive) {
        emit(MerchantError('NFC is not available on this device'));
        return;
      }

      _isListening = true;
      emit(NFCListening());

      await _nfcService.startPaymentReceiver(
        (userId, amount, currency, timestamp) async {
          try {
            final transaction = Transaction(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              merchantId: merchantId,
              customerId: userId,
              amount: double.parse(amount),
              timestamp:
                  DateTime.fromMillisecondsSinceEpoch(int.parse(timestamp)),
              description: 'NFC Payment',
              status: TransactionStatus.completed,
              currency: currency,
            );

            await _recordTransaction(transaction);
            emit(PaymentReceived(transaction));

            // Reload transactions after recording new one
            await loadTransactions();

            // Reset to listening state to show ready for next payment
            emit(NFCListening());
          } catch (e) {
            emit(MerchantError('Failed to process payment: ${e.toString()}'));
            // Reset to listening state after error
            emit(NFCListening());
          }
        },
      );
    } catch (e) {
      _isListening = false;
      emit(MerchantError(
          'Failed to start NFC payment listener: ${e.toString()}'));
    }
  }

  Future<void> stopListeningForPayment() async {
    if (!_isListening) return;

    try {
      await _nfcService.stopPaymentReceiver();
      _isListening = false;
      emit(MerchantInitial());
    } catch (e) {
      emit(MerchantError(
          'Failed to stop NFC payment listener: ${e.toString()}'));
    }
  }

  Future<void> loadTransactions() async {
    try {
      final transactions = _transactionBox.values
          .where((transaction) => transaction.merchantId == merchantId)
          .toList()
        ..sort((a, b) =>
            b.timestamp.compareTo(a.timestamp)); // Sort by newest first

      final totalRevenue = transactions.fold(
        0.0,
        (sum, transaction) => sum + transaction.amount,
      );

      emit(TransactionHistoryLoaded(transactions, totalRevenue));
    } catch (e) {
      emit(MerchantError('Failed to load transactions: ${e.toString()}'));
    }
  }

  Future<void> _recordTransaction(Transaction transaction) async {
    try {
      await _transactionBox.put(transaction.id, transaction);
    } catch (e) {
      throw Exception('Failed to record transaction: ${e.toString()}');
    }
  }

  @override
  Future<void> close() async {
    await stopListeningForPayment();
    return super.close();
  }
}
