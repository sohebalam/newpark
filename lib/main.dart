import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:sparepark/firebase_options.dart';
// import 'package:sparepark/screens/auth/register_screen.dart';
import 'package:sparepark/screens/mapscreens/map_home.dart';
import 'package:provider/provider.dart';
import 'package:sparepark/shared/auth_service.dart';
import 'package:sparepark/shared/widgets/drawer.dart';
// import 'package:flutter_stripe/flutter_stripe.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Stripe.publishableKey =
  //     'pk_test_51N4eusA3A5lLQKKzHmKCZVaUW7lheJqD1xgmoQuKagsz0glmNUx9flCfp5xriz07jBWU51DYRzfv2eGwEZsmkhZm00lWvz2Dqb';
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(
          create: (_) => AuthService(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Flutter Auth Example',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        initialRoute: '/map_home',
        routes: {
          '/map_home': (context) => MapHome(),
          // '/register': (context) => RegisterScreen(),
        },
      ),
    );
  }
}
