import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:provider/provider.dart';
import 'package:sparepark/models/booking_model.dart';
import 'package:sparepark/shared/auth_service.dart';
import 'package:sparepark/shared/style/contstants.dart';
import 'package:sparepark/shared/widgets/app_bar.dart';

class Payment extends StatefulWidget {
  final String b_id;
  final double total;
  final String address;
  final String postcode;

  const Payment({
    Key? key,
    required this.b_id,
    required this.total,
    required this.address,
    required this.postcode,
  }) : super(key: key);

  @override
  _PaymentState createState() => _PaymentState();
}

class _PaymentState extends State<Payment> {
  Map<String, dynamic>? paymentIntent;

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final isLoggedInStream = authService.user!.map((user) => user != null);
    return Scaffold(
        appBar: CustomAppBar(
          title: 'Pay',
          isLoggedInStream: isLoggedInStream,
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Center(
              child: Text(
                '${widget.address}',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Center(
              child: Text(
                '${widget.postcode}',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 16),
            Center(
              child: Text(
                '£${widget.total}',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
            SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Constants().primaryColor,
                ),
                onPressed: () async {
                  await makePayment();
                },
                child: Text('Make Payment'),
              ),
            ),
          ],
        ));
  }

  Future<void> makePayment() async {
    try {
      paymentIntent = await createPaymentIntent(
        widget.total.toStringAsFixed(2),
        'GBP',
      );

      await Stripe.instance
          .initPaymentSheet(
            paymentSheetParameters: SetupPaymentSheetParameters(
              paymentIntentClientSecret: paymentIntent!['client_secret'],
              style: ThemeMode.dark,
              merchantDisplayName: 'Spare Park',
            ),
          )
          .then((_) {});

      await Stripe.instance.presentPaymentSheet().then((_) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green,
                    ),
                    Text("Payment Successful"),
                  ],
                ),
              ],
            ),
          ),
        );

        paymentIntent = null;
      }).onError((error, stackTrace) {
        print('Error is:--->$error $stackTrace');
      });
    } on StripeException catch (e) {
      print('Error is:---> $e');
      showDialog(
        context: context,
        builder: (_) => const AlertDialog(
          content: Text("Cancelled "),
        ),
      );
    } catch (e) {
      print('$e');
    }
  }

  Future<Map<String, dynamic>> createPaymentIntent(
    String amount,
    String currency,
  ) async {
    try {
      final calculatedAmount = (double.parse(amount) * 100).toInt();
      final body = {
        'amount': calculatedAmount.toString(),
        'currency': currency,
        'payment_method_types[]': 'card'
      };

      final response = await http.post(
        Uri.parse('https://api.stripe.com/v1/payment_intents'),
        headers: {
          'Authorization':
              'Bearer sk_test_51N4eusA3A5lLQKKz6dxEn2tp4Lo5p858G1GN9AuoTR29rjE4JxMOrA1nqFeXDpzMo2AjfHTd4gDkUrVemhLw95FM005PPx9ygl',
          'Content-Type': 'application/x-www-form-urlencoded'
        },
        body: body,
      );
      print('Payment Intent Body->>> ${response.body.toString()}');

      await placeInFireBase(response.body);

      return jsonDecode(response.body);
    } catch (err) {
      print('err charging user: ${err.toString()}');
      rethrow;
    }
  }

  placeInFireBase(responseBody) async {
    responseBody.toString();
    final responseJson = jsonDecode(responseBody);
    final paymentIntentId = responseJson['id'];
    print(paymentIntentId);
    final bookingRef = FirebaseFirestore.instance.collection('bookings').doc(widget
        .b_id); // Replace <document-id> with the ID of the document you want to update
    await bookingRef.update({
      'paid': true,
      'paymentId': paymentIntentId,
    });
    print(paymentIntentId);
  }
}
