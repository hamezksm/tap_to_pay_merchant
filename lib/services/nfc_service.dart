import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:ndef/ndef.dart' as ndef;

// Callback type definition for payment processing
typedef PaymentCallback = void Function(
    String userId, String amount, String currency, String timestamp);

class NFCService {
  Future<void> startPaymentReceiver(PaymentCallback onPaymentReceived) async {
    try {
      // Check NFC availability
      var availability = await FlutterNfcKit.nfcAvailability;
      if (availability != NFCAvailability.available) {
        throw Exception('NFC not available on this device');
      }

      while (true) {
        try {
          // Start listening for NFC payments
          NFCTag tag = await FlutterNfcKit.poll(
            timeout: const Duration(seconds: 30),
            iosMultipleTagMessage: "Multiple devices detected",
            iosAlertMessage: "Waiting for customer payment...",
          );

          // Verify if tag contains NDEF data
          if (tag.ndefAvailable ?? false) {
            var ndefRecords = await FlutterNfcKit.readNDEFRecords();

            for (var record in ndefRecords) {
              if (record is ndef.UriRecord) {
                // Parse payment data from URI format
                String paymentData = _parsePaymentUri(record.payload!);
                if (paymentData.isNotEmpty) {
                  // Parse the payment data
                  final parts = paymentData.split('|');
                  if (parts.length == 4) {
                    final userId = parts[0];
                    final amount = parts[1];
                    final currency = parts[2];
                    final timestamp = parts[3];

                    // Notify callback of received payment
                    onPaymentReceived(userId, amount, currency, timestamp);
                  }
                }
              }
            }
          }

          // Complete this reading session
          await FlutterNfcKit.finish(iosAlertMessage: "Payment received!");
        } catch (e) {
          print('Error during payment reading: $e');
          await FlutterNfcKit.finish(iosErrorMessage: "Payment reading failed");
        }
      }
    } catch (e) {
      print('Fatal NFC error: $e');
      await FlutterNfcKit.finish();
    }
  }

  String _parsePaymentUri(List<int> payload) {
    try {
      String fullUri = String.fromCharCodes(payload);
      // Remove 'pay://' prefix
      if (fullUri.startsWith('pay://')) {
        return fullUri.substring(6);
      }
      return '';
    } catch (e) {
      print('Error parsing payment URI: $e');
      return '';
    }
  }

  // Method to stop listening for payments
  Future<void> stopPaymentReceiver() async {
    try {
      await FlutterNfcKit.finish();
    } catch (e) {
      print('Error stopping NFC payment receiver: $e');
    }
  }

  // Check if device can receive NFC payments
  Future<bool> canReceiveNFCPayments() async {
    try {
      var availability = await FlutterNfcKit.nfcAvailability;
      return availability == NFCAvailability.available;
    } catch (e) {
      print('Error checking NFC capability: $e');
      return false;
    }
  }
}

// Example usage:
/*
void main() {
  final merchantService = MerchantNFCPaymentService();
  
  merchantService.startPaymentReceiver((userId, amount, currency, timestamp) {
    print('Payment received!');
    print('User ID: $userId');
    print('Amount: $amount $currency');
    print('Timestamp: $timestamp');
    
    // Process payment in your backend
    processPayment(userId, amount, currency, timestamp);
  });
}
*/