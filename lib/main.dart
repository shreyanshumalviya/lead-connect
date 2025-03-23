import 'package:call/phone_state_handler/phone_state_handler.dart';
import 'package:call/screen/home.dart';
import 'package:call/screen/login_screen.dart';
import 'package:call/screen/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:call/core/config.dart';
// import 'package:phone_state_background/phone_state_background.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize phone state background service
    // await PhoneStateBackground.initialize(phoneStateBackgroundCallbackHandler);

    // Request necessary permissions
    // await PhoneStateBackground.requestPermissions();
    // Retry any failed requests from previous sessions
    // await retryFailedRequests();
  } catch (e) {
    print('Failed to initialize phone state background: $e');
    // Handle initialization failure appropriately
  }
  await ApiConstants.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calling is our Duty',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const MyHomePage(title: 'Calling is our Duty'),
      },
    );
  }
}
