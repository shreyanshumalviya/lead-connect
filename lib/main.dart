import 'package:call/screen/home.dart';
import 'package:call/screen/login_screen.dart';
import 'package:call/screen/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:call/core/config.dart';
import 'package:permission_handler/permission_handler.dart';
// import 'package:phone_state_background/phone_state_background.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    requestPermissions();
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

Future<void> requestPermissions() async {
  var status = await Permission.phone.request();
  if (status.isGranted) {
    print("Phone permission granted");
    // Proceed with your app logic
  } else if (status.isDenied) {
    print("Phone permission denied");
    // You can show a dialog to the user explaining why the permission is needed
  } else if (status.isPermanentlyDenied) {
    print("Phone permission permanently denied");
    // You can open app settings to let the user enable the permission
    openAppSettings();
  } else {
    print("Phone permission denied");
  }
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
