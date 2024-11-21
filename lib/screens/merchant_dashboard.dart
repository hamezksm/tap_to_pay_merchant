import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tap_to_pay_merchant/models/transaction.dart';
import 'package:tap_to_pay_merchant/state/transaction_state/transaction_cubit.dart';
import 'package:tap_to_pay_merchant/state/transaction_state/transaction_state.dart';

class MerchantDashboard extends StatelessWidget {
  const MerchantDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment Terminal')),
      body: BlocConsumer<MerchantCubit, MerchantState>(
        listener: (context, state) {
          if (state is PaymentReceived) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:
                    Text('Payment received: \$${state.transaction.amount}'),
                backgroundColor: Colors.green,
              ),
            );
          }
          if (state is MerchantError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          return Column(
            children: [
              if (state is TransactionHistoryLoaded) ...[
                _RevenueSummaryCard(
                  totalRevenue: state.totalRevenue,
                  transactionCount: state.transactions.length,
                ),
                Expanded(
                  child: _TransactionList(
                    transactions: state.transactions,
                  ),
                ),
              ],
              _PaymentReceiveSection(
                isListening: state is NFCListening,
                onStartListening: () {
                  context.read<MerchantCubit>().startListeningForPayment();
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RevenueSummaryCard extends StatelessWidget {
  final double totalRevenue;
  final int transactionCount;

  const _RevenueSummaryCard({
    required this.totalRevenue,
    required this.transactionCount,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total Revenue: \$${totalRevenue.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Transactions: $transactionCount',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionList extends StatelessWidget {
  final List<Transaction> transactions;

  const _TransactionList({required this.transactions});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final transaction = transactions[index];
        return ListTile(
          title: Text('Transaction ID: ${transaction.id}'),
          subtitle: Text(
            'Amount: \$${transaction.amount.toStringAsFixed(2)}\n'
            'Description: ${transaction.description}\n'
            'Timestamp: ${transaction.timestamp}',
          ),
        );
      },
    );
  }
}

class _PaymentReceiveSection extends StatelessWidget {
  final bool isListening;
  final VoidCallback onStartListening;

  const _PaymentReceiveSection({
    required this.isListening,
    required this.onStartListening,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          ElevatedButton(
            onPressed: isListening ? null : onStartListening,
            child: isListening
                ? const CircularProgressIndicator()
                : const Text('Start Listening for Payment'),
          ),
        ],
      ),
    );
  }
}
