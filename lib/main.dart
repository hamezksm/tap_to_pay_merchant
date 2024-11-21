import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:tap_to_pay_merchant/models/transaction.dart';
import 'package:tap_to_pay_merchant/screens/merchant_dashboard.dart';
import 'package:tap_to_pay_merchant/services/nfc_service.dart';
import 'package:tap_to_pay_merchant/state/transaction_state/transaction_cubit.dart';

void main() async {
  await Hive.initFlutter();
  Hive.registerAdapter(TransactionAdapter());
  await Hive.openBox<Transaction>('transactions');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Merchant Payment Terminal',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: BlocProvider(
        create: (context) => MerchantCubit(
          merchantId: 'merchantId', // Replace with actual merchantId
          nfcService: NFCService(),
          transactionBox: Hive.box<Transaction>('transactions'),
        ),
        child: const MerchantDashboard(),
      ),
    );
  }
}
